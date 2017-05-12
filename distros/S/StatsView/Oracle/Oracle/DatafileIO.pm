################################################################################
# Monitor the Datafile IO

use strict;
use StatsView::Oracle::Monitor;
package StatsView::Oracle::DatafileIO;
@StatsView::Oracle::DatafileIO::ISA = qw(StatsView::Oracle::Monitor);

################################################################################

sub new($$$$)
{
my ($class, $db, $fh, $rate) = @_;
$class = ref($class) || $class;
my $self = $class->SUPER::new($db, $fh, $rate);
my $query = q(select /*+ rule */ name, phyrds, phywrts, phyblkrd, phyblkwrt
              from v$filestat, v$datafile
              where v$filestat.file# = v$datafile.file#);
$self->{cursor} = $db->prepare($query);
$self->header("multirow", "Datafile IO activity",
              "Reads/Sec,Writes/Sec,Blocks Read/Sec,Blocks Written/Sec",
              "NNNN");
$self->{cursor}->execute();
my ($df, $r, $w, $br, $bw);
while (($df, $r, $w, $br, $bw) = $self->{cursor}->fetchrow())
   {
   $self->{df}{$df} = [ $r, $w, $br, $bw ];
   }
return($self);
}

##############################################################################

sub sample($$)
{
my ($self, $ts) = @_;
$self->{cursor}->execute();
my (@data, $df, $r, $w, $br, $bw);
while (($df, $r, $w, $br, $bw) = $self->{cursor}->fetchrow())
   {
   my $d_r  = ($r  - $self->{df}{$df}[0]) / $self->{rate};
   my $d_w  = ($w  - $self->{df}{$df}[1]) / $self->{rate};
   my $d_br = ($br - $self->{df}{$df}[2]) / $self->{rate};
   my $d_bw = ($bw - $self->{df}{$df}[3]) / $self->{rate};
   $self->{df}{$df} = [ $r, $w, $br, $bw ];
   push(@data, "$df,$d_r,$d_w,$d_br,$d_bw");
   }
$self->data($ts, @data);
}

################################################################################
1;
