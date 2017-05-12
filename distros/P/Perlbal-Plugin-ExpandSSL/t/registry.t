#!perl
{
    package FakeCert;
    use strict;
    use warnings;

    my $found = 0;

    sub new { return bless {}, shift }

    sub error {
        $found++ or return;
        return 'my error';
    }

    sub subject_cn { 'subject_cn' }
}

{
    package FakeSVC;
    sub new { return bless {}, shift }
}

{
    package FakeHeaders;
    use strict;
    use warnings;
    use Test::More;

    my $found = 0;

    sub new    { return bless {}, shift }
    sub header {
        my ( $self, $key, $value ) = @_;
        isa_ok( $self, 'FakeHeaders' );
        cmp_ok( scalar @_, '==', 3, 'correct header params number' );

        my $val = $found++ ? 'my error' : 'subject_cn';

        is( $key,   'X_FORWARDED_SSL_S_DN_CN', 'FakeHeaders correct key'   );
        is( $value, $val,                      'FakeHeaders correct value' );
    }
}

package main;
use strict;
use warnings;

use Test::More tests => 28;
use Test::Warn;
use Perlbal::Plugin::ExpandSSL;

my @pem = ( 'first line', 'second line' );
{
    # overriding packages
    no warnings qw/ redefine once /;
    *Perlbal::Plugin::ExpandSSL::read_file = sub {
        cmp_ok( scalar @_, '==', 1, 'read_file() has 1 param' );
        is( $_[0], 'my_file', 'read_file() has correct param' );
        return @pem;
    };

    *Perlbal::Plugin::ExpandSSL::serialize_pem = sub {
        cmp_ok( scalar @_, '==', 2, 'serialize_pem() has 2 params' );
        is_deeply( \@_, \@pem, 'serialize_pem() has correct params' );
        return 'pem';
    };

    *Perlbal::Plugin::ExpandSSL::decode_base64 = sub ($) {
        cmp_ok( scalar @_, '==', 1, 'decode_base64() has 1 param' );
        is( $_[0], 'pem', 'decode_base64() has correct param' );
        return 'der';
    };

    *Crypt::X509::new = sub {
        my $class = shift;
        my %opts  = @_;
        my @exp   = qw/cert der/;
        is( $class, 'Crypt::X509', 'Crypt::X509::new() got class' );
        cmp_ok( scalar @_, '==', 2, 'Crypt::X509::new() has 2 more params' );
        is_deeply( \@_, \@exp, 'Crypt::X509::new() has correct params' );
        return FakeCert->new();
    };
}

my $return;
$return = Perlbal::Plugin::ExpandSSL::build_registry('my_file');
cmp_ok( $return, '==', 0, 'build_registry() returns 0' );

warning_like {
    $return = Perlbal::Plugin::ExpandSSL::build_registry('my_file');
} qr/^ERROR: my error$/, 'Correct warning on build_registry() fake error';
cmp_ok( $return, '==', 1, 'build_registry() returns 1' );

my $svc = FakeSVC->new;
isa_ok( $svc, 'FakeSVC' );
my $headers = FakeHeaders->new();
isa_ok( $headers, 'FakeHeaders' );

$svc->{'req_headers'}   = $headers;
$svc->{'ssl_cert_file'} = 'my_fake_file';

$return = Perlbal::Plugin::ExpandSSL::expand_ssl($svc);

cmp_ok( $return, '==', 0, 'expand_ssl returns 0' );

