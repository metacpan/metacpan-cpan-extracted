use strict;
use warnings;
package RT::Extension::AjaxPreviewScrips;

our $VERSION = '0.10';
RT->AddStyleSheets("ajaxpreviewscrips.css");
RT->AddJavaScript("checkboxes.js");
RT->Config->AddOption(
    Name            => "SquelchedRecipients",
    Section         => 'Ticket display',
    Overridable     => 1,
    SortOrder       => 8.5,
    Widget          => '/Widgets/Form/Boolean',
    WidgetArguments => {
        Description => "Default to squelching all outgoing email notifications (from web interface) on ticket update", #loc
    },
);

=head1 NAME

RT-Extension-AjaxPreviewScrips - Ajax preview scrips

=head1 DESCRIPTION

This extension AJAX-ifies the "Preview Scrips" part on ticket update page.

=head1 RT VERSION

Works with RT 4.2

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

    Plugin('RT::Extension::AjaxPreviewScrips');

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=cut

no warnings 'redefine';

package HTML::Mason::Commands;
use vars qw/%session/;
sub CreateTicket {
    my %ARGS = (@_);

    my (@Actions);

    my $Ticket = delete $ARGS{TicketObj} || RT::Ticket->new( $session{'CurrentUser'} );

    my $Queue = RT::Queue->new( $session{'CurrentUser'} );
    unless ( $Queue->Load( $ARGS{'Queue'} ) ) {
        Abort('Queue not found');
    }

    unless ( $Queue->CurrentUserHasRight('CreateTicket') ) {
        Abort('You have no permission to create tickets in that queue.');
    }

    my $due;
    if ( defined $ARGS{'Due'} and $ARGS{'Due'} =~ /\S/ ) {
        $due = RT::Date->new( $session{'CurrentUser'} );
        $due->Set( Format => 'unknown', Value => $ARGS{'Due'} );
    }
    my $starts;
    if ( defined $ARGS{'Starts'} and $ARGS{'Starts'} =~ /\S/ ) {
        $starts = RT::Date->new( $session{'CurrentUser'} );
        $starts->Set( Format => 'unknown', Value => $ARGS{'Starts'} );
    }

    my $sigless = RT::Interface::Web::StripContent(
        Content        => $ARGS{Content},
        ContentType    => $ARGS{ContentType},
        StripSignature => 1,
        CurrentUser    => $session{'CurrentUser'},
    );

    my $MIMEObj = MakeMIMEEntity(
        Subject => $ARGS{'Subject'},
        From    => $ARGS{'From'},
        Cc      => $ARGS{'Cc'},
        Body    => $sigless,
        Type    => $ARGS{'ContentType'},
        Interface => RT::Interface::Web::MobileClient() ? 'Mobile' : 'Web',
    );

    my @attachments;
    if ( my $tmp = $session{'Attachments'}{ $ARGS{'Token'} || '' } ) {
        push @attachments, grep $_, map $tmp->{$_}, sort keys %$tmp;

        delete $session{'Attachments'}{ $ARGS{'Token'} || '' }
            unless $ARGS{'KeepAttachments'};
        $session{'Attachments'} = $session{'Attachments'}
            if @attachments;
    }
    if ( $ARGS{'Attachments'} ) {
        push @attachments, grep $_, map $ARGS{Attachments}->{$_}, sort keys %{ $ARGS{'Attachments'} };
    }
    if ( @attachments ) {
        $MIMEObj->make_multipart;
        $MIMEObj->add_part( $_ ) foreach @attachments;
    }

    for my $argument (qw(Encrypt Sign)) {
        if ( defined $ARGS{ $argument } ) {
            $MIMEObj->head->replace( "X-RT-$argument" => $ARGS{$argument} ? 1 : 0 );
        }
    }

    my %create_args = (
        Type => $ARGS{'Type'} || 'ticket',
        Queue => $ARGS{'Queue'},
        Owner => $ARGS{'Owner'},

        # note: name change
        Requestor       => $ARGS{'Requestors'},
        Cc              => $ARGS{'Cc'},
        AdminCc         => $ARGS{'AdminCc'},
        InitialPriority => $ARGS{'InitialPriority'},
        FinalPriority   => $ARGS{'FinalPriority'},
        TimeLeft        => $ARGS{'TimeLeft'},
        TimeEstimated   => $ARGS{'TimeEstimated'},
        TimeWorked      => $ARGS{'TimeWorked'},
        Subject         => $ARGS{'Subject'},
        Status          => $ARGS{'Status'},
        Due             => $due ? $due->ISO : undef,
        Starts          => $starts ? $starts->ISO : undef,
        MIMEObj         => $MIMEObj,
        TransSquelchMailTo => $ARGS{'TransSquelchMailTo'},
    );

    my @txn_squelch;
    foreach my $type (qw(Requestor Cc AdminCc)) {
        push @txn_squelch, map $_->address, Email::Address->parse( $create_args{$type} )
            if grep $_ eq $type || $_ eq ( $type . 's' ), @{ $ARGS{'SkipNotification'} || [] };
    }
    push @{$create_args{TransSquelchMailTo}}, @txn_squelch;

    if ( $ARGS{'AttachTickets'} ) {
        require RT::Action::SendEmail;
        RT::Action::SendEmail->AttachTickets( RT::Action::SendEmail->AttachTickets,
            ref $ARGS{'AttachTickets'}
            ? @{ $ARGS{'AttachTickets'} }
            : ( $ARGS{'AttachTickets'} ) );
    }

    my %cfs = ProcessObjectCustomFieldUpdatesForCreate(
        ARGSRef         => \%ARGS,
        ContextObject   => $Queue,
    );

    my %links = ProcessLinksForCreate( ARGSRef => \%ARGS );

    my ( $id, $Trans, $ErrMsg ) = $Ticket->Create(%create_args, %links, %cfs);

    unless ($id) {
        Abort($ErrMsg);
    }

    push( @Actions, split( "\n", $ErrMsg ) );
    unless ( $Ticket->CurrentUserHasRight('ShowTicket') ) {
        Abort( "No permission to view newly created ticket #" . $Ticket->id . "." );
    }
    return ( $Ticket, @Actions );

}

