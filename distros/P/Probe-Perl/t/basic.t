
use strict;
use Test;
BEGIN { plan tests => 19 }

use Probe::Perl;
ok 1;

my $pp = new Probe::Perl();
ok defined $pp;

use Config;
ok $Config{version}, $pp->config('version');

# returns undef for non-existent keys
ok defined( $pp->config( 'foobarbaz' ) ), '';

# basic config test
$pp->config( foo => 'bar' );
ok $pp->config( 'foo' ), 'bar';

# override $Config value
my $perl = $pp->config( 'perl' );
$pp->config( perl => 'otherperl' );
ok $pp->config( 'perl' ), 'otherperl';

# undo override
$pp->config_revert( 'perl' );
ok $pp->config( 'perl' ), $perl;

ok( Probe::Perl->os_type( 'linux' ), 'Unix');
ok( Probe::Perl->os_type( 'MSWin32' ), 'Windows');


# both object and class method return same value
my $perl1 = $pp->find_perl_interpreter();
ok $perl1;
my $perl2 = Probe::Perl->find_perl_interpreter();
ok $perl2;
ok $perl1, $perl2;

ok $pp->perl_is_same( $perl1 ), 1, "$perl1 should be same as $perl2";


# both object and class method return same value
my $perl_vers1 = $pp->perl_version();
ok $perl_vers1;
my $perl_vers2 = Probe::Perl->perl_version();
ok $perl_vers2;
ok $perl_vers1, $perl_vers2;


my @perl_inc1 = $pp->perl_inc();
ok @perl_inc1;

my @perl_inc2 = Probe::Perl->perl_inc();
ok @perl_inc2;

ok compare_array( \@perl_inc1, \@perl_inc2 );

sub compare_array {
  my( $a1, $a2 ) = @_;
  return 0 unless @$a1 == @$a2;
  foreach my $i ( 0..$#$a1 ) {
    return 0 unless $a1->[$i] eq $a2->[$i];
  }
  return 1;
}
