#!perl
# This test file has been automatically generated. Any change made here will be lost.
# Edit the script in ./build/build_modules.pl instead
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More qw( no_plan );
    use Module::Generic;
    use Scalar::Util ();
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Net::API::CPAN::Rating' );
};

use strict;
use warnings;

my $test_data = Module::Generic->new->new_json->decode( join( '', <DATA> ) );
$test_data->{debug} = $DEBUG;
my $this;
my $obj = Net::API::CPAN::Rating->new( $test_data );
isa_ok( $obj => 'Net::API::CPAN::Rating' );
if( !defined( $obj ) )
{
    BAIL_OUT( Net::API::CPAN::Rating->error );
}

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/Rating.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$obj, ''$m'' );"'
can_ok( $obj, 'author' );
can_ok( $obj, 'date' );
can_ok( $obj, 'details' );
can_ok( $obj, 'distribution' );
can_ok( $obj, 'helpful' );
can_ok( $obj, 'object' );
can_ok( $obj, 'rating' );
can_ok( $obj, 'release' );
can_ok( $obj, 'user' );

is( $obj->author, $test_data->{author}, 'author' );
$this = $obj->date;
is( $this => $test_data->{date}, 'date' );
if( defined( $test_data->{date} ) )
{
    isa_ok( $this => 'DateTime', 'date returns a DateTime object' );
}
$this = $obj->details;
ok( Scalar::Util::blessed( $this ), 'details returns a dynamic class' );
is( $obj->distribution, $test_data->{distribution}, 'distribution' );
$this = $obj->helpful;
isa_ok( $this => 'Module::Generic::Array', 'helpful returns an array object' );
$this = $obj->rating;
is( $this => $test_data->{rating}, 'rating' );
if( defined( $test_data->{rating} ) )
{
    isa_ok( $this => 'Module::Generic::Number', 'rating returns a number object' );
}
is( $obj->release, $test_data->{release}, 'release' );
is( $obj->user, $test_data->{user}, 'user' );

done_testing();

__END__
{
   "rating" : "5.0",
   "user" : "CPANRatings",
   "distribution" : "Japan-Folklore",
   "release" : "PLACEHOLDER",
   "date" : "2018-05-31T09:20:07",
   "author" : "PLACEHOLDER"
}
