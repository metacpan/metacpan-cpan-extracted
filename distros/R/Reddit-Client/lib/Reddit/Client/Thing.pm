package Reddit::Client::Thing;

use strict;
use warnings;
use Carp;

use List::Util qw/first/;

# If a field is used by another class it must also be added to that class's 
# fields
# Why does adding a field that exists in link but not comment (can_mod_post)
# break comments but not other types of things, like profiles?
# because can_mod_post DOES exist for comments. this would get to that field,
# which was previously ignored, but now it's in BOOL here, so it would try to 
# set it, but the field didn't exist in Comment, so it would fail.
our @BOOL_FIELDS = qw/
can_mod_post
clicked
has_mail
has_mod_mail
has_verified_email
hidden
is_employee
is_gold
is_mod
is_original_content
is_self
likes
locked
new
over18
over_18
public_traffic
quarantine
removed
saved
spam
spoiler
stickied
verified
was_comment

isAuto
isHighlighted
isInternal
isRepliable
/;

use fields qw/session name id/;

sub new {
	# $reddit is a Reddit::Client object
    my ($class, $reddit, $source_data) = @_;
    my $self = fields::new($class);
    $self->{session} = $reddit; # could this be called something more sensible
    $self->load_from_source_data($source_data) if $source_data;
    return $self;
}

sub load_from_source_data {
    require Reddit::Client;
 
    my ($self, $source_data) = @_;
    if ($source_data) {
		# Hack that allows us to set link_id reliably when creating a MoreCommen
		# object from Comment. This ensures that link_id is always set before 
		# replies.
        #foreach my $field (keys %$source_data) {
        foreach my $field (sort keys %$source_data) {
            # Set data fields
            my $setter = sprintf 'set_%s', $field;
            if ($self->can($setter)) {
                $self->can($setter)->($self, $source_data->{$field});
            } elsif (first {$_ eq $field} @BOOL_FIELDS) {
                $self->set_bool($field, $source_data->{$field});
            } else {
	            eval { $self->{$field} = $source_data->{$field} };
	            Reddit::Client::DEBUG("Field %s is missing from package %s\n", $field, ref $self)
	                if $@;
            }

            # Add getter for field
            my $getter = sub { $_[0]->{$field} };
            my $class  = ref $self;
            my $method = sprintf '%s::get_%s', $class, $field;

            unless ($self->can($method)) {
                no strict 'refs';
                *{$method} = \&$getter;
            }
        }
    }
}

sub set_bool {
    my ($self, $field, $value) = @_;
    $self->{$field} = $value ? 1 : 0;
}

1;

__END__

=pod

=head1 NAME

Reddit::Client::Thing

=head1 DESCRIPTION

A "Thing" is the base class of all Reddit objects. 

Generally, consumers of the Reddit::Client module do not instantiate these
objects directly. Things offer a bit of syntactic sugar around the data
returned by reddit's servers, such as the ability to comment directly on
a Link object.

=head1 SUBROUTINES/METHODS

=over

=item new($session, $data)

Creates a new Thing. C<$session> must be an instance of Reddit::Client.
C<$data>, when present, must be a hash reference of key/value pairs.

=back

=head1 INTERNAL ROUTINES

=over

=item set_bool($field, $value)

Sets a field to a boolean value of 1 or 0, rather than the JSON
module's boolean type.

=item load_from_source_data($data)

Populates an instances field with data directly from JSON data returned
by reddit's servers.

=back

=head1 AUTHOR

L<mailto:earthtone.rc@gmail.com>

=head1 LICENSE

BSD license

=cut
