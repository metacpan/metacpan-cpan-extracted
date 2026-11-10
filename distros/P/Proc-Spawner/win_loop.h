/* win_loop.h: the Windows backend of Proc::Spawner::Loop (W5, post-0.10; the user, 2026-11-08: "Use the Windows'
   way").  One I/O completion port receives every event:
     - a read or write on a handle opened for overlapped I/O: issued so, its completion comes from the system;
     - a read or write on a synchronous handle (an anonymous pipe, an end shared with children, a console): a helper
       thread does it, blocking, and posts the result;
     - a child's end: RegisterWaitForSingleObject on its process handle, whose callback posts it.
   Each operation is a wl_op whose first member is its OVERLAPPED, so a completion leads back to it.  The loop takes
   the completions with wl_wait.  Memory comes from the process heap (win_malloc and co., win_spawn.h), never from
   the CRT under Perl's macros.  Included by Spawner.xs on Windows only. */
#ifndef WIN_LOOP_H
#define WIN_LOOP_H
#include <windows.h>
#include <io.h>
#include <fcntl.h>
#include <errno.h>

#define WL_KEY_IO 1       /* the completion of overlapped I/O on a handle associated with the port */
#define WL_KEY_POSTED 2   /* posted by a helper thread or a wait callback */
#define WL_KEY_WAKE 3     /* posted by the console control handler (Ctrl-C, Ctrl-Break, close, shutdown) */

typedef struct wl_op {
    OVERLAPPED ov;               /* first: (wl_op *)the OVERLAPPED of a completion */
    IV id; char kind;            /* 'r', 'w', 'c' */
    HANDLE h;                    /* the file (r, w), or the process (c, opened here) */
    HANDLE thread, wait;         /* the helper thread (synchronous handles), or RegisterWaitForSingleObject's */
    char *buf; DWORD len, done;  /* r: the buffer; w: the bytes, how many are written */
    DWORD err;                   /* the Windows error, 0 if none */
    volatile LONG cancelled, posted;
    int async;                   /* overlapped I/O on h */
    struct wl_op *next, *prev;   /* the live operations */
} wl_op;

static HANDLE wl_port;
static wl_op *wl_ops;

static int wl_init(void) {
    if (!wl_port) wl_port = CreateIoCompletionPort(INVALID_HANDLE_VALUE, NULL, 0, 1);
    return wl_port != NULL;
}

static wl_op *wl_new(IV id, char kind) {
    wl_op *op = (wl_op *)win_calloc(1, sizeof *op);
    if (!op) return NULL;
    op->id = id; op->kind = kind;
    op->next = wl_ops; if (wl_ops) wl_ops->prev = op; wl_ops = op;
    return op;
}
static void wl_free(wl_op *op) {
    if (op->prev) op->prev->next = op->next; else wl_ops = op->next;
    if (op->next) op->next->prev = op->prev;
    if (op->thread) CloseHandle(op->thread);
    if (op->kind == 'c' && op->h) CloseHandle(op->h);
    win_free(op->buf); win_free(op);
}
static wl_op *wl_find(IV id) { wl_op *op; for (op = wl_ops; op; op = op->next) if (op->id == id) return op; return NULL; }

/* Was the handle opened for overlapped I/O?  FileModeInformation (16) has neither FILE_SYNCHRONOUS_IO_ALERT (0x10)
   nor FILE_SYNCHRONOUS_IO_NONALERT (0x20) then.  A handle the call does not know (a console): synchronous. */
typedef LONG (NTAPI *wl_nqif_t)(HANDLE, PVOID, PVOID, ULONG, ULONG);
static int wl_is_async(HANDLE h) {
    static wl_nqif_t nqif; ULONG mode = 0; ULONG_PTR iosb[2];
    if (!nqif) nqif = (wl_nqif_t)GetProcAddress(GetModuleHandleA("ntdll.dll"), "NtQueryInformationFile");
    if (!nqif || nqif(h, iosb, &mode, sizeof mode, 16) != 0) return 0;
    return !(mode & 0x30);
}

/* While the loop waits (Perl's wait_until), a console control handler of ours wakes it: Windows calls the newest
   handler first, so ours posts a wake-up and returns FALSE, and Perl's own (win32_ctrlhandler) then marks the signal
   pending (with a Perl handler in %SIG) or ends the process (the default).  Since ours runs first, the wait gives
   Perl's a moment to mark the signal before it returns (__wl_wait). */
