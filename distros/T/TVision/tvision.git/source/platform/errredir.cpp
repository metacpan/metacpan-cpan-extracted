#include <internal/errredir.h>

#ifdef _TV_UNIX

#include <initializer_list>
#include <stdio.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/ioctl.h>

namespace tvision
{

StderrRedirector::StderrRedirector() noexcept
{
    // Text written into standard error will mess up the display or simply
    // get lost since the application is using the alternate screen buffer,
    // with no scrollback.
    // Make 'stderr' point to a pipe buffer so that the contents can be
    // dumped to the screen after restoring the screen buffer.
    int flags;
    if ( fileno(stderr) == STDERR_FILENO
         && isatty(STDERR_FILENO)
         && (ttyFd = dup(STDERR_FILENO)) != -1
         && pipe(bufFd) != -1
         && dup2(bufFd[1], STDERR_FILENO) != -1
         && (flags = fcntl(STDERR_FILENO, F_GETFL)) != -1
         && fcntl(STDERR_FILENO, F_SETFL, flags | O_NONBLOCK) != -1
         && fcntl(ttyFd, F_SETFD, FD_CLOEXEC) != -1
         && fcntl(bufFd[0], F_SETFD, FD_CLOEXEC) != -1
         && fcntl(bufFd[1], F_SETFD, FD_CLOEXEC) != -1 )
    {
        // Success.
    }
    else
    {
        for (int fd : {ttyFd, bufFd[0], bufFd[1]})
            if (fd != -1)
                close(fd);
        ttyFd = bufFd[0] = bufFd[1] = -1;
    }
}

static bool isSameFile(int fd1, int fd2)
{
    struct stat stat1, stat2;
    return fstat(fd1, &stat1) != -1
        && fstat(fd2, &stat2) != -1
        && stat1.st_dev == stat2.st_dev
        && stat1.st_ino == stat2.st_ino;
}

static void writeFile(int dst, const char *buf, size_t size)
{
    size_t bytesLeft = size;
    ssize_t w;
    while ( bytesLeft > 0 &&
            (w = write(dst, &buf[size - bytesLeft], bytesLeft)) > 0 )
        bytesLeft -= (size_t) w;
}

static void dumpPipe(int src, int dst, size_t size)
{
    static thread_local char buf alignas(4096) [4096];
    size_t bytesLeft = size;
    ssize_t r;
    while ( bytesLeft > 0 &&
            (r = read(src, buf, min(bytesLeft, sizeof(buf)))) > 0 )
    {
        writeFile(dst, buf, (size_t) r);
        bytesLeft -= (size_t) r;
    }
}

StderrRedirector::~StderrRedirector()
{
    // Restore standard error to the default state as long as it still
    // refers to our buffer, then dump the buffer contents to it.
    // There are some edge cases that are not being handled here:
    // - read()/write() and EINTR.
    // - If the pipe keeps being written to as we read from it.
    // But this runs during program shutdown and we don't want to get stuck here.
    if (isSameFile(bufFd[1], STDERR_FILENO))
    {
        dup2(ttyFd, STDERR_FILENO);

        int size;
        if (ioctl(bufFd[0], FIONREAD, &size) != -1 && size > 0)
            dumpPipe(bufFd[0], ttyFd, (size_t) size);
    }

    for (int fd : {ttyFd, bufFd[0], bufFd[1]})
        if (fd != -1)
            close(fd);
}

} // namespace tvision

#endif // _TV_UNIX
