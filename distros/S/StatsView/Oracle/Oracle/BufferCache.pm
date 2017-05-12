################################################################################
# Monitor the Buffer Cache

use strict;
use StatsView::Oracle::Monitor;
package StatsView::Oracle::BufferCache;
@StatsView::Oracle::BufferCache::ISA = qw(StatsView::Oracle::Monitor);

################################################################################

sub new($$$$)
{
my ($class, $db, $fh, $rate) = @_;
$class = ref($class) || $class;
my $self = $class->SUPER::new($db, $fh, $rate);
my $query = q(select /*+ rule */ name, value from v$sysstat where
              name in ('db block gets', 'consistent gets', 'physical reads'));
$self->{cursor} = $db->prepare($query);
$self->header("singlerow", "Buffer Cache activity",
              "I/O Requests/Sec,Physical I/Os/Sec,Hit Ratio", "NN%");
$self->{cursor}->execute();
my ($io_req, $phys_io) = (0, 0);
while (my ($k, $v) = $self->{cursor}->fetchrow())
   {
   $k eq 'db block gets' && ($io_req += $v);
   $k eq 'consistent gets' && ($io_req += $v);
   $k eq 'physical reads' && ($phys_io = $v);
   }
@$self{qw(io_req phys_io)} = ($io_req, $phys_io);
return($self);
}

##############################################################################

sub sample($$)
{
my ($self, $ts) = @_;
$self->{cursor}->execute();
my ($io_req, $phys_io) = (0, 0);
while (my ($k, $v) = $self->{cursor}->fetchrow())
   {
   $k eq 'db block gets' && ($io_req += $v);
   $k eq 'consistent gets' && ($io_req += $v);
   $k eq 'physical reads' && ($phys_io = $v);
   }
my $d_io_req = ($io_req - $self->{io_req}) / $self->{rate};
my $d_phys_io = ($phys_io - $self->{phys_io}) / $self->{rate};
@$self{qw(io_req phys_io)} = ($io_req, $phys_io);
my $ratio = $d_io_req ? (1 - $d_phys_io / $d_io_req) * 100 : 100;
$self->data($ts, "$d_io_req,$d_phys_io,$ratio");
}

################################################################################
1;
