package Net::Gnats::Field;
use strictures;
BEGIN {
  $Net::Gnats::Field::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::FieldInstance;

=head1 NAME

Net::Gnats::Field

=head1 DESCRIPTION

Base class for a PR's metadata

In a given session, for a given field, this should have to be run once
and stashed somewhere for reuse.

=head1 EXAMPLES

Construct an empty field

 my $f = Net::Gnats::Field->new;

Initialize from server

 my $f = Net::Gnats::Field->new( name => 'myfield' )->initialize($session);

Manual initialization

 my $f = Net::Gnats::Field
   ->new( name => 'myfield',
          description => 'description',
          type => type,
          default => default,
          flags => flags,
          validators => validators );

=cut

sub new {
  my ( $class, %o ) = @_;
  return bless {}, $class if not %o;
  return bless \%o, $class;
}

sub change_reason_field {
  my ( $self, $name ) = @_;
  return undef if not $self->requires_change_reason;
  $self->_create_change_reason($name) if not defined $self->{change_reason};
  return $self->{change_reason};
}

sub default {
  my ( $self, $value ) = @_;
  $self->{default} = $value if defined $value;
  $self->{default};
}

sub description {
  my ( $self, $value ) = @_;
  $self->{description} = $value if defined $value;
  $self->{description};
}

sub flags {
  my ( $self, $value ) = @_;
  $self->{flags} = $value if defined $value;
  $self->{flags};
}

sub name {
  my ( $self, $value ) = @_;
  $self->{name} = $value if defined $value;
  $self->{name};
}

sub requires_change_reason {
  return 1 if shift->flags =~ /requireChangeReason/;
  return 0;
}

sub type {
  my ( $self, $value ) = @_;
  $self->{type} = $value if defined $value;
  $self->{type};
}

sub validators {
  my ( $self, $value ) = @_;
  $self->{validators} = $value if defined $value;
  $self->{validators};
}

=head1 METHODS

=head2 initialize

=cut

sub initialize {
  my ( $self ) = @_;
}

=head2 instance

Creates an instance of this meta field.  Represents a literal field in a PR.

=cut

sub instance {
  my ( $self, %options ) = @_;
  my $name = defined $options{for_name} ? $options{for_name} : $self->name;
  my $fi = Net::Gnats::FieldInstance->new( schema => $self, name => $name );
  $fi->value( $options{value} ) if defined $options{value};
  return $fi;
}

sub _create_change_reason {
  my ($self, $name) = @_;
  my $f = Net::Gnats::Field->new;
  $f->name($name . '-Changed-Why');
  $f->description($self->description . ' - Reason for Change');
  $f->type('multiText');
  $self->{change_reason} = $f;
}

1;
