# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
# ((c, m, c) * (g + s)) + none + all
use Test::More 0.96 tests => (3 * 2) + 1 + 1;

# test that we set up Sub::Exporter correctly

my $testmodprefix = 'Local::Test_';
my $mod = 'String::Substitution';
eval "require $mod" or die $@;

foreach my $suffix ( qw(copy modify context) ){
  my $testmod = "${testmodprefix}_${suffix}";
  eval <<PM;
  {
    package $testmod;
    use $mod -$suffix;
  }
PM
  foreach my $sub ( qw(gsub sub) ){
    no strict 'refs';
    # cheap numeric compare of references (see perlref)
    cmp_ok(\&{"${testmod}::${sub}"}, '==', \&{"${mod}::${sub}_${suffix}"}, "$suffix imported as $sub");
  }
}

eval <<PM;
{
  package ${testmodprefix}none;
  use $mod;
}
PM
is_deeply(regular_subs(\%Local::Test_none::), {}, 'export nothing by default');

eval <<PM;
{
  package ${testmodprefix}all;
  use $mod -all;
}
PM
no strict 'refs';
is_deeply(regular_subs(\%Local::Test_all::), regular_subs(\%{"${mod}::"}), 'export all when requested');

sub regular_subs {
  my %ns = %{$_[0]};
  my %subs;
  no strict 'refs';
  while( my ($k, $v) = each %ns ){
    # remove any built-in or unusual subs
    next if $k =~ /(^[A-Z_]|can|isa|import)/;
    $subs{$k} = *{$v}{CODE} || next;
  }
  return \%subs;
}
