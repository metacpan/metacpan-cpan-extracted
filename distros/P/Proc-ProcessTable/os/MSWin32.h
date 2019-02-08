static char *Fields[] = {
	"uid",
	"pid",
	"ppid",
#ifdef USE_CYGWIN
	"pgid",
	"winpid",
#endif
	"fname",
	"start",
#ifdef USE_CYGWIN
	"ttynum",
	"state",
#endif

#ifndef USE_CYGWIN
	"sid",
	"user_name",
	"domain_name",
#endif
};
