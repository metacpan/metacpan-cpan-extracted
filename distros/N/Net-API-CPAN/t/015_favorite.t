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
    use_ok( 'Net::API::CPAN::Favorite' );
};

use strict;
use warnings;

my $test_data = Module::Generic->new->new_json->decode( join( '', <DATA> ) );
$test_data->{debug} = $DEBUG;
my $this;
my $obj = Net::API::CPAN::Favorite->new( $test_data );
isa_ok( $obj => 'Net::API::CPAN::Favorite' );
if( !defined( $obj ) )
{
    BAIL_OUT( Net::API::CPAN::Favorite->error );
}

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/Favorite.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$obj, ''$m'' );"'
can_ok( $obj, 'author' );
can_ok( $obj, 'date' );
can_ok( $obj, 'distribution' );
can_ok( $obj, 'id' );
can_ok( $obj, 'object' );
can_ok( $obj, 'release' );
can_ok( $obj, 'user' );

is( $obj->author, $test_data->{author}, 'author' );
$this = $obj->date;
is( $this => $test_data->{date}, 'date' );
if( defined( $test_data->{date} ) )
{
    isa_ok( $this => 'DateTime', 'date returns a DateTime object' );
}
is( $obj->distribution, $test_data->{distribution}, 'distribution' );
is( $obj->id, $test_data->{id}, 'id' );
is( $obj->release, $test_data->{release}, 'release' );
is( $obj->user, $test_data->{user}, 'user' );

done_testing();

__END__
{
   "date" : "2023-07-29T05:12:10",
   "release" : "Folklore-Japan-v1.2.3",
   "distribution" : "Folklore-Japan",
   "author" : "MOMOTTARO",
   "user" : "JA01Pa34nIs56Co89ol",
   "id" : "Go34To56Ok78aY90ama_I"
}