static volatile LONG wl_woken;
static int wl_ctrl_on;
static BOOL WINAPI wl_ctrl(DWORD type) {
    (void)type; InterlockedExchange(&wl_woken, 1);
    if (wl_port) PostQueuedCompletionStatus(wl_port, 0, WL_KEY_WAKE, NULL);
    return FALSE;
}
static int wl_ctrl_watch(int on) {   /* 1 if the handler is (on) or is no longer (off) installed */
    if (!on == !wl_ctrl_on) return 1;
    if (!wl_init() || !SetConsoleCtrlHandler(wl_ctrl, on ? TRUE : FALSE)) return 0;
    wl_ctrl_on = on; return 1;
}

static void wl_post(wl_op *op) { InterlockedExchange(&op->posted, 1); PostQueuedCompletionStatus(wl_port, op->done, WL_KEY_POSTED, &op->ov); }

static DWORD WINAPI wl_thread(LPVOID p) {   /* a read or a write on a synchronous handle, blocking */
    wl_op *op = (wl_op *)p; DWORD n;
    if (op->kind == 'r') {
        if (!op->cancelled && !ReadFile(op->h, op->buf, op->len, &n, NULL)) { op->err = GetLastError(); n = 0; }
        else if (op->cancelled) n = 0;
        op->done = n;
    } else {
        while (op->done < op->len && !op->cancelled) {
            if (!WriteFile(op->h, op->buf + op->done, op->len - op->done, &n, NULL)) { op->err = GetLastError(); break; }
            op->done += n;
        }
    }
    wl_post(op);
    return 0;
}

static int wl_issue(wl_op *op) {   /* the next overlapped read or write; 0 with op->err if it could not start */
    BOOL ok; DWORD e;
    memset(&op->ov, 0, sizeof op->ov);
    ok = op->kind == 'r' ? ReadFile(op->h, op->buf, op->len, NULL, &op->ov)
                         : WriteFile(op->h, op->buf + op->done, op->len - op->done, NULL, &op->ov);
    if (ok || (e = GetLastError()) == ERROR_IO_PENDING) return 1;   /* (success too: its completion is queued) */
    op->err = e; return 0;
}

/* Start a read (kind 'r', at most len bytes) or a write (kind 'w', the len bytes at data) on fd: 1, or 0 with errno. */
static int wl_io(IV id, char kind, int fd, const char *data, DWORD len) {
    intptr_t hv = _get_osfhandle(fd); wl_op *op;
    if (hv == -1 || hv == -2) { errno = EBADF; return 0; }
    if (!wl_init() || !(op = wl_new(id, kind))) { errno = ENOMEM; return 0; }
    op->h = (HANDLE)hv; op->len = kind == 'r' ? (len ? len : 1) : len;
    if (!(op->buf = (char *)win_malloc(op->len))) { wl_free(op); errno = ENOMEM; return 0; }
    if (kind == 'w') memcpy(op->buf, data, len);
    if (kind == 'w' && len == 0) { wl_post(op); return 1; }
    op->async = wl_is_async(op->h);
    if (op->async) {   /* associated once with the port (a second time fails, and needs not succeed) */
        CreateIoCompletionPort(op->h, wl_port, WL_KEY_IO, 0);
        if (!wl_issue(op)) wl_post(op);
        return 1;
    }
    op->thread = CreateThread(NULL, 64 * 1024, wl_thread, op, STACK_SIZE_PARAM_IS_A_RESERVATION, NULL);
    if (!op->thread) { wl_free(op); errno = EAGAIN; return 0; }
    return 1;
}

static VOID CALLBACK wl_exited(PVOID p, BOOLEAN timed_out) { (void)timed_out; wl_post((wl_op *)p); }

/* Watch the process pid for its end: 1, or 0 with errno (ESRCH: no such process to open). */
static int wl_child(IV id, DWORD pid) {
    wl_op *op;
    if (!wl_init() || !(op = wl_new(id, 'c'))) { errno = ENOMEM; return 0; }
    op->h = OpenProcess(SYNCHRONIZE, FALSE, pid);
    if (!op->h) { wl_free(op); errno = ESRCH; return 0; }
    if (!RegisterWaitForSingleObject(&op->wait, op->h, wl_exited, op, INFINITE, WT_EXECUTEONLYONCE)) {
        wl_free(op); errno = EAGAIN; return 0; }
    return 1;
}

