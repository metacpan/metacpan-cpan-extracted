package Net::Gnats::Schema;
use strictures;
BEGIN {
  $Net::Gnats::Schema::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Command;
use Net::Gnats::Field;
use Net::Gnats::PR;


sub new {
  my ( $class, $session ) = @_;

  my $self = bless {}, $class;
  $self->initialize($session) if defined $session;
  return $self;
}

=head2 initialize

Initializes, or re-initializes, the schema for this session.

=cut

sub initialize {
  my ( $self, $session ) = @_;

  my $c_f = Net::Gnats::Command->list(subcommand => 'fieldnames');
  my $fields = $session->issue($c_f)->response->as_list;

  my $c_fr = Net::Gnats::Command->list(subcommand => 'initialrequiredfields');
  my $c_fi = Net::Gnats::Command->list(subcommand => 'initialinputfields');

  $self->{initial} = $session->issue($c_fi)->response->as_list;
  $self->{required} = $session->issue($c_fr)->response->as_list;

  my $c_types = Net::Gnats::Command->ftyp(fields => $fields);
  my $c_descs = Net::Gnats::Command->fdsc(fields => $fields);
  my $c_deflt = Net::Gnats::Command->inputdefault(fields => $fields);
  my $c_flags = Net::Gnats::Command->fieldflags(fields => $fields);

  $session->issue($c_types);
  $session->issue($c_descs);
  $session->issue($c_deflt);
  $session->issue($c_flags);

  foreach my $fname (@{ $fields }) {
    my $f = Net::Gnats::Field->new;
    $f->name($fname);
    $f->description($c_descs->from($fname));
    $f->type($c_types->from($fname));
    $f->default($c_deflt->from($fname));
    $f->flags($c_flags->from($fname));
    $self->{fields}->{$fname} = $f;
#    $self->{db_meta}->{fields}->{$f}->{validators} = @{ $vldtr }[$i];
  }
}


=head2 field

Returns the field object for the named field.

=cut

sub field {
  my ( $self, $name ) = @_;
  return 0 if not defined $self->{fields}->{$name};
  return $self->{fields}->{$name}
}

=head2 fields

Returns an anonymous array of all fields for this PR Schema.

=cut

sub fields { [ keys %{ shift->{fields} } ] }

=head2 initial

Returns an anonymous array of initial input fields for this PR Schema.

=cut

sub initial { shift->{initial} }

=head2 required

Returns an anonymous array of required input fields for this PR Schema.

=cut

sub required { shift->{required} }

sub new_pr {
  my ($self) = @_;
  return Net::Gnats::PR->new();
}

1;
