sub CheckForLoops {
    my $head = shift;

    # If this instance of RT sent it our, we don't want to take it in
    my $RTLoop = $head->get("X-RT-Loop-Prevention") || "";
    chomp ($RTLoop); # remove that newline
    if ( $RTLoop eq RT->Config->Get('rtname') ) {
        if ( $head->get('X-RT-Allow-Self-Loops') and RT->Config->Get('LinkSelfLoops') ) {
            return -1;
        } else {
            return 1;
        }
    }

    # TODO: We might not trap the case where RT instance A sends a mail
    # to RT instance B which sends a mail to ...
    return 0;
}

sub Gateway {
    my $argsref = shift;
    my %args    = (
        action  => 'correspond',
        queue   => '1',
        ticket  => undef,
        message => undef,
        %$argsref
    );

    my $SystemTicket;
    my $Right;

    # Validate the action
    my ( $status, @actions ) = IsCorrectAction( $args{'action'} );
    unless ($status) {
        return (
            -75,
            "Invalid 'action' parameter "
                . $actions[0]
                . " for queue "
                . $args{'queue'},
            undef
        );
    }

    my $parser = RT::EmailParser->new();
    $parser->SmartParseMIMEEntityFromScalar(
        Message => $args{'message'},
        Decode => 0,
        Exact => 1,
    );

    my $Message = $parser->Entity();
    unless ($Message) {
        MailError(
            Subject     => "RT Bounce: Unparseable message",
            Explanation => "RT couldn't process the message below",
            Attach      => $args{'message'}
        );

        return ( 0,
            "Failed to parse this message. Something is likely badly wrong with the message"
        );
    }

    my @mail_plugins = grep $_, RT->Config->Get('MailPlugins');
    push @mail_plugins, "Auth::MailFrom" unless @mail_plugins;
    @mail_plugins = _LoadPlugins( @mail_plugins );

    my %skip_plugin;
    foreach my $class( grep !ref, @mail_plugins ) {
        # check if we should apply filter before decoding
        my $check_cb = do {
            no strict 'refs';
            *{ $class . "::ApplyBeforeDecode" }{CODE};
        };
        next unless defined $check_cb;
        next unless $check_cb->(
            Message       => $Message,
            RawMessageRef => \$args{'message'},
        );

        $skip_plugin{ $class }++;

        my $Code = do {
            no strict 'refs';
            *{ $class . "::GetCurrentUser" }{CODE};
        };
        my ($status, $msg) = $Code->(
            Message       => $Message,
            RawMessageRef => \$args{'message'},
        );
        next if $status > 0;

        if ( $status == -2 ) {
            return (1, $msg, undef);
        } elsif ( $status == -1 ) {
            return (0, $msg, undef);
        }
    }
    @mail_plugins = grep !$skip_plugin{"$_"}, @mail_plugins;
    $parser->_DecodeBodies;
    $parser->_PostProcessNewEntity;

    my $head = $Message->head;
    my $ErrorsTo = ParseErrorsToAddressFromHead( $head );

    my $MessageId = $head->get('Message-ID')
        || "<no-message-id-". time . rand(2000) .'@'. RT->Config->Get('Organization') .'>';
    chomp $MessageId;

    #Pull apart the subject line
    my $Subject = $head->get('Subject') || '';
    chomp $Subject;
    
    # {{{ Lets check for mail loops of various sorts.
    my ($IsALoop, $result);
    ( undef, $ErrorsTo, $result, $IsALoop ) =
      _HandleMachineGeneratedMail(
        Message  => $Message,
        ErrorsTo => $ErrorsTo,
        Subject  => $Subject,
        MessageId => $MessageId
    );

    # Do not pass loop messages to MailPlugins, to make sure the loop
    # is broken, unless $RT::StoreLoops is set.
    if ($IsALoop > 0) {
        return ( 0, $result, undef );
    }

    # }}}

    $args{'ticket'} ||= ParseTicketId( $Subject );

    $SystemTicket = RT::Ticket->new( $RT::SystemUser );
    $SystemTicket->Load( $args{'ticket'} ) if ( $args{'ticket'} ) ;
    if ( $SystemTicket->id ) {
        $Right = 'ReplyToTicket';
    } else {
        $Right = 'CreateTicket';
    }

    #Set up a queue object
    my $SystemQueueObj = RT::Queue->new( $RT::SystemUser );
    $SystemQueueObj->Load( $args{'queue'} );

    # We can safely have no queue of we have a known-good ticket
    unless ( $SystemTicket->id || $SystemQueueObj->id ) {
        return ( -75, "RT couldn't find the queue: " . $args{'queue'}, undef );
    }

    my ($AuthStat, $CurrentUser, $error) = GetAuthenticationLevel(
        MailPlugins   => \@mail_plugins,
        Actions       => \@actions,
        Message       => $Message,
        RawMessageRef => \$args{message},
        SystemTicket  => $SystemTicket,
        SystemQueue   => $SystemQueueObj,
    );

    # {{{ If authentication fails and no new user was created, get out.
    if ( !$CurrentUser || !$CurrentUser->id || $AuthStat == -1 ) {

        # If the plugins refused to create one, they lose.
        unless ( $AuthStat == -1 ) {
            _NoAuthorizedUserFound(
                Right     => $Right,
                Message   => $Message,
                Requestor => $ErrorsTo,
                Queue     => $args{'queue'}
            );

        }
        return ( 0, "Could not load a valid user", undef );
    }

    # If we got a user, but they don't have the right to say things
    if ( $AuthStat == 0 ) {
        MailError(
            To          => $ErrorsTo,
            Subject     => "Permission Denied",
            Explanation =>
                "You do not have permission to communicate with RT",
            MIMEObj => $Message
        );
        return (
            0,
            "$ErrorsTo tried to submit a message to "
                . $args{'Queue'}
                . " without permission.",
            undef
        );
    }

    # if plugin's updated SystemTicket then update arguments
    $args{'ticket'} = $SystemTicket->Id if $SystemTicket && $SystemTicket->Id;

    my $Ticket = RT::Ticket->new($CurrentUser);

    if ( !$args{'ticket'} && grep /^(comment|correspond)$/, @actions )
    {
        # This might be a creation we already saw; check if we've seen
        # the message-id in this queue recently.

        if (my $other = RecentMessage( $MessageId, queue => $SystemQueueObj->Id )) {
            warn "Found dup, ticket is @{[$other->Id]}";
            return ( 1, "Duplicate self-loop delivery (#@{[$other->Id]}))", $other );
        }

        my @ret = CreateTicket(
            CurrentUser => $CurrentUser,
            Message     => $Message,
            QueueObj    => $SystemQueueObj,
            ErrorsTo    => $ErrorsTo,
        );
        return @ret unless $ret[0];
        # strip comments&corresponds from the actions we don't need
        # to record them if we've created the ticket just now
        @actions = grep !/^(comment|correspond)$/, @actions;
        ($args{'ticket'}, undef, $Ticket) = @ret;

    } elsif ( $args{'ticket'} ) {

        $Ticket->Load( $args{'ticket'} );
        unless ( $Ticket->Id ) {
            my $error = "Could not find a ticket with id " . $args{'ticket'};
            MailError(
                To          => $ErrorsTo,
                Subject     => "Message not recorded: $Subject",
                Explanation => $error,
                MIMEObj     => $Message
            );

            return ( 0, $error );
        }
        $args{'ticket'} = $Ticket->id;
    } else {
        return ( 1, "Success", $Ticket );
    }

    # }}}

    my $unsafe_actions = RT->Config->Get('UnsafeEmailCommands');
    my $return = $Ticket->Id;
    foreach my $action (@actions) {

        #   If the action is comment, add a comment.
        if ( $action =~ /^(?:comment|correspond)$/i ) {

            # Check if this is an internal self-loop
            if (    $Ticket->QueueObj->Id != $SystemQueueObj->Id
                and $IsALoop < 0 )
            {
                my @ret = LinkSelfLoops(
                    Ticket      => $Ticket,
                    QueueObj    => $SystemQueueObj,
                    Message     => $Message,
                    ErrorsTo    => $ErrorsTo,
                    CurrentUser => $CurrentUser,
                );
                if (not $ret[0]) {
                    # If it failed, return the error
                    return @ret;
                } elsif (ref $ret[0]) {
                    # Returns the object to comment on
                    $Ticket = $ret[0];
                } else {
                    # Or a simple true value to drop on the floor
                    $return = $ret[0];
                    next;
                }
            }

            my $method = ucfirst lc $action;
            my ( $status, $msg ) = $Ticket->$method( MIMEObj => $Message );
            unless ($status) {

                #Warn the sender that we couldn't actually submit the comment.
                MailError(
                    To          => $ErrorsTo,
                    Subject     => "Message not recorded: $Subject",
                    Explanation => $msg,
                    MIMEObj     => $Message
                );
                return ( 0, "Message not recorded: $msg", $Ticket );
            }
        } elsif ($unsafe_actions) {
            my ( $status, $msg ) = _RunUnsafeAction(
                Action      => $action,
                ErrorsTo    => $ErrorsTo,
                Message     => $Message,
                Ticket      => $Ticket,
                CurrentUser => $CurrentUser,
            );
            return ($status, $msg, $Ticket) unless $status == 1;
        }
    }
    $Ticket->Load($return);
    return ( 1, "Success", $Ticket );
}

