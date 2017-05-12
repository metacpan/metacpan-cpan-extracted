package MooseX::Role::REST::Consumer::Response;
use Moose;
use Carp;
use overload
  'bool' => sub { shift->is_success },
  '""'   => sub { shift->_stringify() };

has 'is_success'    => ( isa => 'Bool', is => 'ro', required => 1 );
has 'error_message' => ( isa => 'Str',  is => 'ro', required => 0 );
has 'data'          => (                is => 'ro', required => 0 );
has 'request'       => ( is => 'ro' );
has 'response'      => ( is => 'ro' );

sub success {
  my $class = shift;
  return $class->new(is_success => 1, @_);
}

sub failure {
  my $class = shift;
  return $class->new(is_success => 0, @_);
}

sub is_failure {
  my $self = shift;
  return $self->is_success ? 0 : 1;
}

sub _stringify {
  my $self = shift;

  if (defined $self->error_message) {
    return $self->error_message;
  }
  return '';
}

__PACKAGE__->meta->make_immutable();

=cut 

=head1 NAME

MooseX::Role::REST::Consumer::Response - A simple utility to provide object-oriented return values with messaging

=head1 SYNOPSIS

  use MooseX::Role::REST::Consumer::Response

  sub do_something {
      ....

    return MooseX::Role::REST::Consumer::Response->success(
        message => "Everything worked",
    );
  }

  my $response = do_something();
  print "Response: $response\n";
  if (! $response) {
      ...
  }

=head1 DESCRIPTION

The B<Reponse> object in this class can be used in boolean or string context and should DWIM.

=head1 CLASS METHODS

=head2 new (%param)

=over 4

=item B<is_success> - Boolean of if success or not

=item B<message> - Optional text message

=back

Returns blessed object

=head2 success (%param)

Takes same parameters as B<new> but implies ( is_success => 1 );

=head2 failure (%param)

Similar to B<success> but implies ( is_success => 0 );

=head1 OBJECT METHODS

First, some basic L<Moose> attribute accessors:

=over 4

=item B<is_success>

=item B<error_message>

=back


=head2 is_failure

Returns boolean

=cut


