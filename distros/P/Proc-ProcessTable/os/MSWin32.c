/* 

	Adapted from ps.cc by J Robert Ray <jrray@jrray.org>


   ps.cc

   Copyright 1996, 1997, 1998, 1999, 2000, 2001, 2002 Red Hat, Inc.

This file is part of Cygwin.

This software is a copyrighted work licensed under the terms of the
Cygwin license.  Please consult the file "CYGWIN_LICENSE" for
details. */

#include <stdio.h>
#include <windows.h>
#include <time.h>
#include <stdlib.h>
#include <tlhelp32.h>
#include <psapi.h>

#ifdef USE_CYGWIN
#include <getopt.h>
#include <unistd.h>
#include <pwd.h>
#include <sys/cygwin.h>
#else
#include <sddl.h>
#endif

#include "os/MSWin32.h"


#ifdef USE_CYGWIN
typedef DWORD (WINAPI *GETMODULEFILENAME)(
  HANDLE hProcess,
  HMODULE hModule,
  LPTSTR lpstrFileName,
  DWORD nSize
);
#endif

typedef HANDLE (WINAPI *CREATESNAPSHOT)(
    DWORD dwFlags,
    DWORD th32ProcessID
);

typedef BOOL (WINAPI *PROCESSWALK)(
    HANDLE hSnapshot,
    LPPROCESSENTRY32 lppe
);

#ifdef USE_CYGWIN
typedef struct external_pinfo external_pinfo;

GETMODULEFILENAME myGetModuleFileNameEx;
#endif

CREATESNAPSHOT myCreateToolhelp32Snapshot;
PROCESSWALK myProcess32First;
PROCESSWALK myProcess32Next;

static int init_win_result = FALSE;

extern void bless_into_proc(char* , char**, ...);

#ifdef USE_CYGWIN
// Win95 functions
static DWORD WINAPI GetModuleFileNameEx95 (
  HANDLE hProcess,
  HMODULE hModule,
  LPTSTR lpstrFileName,
  DWORD n
)
{
  HANDLE h;
  DWORD pid = (DWORD) hModule;
  PROCESSENTRY32 proc;

  h = myCreateToolhelp32Snapshot (TH32CS_SNAPPROCESS, 0);
  if (!h)
    return 0;

  proc.dwSize = sizeof (proc);
  if (myProcess32First(h, &proc))
    do
      if (proc.th32ProcessID == pid)
	{
	  CloseHandle (h);
	  strcpy (lpstrFileName, proc.szExeFile);
	  return 1;
	}
    while (myProcess32Next (h, &proc));
  CloseHandle (h);
  return 0;
}
#endif

int
init_win ()
{
  HMODULE h;

#ifdef USE_CYGWIN
  OSVERSIONINFO os_version_info;

  memset (&os_version_info, 0, sizeof os_version_info);
  os_version_info.dwOSVersionInfoSize = sizeof (OSVERSIONINFO);
  GetVersionEx (&os_version_info);

  if (os_version_info.dwPlatformId == VER_PLATFORM_WIN32_NT)
    {
      h = LoadLibrary ("psapi.dll");
      if (!h)
	return 0;
      myGetModuleFileNameEx = (GETMODULEFILENAME) GetProcAddress (h, "GetModuleFileNameExA");
      if (!myGetModuleFileNameEx)
	return 0;
      return 1;
    }
#endif

  h = GetModuleHandle("KERNEL32.DLL");
  myCreateToolhelp32Snapshot = (CREATESNAPSHOT)GetProcAddress (h, "CreateToolhelp32Snapshot");
  myProcess32First = (PROCESSWALK)GetProcAddress (h, "Process32First");
  myProcess32Next  = (PROCESSWALK)GetProcAddress (h, "Process32Next");
  if (!myCreateToolhelp32Snapshot || !myProcess32First || !myProcess32Next)
    return 0;

#ifdef USE_CYGWIN
  myGetModuleFileNameEx = GetModuleFileNameEx95;
#endif
  return 1;
}

