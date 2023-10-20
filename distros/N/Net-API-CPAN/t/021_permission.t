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
    use_ok( 'Net::API::CPAN::Permission' );
};

use strict;
use warnings;

my $test_data = Module::Generic->new->new_json->decode( join( '', <DATA> ) );
$test_data->{debug} = $DEBUG;
my $this;
my $obj = Net::API::CPAN::Permission->new( $test_data );
isa_ok( $obj => 'Net::API::CPAN::Permission' );
if( !defined( $obj ) )
{
    BAIL_OUT( Net::API::CPAN::Permission->error );
}

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/Permission.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$obj, ''$m'' );"'
can_ok( $obj, 'co_maintainers' );
can_ok( $obj, 'module_name' );
can_ok( $obj, 'object' );
can_ok( $obj, 'owner' );

$this = $obj->co_maintainers;
ok( ( Scalar::Util::reftype( $this ) eq 'ARRAY' && Scalar::Util::blessed( $this ) ), 'co_maintainers returns an array object' );
if( defined( $test_data->{co_maintainers} ) )
{
    ok( scalar( @$this ) == scalar( @{$test_data->{co_maintainers}} ), 'co_maintainers -> array size matches' );
    for( my $i = 0; $i < @$this; $i++ )
    {
        is( $this->[$i], $test_data->{co_maintainers}->[$i], 'co_maintainers -> value offset $i' );
    }
}
else
{
    ok( !scalar( @$this ), 'co_maintainers -> array is empty' );
}
is( $obj->module_name, $test_data->{module_name}, 'module_name' );
is( $obj->owner, $test_data->{owner}, 'owner' );

done_testing();

__END__
{
   "co_maintainers" : [
      "URASHIMATARO",
      "KINTARO",
      "YAMATONADESHIKO"
   ],
   "module_name" : "Folklore::Japan",
   "owner" : "MOMOTARO"
}