sub RecentMessage {
    my ($messageid, $type, $id) = @_;
    my $messages = RT::Attachments->new($RT::SystemUser);
    $messages->Limit( FIELD => 'messageid', VALUE => $messageid );
    my $txns = $messages->Join(
        ALIAS1 => 'main',
        FIELD1 => 'transactionid',
        TABLE2 => 'Transactions',
        FIELD2 => 'id',
    );
    $messages->Limit(
        ALIAS => $txns,
        FIELD => 'objecttype',
        VALUE => 'RT::Ticket',
    );
    if ( $type eq "queue" ) {
        my $tickets = $messages->Join(
            ALIAS1 => $txns,
            FIELD1 => 'objectid',
            TABLE2 => 'Tickets',
            FIELD2 => 'id',
        );
        $messages->Limit(
            ALIAS => $tickets,
            FIELD => 'queue',
            VALUE => $id,
        );
    } else {
        $messages->Limit(
            ALIAS => $txns,
            FIELD => 'objectid',
            VALUE => $id,
        );
    }

    my $first = $messages->First;
    return $first ? $first->TransactionObj->Object : undef
}


=head2 LinkSelfLoops

=cut

sub LinkSelfLoops {
    my %args = (
        Ticket      => undef,
        QueueObj    => undef,
        Message     => undef,
        ErrorsTo    => undef,
        CurrentUser => undef,
        @_
    );

    # Determine original message-id by looking at our headers, looking
    # up that txn, and chasing the txn's attachment's headers, etc..
    my $txn = RT::Transaction->new( $RT::SystemUser );
    $txn->Load( $args{Message}->head->get('X-RT-Transaction-Id') );
    my $origid;
    while ($txn->Id) {
        last unless my $attach = $txn->Attachments->First;
        $origid = $attach->MessageId;
        last unless my $txnid = $attach->GetHeader("X-RT-Transaction-Id");
        $txn = RT::Transaction->new( $RT::SystemUser );
        $txn->Load($txnid);
    }

    die "No original message-id" unless $origid;
    chomp $origid;

    my $orig = $txn->Attachments->First->ContentAsMIME;
    $args{Message}->head->set($_, $orig->head->get($_))
        for qw/Subject Content-Type Content-Transfer-Encoding Content-Length MIME-Version/;
    $args{Message}->bodyhandle( $orig->bodyhandle );
    $args{Message}->parts( [$orig->parts] );

    # Look for linked tickets in the given queue
    my @links = map {$_->Content}
        $args{Ticket}->Attributes->Named('InternalLinks-'.$args{QueueObj}->Id);

    if (not @links) {
        # No existing link between ticket and that queue.  Look for
        # the message-id in the queue
        my $other = RecentMessage($origid, queue => $args{QueueObj}->Id);
        unless ($other) {
            # If we didn't find it, create it
            my @ret = CreateTicket(
                CurrentUser => $args{CurrentUser},
                Message     => $args{Message},
                QueueObj    => $args{QueueObj},
                ErrorsTo    => $args{ErrorsTo},
            );
            return @ret unless $ret[0];
            (undef, undef, $other) = @ret;
        }
        # Regardless, link them now.
        $args{Ticket}->AddAttribute(
            Name    => "InternalLinks-" . $other->__Value('Queue'),
            Content => $other->Id,
        );
        $other->AddAttribute(
            Name    => "InternalLinks-" . $args{Ticket}->__Value('Queue'),
            Content => $args{Ticket}->Id,
        );
        # ..and drop the message on the floor.
        return $other->Id;
    }

    if (@links > 1) {
        die "More than one link to queue @{[$args{QueueObj}->Name]}: @links";
    }

    # We found a specific linked ticket in the given queue.  See if it
    # has seen the original message-id yet -- if so, drop on the floor.
    my $other = RT::Ticket->new( $args{CurrentUser} );
    $other->Load(@links);
    return $args{Ticket}->Id if RecentMessage($origid, ticket => $other->id);

    # Otherwise, the comment/correspond goes on the linked ticket
    return $other;
}

