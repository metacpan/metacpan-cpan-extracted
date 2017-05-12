# $Id: UnSubscribe.pm 1243 2003-07-21 16:50:06Z richardc $
package Siesta::Plugin::UnSubscribe;
use strict;
use Siesta::Plugin;
use base 'Siesta::Plugin';

sub description {
    'A system plugin used for unsubscribing a member to the list';
}

sub process {
    my $self = shift;
    my $mail = shift;
    my $list = $self->list;

    my $email = $mail->from;
    if ( $list->remove_member($email) ) {
        $mail->reply(
            from => $list->address( 'admin' ),
            to   => $list->owner->email,
            body => "$email LEFT " . $list->name
           );

        $mail->reply(
            from => $list->address( 'unsubscribe' ),
            body => Siesta->bake('unsubscribe_success',
                                 list    => $list,
                                 message => $mail ) );
    }
    else {
        $mail->reply(
            to   => $list->owner->email,
            from => $list->address( 'admin' ),
            body => "$email FAIL LEFT " . $list->name
           );

        $mail->reply(
            from => $list->address( 'admin' ),
            body => Siesta->bake('unsubscribe_failure',
                                 list    => $list,
                                 message => $mail ) );
    }
    return 1;
}

1;
