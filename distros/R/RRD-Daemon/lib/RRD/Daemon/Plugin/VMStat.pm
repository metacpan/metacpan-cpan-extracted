package RRD::Daemon::Plugin::VMStat;

# methods for reading from sensors -A for prrd

# pragmata ----------------------------

use feature qw( :5.10 );
use strict;
use warnings;

# inheritance -------------------------

use base qw( RRD::Daemon::Plugin );

# utility -----------------------------

use FindBin        qw( $Bin );
use IPC::Run       qw( new_chunker );
use Log::Log4perl  qw( );

use lib  "$Bin/perllib";
use RRD::Daemon::Util  qw( trace warn );

# constants ---------------------------

use constant COLUMN_DATA =>
  +{ r      => +{ name => 'proc_wait_read',  unit => 'count' },
     b      => +{ name => 'proc_wait_sleep', unit => 'count' },
     swpd   => +{ name => 'vm_used',         unit => 'KiB' },
     free   => +{ name => 'vm_idle',         unit => 'KiB' },
     buff   => +{ name => 'vm_buffer',       unit => 'KiB' },
     cache  => +{ name => 'vm_cache',        unit => 'KiB' },
     si     => +{ name => 'swap_in',         unit => 'KiB/s', },
     so     => +{ name => 'swap_out',        unit => 'KiB/s', },
     bi     => +{ name => 'io_blocks_in',    unit => 'count/s', },
     bo     => +{ name => 'io_blocks_out',   unit => 'count/s', },
     in     => +{ name => 'interrupt',       unit => 'count/s', },
     cs     => +{ name => 'context_switch',  unit => 'count/s', },
     us     => +{ name => 'user_time',       unit => 'percent', },
     sy     => +{ name => 'sys_time',        unit => 'percent', },
     id     => +{ name => 'idle_time',       unit => 'percent', },
     wa     => +{ name => 'io_wait_time',    unit => 'percent', },
 };

use constant COLUMN_UNIT => +{ map @{COLUMN_DATA->{$_}}{qw( name unit )},
                                   keys %{COLUMN_DATA()} };

# methods --------------------------------------------------------------------

sub harness      { $_[0]->{harness} }
sub columns      { $_[0]->{columns} }
sub column       { $_[0]->columns->[$_[1]] }
sub pump         { $_[0]->harness->pump_nb; $_[0]->parse_lines; $_[0]->lines_clear }
sub lines        { @{$_[0]->{lines}} }
sub lines_clear  { $_[0]->{lines} = [] }
sub pushline     { chomp(my $x = $_[1]); push @{$_[0]->{lines}}, $x }
sub interval     { 10 }
sub cmd          { [ vmstat => $_[0]->interval ] }
sub set_columns  { $_[0]->{columns} = [ @_[1..$#_] ] };
sub set_values   {
  # first set of values is accumulated since boot time.
  # discard those
  $_[0]->{values} = +{}, return
    unless exists $_[0]->{values};
 $_[0]->{values}->{$_[0]->column($_-1)} = $_[$_] for 1..$#_
}
sub clear_values { $_[0]->{values} = +{} if exists $_[0]->{values} }
sub values       { $_[0]->{values} || +{} }
sub min          { 0 }
sub max          { 'percent' eq COLUMN_UNIT->{$_[1]} ? 100 : 'U' }

# -------------------------------------

sub keys      {
  my ($self) = @_;
  $self->start;
  $self->pump;
  until ( $self->columns ) {
    warn "sleeping waiting for columns from $_[0]";
    sleep 1;
    $self->pump;
  }

  $self->columns;
}

# -------------------------------------

sub read_values {
  my ($self) = @_;

  $self->start;

  no warnings 'internal'; # needed to silence unreferenced scalar warnings
  $self->pump;
#  $self->parse_lines;

#  $self->lines_clear;

  return $self->values;
}

# -------------------------------------

sub parse_lines {
  my ($self) = @_;

  $self->parse_line($_)
    for $self->lines;
}

# -------------------------------------

sub parse_line {
  my ($self, $line) = @_;

  given ($line) {
    when ( /--/ )        { } # super-header: ignore

    when ( /^\s*[a-z]/ ) {   # header; cache bits
      $self->set_columns(map COLUMN_DATA->{$_}->{name} || $_, split ' ', $_);
    }

    when ( /^\s*\d/  )   {   # values
      $self->clear_values;
      $self->set_values(split ' ', $_);
    }

    default { warn "ignorning vmstat output line >>$_<<" }
  }
}

# -------------------------------------

sub start {
  my ($self) = @_;
  return if $self->{harness};

  $self->{input} = '';
  my $h =
    IPC::Run::harness $self->cmd, '>'
        # this is a bit line new_chunker, but it returns individual lines
        # faster.  new_chunker often won't return a line until the next line is
        # available
                       => sub {
                         my $input = $self->{input};
                         $input .= $_[0];
                         my @lines = split /^/, $_[0];
                         $self->{input} = '';
                         for my $l (@lines) {
                           if ( "\n" eq substr $l, -1 ) {
                             $self->pushline($l);
                           } else {
                             $input = $l;
                           }
                         }
                       };
  $h->start;
  $self->{harness} = $h;
  $self->lines_clear;
}

# ----------------------------------------------------------------------------
1; # keep require happy