/* Stop an operation: no event comes for it.  An operation still in flight is freed when its completion arrives. */
static void wl_cancel(IV id) {
    wl_op *op = wl_find(id);
    if (!op) return;
    InterlockedExchange(&op->cancelled, 1);
    if (op->kind == 'c') {
        UnregisterWaitEx(op->wait, INVALID_HANDLE_VALUE); op->wait = NULL;   /* (waits for a running callback) */
        if (!op->posted) wl_free(op);
    } else if (op->async) CancelIoEx(op->h, &op->ov);
    else if (op->thread && !op->posted) CancelSynchronousIo(op->thread);
}

static int wl_errno(DWORD e) {
    switch (e) {
    case ERROR_BROKEN_PIPE: case ERROR_NO_DATA: case ERROR_PIPE_NOT_CONNECTED: return EPIPE;
    case ERROR_INVALID_HANDLE: return EBADF;
    case ERROR_ACCESS_DENIED: return EACCES;
    case ERROR_NOT_ENOUGH_MEMORY: case ERROR_OUTOFMEMORY: return ENOMEM;
    case ERROR_OPERATION_ABORTED: return EINTR;
    default: return EIO;
    }
}

/* One completion taken from the port: 1 and the operation (no longer live) when it is an event to report, 0 when
   it is not one (a cancelled operation, now freed; an overlapped write with more to write, issued again). */
static int wl_complete(wl_op *op, DWORD n, ULONG_PTR key) {
    if (key == WL_KEY_IO) {
        DWORD got = 0;
        if (!GetOverlappedResult(op->h, &op->ov, &got, FALSE)) op->err = GetLastError();
        if (op->kind == 'r') op->done = got;
        else {
            op->done += got;
            if (!op->err && !op->cancelled && op->done < op->len) { if (wl_issue(op)) return 0; }
        }
    } else (void)n;
    if (op->kind == 'c' && op->wait) { UnregisterWaitEx(op->wait, NULL); op->wait = NULL; }
    if (op->cancelled) { wl_free(op); return 0; }
    return 1;
}

/* A pipe whose read end (async_r) and/or write end (async_w) are opened for overlapped I/O: a named pipe of its own
   (the read end the server); neither end inherited.  The two fds, or -1 with errno. */
static int wl_pipe(int async_r, int async_w, int *rfd, int *wfd) {
    static LONG serial; wchar_t name[96]; HANDLE r, w; SECURITY_ATTRIBUTES sa = { sizeof sa, NULL, FALSE };
    _snwprintf(name, 96, L"\\\\.\\pipe\\Proc-Spawner-%lu-%ld", (unsigned long)GetCurrentProcessId(), (long)InterlockedIncrement(&serial));
    r = CreateNamedPipeW(name, PIPE_ACCESS_INBOUND | FILE_FLAG_FIRST_PIPE_INSTANCE | (async_r ? FILE_FLAG_OVERLAPPED : 0),
                         PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT | PIPE_REJECT_REMOTE_CLIENTS, 1, 65536, 65536, 0, &sa);
    if (r == INVALID_HANDLE_VALUE) { errno = wl_errno(GetLastError()); return -1; }
    w = CreateFileW(name, GENERIC_WRITE, 0, &sa, OPEN_EXISTING, async_w ? FILE_FLAG_OVERLAPPED : 0, NULL);
    if (w == INVALID_HANDLE_VALUE) { errno = wl_errno(GetLastError()); CloseHandle(r); return -1; }
    *rfd = _open_osfhandle((intptr_t)r, _O_RDONLY | _O_BINARY);
    *wfd = _open_osfhandle((intptr_t)w, _O_WRONLY | _O_BINARY);
    if (*rfd < 0 || *wfd < 0) {
        if (*rfd >= 0) _close(*rfd); else CloseHandle(r);
        if (*wfd >= 0) _close(*wfd); else CloseHandle(w);
        errno = EMFILE; return -1;
    }
    return 0;
}

#endif
