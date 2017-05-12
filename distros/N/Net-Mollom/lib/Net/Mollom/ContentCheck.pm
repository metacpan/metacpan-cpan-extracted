package Net::Mollom::ContentCheck;
use Any::Moose;

has is_spam => (is => 'rw', isa => 'Bool');
has is_ham  => (is => 'rw', isa => 'Bool');
has is_unsure  => (is => 'rw', isa => 'Bool');
has quality => (is => 'rw', isa => 'Num');
has session_id => (is => 'rw', isa => 'Str');

no Any::Moose;
__PACKAGE__->meta->make_immutable;

=head1 NAME

Net::Mollom::ContentCheck

=head1 SYNOPSIS

The results of the C<mollom.checkContent> XML-RPC call.

    my $mollom = Net::Mollom->new(...);
    my $check = $mollom->check_content(
        post_title => $title,
        post_body  => $body,
    );

    if( $check->is_spam ) {
        warn "someone's trying to sell us v1@grA!"
    } elsif( $check->quality < .5 ) {
        warn "someone might be trying to flame us!"
    }

=head1 METHODS

You should not construct an object of this class by yourself. Instead
it should be done by L<Net::Mollom>'s call to C<check_content()>. After
you get one, these are the methods you can call.

=head2 is_spam

Returns true if the content sent was spam.

=head2 is_ham

Returns true if the content sent was not spam.

=head2 is_unsure

Returns true if Mollom isn't completely sure if this comment was spam or ham.

=head2 quality

A real number between 0 and 1 that's shows the quality of the content
posted. 0 being the worst and 1 being the best.

=head2 session_id

The ID of the Mollom session that this check was part of. This can be
saved and used later (ie, you need to call C<send_feedback> for some
content after some time in the future).

=cut

1;
