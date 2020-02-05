AC_PREREQ(2.63)
AC_INIT([libruncap], [m4_esyscmd_s([git describe])], [gray+runcap@gnu.org.ua])
AC_CONFIG_SRCDIR([runcap.c])
AM_INIT_AUTOMAKE([1.11 foreign tar-ustar silent-rules])

# Enable silent rules by default:
AM_SILENT_RULES([yes])

# Checks for programs.
AC_PROG_CC

RUNCAP_SETUP([.],m4_esyscmd_s([echo ${RUNCAP_BUILD:-install}]))
	      
# Generate files
AC_OUTPUT
