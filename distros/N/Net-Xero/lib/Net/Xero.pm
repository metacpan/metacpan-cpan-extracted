package Net::Xero;
$Net::Xero::VERSION = '0.44';
use 5.010;
use strictures 1;
use Moo;
use Net::OAuth;
use LWP::UserAgent;
use HTTP::Request::Common;
use Data::Random qw(rand_chars);
use XML::LibXML::Simple qw(XMLin);
use File::ShareDir 'dist_dir';
use Template;
use Crypt::OpenSSL::RSA;
use URI::Escape;
use Data::Dumper;
use IO::All;
no warnings 'experimental::smartmatch';

$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

=head1 NAME

Net::Xero - Interface to Xero accounting

=head1 VERSION

Version 0.40

=cut

has 'api_url' => (
    is      => 'rw',
    default => 'https://api.xero.com',
);

has 'ua' => (
    is      => 'rw',
    default => sub { LWP::UserAgent->new },
);

has 'debug' => (
    is      => 'rw',
    default => 0,
);

has 'error' => (
    is        => 'rw',
    predicate => 'has_error',
    clearer   => 'clear_error',
);

has 'key'    => (is => 'rw');
has 'secret' => (is => 'rw');
has 'cert'   => (is => 'rw');

has 'nonce'  => (
    is      => 'ro',
    default => join('', rand_chars(size => 16, set => 'alphanumeric')),
);

has 'login_link' => (is => 'rw');

has 'callback_url' => (
    is      => 'rw',
    default => 'http://localhost:3000/callback',
);

has 'request_token'  => (is => 'rw');
has 'request_secret' => (is => 'rw');
has 'access_token'   => (is => 'rw');
has 'access_secret'  => (is => 'rw');

has 'template_path'  => (
    is      => 'rw',
    default => ( dist_dir('Net-Xero') ),
);

#has 'template_path' => (is => 'rw', isa => 'Str');

=head1 SYNOPSIS

Quick summary of what the module does.

For a private application you will receive the access_token/secret when you
submit your X509 to xero. You can ignore login/auth in this instance as follows:
use Net::Xero;

my $foo = Net::Xero->new(
  access_token => 'YY',
  access_secret => 'XX',
);

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=cut

=head2 login

This sets up the initial OAuth handshake and returns the login URL. This
URL has to be clicked by the user and the the user then has to accept
the application in xero.

Xero then redirects back to the callback URL defined with
C<$self-E<gt>callback_url>. If the user already accepted the application the
redirect may happen without the user actually clicking anywhere.

=cut

sub login {
    my $self = shift;

    my $request = Net::OAuth->request("request token")->new(
        consumer_key     => $self->key,
        consumer_secret  => $self->secret,
        request_url      => $self->api_url . '/oauth/RequestToken',
        request_method   => 'POST',
        signature_method => 'RSA-SHA1',
        timestamp        => time,
        nonce            => $self->nonce,
        callback         => $self->callback_url,
    );

    my $private_key = Crypt::OpenSSL::RSA->new_private_key($self->cert);
    $request->sign($private_key);
    my $res = $self->ua->request(GET $request->to_url);

    if ($res->is_success) {
        my $response =
            Net::OAuth->response('request token')
            ->from_post_body($res->content);
        $self->request_token($response->token);
        $self->request_secret($response->token_secret);
        print STDERR "Got Request Token ", $response->token, "\n"
            if $self->debug;
        print STDERR "Got Request Token Secret ", $response->token_secret, "\n"
            if $self->debug;
        return
              $self->api_url
            . '/oauth/Authorize?oauth_token='
            . $response->token
            . '&oauth_callback='
            . $self->callback_url;
    }
    else {
        $self->error($res->status_line);
        warn "Something went wrong: " . $res->status_line;
    }
}

=head2 auth

The auth method changes the initial request token into access token that we need
for subsequent access to the API. This method only has to be called once
after login.

=cut

sub auth {
    my $self = shift;

    my $request = Net::OAuth->request("access token")->new(
        consumer_key     => $self->key,
        consumer_secret  => $self->secret,
        request_url      => $self->api_url . '/oauth/AccessToken',
        request_method   => 'POST',
        signature_method => 'RSA-SHA1',
        timestamp        => time,
        nonce            => $self->nonce,
        callback         => $self->callback_url,
        token            => $self->request_token,
        token_secret     => $self->request_secret,
    );
    my $private_key = Crypt::OpenSSL::RSA->new_private_key($self->cert);
    $request->sign($private_key);
    my $res = $self->ua->request(GET $request->to_url);

    if ($res->is_success) {
        my $response =
            Net::OAuth->response('access token')->from_post_body($res->content);
        $self->access_token($response->token);
        $self->access_secret($response->token_secret);
        print STDERR "Got Access Token ", $response->token, "\n"
            if $self->debug;
        print STDERR "Got Access Token Secret ", $response->token_secret, "\n"
            if $self->debug;
    }
    else {
        $self->error($res->status_line);
        $self->error($res->status_line . "\n" . $res->content);
    }
}

=head2 set_cert

=cut

sub set_cert {
  my ($self, $path) = @_;
  my $cert = io $path;
  $self->cert($cert->all);
}

=head2 get_inv_by_ref

=cut

sub get_inv_by_ref {
    my ($self, @ref) = @_;

    my $path = 'Invoices?where=Reference.ToString()=="' . (shift @ref) . '"';
    $path .= ' OR Reference.ToString()=="' . $_ . '"' foreach (@ref);

    return $self->_talk($path, 'GET');
}

=head2 get_invoices

=cut

