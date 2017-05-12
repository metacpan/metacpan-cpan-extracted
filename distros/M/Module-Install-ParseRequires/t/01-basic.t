
use strict;
use warnings;

use Test::More;

plan 'no_plan';

use File::Path qw/ rmtree /;
use YAML::Tiny;
use Config;
use File::Spec;

eval { rmtree('dist') };

my $make = $Config{make};

mkdir 'dist' or die "$!\n";
chdir 'dist' or die "$!\n";
open MFPL, '>Makefile.PL' or die "$!\n";
print MFPL <<_END_;
use strict;
use inc::Module::Install;
name 'Xyzzy';
version '0.01';
author 'Xyzzy';
abstract 'Xyzzy';
license 'perl';
parse_requires test => <<_PARSE_;
Test::More
Test::Xyzzy 1.02
_PARSE_
parse_requires <<_PARSE_;
Moose
JSON 2
Xyzzy 1.02
_PARSE_
parse_recommends <<_PARSE_;
DBI
_PARSE_
WriteAll;
_END_
close MFPL;

system "$^X Makefile.PL";
my $data = YAML::Tiny->read( 'META.yml' )->[0];
is( $data->{requires}->{Moose}, 0 );
is( $data->{requires}->{JSON}, 2 );
is( $data->{requires}->{Xyzzy}, '1.02' );
is( $data->{build_requires}->{'Test::More'}, 0 );
is( $data->{build_requires}->{'Test::Xyzzy'}, '1.02' );
is( $data->{recommends}->{DBI}, '0' );

ok( -e File::Spec->canonpath( 'inc/Module/Install/ParseRequires.pm' ) );
