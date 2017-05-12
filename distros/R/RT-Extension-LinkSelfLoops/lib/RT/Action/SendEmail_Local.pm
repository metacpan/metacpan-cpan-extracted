sub SetRTSpecialHeaders {
    my $self = shift;

    $self->SetSubject();
    $self->SetSubjectToken();
    $self->SetHeaderAsEncoding( 'Subject',
        RT->Config->Get('EmailOutputEncoding') )
        if ( RT->Config->Get('EmailOutputEncoding') );
    $self->SetReturnAddress();
    $self->SetReferencesHeaders();
    $self->SetHeader("X-RT-Transaction-Id" => $self->TransactionObj->Id );

    unless ( $self->TemplateObj->MIMEObj->head->get('Message-ID') ) {

        # Get Message-ID for this txn
        my $msgid = "";
        if ( my $msg = $self->TransactionObj->Message->First ) {
            $msgid = $msg->GetHeader("RT-Message-ID")
                || $msg->GetHeader("Message-ID");
        }

        # If there is one, and we can parse it, then base our Message-ID on it
        if (    $msgid
            and $msgid
            =~ s/<(rt-.*?-\d+-\d+)\.(\d+)-\d+-\d+\@\QRT->Config->Get('Organization')\E>$/
                         "<$1." . $self->TicketObj->id
                          . "-" . $self->ScripObj->id
                          . "-" . $self->ScripActionObj->{_Message_ID}
                          . "@" . RT->Config->Get('Organization') . ">"/eg
            and $2 == $self->TicketObj->id
            )
        {
            $self->SetHeader( "Message-ID" => $msgid );
        } else {
            $self->SetHeader(
                'Message-ID' => RT::Interface::Email::GenMessageId(
                    Ticket      => $self->TicketObj,
                    Scrip       => $self->ScripObj,
                    ScripAction => $self->ScripActionObj
                ),
            );
        }
    }

    $self->SetHeader( 'Precedence', "bulk" )
        unless ( $self->TemplateObj->MIMEObj->head->get("Precedence") );

    $self->SetHeader( 'X-RT-Loop-Prevention', RT->Config->Get('rtname') );
    $self->SetHeader( 'X-RT-Allow-Self-Loops', 1) if RT->Config->Get('LinkSelfLoops');
    $self->SetHeader( 'RT-Ticket',
        RT->Config->Get('rtname') . " #" . $self->TicketObj->id() );
    $self->SetHeader( 'Managed-by',
        "RT $RT::VERSION (http://www.bestpractical.com/rt/)" );

# XXX, TODO: use /ShowUser/ShowUserEntry(or something like that) when it would be
#            refactored into user's method.
    if ( my $email = $self->TransactionObj->CreatorObj->EmailAddress ) {
        $self->SetHeader( 'RT-Originator', $email );
    }

}

1;
