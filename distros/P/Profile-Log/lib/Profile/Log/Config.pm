#  -*- perl -*-

package Profile::Log::Config;

our $TT_INSTDIR = "__error_Makefile.PL__";

$TT_INSTDIR = "templates/" if $TT_INSTDIR =~ m/^__/;

1;
