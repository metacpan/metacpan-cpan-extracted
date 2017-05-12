package Net::SMS::ArxMobile;
BEGIN {
  $Net::SMS::ArxMobile::VERSION = '0.01';
}

# ABSTRACT: Send SMS messages via the ArXMobile HTTP API

use strict;
use warnings;


use Carp ();
#se Data::Dumper ();
use HTTP::Request ();
use LWP::UserAgent ();
use XML::Simple ();

use constant {
    XML_DECL      => q{<?xml version="1.0" ?>},   # Ugh
    API_URL_SEND  => q{https://invenue.com/api/message.php},
    API_URL_QUERY => q{https://invenue.com/api/query.php},
    API_TIMEOUT   => 30,
};

sub new {
    my ($class, %args) = @_;

    if (! exists $args{_auth_code} || ! $args{_auth_code}) {
        Carp::croak("${class}->new() requires the ArXMobile '_auth_code' parameter\n");
    }

    my $self = \%args;
    bless $self, $class;
}

sub _useragent {
    my ($self) = @_;

    my $ua = LWP::UserAgent->new();
    $ua->timeout(API_TIMEOUT);
    $ua->agent("Net::SMS::ArxMobile/$Net::SMS::ArxMobile::VERSION");

    return $ua;
}

sub _query_smsid_xml {
    my ($self, %args) = @_;

    my $smsid = $args{smsid};
    my $auth_code = $args{_auth_code};

    my $xml = _to_xml({
        query => {
            auth_code => $auth_code,
            smsid => $smsid,
        },
    });

    return $xml;
}

sub _send_sms_xml {
    my ($self, %args) = @_;

    my $body = $args{text};
    my $phone = $args{to};
    my $auth_code = $args{_auth_code};

    my $xml = _to_xml({
        message => {
            auth_code => $auth_code,
            body => $body,
            user => {
                phone => $phone,
            },
        },
    });

    return $xml;
}

sub _to_xml {
    my ($data_struct) = @_;
    my %xml_opts = _xml_out_opts();
    return XML::Simple::XMLout($data_struct, %xml_opts);
}

sub _xml_out_opts {
    return (
        KeepRoot => 1,
        NoAttr   => 1,
        XMLDecl  => XML_DECL,
    );
}

sub query_smsid {
    my ($self, %args) = @_;

    my $ua = _useragent();
    my $api_url = API_URL_QUERY;
    my $req_xml = $self->_query_smsid_xml(
        _auth_code => $self->{_auth_code},
        smsid => $args{smsid},
    );

    my $req = HTTP::Request->new(POST => $api_url);
    $req->header("Content-Type" => "text/xml");
    $req->content($req_xml);

    my $resp = $ua->request($req);
    my $as_string = $resp->as_string;
    my $resp_body = $resp->content;

    if (! $resp->is_success) {
        my $status = $resp->status_line;
        warn "HTTP request failed: $status\n$resp_body\n";
        return;
    }

    #warn "HTTP Request: " . $req->as_string . "\n";
    #warn "HTTP Response: $as_string\n";
    #warn "HTTP Response content: $resp_body\n";

    my $api_data = XML::Simple::XMLin($resp_body, SuppressEmpty => '');
    if (! $api_data || ref $api_data ne "HASH") {
        warn "No result (or invalid XML?) from API\n";
        return;
    }

    my $sms_data = $api_data->{result};
    return $sms_data;
}

sub send_sms {
    my ($self, %args) = @_;

    $args{to} =~ s{^\+}{};
    $args{to} =~ s{[- ]}{}g;

    my $ua = $self->_useragent();
    my $api_url = API_URL_SEND;
    my $req_xml = $self->_send_sms_xml(
        _auth_code => $self->{_auth_code},
        text => $args{text},
        to => $args{to},
    );

    my $req = HTTP::Request->new(POST => $api_url);
    $req->header("Content-Type" => "text/xml");
    $req->content($req_xml);

    my $resp = $ua->request($req);
    my $as_string = $resp->as_string;

    #warn "HTTP Request: " . $req->as_string . "\n";
    #warn "HTTP Response: $as_string\n";
    #warn "HTTP Response content: " . $resp->content . "\n";

    if (! $resp->is_success) {
        my $status = $resp->status_line;
        warn "HTTP request failed: $status\n$as_string\n";
        return 0;
    }

    my $xml = $resp->content;
    my $api_data = XML::Simple::XMLin($xml, SuppressEmpty => '');

    if (! $api_data || ref $api_data ne "HASH") {
        warn "No response (or invalid XML) from API\n";
        return;
    }

    #warn Data::Dumper::Dumper($api_data), "\n";

    my $sms = $api_data->{result};

    if (! $sms || ref $sms ne "HASH") {
        warn "Couldn't find any sms result in the XML\n";
        return;
    }

    if ($sms->{error}) {
        warn "Failed: $sms->{error}\n";
        return;
    }

    my $smsid = $sms->{smsid};
    if (! $smsid) {
        warn "smsid not found in ArxMobile response:\n$xml\n";
    }

    return $smsid;
}

1;


__END__
=pod

=head1 NAME

Net::SMS::ArxMobile - Send SMS messages via the ArXMobile HTTP API

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  # Create a testing sender
  my $arx = Net::SMS::ArxMobile->new(
      _auth_code => '{ArXMobile auth code}',
  );

  # Send a message
  my $sent = $arx->send_sms(
      text => "You're in a maze of twisty little passages, all alike.",
      to   => '+1 888 555 1212',
  );

  if ($sent) {
      # Message sent
  }
  else {
      # Something failed
  }

=head1 DESCRIPTION

Perl module to send SMS messages through the HTTP API provided by ArxMobile
(www.arxmobile.com).

B<NOTE: Your ability to send messages outside of the United States
could be limited>.

Example of formats that work are:

=over 4

=item C<+1 888 555 1234>

=item C<18885551234>

=back

I have never tried this code with non-US numbers. Probably it works.
Probably depends on your auth code?

Probably the Earth will be hit by a massive asteroid in 5 seconds.

=head1 METHODS

=head2 C<new( _auth_code => '{ArxMobile auth code}')>

Nothing fancy. You need to supply your Arxmobile auth code
in the constructor, or it will complain loudly.

=head2 C<send_sms(to => $phone_number, text => $message)>

Uses the API to send a message given in C<$message> to
the phone number given in C<$phone_number>.

B<NOTE: Your ability to send messages outside of the United States
could be limited>.

Phone number should be given in one of these formats:

=over 4

=item C<+1 888 555 1234>

=item C<18885551234>

=back

Returns a string that is the B<smsid>.

The smsid can be used to query the status via the C<query_smsid()>
method.

This API is explicitly C<SMS::Send> compatible.

=head2 C<query_smsid(smsid => $smsid)>

Queries the ArxMobile server to check the status of an SMS given its
B<smsid>. The B<smsid> is obtained through a successful C<send_sms()> call.

Example of B<HTTP> response:

    <?xml version='1.0' ?>
    <results>
      <result>
        <phone>{11-digit phone number}</phone>
        <status>1</status>
        <error></error>
        <smsid>{smsid-string}</smsid> <!-- ex.: a552e6f04acd292df310c21b13ea63c8 -->
      </result>
    </results>

The method B<will return a hashref> with the correspondent data structure
obtained by parsing back the XML file. Example:

    {
        phone => '{11-digit phone number}',
        status => '1',
        error => '',
        smsid => '{smsid-string}',
    }

This parsing B<does not account for multiple results>.

=head1 SEE ALSO

=head2 ArXMobile website, http://www.arxmobile.com/

=head1 AUTHOR

Cosimo Streppone <cosimo@opera.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Opera Software ASA.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

