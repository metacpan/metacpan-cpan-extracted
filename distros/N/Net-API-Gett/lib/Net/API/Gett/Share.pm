package Net::API::Gett::Share;

=head1 NAME

Net::API::Gett::Share - Gett share object

=cut

use Moo;
use Carp qw(croak);
use Array::Iterator;
use MooX::Types::MooseLike::Base qw(Int Str);

our $VERSION = '1.06';

=head1 PURPOSE

Encapsulate Gett shares.  You normally shouldn't instantiate this class on its own, as the
library will create and return this object as appropriate.

=head1 ATTRIBUTES

=over

=item user

L<Net::API::Gett::User> object. C<has_user()> predicate.

=back

=cut

has 'user' => (
    is => 'rw',
    predicate => 'has_user',
    isa => sub { die "$_[0] is not Net::API::Gett::User" unless ref($_[0]) =~ /User/ },
    lazy => 1,
);

=over

=item request

L<Net::API::Gett::Request> object.

=back

=cut

has 'request' => (
    is => 'rw',
    isa => sub { die "$_[0] is not Net::API::Gett::Request" unless ref($_[0]) =~ /Request/ },
    default => sub { Net::API::Gett::Request->new() },
    lazy => 1,
);

=over 

=item sharename

Scalar string. Read only.

=item title

Scalar string.

=item created 

Scalar integer. Read only. This value is in Unix epoch seconds, suitable for use in a call to C<localtime()>.

=item getturl

Scalar string. The URL to use in a browser to access a share.

=item files

This attribute holds any L<Net::API::Gett:File> objects linked to a particular 
share instance. It returns a list of L<Net::API::Gett:File> objects if 
there are any, otherwise returns an empty list. See also 
C<get_file_iterator()> below.

=back

=cut

has 'sharename' => (
    is => 'ro',
    isa => Str,
);

has 'title' => (
    is => 'rw',
);

has 'created' => (
    is => 'ro',
    isa => Int,
);

has 'getturl' => (
    is => 'ro',
    isa => Str,
);

sub files {
    my $self = shift;

    return () unless exists $self->{'files'};

    return @{ $self->{'files'} };
}

=head1 METHODS

=over

=item add_file()

This method stores a new L<Net::API::Gett::File> object in the share object.
It returns undef if the value passed is not an L<Net::API::Gett::File> object.

=back

=cut

sub add_file {
    my $self = shift;
    my $file = shift;

    return undef unless ref($file) =~ /File/;

    $file->sharename($self->sharename) unless $file->sharename;

    $file->user($self->user) if $self->has_user;

    push @{ $self->{'files'} }, $file;
}

=over

=item file_iterator()

This method returns a L<Array::Iterator> object on the files in this share. For full details 
about L<Array::Iterator> please read its documentation. It supports standard iterator
methods such as:

=over

=item * next()

=item * has_next()

=item * get_next()

=item * peek()

=back

Example code using peek:

  my $share = $gett->get_share("4ddsfds");
  my $file_iter = $share->file_iterator();

  while ( $file_iter->has_next ) {
    if ( $file_iter->peek->size > 1_048_576 ) {
      # Skip big file
      warn $file_iter->peek->filename . " is too large, skipping\n";
      $file_iter->next();
    } 
    else {
      my $file = $file_iter->next();
      printf "name: %s\tsize: %d\n", $file->filename, $file->size;
    }
  }

Example code using get_next:

  for my $file ( $file_iter->get_next() ) {
    say "name: " . $file->filename . "\tsize: " . $file->size;
  }

=back

This method returns undef if there are no files associated with a share.

=cut

sub file_iterator {
    my $self = shift;

    return undef unless exists $self->{'files'};

    return Array::Iterator->new($self->{'files'});
}

=over

=item update()

This method updates share attributes.  At present, only the share title can be changed (or deleted), 
so pass in a string to set a new title for a specific share.

Calling this method with an empty parameter list or explicitly passing C<undef> 
will B<delete> any title currently set on the share.

Returns a L<Net::API::Gett:Share> object with updated values.

=back

=cut
        
sub update {
    my $self = shift;

    croak "Cannot call update without a Net::API::Gett::User object" unless $self->has_user;

    my $title = shift;
    my $name = $self->sharename;

    $self->user->login unless $self->user->has_access_token;

    my $response = $self->request->post("/shares/$name/update?accesstoken=".$self->user->access_token, 
            { title => $title } );

    if ( $response ) {
        $self->title( $response->{'title'} );
        return $self;
    }
    else {
        return undef;
    }
}

=over

=item destroy()

This method destroys the share and all of the share's files.  Returns a true boolean
on success.

=back

=cut

sub destroy {
    my $self = shift;

    croak "Cannot call destroy without a Net::API::Gett::User object" unless $self->has_user;

    my $name = $self->sharename;

    $self->user->login unless $self->user->has_access_token;

    my $response = $self->request->post("/shares/$name/destroy?accesstoken=".$self->user->access_token);

    if ( $response ) {
        return 1;
    }
    else {
        return undef;
    }
}

=head1 SEE ALSO

L<Net::API::Gett>, L<Array::Iterator>

=cut

1;
