#!perl

use 5.010;
use strict;

use Module::CoreList;
use Module::CoreList::More;
use Test::More 0.98;

# Make warnings a punishable offense
local $SIG{__WARN__} = sub { die $_[0] };

# A few modules to look at in detail
my %mods_to_test =
  (
   'CPAN::FirstTime' => 'has a space at the end'
   ,'CGI::Fast' => 'has a letter in "1.00a"'
   ,'CPAN::Nox' => 'uses an underscore (like many other modules)'
   ,'Unicode' => 'double-dotted version'
  );


sub check_mod_for_warning {
  my ($mod,$why) = @_;
  ok( eval {Module::CoreList::More->is_core($mod,0);1}, "is_core($mod) $why" );
  diag "is_core($mod) warned: $@" if $@;

  ok( eval {Module::CoreList::More->is_still_core($mod,0);1},
      "is_still_core($mod) $why" );
  diag "is_still_core($mod) warned: $@" if $@;
}


# run the specific tests in a random order
while (my ($mod,$why) = each %mods_to_test) {
  check_mod_for_warning($mod,$why);
}

subtest no_module_warns => sub {
  my @mods = Module::CoreList::find_modules('.');
  for my $mod (@mods) {
    next if $mods_to_test{$mod};
    check_mod_for_warning($mod,"vers");
  }
};

DONE_TESTING:
done_testing;
