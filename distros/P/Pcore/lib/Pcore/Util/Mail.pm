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
    P->log->sendlog( 'IMAP', 'IMAP search: ' . $search_string );

    my $messages = [];

    for my $folder ( @{ $args{folders} } ) {
        P->log->sendlog( 'IMAP', 'IMAP search in folder: ' . $folder );

        $imap->select($folder);

        if ( my $res = $imap->search($search_string) ) {
            if ( @{$res} ) {
                P->log->sendlog( 'IMAP', 'IMAP found: ' . $res->@* );

                push $messages->@*, _get_messages( $imap, $folder, $res, $args{found_action} )->@*;
            }
        }
    }
    if ( @{$messages} ) {
        P->log->sendlog( 'IMAP', 'IMAP total found: ' . $messages->@* );

        $imap->disconnect;

        return $messages;
    }

    if ( $args{retries} && --$args{retries} ) {
        P->log->sendlog( 'IMAP', 'IMAP sleep: ' . $args{retries_timeout} );

        sleep $args{retries_timeout};

        $imap->disconnect;

        $imap->reconnect;

        P->log->sendlog( 'IMAP', 'IMAP run next search iteration: ' . $args{retries} );

        goto REDO_SEARCH;
    }

    P->log->sendlog( 'IMAP', 'IMAP nothing found' );

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
        P->log->sendlog( 'IMAP', 'IMAP apply found action: ' . $found_action );

        my $method = $found_action;

        my $res = $imap->$method($messages);

        P->log->sendlog( 'IMAP', 'IMAP messages, affected by action: ' . $res );

        $imap->expunge($folder);
    }
    return $bodies;
}

1;
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