sub get_invoices {
    my ($self, $where) = @_;

    my $path = 'Invoices';

    return $self->_talk($path, 'GET') unless (ref $where eq 'HASH');

    $path .= '?where=';
    my $conjunction =
        (exists $where->{'conjunction'}) ? uc $where->{'conjunction'} : 'OR';
    my $first = 1;

    foreach my $key (%{$where}) {
        $path .= " $conjunction " unless $first;

        given ($key) {
            when ('reference') {
                my @refs = @{ $where->{$key} };
                $path .= 'Reference.ToString()=="' . (shift @refs) . '"';
                $path .= ' OR Reference.ToString()=="' . $_ . '"'
                    foreach (@refs);
            }
            when ('contact') {
                my @contacts = @{ $where->{$key} };
                my $contact  = shift @contacts;
                $path .= join(
                    ' AND ',
                    map {
                              "Contact."
                            . ucfirst($_) . '=="'
                            . $contact->{$_} . '"'
                        } keys %{$contact});

                # finish foreach
            }
            when ('number') {
                my @numbers = @{ $where->{$key} };
                $path .= ' OR InvoiceNumber.ToString()=="' . $_ . '"'
                    foreach (@numbers);
            }
        }

        $first = 0;
    }

    return $self->_talk($path, 'GET');
}

=head2 create_invoice

=cut

sub create_invoice {
    my ($self, $hash) = @_;
    $hash->{command} = 'create_invoice';
    return $self->_talk('Invoices', 'POST', $hash);
}

sub void_invoice  {
  my ($self, $guid) = @_;
  my $hash = { guid => $guid } ;
  $hash->{command} = 'void_invoice';
  return $self->_talk('Invoices', 'POST', $hash );
}

=head2 create_payment

=cut

sub create_payment {
    my ($self, $data) = @_;
    $data->{command} = 'payments';
    return $self->_talk('Payments', 'POST', $data);
}

=head2 create_contact

=cut

sub create_contact {
   my ($self, $data) = @_;
   $data->{command} = 'create_contact';
   $data->{Contacts}->{Contact} = $data;
   return $self->_talk('Contacts', 'POST', $data);
}

=head2 approve_credit_note

=cut

sub approve_credit_note {
    my ($self, $hash) = @_;
    $hash->{command} = 'approve_credit_note';
    return $self->_talk('CreditNotes', 'POST', $hash);
}

=head2 status_invoice

=cut

sub status_invoice {
    my ($self, $hash) = @_;
    $hash->{command} = 'status_invoice';
    return $self->_talk('Invoices', 'POST', $hash);
}

=head2 get

=cut

sub get {
    my ($self, $command) = @_;
    return $self->_talk($command, 'GET');
}

=head2 post

=cut

sub post {
    my ($self, $command, $hash) = @_;
    return $self->_talk($command, 'POST', $hash);
}

=head2 put

=cut

sub put {
    my ($self, $command, $hash) = @_;
    return $self->_talk($command, 'PUT', $hash);
}

=head1 INTERNAL API

=head2 _talk

_talk handles the access to the restricted resources. You should
normally not need to access this directly.

=cut

sub _talk {
    my ($self, $command, $method, $hash) = @_;

    $self->clear_error;

    my $path = join('', map(ucfirst, split(/_/, $command)));

    my $request_url = $self->api_url . '/api.xro/2.0/' . $path;
    my %opts        = (
        consumer_key     => $self->key,
        consumer_secret  => $self->secret,
        request_url      => $request_url,
        request_method   => $method,
        signature_method => 'RSA-SHA1',
        timestamp        => time,
        nonce        => join('', rand_chars(size => 16, set => 'alphanumeric')),
        token        => $self->access_token,
        token_secret => $self->access_secret,
    );

    my $content;
    if ($method =~ m/^(POST|PUT)$/) {
        $hash->{command} ||= $command;
        $content = $self->_template($hash);
        $opts{extra_params} = { xml => $content } if ($method eq 'POST');
    }

    my $request     = Net::OAuth->request("protected resource")->new(%opts);
    my $private_key = Crypt::OpenSSL::RSA->new_private_key($self->cert);
    $request->sign($private_key);
    #my $req = HTTP::Request->new($method, $request->to_url);
    my $req = HTTP::Request->new($method, $request_url);
    if ($hash and ($method eq 'POST')) {
        $req->content($request->to_post_body);
        $req->header('Content-Type' =>
                'application/x-www-form-urlencoded; charset=utf-8');
    }
    else {
        $req->content($content) if ($hash and ($method eq 'PUT'));
        $req->header(Authorization => $request->to_authorization_header);
    }

    print STDERR $req->as_string if $self->debug;

    my $res = $self->ua->request($req);

    if ($res->is_success) {
        print STDERR "Got Content ", $res->content, "\n" if $self->debug;
        return XMLin($res->content);
    }
    else {
        warn "Something went wrong: " . $res->content;
        $self->error($res->status_line . " " . $res->content);
    }

    return;
}

=head2 _template

=cut

sub _template {
    my ($self, $hash) = @_;

    $hash->{command} .= '.tt';
    print STDERR Dumper($hash) if $self->debug;
    my $tt;
    if ($self->debug) {
        $tt = Template->new(
            #DEBUG        => 'all',
            INCLUDE_PATH => [ $self->template_path ],
        );
    }
    else {
        $tt = Template->new(INCLUDE_PATH => [ $self->template_path ]);
    }

    my $template = '';
    $tt->process('frame.tt', $hash, \$template)
        || die $tt->error;
    utf8::encode($template);
    print STDERR $template if $self->debug;

    return $template;
}

=head1 AUTHOR

Lenz Gschwendtner, C<< <norbu09 at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-xero at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Xero>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Xero


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Xero>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Xero>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Xero>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Xero/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Lenz Gschwendtner.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

__PACKAGE__->meta->make_immutable();
