package Template::Test::Latex;

use strict;
use vars qw(@ISA @EXPORT);
use Config;
use Template::Test;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(find_program grep_dvi dvitype require_dvitype);

our $WIN32  = ($^O eq 'MSWin32');

$Template::Plugin::Latex::DEBUG = grep(/-d/, @ARGV);
$Template::Plugin::Latex::DEBUG = $Template::Plugin::Latex::DEBUG;

my $dvitype = find_program($ENV{PATH}, "dvitype");

sub dvitype {
    return $dvitype;
}

sub require_dvitype {
    if (!$dvitype || ! -x $dvitype) {
        skip_all("'dvitype' is not available");
        exit(0);
    }
}


#------------------------------------------------------------------------
# find_program($path, $prog)
#
# Find a program, $prog, by traversing the given directory path, $path.
# Returns full path if the program is found.
#
# Written by Craig Barratt, Richard Tietjen add fixes for Win32.
#
# abw changed name from studly caps findProgram() to find_program() :-)
#------------------------------------------------------------------------

sub find_program {
    my($path, $prog) = @_;

    foreach my $dir ( split($Config{path_sep}, $path) ) {
        my $file = File::Spec->catfile($dir, $prog);
        if ( !$WIN32 ) {
            return $file if ( -x $file );
        } else {
            # Windows executables end in .xxx, exe precedes .bat and .cmd
            foreach my $dx ( qw/exe bat cmd/ ) {
                return "$file.$dx" if ( -x "$file.$dx" );
            }
        }
    }

}

sub grep_dvi {
    my $dir = shift;
    my $file = shift;
    my $regexp = shift;
    my $path = File::Spec->catfile($dir, $file);
    return "FAIL - $file does not exist" unless -f $path;
    return "FAIL - can't find dvitype" unless $dvitype and -x $dvitype;
    my $dvioutput =  `$dvitype $path`; 
    foreach (split(/\n/, $dvioutput)) {
	next unless /^\[(.*)\]$/;
	return "PASS - found '$regexp'" if /$regexp/;
    }
    return "FAIL - '$regexp' not found";
}

1;
