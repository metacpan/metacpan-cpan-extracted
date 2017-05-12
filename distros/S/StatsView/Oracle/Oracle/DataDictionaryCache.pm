################################################################################
# Monitor the Library Cache

use strict;
use StatsView::Oracle::Monitor;
package StatsView::Oracle::DataDictionaryCache;
@StatsView::Oracle::DataDictionaryCache::ISA = qw(StatsView::Oracle::Monitor);

################################################################################

sub new($$$$)
{
my ($class, $db, $fh, $rate) = @_;
$class = ref($class) || $class;
my $self = $class->SUPER::new($db, $fh, $rate);
my $query = q(select /*+ rule */ sum(gets), sum(getmisses) from v$rowcache);
$self->{cursor} = $db->prepare($query);
$self->header("singlerow", "Data Dictionary Cache activity",
              "Gets/Sec,Get Misses/Sec,Hit Ratio", "NN%");
$self->{cursor}->execute();
@$self{qw(gets getmisses)} = $self->{cursor}->fetchrow();
return($self);
}

##############################################################################

sub sample($$)
{
my ($self, $ts) = @_;
$self->{cursor}->execute();
my ($gets, $getmisses) = $self->{cursor}->fetchrow();
my $d_gets = $gets - $self->{gets};
my $d_getmisses = $getmisses - $self->{getmisses};
@$self{qw(gets getmisses)} = ($gets, $getmisses);
my $ratio = $d_gets ? (1 - $d_getmisses / $d_gets) * 100 : 100;
$d_gets /= $self->{rate};
$d_getmisses /= $self->{rate};
$self->data($ts, "$d_gets,$d_getmisses,$ratio");
}

################################################################################
1;
