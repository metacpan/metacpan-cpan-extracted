package Net::ACME2::Curl;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::ACME2::Curl

=head1 SYNOPSIS

To integrate with, e.g., L<Mojolicious>:

    my $promiser = Net::Curl::Promiser::Mojo->new();

    my $acme2_ua = Net::ACME2::Curl->new($promiser);

    my $acme = SomeNetACME2Subclass->new(
        async_ua => $acme2_ua,
        ...,
    );

    my $tos_p = $acme->get_terms_of_service()->then(
        sub { my $url = shift; ... },
    );

… and so on.

=head1 DESCRIPTION

This class implements non-blocking I/O in L<Net::ACME2> via
L<Net::Curl::Promiser>. By using this module you can integrate Net::ACME2
into most popular Perl event loops.

=head1 STATUS

This module is currently B<EXPERIMENTAL>. Caveat emptor.

=cut

#----------------------------------------------------------------------

use Net::Curl::Easy ();

use Net::ACME2 ();
use Net::ACME2::HTTP::Convert ();
use Net::ACME2::X ();

use constant _HTTP_TINY_INTERNAL_EXCEPTION_REASON => 'Internal Exception';

#----------------------------------------------------------------------

=head1 METHODS

=head2 $obj = I<CLASS>->new( $PROMISER )

Instantiates this class. Receives an instance of an appropriate
L<Net::Curl::Promiser> subclass for the environment.

=cut

sub new {
    my ($class, $promiser) = @_;

    return bless { _promiser => $promiser }, $class;
}

=head2 $obj = I<OBJ>->set_easy_callback( $CODEREF )

Installs a callback ($CODEREF) that I<OBJ> will call after creating
a L<Net::Curl::Easy> instance. That instance is given as an argument to
the callback. Via this method you can customize each HTTP request, e.g.,
to set timeouts, DNS resolution settings, a custom User-Agent string,
and the like.

=cut

sub set_easy_callback {
    my ($self, $cb) = @_;

    $self->{'_easy_cb'} = $cb;

    return $self;
}

sub _get_ua_string {
    my ($self) = @_;

    return ref($self) . " $Net::ACME2::VERSION";
}

# Not documented because it’s part of the required interface.
sub request {
    my ($self, $method, $url, $args_hr) = @_;

    my $easy = $self->_xlate_http_tiny_request_to_net_curl_easy($method, $url, $args_hr);

    $_ = q<> for @{$easy}{ qw( _head _body ) };

    $easy->setopt( Net::Curl::Easy::CURLOPT_HEADERDATA(), \$easy->{'_head'} );
    $easy->setopt( Net::Curl::Easy::CURLOPT_FILE(), \$easy->{'_body'} );

    my $p1 = $self->{'_promiser'}->add_handle($easy)->then(
        sub {
            my ($easy) = @_;

            return _imitate_http_tiny( shift(), @{$easy}{'_head', '_body'} );
        },
        sub {
            return {
                success => 0,
                url => $easy->getinfo( Net::Curl::Easy::CURLINFO_EFFECTIVE_URL() ),
                status => 599,
                reason => _HTTP_TINY_INTERNAL_EXCEPTION_REASON,
                content => q<> . shift(),
                headers => {},
            };
        },
    );

    return $p1->then( sub {
        my ($resp) = @_;

        return Net::ACME2::HTTP::Convert::http_tiny_to_net_acme2($method, $resp);
    } );
}

# curl response -> HTTP::Tiny response
sub _imitate_http_tiny {
    my ($easy, $head, $body) = @_;

    my $status_code = $easy->getinfo( Net::Curl::Easy::CURLINFO_RESPONSE_CODE() );

    my $reason;

    my %headers;
    for my $line ( split m<\x0d?\x0a>, $head ) {
        next if !length $line;

        if (defined $reason) {
            my ($name, $value) = split m<\s*:\s*>, $line, 2;
            $name =~ tr<A-Z><a-z>;

            if (exists $headers{$name}) {
                if (ref $headers{$name}) {
                    push @{$headers{$name}}, $value;
                }
                else {
                    $headers{$name} = [ $headers{$name}, $value ];
                }
            }
            else {
                $headers{$name} = $value;
            }
        }
        else {
            if ( $line =~ m<.+? \s+ .+? \s+ (.*)>x ) {
                $reason = $1;
            }
            else {
                die Net::ACME2::X->create('Generic', "Unparsable first header line: [$line]");
            }
        }
    }

    my %resp = (
        success => ($status_code >= 200) && ($status_code <= 299),
        url => $easy->getinfo( Net::Curl::Easy::CURLINFO_EFFECTIVE_URL() ),
        status => $status_code,
        reason => $reason,
        content => $body,
        headers => \%headers,
    );

    return \%resp;
}

# HTTP::Tiny request -> curl request
sub _xlate_http_tiny_request_to_net_curl_easy {
    my ($self, $method, $url, $args_hr) = @_;

    my $easy = Net::Curl::Easy->new();

    # By setting this here we allow the callback to overwrite it.
    $easy->setopt( Net::Curl::Easy::CURLOPT_USERAGENT(), $self->_get_ua_string() );

    $self->{'_easy_cb'}->($easy) if $self->{'_easy_cb'};

    # $easy->setopt( Net::Curl::Easy::CURLOPT_VERBOSE(), 1 );

    $easy->setopt( Net::Curl::Easy::CURLOPT_URL(), $url );

    _assign_headers( $args_hr->{'headers'}, $easy );

    if ($method eq 'POST') {
        $easy->setopt( Net::Curl::Easy::CURLOPT_POST(), 1 );

        if (defined $args_hr->{'content'} && length $args_hr->{'content'}) {
            $easy->setopt(
                Net::Curl::Easy::CURLOPT_POSTFIELDSIZE(),
                length $args_hr->{'content'},
            );
            $easy->setopt(
                Net::Curl::Easy::CURLOPT_COPYPOSTFIELDS(),
                $args_hr->{'content'},
            );
        }
    }
    elsif ($method eq 'HEAD') {

        # e.g., HEAD
        $easy->setopt( Net::Curl::Easy::CURLOPT_NOBODY(), 1 );
    }
    elsif ($method eq 'GET') {

        # GET is curl's default; no options needed.
    }
    else {
        $easy->setopt( Net::Curl::Easy::CURLOPT_CUSTOMREQUEST(), $method );
    }

    return $easy;
}

sub _assign_headers {
    my ($hdrs_hr, $easy) = @_;

    if ($hdrs_hr && %$hdrs_hr) {
        my @hdr_strs;

        for my $name (keys %$hdrs_hr) {
            my $value = $hdrs_hr->{$name};

            if ( (ref($value) || q<a>)->isa('ARRAY') ) {
                push @hdr_strs, "$name: $_" for @$value;
            }
            elsif (ref $value) {
                die "Can’t handle $value as header!" if ref $value;
            }
            else {
                push @hdr_strs, "$name: $value";
            }
        }

        $easy->pushopt( Net::Curl::Easy::CURLOPT_HTTPHEADER(), \@hdr_strs );
    }

    return;
}

1;
