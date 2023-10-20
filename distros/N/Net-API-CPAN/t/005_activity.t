#!perl
BEGIN
{
    use strict;
    use warnings;
    use vars qw( $DEBUG );
    use Test::More qw( no_plan );
    # 2023-09-14T06:22:30
    use Test::Time time => 1694640150;
    use Module::Generic;
    use Scalar::Util ();
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Net::API::CPAN::Activity' ) || BAIL_OUT( "Uanble to load Net::API::CPAN::Activity" );
};

use strict;
use warnings;

my $test_data = Module::Generic->new->new_json->decode( join( '', <DATA> ) );
$test_data->{debug} = $DEBUG;
my $this;
my $obj = Net::API::CPAN::Activity->new( $test_data );
isa_ok( $obj => 'Net::API::CPAN::Activity' );
if( !defined( $obj ) )
{
    BAIL_OUT( Net::API::CPAN::Activity->error );
}

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/Activity.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$obj, ''$m'' );"'
can_ok( $obj, 'activity' );
can_ok( $obj, 'activities' );

# NOTE: activity()
my $array = $obj->activity;
isa_ok( $array => 'Module::Generic::Array' );
is( $array->length, 24, 'activity size' );
my $first = $array->first;
ok( ref( $first // '' ) eq 'HASH', 'activity returns an array of hash references' );
ok( exists( $first->{dt} ), 'activity hash has property "dt"' );
ok( exists( $first->{value} ), 'activity hash has property "value"' );
isa_ok( $first->{dt} => 'DateTime' );
is( $first->{dt}->stringify, '2021-10-01T00:00:00', 'activity first DateTime value' );
is( $first->{value}, 8, 'activity first aggregate value' );

# NOTE: activities()
my $hash = $obj->activities;
isa_ok( $hash => 'Module::Generic::Hash' );
# require Data::Pretty;
# diag( Data::Pretty::dump( $hash ) );
is( $hash->length, 24, 'activities hash size' );
my $first_dt = $hash->keys->sort->first;
isa_ok( $first_dt => 'DateTime' );
is( $first_dt->stringify, '2021-10-01T00:00:00', 'activities first DateTime value' );
is( $hash->{ $first_dt }, 8, 'activity first aggregate value' );

done_testing();

__END__
{
   "activity" : [
      8,
      6,
      6,
      8,
      9,
      3,
      7,
      15,
      4,
      7,
      4,
      7,
      13,
      3,
      1,
      1,
      4,
      1,
      1,
      2,
      4,
      3,
      4,
      1
   ]
}
