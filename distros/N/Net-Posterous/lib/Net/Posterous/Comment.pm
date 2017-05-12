package Net::Posterous::Comment;

use strict;
use base qw(Net::Posterous::Object);
use Class::Accessor "antlers";
use DateTime::Format::Strptime;

=head1 NAME

Net::Posterous::Comment - represent a comment in Net::Posterous

=head1 METHODS

=cut


=head2 id 

Get or set the id of the comment.

=cut

has id => ( is => "rw", isa => "Int" );

=head2 body

=head2 comment

Get or set the body of the comment. C<comment> is an alias.

=cut

has body => ( is => "rw", isa => "Str" );

# GODDAMN IT Posterous - don't use different names in different parts of the API
sub comment {
    shift->body(@_);
}

=head2 datetime

Get or set the date of this comment as a C<DateTime> object.

=cut

sub datetime {
    shift->_handle_datetime(@_);    
}

=head2 date

Get or set the date of this comment as an RFC822 encoded date string.

=cut

has date => ( is => "rw", isa => "Str" );


=head2 author 

=head2 name

Get or set the author's name of this comment.

C<name> is an alias.

=cut

has author => ( is => "rw", isa => "Str" );

# GODDAMN IT Posterous - don't use different names in different parts of the API
sub name { shift->author(@_) }

=head2 email

Get or set the email of this comment.

=cut

has email => ( is => "rw", isa => "Str" );

=head2 author_pic 

=head2 authorpic

Get or set the url to the author of the comment's user pic.

C<authorpic> is an alias due to Posterous having interestingly inconsistent naming schema.

=cut

sub author_pic { shift->authorpic(@_) }
has authorpic => ( is => "rw", isa => "Str" );

sub _to_params {
    my $self   = shift;
    my @keys   = qw(comment name email date);
    my %params = ();
    foreach my $key (@keys) {
        my $val = $self->$key || next;
        $params{$key} = $val;
    }

    return %params;   
}

1;