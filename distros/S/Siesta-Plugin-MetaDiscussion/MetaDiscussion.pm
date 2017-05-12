package Siesta::Plugin::MetaDiscussion;
use strict;
use Siesta::Plugin;
use base 'Siesta::Plugin';
use Siesta;

our $VERSION='0.03';


# "I have always taken you with a grain of salt. On your birthday when you asked me
# to do a striptease to the theme from Mighty Mouse, I said okay. When we were at
# that hotel on prom night and you asked me to sleep underneath the bed in case
# your mother burst in, I did it. And even when we were at my Grandmother's funeral
# and you told most of my relatives that you could see her nipples through her
# burial dress, I let it slide, but if you think I'm gonna suffer anymore of your
# shit with a smile now that we've broken up, you're in for a big fucking
# disappointment."  - Rene, Mallrats


sub description {
    'Remove MetaDiscussion';
}



sub process {
    my $self = shift;
    my $mail = shift;
    my $list = $self->list;

    my %trigger_phrases = (
                           'supercite'        => 2,
                           'jeopardy style'   => 1.5,
                           'top posting'      => 1,
                           'rfc1855'          => 2,
                           '1855'             => 0.9,
                           'oneliner'         => 0.9,
                           'oneliners'        => 1.0,
                           'reply-to'         => 1.0,
                           'reply-to munging' => 2.0,
                          );
    my $score = 0;

    for (keys(%trigger_phrases)) {
      $score += $trigger_phrases{$_} * $mail->body() =~ /$_/i;
    }

    return if ($score < $self->pref('threshold'));

    if ($self->pref('approve')) {
        my $id = $mail->defer(
            why => "metadiscussion post requires approval",
            who => $list->owner);
        $mail->reply( to      => $list->owner->email,
                      from    => $list->return_path,
                      subject => "deferred message",
                      body    => Siesta->bake('metadisucssion_approve',
                                              list     => $list,
                                              mail     => $mail,
                                              deferred => $id),
                     );
      }
    else {
        $mail->reply( to   => $list->owner->email,
                      from => $list->return_path,
                      body => Siesta->bake('metadiscussion_dropped',
                                           list => $list,
                                           mail => $mail)
                    );
    }


    return 1 unless $self->pref('tell_user');

    $mail->reply( from => $list->return_path,
                  body => Siesta->bake('metadiscussion_held',
                                       extra => "\nYour message is now held in an approval queue.")

                );
    return 1;
}

sub options {
    +{
      'tell_user'
      => {
          description => "should we tell the user if their post is rejected/delayed",
          type        => "boolean",
          default     => 0,
         },
      'approve'
      => {
          description => "should we hold suspected metadiscussion posts for approval",
          type        => "boolean",
          default     => 1,
         },
      'threshold'
      => {
          description => "the score at which a post is rejected/delayed",
          type        => "number",
          default     => 4,
         },
     };
}

1;

=pod

=head1 NAME

Siesta::Plugin::MetaDiscussion - reject messages to a mailing list about mailing lists

=head1 DESCRIPTION

THIS HAS BEEN TOTALLY UNTESTED, WAIT FOR RELEASE 0.02 UNLESS YOU WANT TO
DO DEBUGGING. IT DOESNT EVEN PASS TESTS ON MY BOX ... MUHAHAHAHAHAHA!

(Fixed now and released as 0.02 but this note kept in for historical reasons - Simon)


=head1 COPYRIGHT

(c)opyright 2003 - Greg McCarroll <greg@mccarroll.org.uk>

=head1 FIXED BY

Simon Wistow 

=cut


