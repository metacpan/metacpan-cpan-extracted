#! perl
#
# Tests for specification parser based on Config::Scoped.

use strict;
use warnings;
use Test::More;
use Class::Load qw(try_load_class);

try_load_class('Config::Scoped')
    or plan skip_all => "No Config::Scoped module.";

plan tests => 3;

require Template::Flute::Specification::Scoped;

my $conf = <<EOF;
specification {
    encoding = iso8859-1
}
list test {
    class = cpan
}
input user {
    list = test
}
EOF

my $spec = new Template::Flute::Specification::Scoped;
my $ret;

eval {
	$ret = $spec->parse($conf);
};

diag("Failure parsing specification: $@") if $@;
isa_ok($ret, 'Template::Flute::Specification');

# check for proper encoding
ok($ret->encoding() eq 'iso8859-1', 'get encoding from specification');

# check for list
ok(exists($ret->{lists}->{test}->{input}));
