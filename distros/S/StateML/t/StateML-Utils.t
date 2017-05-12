use Test;
use StateML::Utils qw( :all );
use strict;

my @tests = (
sub { $_ = "";    ok empty },
sub { $_ = undef; ok empty },
sub { $_ = 0;     ok !empty },
sub { $_ = 1;     ok !empty },
sub { $_ = "a";   ok !empty },

sub { ok as_str( "a" ),   "'a'"   },
sub { ok as_str( undef ), "undef" },
);

plan tests => 0+@tests;

$_->() for @tests;
