package RRD::Daemon::RRDB::Graph;

# pragmata

use strict;
use warnings;
use feature  qw( :5.10 );

# inheritance

use base  qw( Params::Attr );

# utility

use Carp                qw( croak );
use Class::MethodMaker  qw( );
use IO::All             qw( io );
use List::Util          qw( min max );
use Memoize             qw( memoize );
use Regexp::Common;
use RRDs                qw( );

use RRD::Daemon::Util   qw( ftime 
                            debug info tdump tdumps );

# CLASS OBJECT ---------------------------------------------------------------

# -------------------------------------
# CLASS CONSTANTS
# -------------------------------------

use constant RGB_TXT => ['/etc/X11/rgb.txt', '/usr/shar/X11/rgb.txt'];

# -------------------------------------
# CLASS UTILITY FUNCTIONS
# -------------------------------------

sub read_rgb_txt {
  my ($rgb_txt) = grep -e, @{RGB_TXT()}
    or die "failed to find an rgb.txt to use\n";

  my (@rgb, %rgb);
  for my $ln (io($rgb_txt)->chomp->slurp) {
    my ($r, $g, $b, $name);
    if ( my($r,$g,$b,$name) =
         ($ln =~ /^\s*(\d{1,3})\s+(\d{1,3})\s+(\d{1,3})\s+(\S.*?)\s*$/) ) {
      unless ( $r + $g + $b > 192*3 ) { # ignore colours too light
        push @rgb, +{ name => $name, rgb => [$r,$g,$b] };
        $rgb{$name} = [$r,$g,$b];
      }
    }
  }

  return \( @rgb, %rgb );
}
memoize 'read_rgb_txt';

# -------------------------------------

sub get_rgb {
  my ($index) = @_;
  my ($rgb_txt, $rgb_by_name) = read_rgb_txt;
  tdump index => $index;

  if ( $index =~ /^$RE{num}{real}$/ ) {
    my $colour = $rgb_txt->[int @$rgb_txt*$index];
    tdump colour => $colour->{name};
    return $colour->{rgb};
  } else {
    return $rgb_by_name->{$index} // croak "no such colour: '$index'\n";
  }
}

# INSTANCE OBJECT ------------------------------------------------------------

Class::MethodMaker->import
  ([ new    => [qw/ -init new /],
     scalar => [ qw/ range start end /, ],
     array  => [qw/ colours /,
                +{ type => 'RRD::Daemon::RRDB' } => 'rrdbs'],
   ]);

# $rrdb can be an RRDB object, or a scalar of a (pre-existing) rrdb filename
sub init : CheckP('_', 'AR[RRDB::|S]') {
  my ($self, $rrdbs) = @_;

  $self->rrdbs(map ref $_ ? $_ : RRD::Daemon::RRDB->new($_), @$rrdbs);
}

# -------------------------------------

sub linedef {
  my ($self, $name, $rgb, $rrdb) = @_;
  my $rrdfn = $rrdb->fn;

  return sprintf("DEF:%s=$rrdfn:%s:MAX", $name, $name),
         sprintf("LINE2:%s#%02x%02x%02x:%s", $name, @$rgb, $name);
}

# -------------------------------------

sub linedefs {
  my ($self) = @_;

  my @names;
  for my $rrdb ($self->rrdbs) {
    push @names, map +{ name => $_->name, rrdb => $rrdb }, $rrdb->dss;
  }

  return map $self->linedef($names[$_]->{name},
                            $self->colour_rgb($_, 0+@names),
                            $names[$_]->{rrdb}),
#              @names;
             0..$#names;
}

# -------------------------------------

sub colour_rgb {
  my ($self, $index, $namecount) = @_;
  tdumps index => $index, namecount => $namecount;

  if ( $self->colours_isset and $index < $self->colours_count ) {
    return get_rgb($self->colours_index($index));
  } else {
    return get_rgb((0.5+$index)/$namecount);
  }
}

# -------------------------------------

sub last_update { max map $_->last_update, $_[0]->rrdbs }

# -------------------------------------

sub graph {
  my ($self, $out_fn) = @_;

  my @rras = map $_->rras, $self->rrdbs;

  given ( $self->range || '' ) { # make sure it's defined so when ( /.../ ) doesn't whinge
    when ( '' ) { } # do nothing

    when ( /^\d+$/ ) {
      if ( $_ >= @rras ) {
        die "range $_ exceeds number of available RRAs (@{[0+@rras]})\n";
      } else {
        @rras = $rras[$_];
      }
    }

    when ( defined ) { die "a range '$_' was defined, but we cannot parse it\n" }
  }

  my ($start, $end) = ($self->start, $self->end);
  if ( defined $start ) {
    $end //= $self->last_update;
  } elsif ( defined $end ) {
    $start //= $end - 24*60*60; # default start to - 1 day
  } else {
    ($start, $end) = (min(map $_->start, @rras), $self->last_update);
  }

  my @graph = ($out_fn,
               "--title", sprintf('%s - %s', ftime($start), ftime($end)),
               "--start" => $start,
               "--end"   => $end,
               "--width=800", "--height=600",
               $self->linedefs,
              );
  info "drawing graph from %s to %s, writing to %s",
       map(scalar gmtime $_, $start, $end), $out_fn;
  debug +{ graph => \@graph };
  RRDs::graph @graph;
  my $ERROR;
  die "E: $ERROR\n" if $ERROR = RRDs::error;
}

# ----------------------------------------------------------------------------

1; # keep require happy