my $_ProcessUpdateMessageRecipients = \&_ProcessUpdateMessageRecipients;
*_ProcessUpdateMessageRecipients = sub {
    $_ProcessUpdateMessageRecipients->(@_);

    my %args = (
        TicketObj         => undef,
        MessageArgs       => undef,
        @_,
    );
    $args{TicketObj}{TransSquelchMailTo} ||= $args{MessageArgs}{'SquelchMailTo'};
};

my $ProcessUpdateMessage = \&ProcessUpdateMessage;
*ProcessUpdateMessage = sub {
    my @ret = $ProcessUpdateMessage->(@_);
    return @ret if @ret;

    _ProcessUpdateMessageRecipients( MessageArgs => {}, @_ );
    return;
};


package RT::Record;
sub _NewTransaction {
    my $self = shift;
    my %args = (
        TimeTaken => undef,
        Type      => undef,
        OldValue  => undef,
        NewValue  => undef,
        OldReference  => undef,
        NewReference  => undef,
        ReferenceType => undef,
        Data      => undef,
        Field     => undef,
        MIMEObj   => undef,
        ActivateScrips => 1,
        SquelchMailTo => undef,
        @_
    );

    my $in_txn = RT->DatabaseHandle->TransactionDepth;
    RT->DatabaseHandle->BeginTransaction unless $in_txn;

    $self->LockForUpdate;

    my $old_ref = $args{'OldReference'};
    my $new_ref = $args{'NewReference'};
    my $ref_type = $args{'ReferenceType'};
    if ($old_ref or $new_ref) {
        $ref_type ||= ref($old_ref) || ref($new_ref);
        if (!$ref_type) {
            $RT::Logger->error("Reference type not specified for transaction");
            return;
        }
        $old_ref = $old_ref->Id if ref($old_ref);
        $new_ref = $new_ref->Id if ref($new_ref);
    }

    require RT::Transaction;
    my $trans = RT::Transaction->new( $self->CurrentUser );
    my ( $transaction, $msg ) = $trans->Create(
        ObjectId  => $self->Id,
        ObjectType => ref($self),
        TimeTaken => $args{'TimeTaken'},
        Type      => $args{'Type'},
        Data      => $args{'Data'},
        Field     => $args{'Field'},
        NewValue  => $args{'NewValue'},
        OldValue  => $args{'OldValue'},
        NewReference  => $new_ref,
        OldReference  => $old_ref,
        ReferenceType => $ref_type,
        MIMEObj   => $args{'MIMEObj'},
        ActivateScrips => $args{'ActivateScrips'},
        DryRun => $self->{DryRun},
        SquelchMailTo => $args{'SquelchMailTo'} || $self->{TransSquelchMailTo},
    );

    # Rationalize the object since we may have done things to it during the caching.
    $self->Load($self->Id);

    $RT::Logger->warning($msg) unless $transaction;

    $self->_SetLastUpdated;

    if ( defined $args{'TimeTaken'} and $self->can('_UpdateTimeTaken')) {
        $self->_UpdateTimeTaken( $args{'TimeTaken'}, Transaction => $trans );
    }
    if ( RT->Config->Get('UseTransactionBatch') and $transaction ) {
        push @{$self->{_TransactionBatch}}, $trans;
    }

    RT->DatabaseHandle->Commit unless $in_txn;

    return ( $transaction, $msg, $trans );
}

