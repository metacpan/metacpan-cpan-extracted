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
    use_ok( 'Net::API::CPAN::Release::Suggest' );
};

use strict;
use warnings;

my $test_data = Module::Generic->new->new_json->decode( join( '', <DATA> ) );
$test_data->{debug} = $DEBUG;
my $this;
my $obj = Net::API::CPAN::Release::Suggest->new( $test_data );
isa_ok( $obj => 'Net::API::CPAN::Release::Suggest' );
if( !defined( $obj ) )
{
    BAIL_OUT( Net::API::CPAN::Release::Suggest->error );
}

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/Release::Suggest.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$obj, ''$m'' );"'
can_ok( $obj, 'author' );
can_ok( $obj, 'date' );
can_ok( $obj, 'deprecated' );
can_ok( $obj, 'distribution' );
can_ok( $obj, 'name' );
can_ok( $obj, 'object' );
can_ok( $obj, 'release' );

is( $obj->author, $test_data->{author}, 'author' );
$this = $obj->date;
is( $this => $test_data->{date}, 'date' );
if( defined( $test_data->{date} ) )
{
    isa_ok( $this => 'DateTime', 'date returns a DateTime object' );
}
$this = $obj->deprecated;
if( defined( $test_data->{deprecated} ) )
{
    is( $this => $test_data->{deprecated}, 'deprecated returns a boolean value' );
}
else
{
    ok( !$this, 'deprecated returns a boolean value' );
}
is( $obj->distribution, $test_data->{distribution}, 'distribution' );
is( $obj->name, $test_data->{name}, 'name' );
is( $obj->release, $test_data->{release}, 'release' );

done_testing();

__END__
{
    "author" : "MOMOTARO",
    "name" : "Japan::Folklore",
    "deprecated" : false,
    "distribution" : "Japan-Folklore",
    "date" : "2023-09-01T10:12:42",
    "release" : "Japan-Folklore-v1.2.3"
}
