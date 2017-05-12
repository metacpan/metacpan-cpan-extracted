package Net::Mollom;
use Any::Moose;
use XML::RPC;
use DateTime;
use Params::Validate qw(validate SCALAR UNDEF);
use Digest::HMAC_SHA1 qw(hmac_sha1);
use MIME::Base64 qw(encode_base64);
use DateTime;
use Carp qw(carp croak);
use Net::Mollom::ContentCheck;
use Exception::Class (
    'Net::Mollom::Exception',
    'Net::Mollom::ServerListException'    => {isa => 'Net::Mollom::Exception'},
    'Net::Mollom::CommunicationException' => {isa => 'Net::Mollom::Exception'},
    'Net::Mollom::APIException' =>
      {isa => 'Net::Mollom::Exception', fields => [qw(mollom_code mollom_desc)]},
);

has current_server => (is => 'rw', isa => 'Num',  default  => 0);
has public_key     => (is => 'rw', isa => 'Str',  required => 1);
has private_key    => (is => 'rw', isa => 'Str',  required => 1);
has session_id     => (is => 'rw', isa => 'Str');
has xml_rpc        => (is => 'rw', isa => 'XML::RPC');
has warnings       => (is => 'rw', isa => 'Bool', default  => 1);
has attempt_limit  => (is => 'rw', isa => 'Num',  default  => 1);
has attempts       => (is => 'rw', isa => 'Num',  default  => 0);
has servers_init   => (is => 'rw', isa => 'Bool', default  => 0);
has servers        => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub {
        ['http://xmlrpc1.mollom.com', 'http://xmlrpc2.mollom.com', 'http://xmlrpc3.mollom.com'];
    },
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

our $API_VERSION         = '1.0';
our $VERSION             = '0.09';
my $ERROR_PARSE           = 1000;
my $ERROR_REFRESH_SERVERS = 1100;
my $ERROR_NEXT_SERVER     = 1200;
my $MAX_API_TRIES         = 10;

=head1 NAME

Net::Mollom - interface with Mollom web API

=head1 SYNOPSIS

