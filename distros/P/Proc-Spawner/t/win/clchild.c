/* clchild.exe [STATUS [SLEEP_MS]]: prints its command line, directory, FOO, the show-window setting, whether Ctrl-C is
   off for it (a new process group: ConsoleFlags in its process parameters), in UTF-8; the child of t/win/thooks.c and
   of t/win_spawn.t's checks through Proc::Spawner */
#include <windows.h>
#include <winternl.h>
#include <stdio.h>
#include <stdlib.h>
static void u8(const wchar_t *w) { char b[8192]; WideCharToMultiByte(CP_UTF8, 0, w, -1, b, sizeof b, NULL, NULL); fputs(b, stdout); }
int main(int argc, char **argv)
{
    wchar_t d[1024], v[1024]; STARTUPINFOW si; si.cb = sizeof si; GetStartupInfoW(&si);
    printf("cl="); u8(GetCommandLineW()); printf("\n");
    GetCurrentDirectoryW(1024, d); printf("cwd="); u8(d); printf("\n");
    if (GetEnvironmentVariableW(L"FOO", v, 1024)) { printf("FOO="); u8(v); printf("\n"); } else printf("FOO unset\n");
    printf("show=%d,%d\n", (si.dwFlags & STARTF_USESHOWWINDOW) != 0, si.wShowWindow);
    {   /* our PEB's RTL_USER_PROCESS_PARAMETERS: 4 ULONGs, ConsoleHandle, then ConsoleFlags (1: Ctrl-C ignored, as
           CREATE_NEW_PROCESS_GROUP sets it); NtQueryInformationProcess looked up, so that nothing more is linked */
        typedef LONG (WINAPI *nqip_t)(HANDLE, PROCESSINFOCLASS, PVOID, ULONG, PULONG);
        nqip_t q = (nqip_t)(void (*)(void))GetProcAddress(GetModuleHandleA("ntdll.dll"), "NtQueryInformationProcess");
        PROCESS_BASIC_INFORMATION bi; ULONG n;
        if (q && q(GetCurrentProcess(), ProcessBasicInformation, &bi, sizeof bi, &n) >= 0) {
            const char *pp = (const char *)bi.PebBaseAddress->ProcessParameters;
            printf("ctrlc_off=%lu\n", (unsigned long)(*(const ULONG *)(pp + 4 * sizeof(ULONG) + sizeof(HANDLE)) & 1));
        }
        else printf("ctrlc_off unknown\n");
    }
    fflush(stdout);
    if (argc > 2) Sleep(atoi(argv[2]));
    return argc > 1 ? atoi(argv[1]) : 0;
}
