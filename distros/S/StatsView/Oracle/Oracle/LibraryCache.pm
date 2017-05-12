################################################################################
# Monitor the Library Cache

use strict;
use StatsView::Oracle::Monitor;
package StatsView::Oracle::LibraryCache;
@StatsView::Oracle::LibraryCache::ISA = qw(StatsView::Oracle::Monitor);

################################################################################

sub new($$$$)
{
my ($class, $db, $fh, $rate) = @_;
$class = ref($class) || $class;
my $self = $class->SUPER::new($db, $fh, $rate);
my $query = q(select /*+ rule */ sum(pins), sum(reloads) from v$librarycache);
$self->{cursor} = $db->prepare($query);
$self->header("singlerow", "Library Cache activity",
              "Pins/Sec,Reloads/Sec,Hit Ratio", "NN%");
$self->{cursor}->execute();
@$self{qw(pins reloads)} = $self->{cursor}->fetchrow();
return($self);
}

##############################################################################

sub sample($$)
{
my ($self, $ts) = @_;
$self->{cursor}->execute();
my ($pins, $reloads) = $self->{cursor}->fetchrow();
my $d_pins = $pins - $self->{pins};
my $d_reloads = $reloads - $self->{reloads};
@$self{qw(pins reloads)} = ($pins, $reloads);
my $ratio = $d_pins ? (1 - $d_reloads / $d_pins) * 100 : 100;
$d_pins /= $self->{rate};
$d_reloads /= $self->{rate};
$self->data($ts, "$d_pins,$d_reloads,$ratio");
}

################################################################################
1;
