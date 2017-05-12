#!perl

use warnings FATAL => 'all';
use strict;

use Test::More tests => 20;

BEGIN{ use_ok('Ruby', ':DEFAULT', 'rb_inspect') };

is rb_inspect(undef), 'undef', 'inspect undef';
is rb_inspect(1), '1', "inspect I";
is rb_inspect('S'), '"S"', "inspect S";
is rb_inspect(\undef), '\undef', "inspect R";
is rb_inspect([]), '[]', "inspect A";
is rb_inspect({}), '{}', "inspect H";

like rb_inspect(sub{}), qr/^sub/, "inspect SUB";
like rb_inspect(\&rb_eval), qr/XSUB/, "inspect XSUB";

like rb_inspect(*STDOUT{IO}), qr/\bIO\b/, "inspect IO";

our $gvar;
is rb_inspect(\\*gvar), "\\\\*gvar", "inspect GLOB of main::";
is rb_inspect(*Ruby::VERSION), "*Ruby::VERSION", "inspect GLOB of other::";

my @a;
push @a, \@a;
like rb_inspect(\@a), qr/\Q[...]/, "inspect recursive array";
my %h;
$h{k} = \%h;
like rb_inspect(\%h), qr/\Q{...}/, "inspect recursive hash";

my $s;
$s = \$s;
like rb_inspect($s), qr/\Q(...)/, "inspect recursive scalar";

{
	package Uninspectable;
	sub new{ bless {} }
}
{
	package Inspectable;
	use Ruby qw(rb_basic_inspect);
	
	sub new{ bless {} }

	sub inspect{
		'##'. rb_basic_inspect(@_);
	}

}

like rb_inspect(Uninspectable->new), qr/\Q{}/,   "inspect uninspectable object";
like(Inspectable->new->inspect,   qr/##/, "inspect inspectable object");
like(rb_inspect(Inspectable->new()), qr/##/);

like rb_inspect(qr/foobar/), qr/foobar/, "inspect Regexp";

is rb_inspect(nil), "nil", "inspect nil";


