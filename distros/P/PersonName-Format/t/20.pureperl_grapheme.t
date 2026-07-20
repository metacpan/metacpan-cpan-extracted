#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/20.pureperl_grapheme.t
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
    use Config;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;
use utf8;

my $perl = $^X;
my $lib = 'blib/lib';
my $arch = 'blib/arch';
my $code = <<'PERL';
use utf8;
use PersonName::Format;
die( "Pure-Perl backend was not selected\n" )
    unless( $PersonName::Format::IsPurePerl );
my $value = "\x{1F469}\x{200D}\x{1F4BB}Alice";
my $got = PersonName::Format::_first_grapheme( $value );
die( "Unexpected grapheme\n" )
    unless( $got eq "\x{1F469}\x{200D}\x{1F4BB}" );
PERL

local $ENV{PERSONNAME_FORMAT_PUREPERL} = 1;
my $status = system(
    $perl,
    '-I' . $lib,
    '-I' . $arch,
    '-e',
    $code,
);
is( $status, 0, 'Pure-Perl grapheme backend works in a fresh interpreter' );

done_testing();

__END__
