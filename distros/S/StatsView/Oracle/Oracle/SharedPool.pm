################################################################################
# Monitor the Shared Pool

use strict;
use StatsView::Oracle::Monitor;
package StatsView::Oracle::SharedPool;
@StatsView::Oracle::SharedPool::ISA = qw(StatsView::Oracle::Monitor);

################################################################################

sub new($$$$)
{
my ($class, $db, $fh, $rate) = @_;
$class = ref($class) || $class;
my $self = $class->SUPER::new($db, $fh, $rate);
my $query = q(select /*+ rule */ name, count(value), sum(value)
              from v$sesstat, v$statname
              where name in ('session pga memory', 'session pga memory max')
              and v$sesstat.statistic# = v$statname.statistic# group by name);
$self->{cursor} = $db->prepare($query);
$self->header("singlerow", "Shared Pool activity",
              "Sessions,Session Memory,Max Session Memory", "NNN");
return($self);
}

##############################################################################

sub sample($$)
{
my ($self, $ts) = @_;
$self->{cursor}->execute();
my ($n1, $s1, $v1) = $self->{cursor}->fetchrow();
my ($n2, $s2, $v2) = $self->{cursor}->fetchrow();
if ($n1 eq 'max session memory') { my $v3 = $v1, $v1 = $v2; $v2 = $v3 }
$self->data($ts, "$s1,$v1,$v2");
}

################################################################################
1;
