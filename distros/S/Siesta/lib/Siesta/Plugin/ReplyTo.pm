package Siesta::Plugin::ReplyTo;
use strict;
use Siesta::Plugin;
use base 'Siesta::Plugin';

sub description {
    "Munges the Reply-To header to the list address, not the person who sent it";
}

# see :
#   http://www.unicom.com/pw/reply-to-harmful.html
#   http://www.metasystema.org/essays/reply-to-useful.mhtml
#   http://thegestalt.org/simon/replytorant.html
#   http://www.deez.info/sengelha/writings/considered-harmful/
# for various for and against arguments thrashed out by the great
# and the good and for why I don't care. Feel free to argue about
# this to your hearts content - the monkeys dance for my pleasure.
#
# DANCE MONKEYS! DANCE!


sub process {
    my $self = shift;
    my $mail = shift;
    my $list = $self->list;

    $mail->header_set( 'Reply-To', $list->post_address )
      if $self->pref( 'munge' );

    return;
}

sub options {
    +{
      munge =>
      {
       description =>
       'should we munge the reply-to address of the message to be the list post address',
       type    => 'boolean',
       default => 0,
      },
     };
}

1;
