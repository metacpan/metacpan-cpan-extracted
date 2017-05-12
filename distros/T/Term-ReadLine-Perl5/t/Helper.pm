# Common code to all tests.
use Test::More;
use warnings; use strict;

BEGIN {
    $ENV{PERL_RL} = 'Perl5';	# force to use Term::ReadLine::Perl5
    $ENV{LANG} = 'C';
    $ENV{'COLUMNS'} = 80; $ENV{'ROWS'} = 25;

    # Set to not read ~/.inputrc
    # Tests that want this will reset $ENV{'INPUTRC'}
    $ENV{'INPUTRC'} = '/dev/null';
}

use File::Basename qw(dirname); use File::Spec;
my $dir = File::Spec->catfile(dirname(__FILE__));
$dir = File::Spec->rel2abs( $dir ) unless
    File::Spec->file_name_is_absolute( $dir );

my $readline_file = File::Spec->catfile($dir,
					qw(.. lib Term ReadLine readline.pm));
require $readline_file;

package Helper;
1;
