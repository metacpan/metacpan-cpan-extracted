use strict;
use warnings;
use Test::More;

use Zydeco::Lite;

my $base = class;

sub foo {
	extends($base);
}

my $child = class sub {
	with role sub {
		before_apply {
			my ( $role, $target, $kind ) = @_;
			foo() if $kind eq 'class';
		}
	};
};

ok( $child->isa($base) );

done_testing;
