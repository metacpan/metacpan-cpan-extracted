
use strict;
use warnings;

use Test::More;
use RRDTool::OO;

$| = 1;

use Log::Log4perl qw(:easy);

###################################################
my $LOGLEVEL = $OFF;
###################################################

Log::Log4perl->easy_init({level => $LOGLEVEL, layout => "%L: %m%n", 
                          category => 'rrdtool',
                          file => 'stderr'});

my $rrd = RRDTool::OO->new(file => "foo");

eval { $SIG{__DIE__} = $SIG{__WARN__} = sub {}; $rrd->dump(); };

if($@ =~ /Can.t locate/) {
    plan skip_all => "only with RRDs supporting dump/restore";
} else {
    plan tests => 2;
}

    # create with superfluous param
$rrd->create(
    data_source => { name      => 'foobar',
                     type      => 'GAUGE',
                   },
    archive     => { cfunc   => 'MAX',
                     xff     => '0.5',
                     cpoints => 5,
                     rows    => 10,
                   },
);

ok(-e "foo", "RRD exists");
my $size = -s "foo";

#####################################################
# Dump it.
#####################################################
my $pid;
unless ($pid = open DUMP, "-|") {
  die "Can't fork: $!" unless defined $pid;
  $rrd->dump();
  exit 0;
}

#print "\$\$ = $$, pid=$pid\n";
waitpid($pid, 0);

open OUT, ">out";
print OUT $_ for <DUMP>;
close OUT;

unlink "foo";

#####################################################
# Restore it.
#####################################################
$rrd->restore("out");
ok(-f "foo", "RRD resurrected");

END { unlink "foo"; 
      unlink "out";
}
