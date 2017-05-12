package RT::Action::UpdateNagiosTickets;

use strict;
use warnings;

use base qw(RT::Action);

sub Describe {
    my $self = shift;
    return ( ref $self );
}

sub Prepare {
    return (1);
}

sub Commit {
    my $self = shift;

    my $attachment = $self->TransactionObj->Attachments->First;
    return 1 unless $attachment;
    my $new_ticket    = $self->TicketObj;
    my $new_ticket_id = $new_ticket->id;

    my $subject = $attachment->GetHeader('Subject');
    return unless $subject;
    if ( my ( $type, $category, $host, $problem_type, $problem_severity ) =
        $subject =~ m{(PROBLEM|RECOVERY|ACKNOWLEDGEMENT|FLAPPING(?:START|STOP))
                      \s+ (Service|Host)
                      \s+ Alert:
                      \s+ ([^/]+)/?(.*)
                      \s+ is \s+ (\w+)}ix
      )
    {
        $problem_type ||= '';
        $RT::Logger->info(
"Extracted type, category, host, problem_type and problem_severity from
subject with values $type, $category, $host, $problem_type and $problem_severity"
        );
        my $tickets = RT::Tickets->new( $self->CurrentUser );
        $tickets->LimitQueue( VALUE => $new_ticket->Queue )
          unless RT->Config->Get('NagiosSearchAllQueues');
        my $subject = "$category Alert: $host"
              . ( $problem_type ? "/$problem_type" : '' );
        $tickets->LimitSubject(
            VALUE => $subject,
            OPERATOR => 'LIKE',
        );
        my @active = RT::Queue->ActiveStatusArray();
        for my $active (@active) {
            $tickets->LimitStatus(
                VALUE    => $active,
                OPERATOR => '=',
            );
        }

        my $resolved = RT->Config->Get('NagiosResolvedStatus') || 'resolved';

        if ( my $merge_type = RT->Config->Get('NagiosMergeTickets') ) {
            my $merged_ticket;

            $tickets->OrderBy(
                FIELD => 'Created',
                ORDER => $merge_type > 0 ? 'DESC' : 'ASC',
            );
            $merged_ticket = $tickets->Next;

            while ( my $ticket = $tickets->Next ) {
                my ( $ret, $msg ) = $ticket->MergeInto( $merged_ticket->id );
                if ( !$ret ) {
                    $RT::Logger->error( 'failed to merge ticket '
                          . $ticket->id
                          . " into "
                          . $merged_ticket->id
                          . ": $msg" );
                }
            }

            if ( uc $type eq 'RECOVERY' ) {
                if ( not $merged_ticket or not $merged_ticket->id ) {
                    $RT::Logger->error( 'Recovery ticket with no initial ticket: $subject' );
                    $merged_ticket = $new_ticket;
                }
                my ( $ret, $msg ) = $merged_ticket->SetStatus($resolved);
                if ( !$ret ) {
                    $RT::Logger->error( 'failed to resolve ticket '
                          . $merged_ticket->id
                          . ":$msg" );
                }
            }
        }
        elsif ( uc $type eq 'RECOVERY' ) {
            while ( my $ticket = $tickets->Next ) {
                my ( $ret, $msg ) = $ticket->Comment(
                    Content => 'going to be resolved by ' . $new_ticket_id,
                    Status  => $resolved,
                );
                if ( !$ret ) {
                    $RT::Logger->error(
                        'failed to comment ticket ' . $ticket->id . ": $msg" );
                }

                ( $ret, $msg ) = $ticket->SetStatus($resolved);
                if ( !$ret ) {
                    $RT::Logger->error(
                        'failed to resolve ticket ' . $ticket->id . ": $msg" );
                }
            }
            my ( $ret, $msg ) = $new_ticket->SetStatus($resolved);
            if ( !$ret ) {
                $RT::Logger->error(
                    'failed to resolve ticket ' . $new_ticket->id . ":$msg" );
            }
        }
    }
}

1;
