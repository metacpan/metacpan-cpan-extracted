#include <internal/sighandl.h>

#ifdef _TV_UNIX

#include <stdlib.h>

namespace tvision
{

std::atomic<SignalHandlerCallback *> SignalHandler::callback {nullptr};
const int SignalHandler::handledSignals[HandledSignalCount] =
    { SIGINT, SIGQUIT, SIGILL, SIGABRT, SIGBUS, SIGFPE, SIGSEGV, SIGPIPE, SIGTERM, SIGTSTP };

static bool operator==(const struct sigaction &a, const struct sigaction &b) noexcept
{
    constexpr int knownFlags =
        SA_NOCLDSTOP | SA_NOCLDWAIT | SA_SIGINFO | SA_ONSTACK | SA_RESTART |
        SA_NODEFER | SA_RESETHAND;
    return ((a.sa_flags & knownFlags) == (b.sa_flags & knownFlags)) &&
        ((a.sa_flags & SA_SIGINFO) ? a.sa_sigaction == b.sa_sigaction
                                   : a.sa_handler == b.sa_handler);
}

void SignalHandler::enable(SignalHandlerCallback &aCallback) noexcept
{
    if (!callback)
    {
        struct sigaction sa = makeHandlerAction();
        for (int signo : handledSignals)
            sigaction(signo, &sa, &getHandlerInfo(signo).action);
        callback = &aCallback;
    }
}

void SignalHandler::disable() noexcept
{
    if (callback)
    {
        callback = nullptr;
        for (int signo : handledSignals)
        {
            auto &handlerInfo = getHandlerInfo(signo);
            struct sigaction sa = {};
            sigaction(signo, nullptr, &sa);
            // Restore the previous handler only if ours is still installed.
            if (sa == makeHandlerAction())
                sigaction(signo, &handlerInfo.action, nullptr);
            handlerInfo.action = makeDefaultAction();
        }
    }
}

SignalHandler::HandlerInfo &SignalHandler::getHandlerInfo(int signo) noexcept
{
    static HandlerInfo infos[HandledSignalCount];
    switch (signo)
    {
        case SIGINT:    return infos[SigInt];
        case SIGQUIT:   return infos[SigQuit];
        case SIGILL:    return infos[SigIll];
        case SIGABRT:   return infos[SigAbrt];
        case SIGBUS:    return infos[SigBus];
        case SIGFPE:    return infos[SigFpe];
        case SIGSEGV:   return infos[SigSegv];
        case SIGPIPE:   return infos[SigPipe];
        case SIGTERM:   return infos[SigTerm];
        case SIGTSTP:   return infos[SigTstp];
        default:        abort();
    }
}

void SignalHandler::handleSignal(int signo, siginfo_t *info, void *context)
{
    // In a multi-threaded application the signal handler may be changed from
    // another thread while this one is running, but there's nothing we can do
    // about it.
    auto &handlerInfo = getHandlerInfo(signo);
    struct sigaction currentAction {};
    SignalHandlerCallback *callback;
    if ((callback = SignalHandler::callback) && handlerInfo.running.exchange(true) == false)
    {
        struct sigaction nextAction = handlerInfo.action;
        // Uninstall the current action, just in case this signal gets raised
        // again while invoking the callback.
        sigaction(signo, nullptr, &currentAction);
        // Invoke the callback, which should be signal-safe in theory.
        callback(true);
        // Install and invoke the action that was in place when we installed
        // our handler.
        sigaction(signo, &nextAction, nullptr);
        if (invokeHandlerOrDefault(signo, nextAction, info, context))
            // In some cases it is necessary to exit this handler.
            return;
        // If the process didn't get killed, get ready to resume normal process
        // execution.
        callback(false);
        // Reinstall the action that was in place when this handler was invoked.
        sigaction(signo, &currentAction, nullptr);
        handlerInfo.running = false;
    }
    else
    {
        // In the unexpected case where our handler was invoked even though
        // it is already running or no callback was specified, just invoke the
        // default handler.
        struct sigaction sa = makeDefaultAction();
        sigaction(signo, &sa, &currentAction);
        if (invokeDefault(signo, info))
            return;
        // Reinstall the action that was in place when this handler was invoked.
        sigaction(signo, &currentAction, nullptr);
    }
}

template <class T>
static inline bool isCustomHandler(T &&handler)
{
    return (void *) handler != (void *) SIG_DFL
        && (void *) handler != (void *) SIG_IGN;
}

bool SignalHandler::invokeHandlerOrDefault( int signo, const struct sigaction &action,
                                            siginfo_t *info, void *context ) noexcept
{
    // If the handler is a custom one, invoke it directly.
    if ((action.sa_flags & SA_SIGINFO) && isCustomHandler(action.sa_sigaction))
        action.sa_sigaction(signo, info, context);
    else if (!(action.sa_flags & SA_SIGINFO) && isCustomHandler(action.sa_handler))
        action.sa_handler(signo);
    else
        // Run default handler by re-raising the signal.
        return invokeDefault(signo, info);
    return false;
}

bool SignalHandler::invokeDefault(int signo, siginfo_t *info) noexcept
{
    // Allow synchronous signals sent by the kernel to be raised again by exiting
    // the handler. This will preserve the original stack trace, si_addr, etc.
    if ( (signo == SIGILL || signo == SIGBUS || signo == SIGFPE || signo == SIGSEGV)
         && info->si_code > 0 )
        return true;
    // Otherwise, raise the signal manually.
    sigset_t mask, oldMask;
    sigemptyset(&mask);
    // Unblock this signal.
    sigaddset(&mask, signo);
    sigprocmask(SIG_UNBLOCK, &mask, &oldMask);
    raise(signo);
    // If the process didn't get killed, restore the original mask.
    sigprocmask(SIG_SETMASK, &oldMask, nullptr);
    return false;
}

} // namespace tvision

#endif // _TV_UNIX
