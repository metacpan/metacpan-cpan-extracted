# $Id: Send.pm 1179 2003-07-13 15:13:22Z richardc $
package Siesta::Plugin::Send;
use strict;
use Siesta::Plugin;
use base 'Siesta::Plugin';

sub description {
    "dispatch mail to list members";
}

sub process {
    my $self = shift;
    my $mail = shift;

    my $list = $self->list;
  USER: for my $user ($list->members) {
        next if $user->nomail;

        my $message = $mail->clone;

        for my $plugin (grep { $_->personal } $list->plugins) {
            $plugin->member($user);
            next USER if $plugin->process($message);
        }
        Siesta->sender->send( $message,
                              to   => $user->email,
                              from => $list->return_path,
                            );
    }
    return;
}

1;
