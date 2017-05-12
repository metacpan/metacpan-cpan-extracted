package RRD::Daemon::RRDB::RRA;

=head1 RRDB::RRA - Round-robin archive within an rrdtool DB

=cut

# pragmata ----------------------------

use strict;
use warnings;
use feature  qw( :5.10 );

# utility -----------------------------

use base  qw( Params::Attr );

use RRD::Daemon::Util  qw( fdur );

# INSTANCE OBJECT ------------------------------------------------------------

sub new : CheckP(S,S,RRD::Daemon::RRDB,HR) {
  my ($class, $num, $rrdb, $rra) = @_;
#  use Data::Dumper; print STDERR Dumper $rra; die;
  bless +{ num => $num, rrdb => $rrdb, %$rra }, $class;
}

# -------------------------------------

sub num                { $_[0]->{num} }
sub cf                 { $_[0]->{cf} }
sub cur_ruw            { $_[0]->{cur_ruw}  }
sub pdp_per_row        { $_[0]->{pdp_per_row}  }
sub rows               { $_[0]->{rows}  }
sub xff                { $_[0]->{xff}  }
sub cdp_preps          { map $_[0]->{$_},
                             sort map /^cdp_prep\[(\d+)\]$/ ? $1 : (),
                                  keys %{$_[0]} }
sub rrdb               { $_[0]->{rrdb} }
sub start              { $_[0]->rrdb->last_update - $_[0]->duration }
sub secs_per_row       { $_[0]->pdp_per_row * $_[0]->rrdb->step }
sub fsecs_per_row      { fdur($_[0]->secs_per_row) }
sub duration           { $_[0]->secs_per_row * $_[0]->rows }
sub fduration          { fdur($_[0]->duration) }

# -------------------------------------

sub info_string : CheckP(_) {
  my ($self) = @_;

  my $text = '';
  # note that cdp_prep won't exist for DBs that make no sense, temporally
  # that is, if the DB has an RRA for the last ten days, and one for thirty days;
  # but is only 8 days old: there will be no RRA for thirty-day step

  # but I've not seen cdp_prep value/unknown_datapoints anything other than
  # undef
  # xff == x-files factor
  state $header_printed = 0;
  unless ( $header_printed++ ) {
    $text .= join("\t", '# num', qw( cf cur_ruw pdp/row rows xff row dur )) . "\n";
    $text .= join("\t", '## cdp', qw( value unknown )) . "\n";
  }

  $text .= join("\t", $self->{num},
                      map $self->$_//'-',
                          qw( cf cur_ruw pdp_per_row rows xff 
                              fsecs_per_row fduration ))
           . "\n";

  my @cdp_preps = $self->cdp_preps;
  for my $i (0..$#cdp_preps) {
    my $cdp = $cdp_preps[$i];
    $text .= join("\t", "   $i",
                        map $_ // '-',
                            @{$cdp}{qw(value unknown_datapoints)})
             . "\n";
  }


  return $text;
}

# ----------------------------------------------------------------------------

1; # keep require happy
