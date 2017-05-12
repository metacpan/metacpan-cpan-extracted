use strict;
use warnings;
use Test::More;
use Sys::Statistics::Linux;

if (!-x '/bin/df') {
    plan skip_all => "it seems that your system doesn't provide /bin/df";
    exit(0);
}

plan tests => 5;

my @diskusage = qw(
    total
    usage
    free
    usageper
    mountpoint
);

my $sys = Sys::Statistics::Linux->new();
$sys->set(diskusage => 1);
my $stats = $sys->get;

SKIP: {
   if (! %{ $stats->diskusage }) {
      skip "df returned nothing.  Might be in a chroot.", 5;
   }

   for my $dev (keys %{$stats->diskusage}) {
      ok(defined $stats->diskusage->{$dev}->{$_}, "checking diskusage $_") for @diskusage;
      last; # we check only one device, that should be enough
   }
}
