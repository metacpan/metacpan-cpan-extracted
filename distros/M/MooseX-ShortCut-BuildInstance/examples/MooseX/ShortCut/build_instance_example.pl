#!perl
package Mineral;
use Moose;

has 'type' =>( is => 'ro' );

package Identity;
use Moose::Role;

has 'name' =>( is => 'ro' );

use lib '../../../lib';
use MooseX::ShortCut::BuildInstance;
use Test::More;
use Test::Moose;

my 	$paco = build_instance(
		package => 'Pet::Rock',
		superclasses =>['Mineral'],
		roles =>['Identity'],
		type => 'Quartz',
		name => 'Paco',
	);

does_ok( $paco, 'Identity', 'Check that the ' . $paco->meta->name . ' has an -Identity-' );
print'My ' . $paco->meta->name . ' made from -' . $paco->type . '- (a ' .
( join ', ', $paco->meta->superclasses ) . ') is called -' . $paco->name . "-\n";
done_testing();