package RRD::Daemon::RRDB::DS;

=head1 RRDB::DS - Data Source within an rrdtool DB

=cut

# pragmata ----------------------------

use strict;
use warnings;
use feature  qw( :5.10 );

# utility -----------------------------

use base qw( Params::Attr );

# INSTANCE OBJECT ------------------------------------------------------------

sub new : CheckP(S,S,HR) {
  my ($class, $name, $ds) = @_;

  bless +{ name => $name, %$ds }, $class;
}

# -------------------------------------

sub name               { $_[0]->{name} }
sub type               { $_[0]->{type} }
sub max                { $_[0]->{max}  }
sub min                { $_[0]->{min}  }
sub minimal_heartbeat  { $_[0]->{minimal_heartbeat}  }
sub last_ds            { $_[0]->{last_ds}  }
sub value              { $_[0]->{value}  }
sub unknown_sec        { $_[0]->{unknown_sec}  }

# -------------------------------------

sub info_string : CheckP(_) {
  my ($self) = @_;

  my $text;
  state $header_printed = 0;
  $text .= join("\t", '# name', qw( type min max htbeat last value unk_sec )) . "\n"
    unless $header_printed++;
  $text .= join("\t", $self->name,
                # unknown sec is seconds since step without an input value
                 map $self->$_//'-', qw( type min max minimal_heartbeat last_ds
                                         value unknown_sec ))
           . "\n";

  return $text;
}

# ----------------------------------------------------------------------------

1; # keep require happy
