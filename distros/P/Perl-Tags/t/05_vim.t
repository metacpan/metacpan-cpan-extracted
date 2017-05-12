use strict; use warnings;
use Data::Dumper;

use Test::More tests=>1;
use Test::LongString;

use FindBin qw( $Bin );
use File::Copy;
use File::Temp qw( tempdir );

# In make test or prove, STDOUT is piped.  Vim doesn't like
# this, so we're going to save the current output and pipe
# STDOUT to where STDERR is currently going (Still to a terminal)

SKIP: {

    my $version = `vim --version 2>&1`;
    if ($?) {
        skip "error calling vim - perhaps it isn't installed? '$!'", 1;
    }

    if ($version !~ /\+perl/) {
        skip "Looks like your vim isn't compiled with perl", 1;
    }

    my $tempdir = tempdir( 'perltagsXXXX', CLEANUP => 1 );

    my $temp = "$tempdir/Test.pm";
    copy( "$Bin/Test.pm", $temp ) or die "Couldn't copy $temp to $tempdir: $!";

    local *OLD_OUT = *STDOUT;
    open STDOUT, '>&STDERR' or die "Can't open STDOUT as dup of STDERR: $!";

    local $ENV{test_tempdir} = $tempdir;

    my $result = 
    system vim =>
             -u => 't/_vimrc',        # use our vimrc to add Perl::Tags settings etc.
             -S => 't/session.vim',   # use our session file to make modfications to file
            '-n',                     # don't use swapfile
            $temp;

    # restore STDOUT
    *STDOUT = *OLD_OUT;

    $result and skip "System call to vim failed: $!", 1;

    open (my $FH, '<', $temp) or die "Couldn't open $temp: $!";
    local $/ = undef;
    my $modified = <$FH>;
    my $expected = <DATA>;

    is_string ($modified, $expected, "Got expected info after jumping around tags in vim");
}

__DATA__
# Test line here
package Test;

use strict; use warnings;
use Data::Dumper;

# foo line here
# bar line here
my ($foo, $bar);

=head1 SYNOPSIS

    sub example {
        # this sub should not be parsed!
    }

=cut

# wibble line here
sub wibble {
    # blah
}

# TODO: test this line

1;
