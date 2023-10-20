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
    use_ok( 'Net::API::CPAN::Release::Recent' );
};

use strict;
use warnings;

my $test_data = Module::Generic->new->new_json->decode( join( '', <DATA> ) );
$test_data->{debug} = $DEBUG;
my $this;
my $obj = Net::API::CPAN::Release::Recent->new( $test_data );
isa_ok( $obj => 'Net::API::CPAN::Release::Recent' );
if( !defined( $obj ) )
{
    BAIL_OUT( Net::API::CPAN::Release::Recent->error );
}

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/Release::Recent.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$obj, ''$m'' );"'
can_ok( $obj, 'abstract' );
can_ok( $obj, 'author' );
can_ok( $obj, 'date' );
can_ok( $obj, 'distribution' );
can_ok( $obj, 'name' );
can_ok( $obj, 'object' );
can_ok( $obj, 'status' );

is( $obj->abstract, $test_data->{abstract}, 'abstract' );
is( $obj->author, $test_data->{author}, 'author' );
$this = $obj->date;
is( $this => $test_data->{date}, 'date' );
if( defined( $test_data->{date} ) )
{
    isa_ok( $this => 'DateTime', 'date returns a DateTime object' );
}
is( $obj->distribution, $test_data->{distribution}, 'distribution' );
is( $obj->name, $test_data->{name}, 'name' );
is( $obj->status, $test_data->{status}, 'status' );

done_testing();

__END__
{
    "abstract" : "Japan Folklore Object Class",
    "author" : "MOMOTARO",
    "date" : "2023-07-29T05:10:12",
    "distribution" : "Folklore-Japan",
    "name" : "Folklore-Japan-v1.2.3",
    "status" : "latest"
}
