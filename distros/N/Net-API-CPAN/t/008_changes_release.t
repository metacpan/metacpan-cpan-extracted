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
    use_ok( 'Net::API::CPAN::Changes::Release' );
};

use strict;
use warnings;

my $test_data = Module::Generic->new->new_json->decode( join( '', <DATA> ) );
$test_data->{debug} = $DEBUG;
my $this;
my $obj = Net::API::CPAN::Changes::Release->new( $test_data );
isa_ok( $obj => 'Net::API::CPAN::Changes::Release' );
if( !defined( $obj ) )
{
    BAIL_OUT( Net::API::CPAN::Changes::Release->error );
}

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/Changes::Release.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$obj, ''$m'' );"'
can_ok( $obj, 'author' );
can_ok( $obj, 'changes_file' );
can_ok( $obj, 'changes_text' );
can_ok( $obj, 'object' );
can_ok( $obj, 'release' );

is( $obj->author, $test_data->{author}, 'author' );
is( $obj->changes_file, $test_data->{changes_file}, 'changes_file' );
is( $obj->changes_text, $test_data->{changes_text}, 'changes_text' );
is( $obj->release, $test_data->{release}, 'release' );

done_testing();

__END__
{
    "author" : "MOMOTARO",
    "changes_file" : "CHANGES",
    "changes_text" : "Revision history for Perl module Folklore::Japan\n\nv1.2.3 2023-07-29T09:12:10+0900\n    - Initial release\n",
    "release" : "Folklore-Japan-v1.2.3"
}
