package Protocol::Yadis;

use strict;
use warnings;

require Carp;

use constant DEBUG => $ENV{PROTOCOL_YADIS_DEBUG} || 0;

use Protocol::Yadis::Document;

our $VERSION = '1.00';

sub new {
    my $class = shift;
    my %param = @_;

    my $self = {@_};
    bless $self, $class;

    Carp::croak('http_req_cb is required') unless $self->{http_req_cb};

    $self->{_headers} = {'Accept' => 'application/xrds+xml'};

    return $self;
}

sub http_req_cb { shift->{http_req_cb} }
sub head_first  { shift->{head_first} }

sub discover {
    my $self = shift;
    my ($url, $cb) = @_;

    my $method = $self->head_first ? 'HEAD' : 'GET';

    if ($method eq 'GET') {
        return $self->_initial_req($url, sub { $cb->(@_) });
    }
    else {
        $self->_initial_head_req(
            $url => sub {
                my ($self, $location, $error) = @_;

                return $cb->($self, undef, $error) if $error;

                return $self->_initial_req($url, sub { $cb->(@_) })
                  unless $location;

                return $self->_second_req($location => sub { $cb->(@_); });
            }
        );
    }
}

sub _parse_document {
    my $self = shift;
    my ($headers, $body) = @_;

    my $content_type = $headers->{'Content-Type'};

    if (   $content_type
        && $content_type =~ m/^(?:application\/xrds\+xml|text\/xml);?/)
    {
        my $document = Protocol::Yadis::Document->parse($body);

        return $document if $document;
    }

    return;
}

sub _initial_req {
    my $self = shift;
    my ($url, $cb) = @_;

    $self->_initial_get_req(
        $url => sub {
            my ($self, $document, $location, $error) = @_;

            # Error
            return $cb->($self, undef, $error) if $error;

            # Yadis document
            return $cb->($self, $document) if $document;

            # No new location
            return $cb->($self) unless $location;

            # New location
            return $self->_second_req($location => $cb);
        }
    );
}

sub _initial_head_req {
    my $self = shift;
    my ($url, $cb) = @_;

    warn 'HEAD request' if DEBUG;

    $self->http_req_cb->(
        $url, 'HEAD',
        $self->{_headers},
        undef => sub {
            my ($url, $status, $headers, $body, $error) = @_;

            # Error
            return $cb->($self, undef, $error) if $error;

            # Wrong response status
            return $cb->($self, undef, 'Wrong response status')
              unless $status && $status == 200;

            # New location
            if (my $location = $headers->{'X-XRDS-Location'}) {
                warn 'Found X-XRDS-Location' if DEBUG;

                return $cb->($self, $location);
            }

            # Nothing found
            $cb->($self);
        }
    );
}

sub _initial_get_req {
    my $self = shift;
    my ($url, $cb) = @_;

    warn 'GET request' if DEBUG;

    $self->http_req_cb->(
        $url, 'GET',
        $self->{_headers},
        undef => sub {
            my ($url, $status, $headers, $body, $error) = @_;

            # Pass the error
            return $cb->($self, undef, undef, $error) if $error;

            warn 'after user callback' if DEBUG;

            # Wrong response status
            return $cb->($self, undef, undef, 'Wrong response status')
              unless $status && $status == 200;

            warn 'status is ok' if DEBUG;

            # New XRDS location found
            if (my $location = $headers->{'X-XRDS-Location'}) {
                warn 'Found X-XRDS-Location' if DEBUG;

                # Response body
                if ($body) {
                    warn 'Found body' if DEBUG;

                    my $document = $self->_parse_document($headers, $body);

                    # Yadis document discovered
                    return $cb->($self, $document) if $document;
                }

                warn 'no yadis was found' if DEBUG;

                # Not a Yadis document, thus try new location
                return $cb->($self, undef, $location);
            }

            warn 'No X-XRDS-Location header was found' if DEBUG;

            # Response body
            if ($body) {
                my $document = $self->_parse_document($headers, $body);

                # Yadis document discovered
                return $cb->($self, $document) if $document;

                warn 'Found HTML' if DEBUG;
                my ($head) = ($body =~ m/<\s*head\s*>(.*?)<\/\s*head\s*>/is);

                # Invalid HTML
                return $cb->($self, undef, undef, 'No <head> was found')
                  unless $head;

                my $location;
                my $tags = _html_tag(\$head);
                foreach my $tag (@$tags) {
                    next unless $tag->{name} eq 'meta';

                    my $attrs = $tag->{attrs};
                    next
                      unless %$attrs
                          && $attrs->{'http-equiv'}
                          && $attrs->{'http-equiv'} =~ m/^X-XRDS-Location$/i;

                    last if ($location = $attrs->{content});
                }

                # Try new location
                return $cb->($self, undef, $location) if $location;

                # No HTML <meta> information was found
                return $cb->($self, undef, undef, 'No <meta> was found');
            }

            warn 'No body was found' if DEBUG;
            return $cb->($self, undef, undef, 'No document was found');
        }
    );
}

