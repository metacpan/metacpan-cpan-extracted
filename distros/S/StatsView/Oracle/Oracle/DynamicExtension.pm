################################################################################
# Monitor Dynamic Extension

use strict;
use StatsView::Oracle::Monitor;
package StatsView::Oracle::DynamicExtension;
@StatsView::Oracle::DynamicExtension::ISA = qw(StatsView::Oracle::Monitor);

################################################################################

sub new($$$$)
{
my ($class, $db, $fh, $rate) = @_;
$class = ref($class) || $class;
my $self = $class->SUPER::new($db, $fh, $rate);
my $query = q(select /*+ rule */ value from v$sysstat
              where name = 'recursive calls');
$self->{cursor} = $db->prepare($query);
$self->header("singlerow", "Dynamic Extension activity",
              "Recursive Calls/Sec", "N");
$self->{cursor}->execute();
@$self{qw(rec_calls)} = $self->{cursor}->fetchrow();
return($self);
}

##############################################################################

sub sample($$)
{
my ($self, $ts) = @_;
$self->{cursor}->execute();
my ($rec_calls) = $self->{cursor}->fetchrow();
my $d_rec_calls = ($rec_calls - $self->{rec_calls}) / $self->{rate};
@$self{qw(rec_calls)} = ($rec_calls);
$self->data($ts, "$d_rec_calls");
}

################################################################################
1;