sub CreateTicket {
    my %args = (
        CurrentUser => undef,
        Message     => undef,
        QueueObj    => undef,
        ErrorsTo    => undef,
        @_,
    );
    my @Cc;
    my @Requestors = ( $args{CurrentUser}->id );

    if (RT->Config->Get('ParseNewMessageForTicketCcs')) {
        @Cc = ParseCcAddressesFromHead(
            Head        => $args{Message}->head,
            CurrentUser => $args{CurrentUser},
            QueueObj    => $args{QueueObj},
        );
    }

    my $Subject = $args{Message}->head->get('Subject') || '';
    chomp $Subject;

    my $Ticket = RT::Ticket->new($args{CurrentUser});
    my ( $id, $Transaction, $ErrStr ) = $Ticket->Create(
        Queue     => $args{QueueObj}->Id,
        Subject   => $Subject,
        Requestor => \@Requestors,
        Cc        => \@Cc,
        MIMEObj   => $args{Message},
    );
    if ( $id == 0 ) {
        MailError(
            To          => $args{ErrorsTo},
            Subject     => "Ticket creation failed: $Subject",
            Explanation => $ErrStr,
            MIMEObj     => $args{Message}
        );
        return ( 0, "Ticket creation failed: $ErrStr", $Ticket );
    }
    return ($id, "Ticket created", $Ticket);
}

