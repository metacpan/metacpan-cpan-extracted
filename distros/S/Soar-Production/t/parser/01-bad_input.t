#Test that the parser dies with bad input correctly

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Soar::Production::Parser;

use FindBin qw($Bin);
my $path = File::Spec->catdir( $Bin,'data' );

plan tests => 2;

my $parser = Soar::Production::Parser->new();
dies_ok(sub{ $parser->parse_file(File::Spec::catfile($path,'nonexistent') ) }, 
	'Fails on non-existent file');
dies_ok( sub { $parser->parse_text }, 'Fails on no input' );