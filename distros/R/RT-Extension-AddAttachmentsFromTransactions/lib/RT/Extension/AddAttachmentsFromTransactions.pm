package RT::Extension::AddAttachmentsFromTransactions;

use 5.008003;
use strict;
use warnings;

our $VERSION = '2.10';

{
    require RT::Ticket;
    my $orig = RT::Ticket->can('_RecordNote');
    no warnings 'redefine';
    *RT::Ticket::_RecordNote = sub {
        my $self = shift;
        my %args = @_;

        # We can't do anything if we don't have an MIMEObj
        # so let the original method handle it
        return $orig->($self, %args) unless $args{'MIMEObj'};

        # move the Attachment id's from session to the X-RT-Attach header
        for my $id ( @{ $HTML::Mason::Commands::session{'AttachExisting'} } ) {
            $args{'MIMEObj'}->head->add( 'X-RT-Attach' => $id );
        }

        # cleanup session
        delete $HTML::Mason::Commands::session{'AttachExisting'};

        return $orig->($self, %args);
    };
}

{
    require RT::Action::SendEmail;
    my $orig = RT::Action::SendEmail->can('AddAttachments');
    no warnings 'redefine';
    *RT::Action::SendEmail::AddAttachments = sub {
        my $self = shift;

        $orig->($self, @_);

        $self->AddAttachmentsFromHeaders();
    };
}

{
    package RT::Action::SendEmail;

    sub AddAttachmentsFromHeaders {
        my $self  = shift;
        my $orig  = $self->TransactionObj->Attachments->First;
        my $email = $self->TemplateObj->MIMEObj;

        use List::MoreUtils qw(uniq);

        # Add the X-RT-Attach headers from the transaction to the email
        if ($orig and $orig->GetHeader('X-RT-Attach')) {
            for my $id ($orig->ContentAsMIME(Children => 0)->head->get_all('X-RT-Attach')) {
                $email->head->add('X-RT-Attach' => $id);
            }
        }

        # Take all X-RT-Attach headers and add the attachments to the outgoing mail
        for my $id (uniq $email->head->get_all('X-RT-Attach')) {
            $id =~ s/(?:^\s*|\s*$)//g;

            my $attach = RT::Attachment->new( $self->TransactionObj->CreatorObj );
            $attach->Load($id);
            next unless $attach->Id
                and $attach->TransactionObj->CurrentUserCanSee;

            $email->make_multipart( 'mixed', Force => 1 )
                unless $email->effective_type eq 'multipart/mixed';

            $self->AddAttachment($attach, $email);
        }
    }
}

{
    package RT::Attachment;

    unless ( RT::Attachment->can('FriendlyContentLength') ) {
        *FriendlyContentLength = sub {
            my $self = shift;
            my $size = $self->ContentLength;
            return '' unless $size;

            my $kb = int($size/102.4) / 10;
            my $units = RT->Config->Get('AttachmentUnits');

            if (!defined($units)) {
                if ($size > 1024) {
                    $size = $kb . "k";
                } else {
                    $size = $size . "b";
                }
            } elsif ($units eq 'k') {
                $size = $kb . "k";
            } else {
                $size = $size . "b";
            }

            return $size;
        }
    }
}

=encoding utf8

=head1 NAME

RT::Extension::AddAttachmentsFromTransactions - Add Attachments From Transactions

=head1 DESCRIPTION

With this plugin you can attach attachments from previous transactions to a
reply or comment.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::AddAttachmentsFromTransactions');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::AddAttachmentsFromTransactions));

or add C<RT::Extension::AddAttachmentsFromTransactions> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj/*

=item Restart your webserver

=back

=head1 AUTHOR

Christian Loos <cloos@netsandbox.de>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (C) 2012-2015, Christian Loos.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=head1 SEE ALSO

=over

=item L<http://bestpractical.com/rt/>

=item L<http://www.gossamer-threads.com/lists/rt/users/107976>

=item L<https://github.com/bestpractical/rt/tree/4.4/attach-from-transactions>

=back

=head1 THANKS

Thanks to BÁLINT Bekény for contributing the code from his implementation.

Also Thanks to Best Practical Solutions who are working on this feature for
RT 4.4 on the '4.4/attach-from-transactions' branch where I've borrowed some
code for this extension.

=cut

1;
