package Net::LimeLight::Purge;

use warnings;
use strict;

use DateTime::Format::ISO8601;
use Moose;
use SOAP::Lite;

use Net::LimeLight::Purge::Request;
use Net::LimeLight::Purge::StatusResponse;

=head1 NAME

Net::LimeLight::Purge - LimeLight Purge Service API

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

  use Net::LimeLight::Purge;
  use Net::LimeLight::Purge::Request;

  my $req = Net::LimeLight::Purge::Request->new(
      shortname => 'mysite',
      url => 'http://cdn.mysite.com/static/images/foo.jpg'
  );

  my $purge = Net::LimeLight::Purge->new(
      username => 'luxuser',
      password => 'luxpass'
  );
  my $ret = $purge->create_purge_request([ $req ]);
  if($ret == -1) {
      say "Something broke!";
  } else {
      say "Successful Request: $ret";
  }

=head1 METHODS

=cut

has '_date_parser' => (
    is => 'rw',
    lazy => 1,
    default => sub {
        return DateTime::Format::ISO8601->new;
    }
);

has '_header' => (
    is => 'rw',
    isa => 'SOAP::Header',
    lazy => 1,
    default => sub {
        my ($self) = @_;

        return SOAP::Header->new(
            name => 'AuthHeader',
            attr => { xmlns => 'http://www.llnw.com/Purge' },
            value => {
                Username => $self->username,
                Password => $self->password
            }
        );
    }
);

has '_soap' => (
    is => 'rw',
    isa => 'SOAP::Lite',
    lazy => 1,
    default => sub {
        my ($self) = @_;

        return SOAP::Lite->new(
            proxy => $self->proxy,
            uri => $self->uri
        );
    }
);

=head2 username

Your LUX username.

=cut

has 'username' => (
    is => 'rw',
    isa => 'Str',
    required => 1
);

=head2 password

Your LUX password.

=cut

has 'password' => (
    is => 'rw',
    isa => 'Str',
    required => 1
);

=head2 proxy

The address to send SOAP requests.  Defaults to
C<https://soap.llnw.net/PurgeFiles/PurgeService.asmx>.

=cut

has 'proxy' => (
    is => 'rw',
    isa => 'Str',
    default => sub { 'https://soap.llnw.net/PurgeFiles/PurgeService.asmx' }
);

=head2 uri

The uri to use for SOAP requests.  Defaults to C<http://www.llnw.com/Purge>.

=cut

has 'uri' => (
    is => 'rw',
    isa => 'Str',
    default => sub { 'http://www.llnw.com/Purge' }
);

=head2 create_purge_request(\@requests, \%notification_options)

Creates a purge request from  an arrayref of L<Net::LimeLight::Purge::Request>
objects.  Returns the unique number assigned to the request by LimeLight. It
seems that -1 indicates a failure of some type.  An exception is thrown if
there is some type of SOAP error.

The optional second argument allows passing notification options in the
request the keys are:

=over 4

=item I<type>

Defaults to 'none'.  Other valid values are C<none>, C<detail>, and
C<summary>.  Setting this value to something other than those values will
cause an error.

=item I<subject>

The subject of the email.

=item I<to>

The recipient of the email.

=item I<cc>

The recipient to CC the email to.

=item I<bcc>

The recipient to BCC the email to.

=back

=cut

sub create_purge_request {
    my ($self, $requests, $notification) = @_;

    # If we are given nothing, do nothing.
    if(!defined($requests) || (ref($requests) ne 'ARRAY') || (scalar(@{ $requests }) < 1)) {
        return undef;
    }

    # Set it to an empty hashref to save us some code.
    unless(defined($notification)) {
        $notification = {};
    }

    my $soap = $self->_soap;
    $soap->on_action(sub { $self->uri.'/CreatePurgeRequest' });
    my $header = $
    self->_header;

    # Setup the requests for sending...
    my @reqs;
    foreach my $req (@{ $requests }) {
        push(@reqs, SOAP::Data->name('PurgeRequestEntry' => {
            Shortname => SOAP::Data->value($req->shortname),
            Url => $req->url,
            Regex => $req->regex ? 'true' : 'false'
        }));
    }

    my $res = $soap->call(
        SOAP::Data->new(
            name => 'CreatePurgeRequest',
            attr => { xmlns => $self->uri },
        ) => SOAP::Data->name(
            request => {
                EmailType => $notification->{'type'} || 'none',
                EmailSubject => $notification->{'subject'},
                EmailTo => $notification->{'to'},
                EmailCc => $notification->{'cc'},
                EmailBcc => $notification->{'bcc'},
                Entries => \@reqs
            }
        ),
        $header
    );
    if($res->fault) {
        die join(', ',
            $res->faultcode,
            $res->faultstring,
            $res->faultdetail
        );
    }

    return $res->valueof('//CreatePurgeRequestResponse/CreatePurgeRequestResult');
}


=head2 get_all_purge_statuses([$detail])

Get the status of B<ALL> purge requests.  If a true value is passed as the
only parameter then detail will be requested rather than just counts.  Returns
a L<StatusResponse|Net::LimeLight::Purge::StatusResponse> object.  If there
are errors then an exception is thrown.

=cut

sub get_all_purge_statuses {
    my ($self, $detail) = @_;

    my $soap = $self->_soap;
    $soap->on_action(sub { $self->uri.'/GetAllPurgeStatuses' });
    my $header = $self->_header;

    my $res_details = 'false';
    if($detail) {
        $res_details = 'true';
    }

    my $res = $soap->call(
        SOAP::Data->new(
            name => 'GetAllPurgeStatuses',
            attr => { xmlns => $self->uri },
        ) => SOAP::Data->type('string')->name(IncludeDetail => $res_details),
        $header
    );
    if($res->fault) {
        die join(', ',
            $res->faultcode,
            $res->faultstring,
            $res->faultdetail
        );
    }

    # Save me from carpal tunnel
    my $env_prefix = '//GetAllPurgeStatusesResponse/GetAllPurgeStatusesResult';

    my $resp = Net::LimeLight::Purge::StatusResponse->new(
        completed_entries => $res->valueof("$env_prefix/CompletedEntries"),
        total_entries => $res->valueof("$env_prefix/TotalEntries")
    );

    # If we have statuses, put them into the response!
    if($res->match("$env_prefix/EntryStatuses/PurgeEntryStatus")) {
        foreach my $r ($res->dataof) {
            $resp->add_request(
                Net::LimeLight::Purge::Request->new(
                    url => $r->value->{Url},
                    shortname => $r->value->{Shortname},
                    regex => ($r->value->{Regex} eq 'true') ? 1 : 0,
                    completed => ($r->value->{Completed} eq 'true') ? 1 : 0,
                    batch_number => $r->value->{BatchNumber},
                    completed_date => $self->_date_parser->parse_datetime(
                        $r->value->{CompletedDate}
                    )
                )
            );
        }
    }


    return $resp;
}

=head2 password

Set/Get the password of the LUX user.

=head2 proxy

Set/Get the proxy address to use when communicate with the LimeLight service.
This defaults to C<https://soap.llnw.net/PurgeFiles/PurgeService.asmx>

=head2 username

Set/Get the username of the LUX user.

=head2 uri

Set/Get the URI used for this SOAP request.  Defaults to
C<http://www.llnw.com/Purge>. This is the 'namespace' element of the SOAP
request, not the URI that is being communicated with. Look at C<proxy> for
that.

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-limelight-purge at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-LimeLight-Purge>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::LimeLight::Purge

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-LimeLight-Purge>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-LimeLight-Purge>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-LimeLight-Purge>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-LimeLight-Purge/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cory G Watson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