sub _HandleMachineGeneratedMail {
    my %args = ( Message => undef, ErrorsTo => undef, Subject => undef, MessageId => undef, @_ );
    my $head = $args{'Message'}->head;
    my $ErrorsTo = $args{'ErrorsTo'};

    my $IsBounce = CheckForBounce($head);

    my $IsAutoGenerated = CheckForAutoGenerated($head);

    my $IsSuspiciousSender = CheckForSuspiciousSender($head);

    my $IsALoop = CheckForLoops($head);

    my $SquelchReplies = 0;

    my $owner_mail = RT->Config->Get('OwnerEmail');

    #If the message is autogenerated, we need to know, so we can not
    # send mail to the sender
    if ( $IsBounce || $IsSuspiciousSender || $IsAutoGenerated || ($IsALoop > 0) ) {
        $SquelchReplies = 1;
        $ErrorsTo       = $owner_mail;
    }

    # Warn someone if it's a loop, before we drop it on the ground
    if ($IsALoop > 0) {
        $RT::Logger->crit("RT Received mail (".$args{MessageId}.") from itself.");

        #Should we mail it to RTOwner?
        if ( RT->Config->Get('LoopsToRTOwner') ) {
            MailError(
                To          => $owner_mail,
                Subject     => "RT Bounce: ".$args{'Subject'},
                Explanation => "RT thinks this message may be a bounce",
                MIMEObj     => $args{Message}
            );
        }

        #Do we actually want to store it?
        return ( 0, $ErrorsTo, "Message Bounced", $IsALoop )
            unless RT->Config->Get('StoreLoops');
    }

    # Squelch replies if necessary
    # Don't let the user stuff the RT-Squelch-Replies-To header.
    if ( $head->get('RT-Squelch-Replies-To') ) {
        $head->add(
            'RT-Relocated-Squelch-Replies-To',
            $head->get('RT-Squelch-Replies-To')
        );
        $head->delete('RT-Squelch-Replies-To');
    }

    if ($SquelchReplies and $IsALoop >= 0) {

        # Squelch replies to the sender, and also leave a clue to
        # allow us to squelch ALL outbound messages. This way we
        # can punt the logic of "what to do when we get a bounce"
        # to the scrip. We might want to notify nobody. Or just
        # the RT Owner. Or maybe all Privileged watchers.
        my ( $Sender, $junk ) = ParseSenderAddressFromHead($head);
        $head->add( 'RT-Squelch-Replies-To',    $Sender );
        $head->add( 'RT-DetectedAutoGenerated', 'true' );
    }
    return ( 1, $ErrorsTo, "Handled machine detection", $IsALoop );
}

1;
