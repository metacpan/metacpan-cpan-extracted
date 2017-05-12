/*
 * check-pw-wrapper.c - setgid wrapper so that Slauth routines in the
 * web server can have limited access to Mailman subscription info.
 * Using a setgid wrapper helps enforce/maintain separation of HTTPD
 * and Mailman resources, rather than opening holes for direct access.
 */ 

#include <stdio.h>
#include <errno.h>
#include <sys/types.h>
#include <grp.h>
#include <unistd.h>

#ifndef MAILMAN_GROUP
#  define MAILMAN_GROUP	"mailman"
#endif
#ifndef PERL_PATH
#  define PERL_PATH	"/usr/bin/perl"
#endif
#ifndef CHECKPW_NAME
#  define CHECKPW_NAME	"/home/mailman/slauth-bin/check-pw.pl"
#endif

int main( int argc, char *argv[] )
{
	struct group *grent;
	int result, in_fd, out_fd;

	if ( argc < 3 ) {
		fprintf ( stderr, "usage: %s in-fd out-fd\n" );
		exit ( 1 );
	}

	/*
	 * Handle fd's which are not already located at stdin/stdout.
	 * This unscrambles file descriptors from mod_perl2/perl5.8
	 * (which is straightforward in C) so the check-pw.pl script
	 * can simply use stdin and stdout.  As a workaround to the
	 * Fd-scrambling problem under mod_perl/PerlIO, the input and
	 * output FD numbers were provided on the command line.
	 */
	in_fd = atoi(argv[1]);
	out_fd = atoi(argv[2]);
	if ( in_fd != 0 || out_fd != 1 ) {
		/* handle pathological case first */
		if ( in_fd == 1 && out_fd == 0 ) {
			if ( close( 3 ) == -1 ) {
				perror ( "check-pw-wrapper(close#1)" );
				exit ( 1 );
			}
			if ( dup2( in_fd, 3 ) == -1 ) {
				perror ( "check-pw-wrapper(dup2#1)" );
				exit ( 1 );
			}
			if ( close( 1 ) == -1 ) {
				perror ( "check-pw-wrapper(close#2)" );
				exit ( 1 );
			}
			if ( dup2( out_fd, 1 ) == -1 ) {
				perror ( "check-pw-wrapper(dup2#2)" );
				exit ( 1 );
			}
			if ( close( 0 ) == -1 ) {
				perror ( "check-pw-wrapper(close#3)" );
				exit ( 1 );
			}
			if ( dup2( 3, 0) == -1 ) {
				perror ( "check-pw-wrapper(dup2#3)" );
				exit ( 1 );
			}
		} else if ( out_fd == 0 ) {
			if ( close( 1 ) == -1 ) {
				perror ( "check-pw-wrapper(close#4)" );
				exit ( 1 );
			}
			if ( dup2( out_fd, 1 ) == -1 ) {
				perror ( "check-pw-wrapper(dup2#4)" );
				exit ( 1 );
			}
			if ( dup2( in_fd, 0 ) == -1 ) {
				perror ( "check-pw-wrapper(dup2#5)" );
				exit ( 1 );
			}
		} else {
			if ( in_fd != 0 ) {
				if ( close( 0 ) == -1 ) {
					perror ( "check-pw-wrapper(close#5)" );
					exit ( 1 );
				}
				if ( dup2( in_fd, 0 ) == -1 ) {
					perror ( "check-pw-wrapper(dup2#6)" );
					exit ( 1 );
				}
			}
			if ( out_fd != 1 ) {
				if ( close( 1 ) == -1 ) {
					perror ( "check-pw-wrapper(close#6)" );
					exit ( 1 );
				}
				if ( dup2( out_fd, 1 ) == -1 ) {
					perror ( "check-pw-wrapper(dup2#7)" );
					exit ( 1 );
				}
			}
		}
	}

	/* enter the mailman group */
	/* this will only succeed if the program has the setgid bit */
	grent = getgrnam ( MAILMAN_GROUP );
	result = setgid ( grent->gr_gid );
	if ( result == -1 ) {
		perror ( "check-pw-wrapper(setgid)" );
		exit ( 1 );
	}

	/* execute the script */
	execl ( PERL_PATH, "perl", CHECKPW_NAME, (void*) 0 );

	/*
	 * execl does not return if it succeeded in executing the program
	 * because it replaces this program.  If we got here, it failed!
	 */
	
	perror ( "check-pw-wrapper(execl)" );
	exit ( 1 );
	
}