#define FACTOR (0x19db1ded53ea710LL)
#define NSPERSEC 10000000LL

/* Convert a Win32 time to "UNIX" format. */
static long
to_time_t (FILETIME *ptr)
{
  /* A file time is the number of 100ns since jan 1 1601
     stuffed into two long words.
     A time_t is the number of seconds since jan 1 1970.  */

  long rem;
  long long x = ((long long) ptr->dwHighDateTime << 32) + ((unsigned)ptr->dwLowDateTime);
  x -= FACTOR;                  /* number of 100ns between 1601 and 1970 */
  rem = x % ((long long)NSPERSEC);
  rem += (NSPERSEC / 2);
  x /= (long long) NSPERSEC;            /* number of 100ns in a second */
  x += (long long) (rem / NSPERSEC);
  return x;
}

#ifdef USE_CYGWIN

void
OS_get_table()
{
  external_pinfo *p;
  int uid;
  cygwin_getinfo_types query = CW_GETPINFO;
  char ch;
  int pid;
  char *pstate;
  char pname[MAX_PATH];
  char uname[128];
  char *fields;

  uid = getuid ();

  (void) cygwin_internal (CW_LOCK_PINFO, 1000);

  if (query == CW_GETPINFO && !init_win_result)
    query = CW_GETPINFO;

  for (pid = 0;
       (p = (external_pinfo *) cygwin_internal (query, pid | CW_NEXTPID));
       pid = p->pid)
    {
      pstate = " ";
      if (p->process_state & PID_STOPPED)
	pstate = "stopped";
      else if (p->process_state & PID_TTYIN)
	pstate = "ttyin";
      else if (p->process_state & PID_TTYOU)
	pstate = "ttyout";
#ifdef PID_ORPHANED
      if (p->process_state & (PID_ORPHANED | PID_EXITED))
#else
      if (p->process_state & PID_EXITED)
#endif
        strcpy (pname, "<defunct>");
      else if (p->ppid)
	{
	  char *s;
	  pname[0] = '\0';
	  cygwin_conv_path((CCP_RELATIVE|CCP_WIN_A_TO_POSIX), p->progname, pname, PATH_MAX);
	  s = strchr (pname, '\0') - 4;
	  if (s > pname && strcasecmp (s, ".exe") == 0)
	    *s = '\0';
	}
      else if (query == CW_GETPINFO)
	{
	  FILETIME ct, et, kt, ut;
	  HANDLE h = OpenProcess (PROCESS_QUERY_INFORMATION | PROCESS_VM_READ,
	  			  FALSE, p->dwProcessId);
	  if (!h)
	    continue;
	  if (!myGetModuleFileNameEx (h, myProcess32First ? p->dwProcessId : NULL, pname, MAX_PATH))
	    strcpy (pname, "*** unknown ***");
	  if (GetProcessTimes (h, &ct, &et, &kt, &ut))
	    p->start_time = to_time_t (&ct);
	  CloseHandle (h);
	}

        {
          struct passwd *pw;

          if ((pw = getpwuid (p->version >= EXTERNAL_PINFO_VERSION_32_BIT ?
	                      p->uid32 : p->uid)))
            strcpy (uname, pw->pw_name);
          else
            sprintf (uname, "%u", (unsigned)
	             (p->version >= EXTERNAL_PINFO_VERSION_32_BIT ?
		      p->uid32 : p->uid));
        }

	if (query == CW_GETPINFO) {
		fields = "iiiiisiis";
	} else {
		fields = "iiiiisIis";
	}

	bless_into_proc(fields, Fields, 

		p->version >= EXTERNAL_PINFO_VERSION_32_BIT ? p->uid32 : p->uid,
		p->pid,
		p->ppid,
		p->pgid,
		p->dwProcessId,
		pname,
		p->start_time,
		p->ctty,
		pstate
	);

    }
  (void) cygwin_internal (CW_UNLOCK_PINFO);
}

