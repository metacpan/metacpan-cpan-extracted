package RT::Interface::Email::RequiredHeaders;

our $VERSION = '1.2';

=head1 NAME

    RT::Interface::Email::RequiredHeaders - only accept new tickets via email with a certain header

=head1 SYNOPSIS

    Used to enforce ticket-creation from a web-interface.
    Doesn't accept new emails to the support queue without a special header.

=head1 INSTALL

    # etc/RT_SiteConfig.pm
    # Note: Must come before Filter::TakeAction in MailPlugins (if present)

    Set(@Plugins,(qw/
        RT::Interface::Email::RequiredHeaders
    /));
    Set(@MailPlugins, (qw/
        Auth::MailFrom
        RequiredHeaders
    /));
    Set(%Plugin_RequiredHeaders, (
        "required"  => [qw/X-RT-RequiredHeader/], # required is always required
        # "queues"  => [qw/General/],             # defaults to all queues
        # # change default rejection message:
        # "message" => "Error: You can only submit issues via the web.",
   ));


=head1 AUTHOR

    Alister West - http://alisterwest.com/

=head1 LICENCE AND COPYRIGHT

    Copyright 2013, Alister West

    This module is free software; you can redistribute it and/or
    modify it under the same terms as Perl. See http://dev.perl.org/licenses/.

=head1 CHANGES

=over

=item  1.2 - 2013-06-03 - CPAN-ified

=item  1.1 - 2013-06-03 - GitHub-ified

=item  1.0 - 2013-05-30 - Initial working plugin

=back

=cut;

use 5.008;
use warnings;
use strict;

use RT::Interface::Email qw(ParseCcAddressesFromHead);

=head1 GetCurrentUser - RT MailPlugin Callback

    Returns: ($CurrentUser, $auth_level) - not-triggered passthough inputs.
    Returns: ($CurrentUser, -1 )         - halt further processing and send rejection notice.

    See RT::Interface::Email::GetAuthenticationLevel for more on $auth_level.

=cut

sub GetCurrentUser {
    my %args = (
        Message       => undef,
        RawMessageRef => undef,
        CurrentUser   => undef,
        AuthLevel     => undef,
        Action        => undef,
        Ticket        => undef,
        Queue         => undef,
        @_
    );

    # Default return values - if not triggering this plugin.
    my @ret = ( $args{CurrentUser}, $args{AuthLevel} );

    my %config = RT->Config->Get('Plugin_RequiredHeaders');
    my $required = $config{required};
    my $queues   = defined $config{queues} ? $config{queues} : 1;

    $RT::Logger->debug("X-RT-RequestHeaders debugging ...");

    # If required was not supplied - skip this plugin.
    if (!$required || !ref $required || !@$required) {
        $RT::Logger->debug( " .. no 'required' header was set - SKIP");
        return @ret;
    }

    # we only ever filter 'new' tickets.
    if ($args{'Ticket'}->id) {
        $RT::Logger->debug( " .. ticket correspondence - SKIP");
        return @ret;
    }

    # queues are empty or off
    if ($queues == 0 || (ref $queues && !@$queues)) {
        $RT::Logger->debug( " .. config.queues is off - SKIP");
        return @ret;
    }

    # queues == 1 - apply all
    # queues == ['general'] - only to general
    if (ref $queues) {
        my $dest = lc $args{Queue}->Name;

        # skip if destination queue is not mentionend in the config
        if ( grep {!/$dest/i} @$queues ) {
            $RT::Logger->debug( " .. queue[$dest] not found in config.queues - SKIP" );
            return @ret;
        }
    }


    # check message::headers to make sure all required headers are present
    my $head = $args{'Message'}->head;
    foreach my $header (@$required) {

        # Missing a header
        if (! $head->get($header) ) {

            # notify sender
            my $ErrorsTo = RT::Interface::Email::ParseErrorsToAddressFromHead( $head );
            RT::Interface::Email::MailError(
                To          => $ErrorsTo,
                Subject     => "Permission denied : " . $head->get('Subject'),
                Explanation => ($config{message} || "Error: You can only submit issues via the web."),
                MIMEObj     => $args{'Message'}
            );

            # halt further email processing to block creation of a ticket.
            $RT::Logger->info("RequestHeaders: [error] email from $ErrorsTo with header missing ($header) - HALT");
            return ( $args{CurrentUser}, -1 );
        }
    }

    $RT::Logger->info("RequestHeaders: OK - all required headers present");
    return @ret;
}


1;
