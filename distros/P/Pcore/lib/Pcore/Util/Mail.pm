package Pcore::Util::Mail;

use Pcore;
use Pcore::Util::Text qw[decode_utf8];
use Mail::IMAPClient qw[];

sub get_mail {
    my %args = (
        gmail           => 0,
        host            => undef,
        port            => undef,
        ssl             => 1,
        login           => undef,
        password        => undef,
        folders         => undef,
        search          => { unseen => \1 },    # unseen => \1, to => user@domain,
        found_action    => q[],                 # 'delete_message', what to do with founded messages, by default message mark as read and moved to "all mail" folder
        retries         => 1,
        retries_timeout => 3,
        @_,
    );

    if ( $args{gmail} ) {
        P->hash->merge(
            \%args,
            {   host => 'imap.gmail.com',
                port => 993,
                ssl  => 1
            }
        );
        $args{folders} = [ '[Gmail]/All Mail', '[Gmail]/Spam' ] unless $args{folders};
    }
    else {
        $args{folders} = ['INBOX'] unless $args{folders};
    }

    my $imap = Mail::IMAPClient->new(
        Server   => $args{host},
        Port     => $args{port},
        Ssl      => $args{ssl},
        User     => $args{login},
        Password => $args{password},
    ) or die 'IMAP connections error';
    die 'IMAP connection error' unless $imap->IsAuthenticated;

    my @search_string;

    for my $token ( keys $args{search}->%* ) {
        my $res;

        if ( ref $args{search}->{$token} ) {
            $res = $args{search}->{$token}->$* == 1 ? uc $token : undef;
        }
        elsif ( $args{search}->{$token} ) {
            $res = uc($token) . q[ ] . $imap->Quote( $args{search}->{$token} );
        }

        push @search_string, $res if $res;
    }
    my $search_string = join q[ ], @search_string;

  REDO_SEARCH:
    P->sendlog( 'Pcore-Util-Mail.DEBUG', 'IMAP search: ' . $search_string ) if $ENV{PCORE_UTIL_MAIL_DEBUG};

    my $messages = [];

    for my $folder ( @{ $args{folders} } ) {
        P->sendlog( 'Pcore-Util-Mail.DEBUG', 'IMAP search in folder: ' . $folder ) if $ENV{PCORE_UTIL_MAIL_DEBUG};

        $imap->select($folder);

        if ( my $res = $imap->search($search_string) ) {
            if ( @{$res} ) {
                P->sendlog( 'Pcore-Util-Mail.DEBUG', 'IMAP found: ' . $res->@* ) if $ENV{PCORE_UTIL_MAIL_DEBUG};

                push $messages->@*, _get_messages( $imap, $folder, $res, $args{found_action} )->@*;
            }
        }
    }
    if ( @{$messages} ) {
        P->sendlog( 'Pcore-Util-Mail.DEBUG', 'IMAP total found: ' . $messages->@* ) if $ENV{PCORE_UTIL_MAIL_DEBUG};

        $imap->disconnect;

        return $messages;
    }

    if ( $args{retries} && --$args{retries} ) {
        P->sendlog( 'Pcore-Util-Mail.DEBUG', 'IMAP sleep: ' . $args{retries_timeout} ) if $ENV{PCORE_UTIL_MAIL_DEBUG};

        sleep $args{retries_timeout};

        $imap->disconnect;

        $imap->reconnect;

        P->sendlog( 'Pcore-Util-Mail.DEBUG', 'IMAP run next search iteration: ' . $args{retries} ) if $ENV{PCORE_UTIL_MAIL_DEBUG};

        goto REDO_SEARCH;
    }

    P->sendlog( 'Pcore-Util-Mail.DEBUG', 'IMAP nothing found' ) if $ENV{PCORE_UTIL_MAIL_DEBUG};

    $imap->disconnect;

    return;
}

sub _get_messages {
    my $imap         = shift;
    my $folder       = shift;
    my $messages     = shift;
    my $found_action = shift;

    my $bodies = [];
    for my $msg ( @{$messages} ) {
        my $body = $imap->body_string($msg);
        my $content_type = $imap->get_header( $msg, 'Content-Type' );
        if ( $content_type =~ /charset="(.+?)"/sm ) {
            decode_utf8( $body, encoding => $1 );
        }
        push $bodies->@*, $body;
    }
    if ($found_action) {
        P->sendlog( 'Pcore-Util-Mail.DEBUG', 'IMAP apply found action: ' . $found_action ) if $ENV{PCORE_UTIL_MAIL_DEBUG};

        my $method = $found_action;

        my $res = $imap->$method($messages);

        P->sendlog( 'Pcore-Util-Mail.DEBUG', 'IMAP messages, affected by action: ' . $res ) if $ENV{PCORE_UTIL_MAIL_DEBUG};

        $imap->expunge($folder);
    }
    return $bodies;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 7                    | Subroutines::ProhibitExcessComplexity - Subroutine "get_mail" with high complexity score (25)                  |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=head1

=over

=item * type, tls, ssl, ''

=item * host

=item * port

=item * user

=item * password

=item * from

=item * to, several emails allowed, splitted by , or ;

=item * reply_to

=item * subject

=item * body

=item * content_type, default: text/plain; charset="UTF-8"

=item * attachments, [], {}, string - path to file

=back

=head1

=over

=item * login

=item * password

=item * search

=item * found_action, IMAP method to perform on founded messages. Can be undef, "delete_message", "seen" or somethig else.

=item * retries

=item * retries_timeout, default 3 seconds

=back

=cut
