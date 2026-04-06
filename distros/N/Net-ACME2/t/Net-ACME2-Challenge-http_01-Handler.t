use strict;
use warnings;
use autodie;

use Test::More;
use Test::FailWarnings;
use Test::Deep;
use Test::Exception;

use File::Spec ();
use File::Slurp ();
use File::Temp ();

use Net::ACME2::Challenge::http_01 ();

use Net::ACME2::Challenge::http_01::Handler ();

#----------------------------------------------------------------------

my $challenge = Net::ACME2::Challenge::http_01->new(
    token => 'my_token',
);

my $docroot = File::Temp::tempdir( CLEANUP => 1 );

my $fs_path;

{
    my $handler = $challenge->create_handler( 'my_key_authz', $docroot );

    $fs_path = File::Spec->catdir( $docroot, $challenge->path() );

    ok(
        ( -e $fs_path ),
        'challenge path is created',
    );

    my $contents = File::Slurp::read_file($fs_path);

    is(
        $contents,
        'my_key_authz',
        '… and the contents match expectations',
    );
}

ok(
    !( -e $fs_path ),
    'challenge path is removed on DESTROY',
);

{
    my $authz = bless [], 'Mock::Authz';

    my $handler = $challenge->create_handler( $authz, $docroot );

    my $contents = File::Slurp::read_file($fs_path);

    is(
        $contents,
        'my_object_key_authz',
        'create_handler() does the right thing with an authz object',
    );
}

#This ensures that there's no warning or error otherwise
#if the file goes away prematurely.
{
    my $handler = $challenge->create_handler( 'my_key_authz', $docroot );

    my $fs_path = File::Spec->catdir( $docroot, $challenge->path() );

    unlink $fs_path;
}

# die-in-DESTROY bug: when EUID mismatch triggers during normal scope exit,
# die propagates as an exception from DESTROY. After the fix, this should be
# a warning instead — DESTROY must not throw.
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    lives_ok {
        my $handler = $challenge->create_handler( 'my_key_authz', $docroot );

        # Simulate EUID mismatch so DESTROY's guard triggers
        $handler->{'_euid'} = $> + 1;

        # $handler goes out of scope here — DESTROY fires.
        # With die: this throws an exception. With warn: just a warning.
    } 'DESTROY with EUID mismatch does not die';

    ok( scalar @warnings, 'DESTROY with EUID mismatch emits a warning' );
    like(
        $warnings[0] || '',
        qr/EUID/,
        '... warning mentions EUID mismatch',
    );

    # Perl's die-in-DESTROY auto-conversion appends "(in cleanup)".
    # A proper warn does not. This is how we verify the fix.
    unlike(
        $warnings[0] || '',
        qr/\(in cleanup\)/,
        '... warning is a proper warn, not a die converted by Perl',
    );
}

done_testing();

#----------------------------------------------------------------------

package Mock::Authz;

use Test::More;

sub make_key_authorization {
    my ($self, $challenge) = @_;

    isa_ok( $challenge, 'Net::ACME2::Challenge::http_01', 'challenge given to make_key_authorization()');

    return 'my_object_key_authz';
}
