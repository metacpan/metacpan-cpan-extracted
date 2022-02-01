#include <sys/syscall.h>
#include <unistd.h>

int main() {
    char message[] = "Goodbye.\n";
    syscall(SYS_write, STDOUT_FILENO, message, sizeof(message) - 1);

    return 0;
}
