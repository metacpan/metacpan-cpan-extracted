/*
 * see if a string can represent a (base10) integer
 */
static int __is_int(char *str, int strlen) {
	char *p;
	char *end = str + strlen;

	for(p = str; p<end; ++p) {
		if(*p == '.') { return 0; }
	}

	return 1;
}

/*
 * verify pid is an integer... or else "abc" becomes (int)(0)
 * note: if the scalar isn't in int-ready format, make it so and
 * do error checking to rule out strings like "abc", floats like
 * 1.32, and negative integers
 */
static int get_pid(SV* pid_sv) {
	STRLEN len;
	char *pidstr = SvPV(pid_sv, len);
	int pid;

	if(!SvIOKp(pid_sv)) {
		pidstr = SvPV(pid_sv, len);
		if(__is_int(pidstr, len)) {
			if(sscanf(pidstr, "%d", &pid) == 0) {
				croak("got non-number pid: '%s'", pidstr);
			} else {
				/* warn("converted %s to int: %d outside of perlapi", pidstr, pid); */
			}
		} else {
			croak("got non-integer pid: '%s'", pidstr);
		}
	} else {
		pid = SvIV(pid_sv);
	}
	if (pid < 0) {
		croak("got negative pid: '%s'", SvPV(pid_sv, len));
	}
	return pid;
}

/*
 * do whatever platform-specific goop is necessary to determine if
 * a single pid exists or not
 */
static int __pexists(int pid) {
#ifdef WIN32
	/*
	 * this is much faster than iterating over a process snapshot,
	 * and more closely mirrors the POSIX code, but it has a weirdness
	 * on NTish systems - namely if these exists a pid 4, pid's 5, 6,
	 * and 7 will also return true. something in the windows guts is
	 * chopping off the bottom two bits, see:
	 * http://blogs.msdn.com/oldnewthing/archive/2008/02/28/7925962.aspx
	 */
	HANDLE hProcess;

#ifdef win32_pids_mult4
	if(pid % 4) {
		warn("windows ignored the bottom 2 bits of the pid %d, beware!", pid);
	};
#endif

	hProcess = OpenProcess( PROCESS_QUERY_INFORMATION, FALSE, pid );
	if(hProcess == NULL) {
		return 0;
	} else {
		CloseHandle( hProcess );
		return 1;
	}
#else
	int ret;

	ret = kill(pid, 0);
	/*
	 * existent process w/ perms:  ret: 0
	 * existent process w/o perms: ret: -1, err: EPERM
	 * nonexistent process:        ret: -1, err: ESRCH
	 */
	if(ret == 0) {
		return 1;
	} else if(ret == -1) {
		if(errno == EPERM) {
			return 1;
		} else if(errno == ESRCH) {
			return 0;
		} else {
			croak("unknown errno: %d", errno);
		}
	} else {
		croak("kill returned something other than 0 or -1: %d", ret);
	}
#endif
	croak("internal error: we should never get here");

}