#else

static void get_process_owner(HANDLE process, char string_sid[184], char user_name[256], char domain_name[255])
{
  HANDLE process_token;
  PTOKEN_USER token_user;
  DWORD token_user_size;
  char *string_sid_ptr;
  size_t string_sid_len;
  DWORD user_name_size;
  DWORD domain_name_size;
  SID_NAME_USE sid_type;

  string_sid[0] = 0;
  user_name[0] = 0;
  domain_name[0] = 0;

  if (!OpenProcessToken (process, TOKEN_QUERY, &process_token))
    return;

  if (!GetTokenInformation (process_token, TokenUser, NULL, 0, &token_user_size) && GetLastError () != ERROR_INSUFFICIENT_BUFFER)
    {
      CloseHandle (process_token);
      return;
    }

  token_user = malloc (token_user_size);
  if (!token_user)
    {
      CloseHandle (process_token);
      return;
    }

  if (!GetTokenInformation (process_token, TokenUser, token_user, token_user_size, &token_user_size))
    {
      free (token_user);
      CloseHandle (process_token);
      return;
    }

  if (ConvertSidToStringSidA (token_user->User.Sid, &string_sid_ptr))
    {
      string_sid_len = strlen (string_sid_ptr);
      if (string_sid_len < 184)
        memcpy (string_sid, string_sid_ptr, string_sid_len+1);
      LocalFree (string_sid_ptr);
    }

  user_name_size = 256;
  domain_name_size = 256;
  if (!LookupAccountSidA (NULL, token_user->User.Sid, user_name, &user_name_size, domain_name, &domain_name_size, &sid_type) && GetLastError () == ERROR_NONE_MAPPED)
    {
      strcpy (user_name, "NONE_MAPPED");
      strcpy (domain_name, "NONE_MAPPED");
    }

  free (token_user);
  CloseHandle (process_token);
}

static unsigned long get_uid_from_string_sid(char *string_sid)
{
  char *uid_ptr;
  char *ptr;

  uid_ptr = strrchr (string_sid, '-');
  if (!uid_ptr)
    return 0;

  uid_ptr++;

  for (ptr = uid_ptr; *ptr; ptr++)
    if (*ptr < '0' || *ptr > '9')
      return 0;

  return strtoul (uid_ptr, NULL, 10);
}

void
OS_get_table()
{
  HANDLE proc;
  HANDLE snapshot;
  PROCESSENTRY32 proc_entry;
  FILETIME ct, et, kt, ut;
  char string_sid[184];
  char user_name[256];
  char domain_name[256];
  unsigned long uid;
  long start_time;

  if (!init_win_result)
    return;

  snapshot = myCreateToolhelp32Snapshot (TH32CS_SNAPPROCESS, 0);
  if (!snapshot)
    return;

  proc_entry.dwSize = sizeof (proc_entry);
  if (myProcess32First (snapshot, &proc_entry))
    do
      {
        uid = 0;
        start_time = 0;

        proc = OpenProcess (PROCESS_QUERY_INFORMATION, FALSE, proc_entry.th32ProcessID);
        if (proc)
          {
            if (GetProcessTimes (proc, &ct, &et, &kt, &ut))
              start_time = to_time_t (&ct);
            get_process_owner (proc, string_sid, user_name, domain_name);
            CloseHandle (proc);
          }

        uid = get_uid_from_string_sid (string_sid);

        bless_into_proc ("pppslsss", Fields,
          uid,
          proc_entry.th32ProcessID,
          proc_entry.th32ParentProcessID,
          proc_entry.szExeFile,
          start_time,
          string_sid,
          user_name,
          domain_name
        );
      }
    while (myProcess32Next (snapshot, &proc_entry));

  CloseHandle (snapshot);
}

#endif

char*
OS_initialize()
{
	init_win_result = init_win();

	return NULL;
}