Communicate with the Mollom web API (L<http://mollom.com/>) via
XML-RPC to determine whether user input is Spam, Ham, flame or
obscene.

    my $mollom = Net::Mollom->new(
        public_key  => 'a2476604ffba00c907478c8f40b83b03',
        private_key => '42d5448f124966e27db079c8fa92de0f',
    );

    my @server_list = $mollom->server_list();

    my $check = $mollom->check_content(
        post_title => $title,
        post_body  => $text,
    );
    if ($check->is_spam) {
        warn "someone's trying to sell us v1@grA!";
    } elsif ($check->is_unsure) {

        # show them a CAPTCHA to see if they are really human
        my $captcha_url = $mollom->get_image_captcha();
    } elsif ($check->quality < .5) {
        warn "someone's trying to flame us!";
    }

If you have any questions about how any of the methods work, please
consult the Mollom API documentation - L<http://mollom.com/api>.

=head1 CONSTRUCTORS

=head2 new

This creates a new NET::Mollom object for communication. It takes the following
named arguments:

=over

=item * public_key (required)

This is your Mollom API public key.

=item * private_key (required)

This is your Mollom API private key.

=item * attempt_limit

This is the number of times Net::Mollom will try to refresh the server list
before giving up. Defaults to 1.

=item * warnings

This boolean turns on warnings. You will get warnings for the following
situations:

=over

=item * A Mollom server is busy and we need to try a different one.

=item * We have exhausted the list of servers to try and we need to get a new list.

=back

=back

=head1 OBJECT METHODS

=head2 verify_key

Check to make sure that Mollom recognizes your public and private keys.
Returns true if successful, false otherwise. This is not necessary to use
in your application, but can be used when doing initial development or testing.

    if( $mollom->verify_key ) {
        # go a head and do stuff
    } else {
        # doh! you screwed up somewhere
    }

=cut

sub verify_key {
    my $self = shift;
    # get the server list from Mollom if we don't already have one
    $self->server_list() unless $self->servers_init;
    return $self->_make_api_call('verifyKey');
}

=head2 check_content

Check some content for spamminess and quality. Takes the following
optional named arguments:

=over

=item * post_title

=item * post_body

=item * author_name

=item * author_url

=item * author_mail

=item * author_openid

=item * author_ip

=item * author_id

=back

Returns a L<Net::Mollom::ContentCheck> object.

    my $check = $mollom->check_content(
        post_title  => $title,
        post_body   => $body,
        author_name => 'Michael Peters',
        author_mail => 'mpeters@p3.com',
        author_id   => 12345,
    );

=cut

sub check_content {
    my $self = shift;
    my %args = validate(
        @_,
        {
            post_title    => {type => SCALAR | UNDEF, optional => 1},
            post_body     => {type => SCALAR | UNDEF, optional => 1},
            author_name   => {type => SCALAR | UNDEF, optional => 1},
            author_url    => {type => SCALAR | UNDEF, optional => 1},
            author_mail   => {type => SCALAR | UNDEF, optional => 1},
            author_openid => {type => SCALAR | UNDEF, optional => 1},
            author_ip     => {type => SCALAR | UNDEF, optional => 1},
            author_id     => {type => SCALAR | UNDEF, optional => 1},
            session_id    => {type => SCALAR | UNDEF, optional => 1},
        }
    );

    # we need at least 1 arg
    croak "You must pass at least 1 argument to check_content!"
      unless %args && map { defined $args{$_} } keys %args;

    # get the server list from Mollom if we don't already have one
    $self->server_list() unless $self->servers_init;
    my $results = $self->_make_api_call('checkContent', \%args);

    # remember the session_id so we can pass it along in future calls
    $self->session_id($results->{session_id});

    return Net::Mollom::ContentCheck->new(
        is_ham    => $results->{spam} == 1 ? 1 : 0,
        is_spam   => $results->{spam} == 2 ? 1 : 0,
        is_unsure => $results->{spam} == 3 ? 1 : 0,
        quality   => $results->{quality},
        session_id => $results->{session_id},
    );
}

=head2 session_id

This is the Mollom assigned session id. If you've made a call to
C<check_content()> it will be set by Mollom and you must pass it later
to any calls you make to C<send_feedback()>, C<get_image_captcha()>,
C<get_audio_captcha()> or C<check_captcha()>. If you use the same Mollom
object that made the C<check_content()> call then you don't need to do
anything since it will remember that for you. But in most web applications
the next request by a user will not be served by the next process or
even the next server, so there's no guarantee. You need to store and
remember this mollom session_id on your own.

=head2 send_feedback

Send feedback to Mollom about their rating of your content. Take sthe following
optional named parameters:

=over

=item * feedback

A string value of either C<spam>, C<profanity>, C<low-quality>, or C<unwanted>.

=item * session_id

The id of the session where the content was checed (by a call to C<check_content>).

=back

    $mollom->send_feedback

=cut 

sub send_feedback {
    my $self = shift;
    my %args = validate(
        @_,
        {
            feedback   => { type => SCALAR, regex => qr/^(spam|profanity|low-quality|unwanted)$/ },
            session_id => { type => SCALAR | UNDEF, optional => 1 },
        }
    );
    $args{session_id} ||= $self->session_id;

    # get the server list from Mollom if we don't already have one
    $self->server_list() unless $self->servers_init;
    return $self->_make_api_call('sendFeedback', \%args);
}

=head2 get_image_captcha

Returns the URL of an image CAPTCHA. This should only be called if the last
message checked was marked C<is_unsure>. Not for C<is_spam> or C<is_ham>.
It takes the following optional parameters:

=over

=item * author_ip

The IP address of the content author

=item * session_id

The Mollom session_id. Normally you don't need to worry about this since Net::Mollom
will take care of it for you.

=back

=cut

sub get_image_captcha {
    my $self = shift;
    my %args = validate(
        @_,
        {
            author_ip  => { type => SCALAR | UNDEF, optional => 1 },
            session_id => { type => SCALAR | UNDEF, optional => 1 },
        }
    );
    $args{session_id} ||= $self->session_id;

    # get the server list from Mollom if we don't already have one
    $self->server_list() unless $self->servers_init;
    my $results = $self->_make_api_call('getImageCaptcha', \%args);
    $self->session_id($results->{session_id});
    return $results->{url};
}

=head2 get_audio_captcha

Returns the URL of an audio CAPTCHA (mp3 file). This should only be called if the last
message checked was marked C<is_unsure>. Not for C<is_spam> or C<is_ham>.
It takes the following optional parameters:

=over

=item * author_ip

The IP address of the content author

=item * session_id

The Mollom session_id. Normally you don't need to worry about this since Net::Mollom
will take care of it for you.

=back

=cut

sub get_audio_captcha {
    my $self = shift;
    my %args = validate(
        @_,
        {
            author_ip  => { type => SCALAR | UNDEF, optional => 1 },
            session_id => { type => SCALAR | UNDEF, optional => 1 },
        }
    );
    $args{session_id} ||= $self->session_id;

    # get the server list from Mollom if we don't already have one
    $self->server_list() unless $self->servers_init;
    my $results = $self->_make_api_call('getAudioCaptcha', \%args);
    $self->session_id($results->{session_id});
    return $results->{url};
}

=head2 check_captcha

Check that what the user entered matches the last CAPTCHA that Mollom
sent as part of this session. Takes the following named arguments:

=over

=item * solution

The user's answer to the CAPTCHA

=item * session_id

The id of the Mollom session.

=back

Returns true if correct, false otherwise.

=cut

sub check_captcha {
    my $self = shift;
    my %args = validate(
        @_,
        {
            solution   => { type => SCALAR },
            session_id => { type => SCALAR | UNDEF, optional => 1 },
        }
    );
    $args{session_id} ||= $self->session_id;

    # get the server list from Mollom if we don't already have one
    $self->server_list() unless $self->servers_init;
    return $self->_make_api_call('checkCaptcha', \%args);
}

=head2 server_list

This method will ask Mollom what servers to use. The list of servers
is saved in the Net::Mollom package and reused on subsequent calls
to the API. Normally you won't need to call this method on it's own
since it will be called for you when you use another part of the API.

    my @servers = $mollom->server_list();

    # or if you've saved the list in a more permanent data store
    $mollom->server_list(@servers);

=cut

sub server_list {
    my ($self, @list) = @_;
    if( @list ) {
        $self->servers(\@list);
        $self->current_server(0);
    } elsif(!$self->servers_init) {
        # get our list from their API
        my $results = $self->_make_api_call('getServerList');
        $self->servers($results);
        $self->servers_init(1);
        $self->current_server(0);
    }
    return @{$self->servers};
}

=head2 get_statistics

This method gets your Mollom usage statistics. It takes the following required named
parameters:

=over

=item * type

Must be one of C<total_days>, C<total_accepted>, C<total_rejected>, C<yesterday_accepted>,
C<yesterday_rejected>, C<today_accepted>, C<today_rejected>.

=back

Will return the count for the specific statistic type you requested.

=cut

sub get_statistics {
    my $self = shift;
    my %args = validate(
        @_,
        {
            type => {
                type => SCALAR,
                regex =>
                  qr/^(total_(days|accepted|rejected)|yesterday_(accepted_rejected)|today_(accepted_rejected))$/
            },
        }
    );

    # get the server list from Mollom if we don't already have one
    $self->server_list() unless $self->servers_init;
    return $self->_make_api_call('getStatistics', \%args);
}

sub _make_api_call {
    my ($self, $function, $args) = @_;
    my $secret = $self->private_key;
    my @servers = @{$self->servers};

    # keep track of how many times we've descended down into this rabbit hole
    if( !  $self->{_recurse_level} ) {
        $self->{_recurse_level} = 1;
    } else {
        $self->{_recurse_level}++;
    }

    if (!$self->xml_rpc) {
        my $xml_rpc = eval { XML::RPC->new($servers[$self->current_server] . '/' . $API_VERSION) };
        Net::Mollom::CommunicationException->throw(error => $@) if $@;
        $self->xml_rpc($xml_rpc);
    }

    $args->{public_key} ||= $self->public_key;
    $args->{time}       ||= DateTime->now->strftime('%Y-%m-%dT%H:%M:%S.000%z');
    $args->{nonce}      ||= int(rand(2_147_483_647));                          # rand 32 bit integer
    $args->{hash} ||=
      encode_base64(hmac_sha1(join(':', $args->{time}, $args->{nonce}, $secret), $secret));

    if (   $function ne 'getServerList'
        && $function ne 'verifyKey'
        && $function ne 'getStatistics'
        && $self->session_id)
    {
        $args->{session_id} = $self->session_id;
    }

    my $results = eval { $self->xml_rpc->call("mollom.$function", $args) };
    Net::Mollom::CommunicationException->throw(error => $@) if $@;

    # check if there are any errors and handle them accordingly
    if (ref $results && (ref $results eq 'HASH') && $results->{faultCode}) {
        my $fault_code = $results->{faultCode};
        if (($fault_code == $ERROR_REFRESH_SERVERS) && ($self->{_recurse_level} < $MAX_API_TRIES) ) {
            if ($function eq 'getServerList') {
                delete $self->{_recurse_level};
                Net::Mollom::ServerListException->throw(error => "Could not get list of servers from Mollom!");
            } else {
                $self->servers_init(0);
                $self->server_list;
                return $self->_make_api_call($function, $args);
            }
        } elsif (($fault_code == $ERROR_NEXT_SERVER) && ($self->{_recurse_level} < $MAX_API_TRIES)) {
            carp("Mollom server busy, trying the next one.") if $self->warnings;
            my $next_index = $self->current_server + 1;
            if ($servers[$next_index] ) {
                $self->current_server($next_index);
                return $self->_make_api_call($function, $args);
            } else {
                # try to refresh the servers if we can
                if ($self->attempt_limit > $self->attempts) {
                    sleep(1);
                    carp("No more servers to try. Attempting to refresh server list.")
                      if $self->warnings;
                    $self->attempts($self->attempts + 1);
                    $self->servers_init(0);
                    $self->server_list;
                    return $self->_make_api_call($function, $args);
                } else {
                    Net::Mollom::ServerListException->throw(error => "No more Mollom servers to try!");
                }
            }
        } elsif( $self->{_recurse_level} < $MAX_API_TRIES ) {
            delete $self->{_recurse_level};
            Net::Mollom::APIException->throw(
                error => "Error communicating with Mollom [$results->{faultCode}]: $results->{faultString}",
                mollom_code => $results->{faultCode},
                mollom_desc => $results->{faultString},
            );
        } else {
            my $msg = qq(Tried making API call "$function" $self->{_recurse_level} times but failed.)
              . " Giving up";
            delete $self->{_recurse_level};
            Net::Mollom::APIException->throw(
                error       => $msg,
                mollom_code => $results->{faultCode},
                mollom_desc => $results->{faultString},
            );
        }
    } else {
        $self->attempts(0);
        delete $self->{_recurse_level} unless $function eq 'getServerList';
        return $results;
    }
}

=head1 EXCEPTIONS

Any object method can throw a L<Net::Mollom::Exception> object (using L<Exception::Class> underneath).

The following exceptions are possible:

=head2 Net::Mollom::ServerListException

This happens when we've exhausted the list available servers and we've reached
our C<attempt_limit> for getting more.

=head2 Net::Mollom::APIException

There was some kind of problem communicating with the Mollom service.
This is not a network error, but somehow we're not talking to it in a language
it can understand (maybe an API change or bug in Net::Mollom, etc).

=head2 Net::Mollom::CommunicationException

There was some kind of problem communicating with the Mollom service.
This could be a network error or an L<XML::RPC> error.

=head1 AUTHOR

Michael Peters, C<< <mpeters at plusthree.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-mollom at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Mollom>.  I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Mollom

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Mollom>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Mollom>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Mollom>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Mollom/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Michael Peters, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Net::Mollom