package RT::Ticket;
sub DryRun {
    my $self = shift;

    my ($subref) = @_;

    my @transactions;

    $RT::Handle->BeginTransaction();
    {
        # Getting nested "commit"s inside this rollback is fine
        local %DBIx::SearchBuilder::Handle::TRANSROLLBACK;
        local $self->{DryRun} = \@transactions;
        eval { $subref->() };
        warn "Error is $@" if $@;
        $self->ApplyTransactionBatch;
    }

    @transactions = grep {$_} @transactions;

    $RT::Handle->Rollback();

    return wantarray ? @transactions : $transactions[0];
}

sub _ApplyTransactionBatch {
    my $self = shift;

    return if $self->RanTransactionBatch;
    $self->RanTransactionBatch(1);

    my $still_exists = RT::Ticket->new( RT->SystemUser );
    $still_exists->Load( $self->Id );
    if (not $still_exists->Id) {
        # The ticket has been removed from the database, but we still
        # have pending TransactionBatch txns for it.  Unfortunately,
        # because it isn't in the DB anymore, attempting to run scrips
        # on it may produce unpredictable results; simply drop the
        # batched transactions.
        $RT::Logger->warning("TransactionBatch was fired on a ticket that no longer exists; unable to run scrips!  Call ->ApplyTransactionBatch before shredding the ticket, for consistent results.");
        return;
    }

    my $batch = $self->TransactionBatch;

    my %seen;
    my $types = join ',', grep !$seen{$_}++, grep defined, map $_->__Value('Type'), grep defined, @{$batch};

    require RT::Scrips;
    my $scrips = RT::Scrips->new(RT->SystemUser);
    $scrips->Prepare(
        Stage          => 'TransactionBatch',
        TicketObj      => $self,
        TransactionObj => $batch->[0],
        Type           => $types,
    );

    # Entry point of the rule system
    my $rules = RT::Ruleset->FindAllRules(
        Stage          => 'TransactionBatch',
        TicketObj      => $self,
        TransactionObj => $batch->[0],
        Type           => $types,
    );

    if ($self->{DryRun}) {
        my $fake_txn = RT::Transaction->new( $self->CurrentUser );
        $fake_txn->{scrips} = $scrips;
        $fake_txn->{rules} = $rules;
        push @{$self->{DryRun}}, $fake_txn;
    } else {
        $scrips->Commit;
        RT::Ruleset->CommitRules($rules);
    }
}


package RT::Transaction;

my $Create = \&Create;
*Create = sub {
    my $self = shift;
    my %args = (@_);
    $args{CommitScrips} = 0 if $args{DryRun};
    my @retval = $Create->($self, %args);
    push @{$args{DryRun}}, $self if $args{DryRun} and $retval[0];

    return wantarray ? @retval : $retval[0];
};


=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-AjaxPreviewScrips@rt.cpan.org">bug-RT-Extension-AjaxPreviewScrips@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-AjaxPreviewScrips">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-AjaxPreviewScrips@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-AjaxPreviewScrips

=head1 COPYRIGHT

This extension is Copyright (C) 2014-2015 Best Practical Solutions, LLC.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
