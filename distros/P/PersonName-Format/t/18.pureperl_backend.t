#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/18.pureperl_backend.t
##----------------------------------------------------------------------------
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use open ':std' => ':utf8';
    use utf8;
    use Test::More;
    use File::Temp qw( tempfile );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;
use utf8;

my( $fh, $filename ) = tempfile(
    'personname-format-pp-XXXXXX',
    SUFFIX => '.pl',
    UNLINK => 1,
);
binmode( $fh, ':encoding(UTF-8)' );
print( $fh <<'PERL' );
use v5.10.1;
use strict;
use warnings;
use utf8;
use PersonName::Format;
die( "Pure Perl was not selected\n" ) unless( $PersonName::Format::IsPurePerl );
my $script = PersonName::Format::_get_name_script( '宮崎', '駿' );
die( "Unexpected script '${script}'\n" ) unless( $script eq 'Hani' );
print( "ok\n" );
PERL
close( $fh );

local $ENV{PERSONNAME_FORMAT_PUREPERL} = 1;
my $output = qx{$^X -Iblib/lib -Iblib/arch $filename 2>&1};
my $status = $? >> 8;
is( $status, 0, 'Pure-Perl backend can be forced in a fresh interpreter' ) || diag( $output );
like( $output, qr/^ok/m, 'Forced pure-Perl backend returned the expected script' );

done_testing();

__END__
