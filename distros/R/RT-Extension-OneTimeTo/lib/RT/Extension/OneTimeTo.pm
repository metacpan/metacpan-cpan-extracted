package RT::Extension::OneTimeTo;
use strict;
use warnings;
no warnings 'redefine';

our $VERSION = '1.05';

{
    # Includes RT-Send-To in the list of headers used to grab
    # one-time recipient suggestions
    require RT::Attachment;
    push @RT::Attachment::ADDRESS_HEADERS, "RT-Send-To";
}

use RT::Interface::Web;
my $orig_process = HTML::Mason::Commands->can('_ProcessUpdateMessageRecipients');
*HTML::Mason::Commands::_ProcessUpdateMessageRecipients = sub {
    $orig_process->(@_);

    my %args = (
        ARGSRef           => undef,
        TicketObj         => undef,
        MessageArgs       => undef,
        @_,
    );

    my $to = $args{ARGSRef}->{'UpdateTo'};

    my $message_args = $args{MessageArgs};

    $message_args->{ToMessageTo} = $to;

    # transform UpdateTo into ToMessageTo; mostly copied from the original method
    unless ( $args{'ARGSRef'}->{'UpdateIgnoreAddressCheckboxes'} ) {
        foreach my $key ( keys %{ $args{ARGSRef} } ) {
            next unless $key =~ /^UpdateTo-(.*)$/;

            my $var   = 'ToMessageTo';
            my $value = $1;
            if ( $message_args->{$var} ) {
                $message_args->{$var} .= ", $value";
            } else {
                $message_args->{$var} = $value;
            }
        }
    }
};

use RT::Ticket;
my $orig_note = RT::Ticket->can('_RecordNote');
*RT::Ticket::_RecordNote = sub {
    my $self = shift;
    my %args = @_;

    # We can't do anything if we don't have any message, so let the original
    # method handle it rather than creating an empty mime body
    unless ( $args{'MIMEObj'} || $args{'Content'} ) {
        return $orig_note->($self, %args);
    }

    # lazily initialize the MIMEObj if needed; copied from original method
    unless ( $args{'MIMEObj'} ) {
        my $data = ref $args{'Content'}? $args{'Content'} : [ $args{'Content'} ];
        $args{'MIMEObj'} = MIME::Entity->build(
            Type    => "text/plain",
            Charset => "UTF-8",
            Data    => [ map {Encode::encode("UTF-8", $_)} @{$data} ],
        );
    }

    # if there's a one-time To, add it to the MIMEObj
    my $type = 'To';
    if ( defined $args{ $type . 'MessageTo' } ) {

        my $addresses = join ', ', (
            map { RT::User->CanonicalizeEmailAddress( $_->address ) }
                Email::Address->parse( $args{ $type . 'MessageTo' } ) );
        $args{'MIMEObj'}->head->add( 'RT-Send-' . $type, Encode::encode_utf8( $addresses ) );
    }

    # The original method will always get a MIMEObj now
    return $orig_note->($self, %args);
};

use RT::Action::Notify;
my $orig_recipients = RT::Action::Notify->can('SetRecipients');
*RT::Action::Notify::SetRecipients = sub {
    my $self = shift;
    $orig_recipients->($self, @_);

    # copy RT-Send-To addresses to NoSquelched To addresses
    if ( $self->Argument =~ /\bOtherRecipients\b/ ) {
        if ( my $attachment = $self->TransactionObj->Attachments->First ) {
            push @{ $self->{'NoSquelch'}{'To'} }, map { $_->address } Email::Address->parse(
                $attachment->GetHeader('RT-Send-To')
            );
        }
    }
};

=head1 NAME

RT::Extension::OneTimeTo - Adds a One-time To: box next to the One-time Cc/Bcc boxes

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

This step may need root permissions.

=item Patch RT(For RT 4.4)

For RT 4.4.2+:

    patch -p1 -d /opt/rt4 < patches/Support-UpdateTo-in-preview-scrips.patch

For RT 4.4.0 and 4.4.1:

    patch -p1 -d /opt/rt4 -F3 < patches/Support-UpdateTo-in-preview-scrips.patch

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::OneTimeTo');

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-OneTimeTo@rt.cpan.org|mailto:bug-RT-Extension-OneTimeTo@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-OneTimeTo>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2010-2018 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
