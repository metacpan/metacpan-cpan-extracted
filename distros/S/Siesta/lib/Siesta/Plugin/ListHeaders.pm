package Siesta::Plugin::ListHeaders;
use strict;
use Siesta::Plugin;
use base 'Siesta::Plugin';

sub description {
    "add RFC2919 and RFC2396 headers";
}

sub process {
    my $self = shift;
    my $mail = shift;

    my $list         = $self->list;
    my $name         = $list->name;
    my $post_address = $list->post_address;
    my $owner        = $list->owner->email;
    ( my $list_id       = $post_address ) =~ s/@/./;
    ( my $sub_address   = $post_address ) =~ s/@/-sub@/;
    ( my $unsub_address = $post_address ) =~ s/@/-unsub@/;

    # rfc 2919
    $mail->header_set( 'List-Id', "$name <$list_id>" );

    # rfc 2396
    $mail->header_set( 'List-Help',        "<mailto:$owner>" );
    $mail->header_set( 'List-Unsubscribe', "<mailto:$unsub_address>" );
    $mail->header_set( 'List-Subscribe',   "<mailto:$sub_address>" );
    $mail->header_set( 'List-Post',        "<mailto:$post_address>" );
    $mail->header_set( 'List-Owner',       "<mailto:$post_address>" );
    $mail->header_set( 'List-Archive',     'NO' );

    return;
}

1;
