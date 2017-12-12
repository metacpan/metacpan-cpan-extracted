
use 5.010;
use Test::More 0.88;

use Perl::PrereqScanner;

my @TESTS = (
    {
        perl_code => <<'PERL',

use Importer::Zim 'Scalar::Util' => 'blessed';
use Importer::Zim 'Scalar::Util' => 'blessed' => { -as => 'typeof' };
 
use Importer::Zim 'Mango::BSON' => ':bson';
 
use Importer::Zim 'Foo' => { -version => '3.0' } => 'foo';
 
use Importer::Zim 'SpaceTime::Machine' => [qw(robot rubber_pig)];

PERL
        expected => {
            'Importer::Zim'      => '0',
            'Scalar::Util'       => '0',
            'Mango::BSON'        => '0',
            'Foo'                => '3.0',
            'SpaceTime::Machine' => '0',
        },
        what => 'Importer::Zim synopsis',
    },
    {
        perl_code =>
q{ use zim 'Test::More' => { -version => 0.88 } => qw(ok done_testing); },
        expected => {
            'zim'        => '0',
            'Test::More' => '0.88',
        },
        what => 'Previous TODO',
    },
);

for my $t (@TESTS) {
    my $perl_code = $t->{perl_code};
    my $expected  = $t->{expected};
    my $name      = $t->{what} . " - right prereqs";

    my $scanner = Perl::PrereqScanner->new( { extra_scanners => ['Zim'] } );
    my $prereqs = $scanner->scan_string($perl_code)->as_string_hash;
    is_deeply( $prereqs, $expected, $name );
}

done_testing;
