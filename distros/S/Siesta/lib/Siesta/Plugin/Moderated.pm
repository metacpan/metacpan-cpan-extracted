# $Id: $
package Siesta::Plugin::Moderated;
use strict;
use Siesta::Plugin;
use base 'Siesta::Plugin';
use Siesta::Deferred;

sub description {
    "force all posts to be moderated by the list owner";
}

# TODO let someone who's not the owner be a moderator

sub process {
    my $self = shift;
    my $mail = shift;
    my $list = $self->list;

    return unless $self->pref('moderated');

    # This job would be great if it wasn't for the fucking customers.
    my $id = $mail->defer(
        why     => "moderated",
        who     => $list->owner,
       );


    $mail->reply( to      => $list->owner->email,
                  from    => $list->address('resume'),
                  subject => "deferred message",
                  body    => Siesta->bake('moderated_approve',
                                          list     => $list,
                                          mail     => $mail,
                                          deferred => $id),
                 );

    return 1 unless $self->pref('tell_user');

    $mail->reply( from => $list->return_path,
                  body => Siesta->bake('moderated') );

    return 1;
}

sub options {
    +{
      'moderated'
      => {
          description => "should we hold all posts to be okayed by the list-owner",
          type        => "boolean",
          default     => 0,
         },
      'tell_user'
      => {
          description => "should we tell the user if their post is being held?",
          type        => "boolean",
          default     => 0,
         },
     };
}

1;
