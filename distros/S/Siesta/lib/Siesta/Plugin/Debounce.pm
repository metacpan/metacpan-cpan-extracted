package Siesta::Plugin::Debounce;
use strict;
use Siesta::Plugin;
use base 'Siesta::Plugin';

sub description {
    "handles bounces/loops.";
}

sub process {
    my $self = shift;
    my $mail = shift;

    my $post = $self->list->post_address;
    for my $been ( $mail->header_set('X-Been-There') ) {
        chomp $been;

        # have we been here before?
        return 1 if $been eq $post;
    }

    $mail->header_set( 'X-Been-There', $post );
    return;
}

1;