sub _second_req {
    my $self = shift;
    my ($url, $cb) = @_;

    warn 'Second GET request' if DEBUG;

    $self->http_req_cb->(
        $url, 'GET',
        $self->{_headers},
        undef => sub {
            my ($url, $status, $headers, $body, $error) = @_;

            # Error
            return $cb->($self, undef, $error) if $error;

            # Wrong response status
            return $cb->($self, undef, 'Wrong response status')
              unless $status && $status == 200;

            # No document
            return $cb->($self, undef, 'No body was found') unless $body;

            # Found Yadis document
            if (my $document = $self->_parse_document($headers, $body)) {
                warn 'XRDS Document was found' if DEBUG;
                return $cb->($self, $document);
            }

            # Nothing found
            return $cb->($self);
        }
    );
}

# based on HTML::TagParser
sub _html_tag {
    my $txtref = shift;    # reference
    my $flat   = [];

    while (
        $$txtref =~ s{
        ^(?:[^<]*) < (?:
            ( / )? ( [^/!<>\s"'=]+ )
            ( (?:"[^"]*"|'[^']*'|[^"'<>])+ )?
        |
            (!-- .*? -- | ![^\-] .*? )
        ) \/?> ([^<]*)
    }{}sxg
      )
    {
        my $attrs;
        if ($3) {
            my $attr = $3;
            my $name;
            my $value;
            while ($attr =~ s/^([^=]+)=//s) {
                $name = lc $1;
                $name =~ s/^\s*//s;
                $name =~ s/\s*$//s;
                $attr =~ s/^\s*//s;
                if ($attr =~ m/^('|")/s) {
                    my $quote = $1;
                    $attr =~ s/^$quote(.*?)$quote//s;
                    $value = $1;
                }
                else {
                    $attr =~ s/^(.*?)\s*//s;
                    $value = $1;
                }
                $attrs->{$name} = $value;
            }
        }

        next if defined $4;
        my $hash = {
            name    => lc $2,
            content => $5,
            attrs   => $attrs
        };
        push(@$flat, $hash);
    }

    return $flat;
}

1;
__END__

=head1 NAME

Protocol::Yadis - Asynchronous Yadis implementation

=head1 SYNOPSIS

    my $y = Protocol::Yadis->new(
        http_req_cb => sub {
            my ($url, $method, $headers, $body, $cb) = @_;

            ...

            $cb->($url, $status, $headers, $body, $error);
        }
    );

    $y->discover(
        $url => sub {
            my ($self, $document, $error) = @_;

            if ($document) {
                my $services = $document->services;

                ...
            }
            elsif ($error) {
                die "Error: $error";
            }
            else {
                die "Nothing found";
            }
        }
    );

=head1 DESCRIPTION

This is an asynchronous lightweight but full Yadis implementation.

=head1 ATTRIBUTES

=head2 C<http_req_cb>

    my $y = Protocol::Yadis->new(
        http_req_cb => sub {
            my ($url, $method, $headers, $body, $cb) = @_;

            ...

            $cb->($url, $status, $headers, $body, $error);
        }
    );

This is a required callback that is used to download documents from the network.
Don't forget, that redirects can occur. This callback must handle them properly.
That is why after finishing downloading, callback must be called with the final
$url.

Arguments that are passed to the request callback

=over

=item * B<url> url where to start Yadis discovery

=item * B<method> request method

=item * B<headers> request headers

=item * B<body> request body

=item * B<cb> callback that must be called after download was completed

=back

Arguments that must be passed to the response callback

=over

=item * B<url> url from where the document was downloaded

=item * B<status> response status

=item * B<headers> response headers

=item * B<body> response body

=item * B<error> internal error

=back

=head2 C<head_first>

Do HEAD request first. Disabled by default.

=head1 METHODS

=head2 C<new>

Creates a new L<Protocol::Yadis> instance.

=head2 C<discover>

    $y->discover(
        $url => sub {
            my ($self, $document, $error) = @_;

            if ($document) {
                my $services = $document->services;

                ...
            }
            else {
                die 'error';
            }
        }
    );

Discover Yadis document at the url provided. Callback is called when discovery
was finished. If no document was passed there was an error during discovery.
Error is passed as the third parameter.

If a Yadis document was discovered you get L<Protocol::Yadis::Document> instance
containing all the services.

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
