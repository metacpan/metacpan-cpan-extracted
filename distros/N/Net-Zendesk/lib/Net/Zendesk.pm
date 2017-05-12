package Net::Zendesk;
use strict;
use warnings;
use MIME::Base64;

our $VERSION = '0.01';

sub new {
    my ($class, %args) = @_;
    die 'please provide a zendesk domain name (e.g. domain => "obscura.zendesk.com")'
        unless $args{domain} && $args{domain} =~ /\.zendesk\.com\z/ && $args{domain} !~ m{/};

    die 'sorry! only API version 2 is supported at the moment'
        if exists $args{api} && $args{api} != 2;

    die 'please provide the email of a valid zendesk account' unless $args{email};
    if ($args{token}) {
        $args{auth} = "$args{email}/token:$args{token}";
    }
    elsif ($args{password}) {
        $args{auth} = "$args{email}:$args{password}";
    }
    else {
        die 'please provide a password or a token for zendesk authentication. Oauth is not yet supported by this module';
    }

    return bless {
        _domain => $args{domain},
        _api    => $args{api},
        _auth   => MIME::Base64::encode($args{auth}),
        _ua    => $args{ua} || undef,
    }, $class;
}

sub create_ticket {
    my ($self, $ticket, %extra) = @_;
    my $path = 'tickets.json';
    if (%extra) {
        $path .= '?' . join('&', map("$_=$extra{$_}", keys %extra));
    }
    return $self->make_request('POST', $path, { ticket => $ticket });
}

sub search {
    my ($self, $search_args) = @_;
    my $parsed_args = $self->_parse_search_args($search_args);

    require URI::Escape;
    my $query = URI::Escape::uri_escape(join(' ' => @$parsed_args));

    return $self->make_request('GET', 'search.json?query=' . $query, {});
}

sub make_request {
    my ($self, $type, $path, $params) = @_;
    die 'please provide a type' unless $type
        && ($type eq 'GET' || $type eq 'POST' || $type eq 'PUT' || $type eq 'DELETE');
    die 'please provide a relative path' unless $path && $path !~ m{\A/api};
    die 'please provide a HASHREF with parameters' unless $params && ref $params eq 'HASH';
    my $method = lc $type;
    return $self->_ua->$method(
        'https://' . $self->{_domain} . '/api/v2/' . $path,
        [
            ($method eq 'post' || $method eq 'put'
                ? ('Content-Type' => 'application/json') : ()
            ),
        ],
        $params,
    );
}

sub _parse_search_args {
    my ($self, $search_args) = @_;
    my @query;
    foreach my $keyword (keys %$search_args) {
        die "Net::Zendesk: malformed search keyword '$keyword' contains spaces"
            if $keyword =~ /\s/;
        my $value = $search_args->{$keyword};
        if (ref $value) {
            if (ref $value eq 'HASH') {
                foreach my $inner_key (keys %$value) {
                    my %tokens = (
                        '='   => ':',
                        '>'   => '>',
                        '<'   => '<',
                        '>='  => '>=',
                        '<='  => '<=',
                        '!='  => ':',
                        'or'  => ':',
                        'and' => ':',
                    );
                    die "Net::Zendesk: invalid token '$inner_key' for keyword '$keyword'. Available tokens are " . join(', ', keys %tokens) unless exists $tokens{$inner_key};

                    my $inner_value = $value->{$inner_key};
                    $inner_value = 'none' unless defined $inner_value;

                    if (ref $inner_value) {
                        die 'Net::Zendesk: only scalar values or ARRAY references are supported. Got ' . ref($inner_value) . " for keyword '$keyword' under '$inner_key'." unless ref $inner_value eq 'ARRAY';
                        if ($inner_key eq 'and') {
                            push @query, $keyword . ':'
                            . join ' ', map {
                                defined $_ ? $_ =~ /\s/ ? qq("$_") : $_ : 'none'
                            } @$inner_value;
                        }
                        elsif ($inner_key eq '=' || $inner_key eq 'or') {
                            foreach my $or (@$inner_value) {
                                $or = 'none' unless defined $or;
                                $or = qq("$or") if $or =~ /\s/;
                                push @query, "$keyword$tokens{$inner_key}$or";
                            }
                        }
                        else {
                            die 'Net::Zendesk: only =,and,or tokens are allowed for references';
                        }
                    }
                    else {
                        $inner_value = qq("$inner_value") if $inner_value =~ /\s/;
                        push @query, ($inner_key eq '!=' ? '-' : '')
                                . "$keyword$tokens{$inner_key}$inner_value";
                            }
                }
            }
            elsif (ref $value eq 'ARRAY') {
                foreach my $or (@$value) {
                    $or = 'none' unless defined $or;
                    $or = qq("$or") if $or =~ /\s/;
                    push @query, "$keyword:$or";
                }
            }
            else {
                die 'Net::Zendesk: unsuported reference ' . ref($value) . '. Please use either a scalar or an ARRAY/HASH reference as a value for ' . $keyword;
            }
        }
        else {
            $value = 'none' unless defined $value;
            $value = qq("$value") if $value =~ /\s/;
            push @query, "$keyword:$value";
        }
    }
    return \@query;
}

sub _ua {
    my ($self) = @_;
    return $self->{_ua} if $self->{_ua};
    require Furl;
    require IO::Socket::SSL;
    IO::Socket::SSL->import;
    $self->{_ua} = Furl->new(
        headers => [
            'Accept'        => 'application/json',
            'Authorization' => 'Basic ' . $self->{_auth},
        ],
        ssl_opts => {
            SSL_verify_mode => SSL_VERIFY_PEER(),
        },
    );
}

1;
__END__

=head1 NAME

Net::Zendesk - Thin and lightweight interface for Zendesk's API

=head1 SYNOPSIS

    use Net::Zendesk;

    my $zen = Net::Zendesk->new(
        domain => 'obscura.zendesk.com',
        email  => 'yourvaliduser@example.com',
        token  => 'your_valid_zendesk_api_token',
    );

    $zen->create_ticket(
        {
            requester => {
                name  => 'The Customer',
                email => 'thecustomer@example.com',
            },
            subject => 'My printer is on fire!',
            comment => {
                body => 'The smoke is very colorful.'
            },
        },
        async => 'true',
    );

    my $result = $zen->search({
        status   => 'open',
        priority => { '>=' => 'normal' },
        created  => { '>' => '2017-01-23', '<' => '2017-03-01' },
        subject  => 'photo*',
        assignee => undef,
        -tags    => 'invoice',
    });

    use JSON::Maybe::XS;
    my $data = decode_json( $result->decoded_content );

=head1 DESCRIPTION

This module provides a very simple 1:1 interface to L<Zendesk's REST API|https://developer.zendesk.com/rest_api>.

While it currently provides very few methods (patches welcome!) it comes with
a C<make_request> method that hopefully will let you do pretty much anything
you want with the API.

=head1 API ACTIVATION

To use Zendesk's API, you must of course have a valid zendesk account, and
activate the API via your account's "Admin" settings. Once you do that, you
may chose between 'token' or 'password' authentication. Oauth is not currently
supported by Net::Zendesk.

=head1 CONSTRUCTION

    my $zen = Net::Zendesk->new(
        domain => 'obscura.zendesk.com',
        email  => 'yourvaliduser@example.com',
        token  => 'your_valid_zendesk_api_token',
    );

To instantiate Net::Zendesk objects You must specify your zendesk domain name.
This is usually C<somename.zendesk.com>. You must also specify the email you
use to connect to the account that is going to use the API and the
authentication method - either C<< token => 'yourtoken' >> or
C<< password => 'yourpassword' >>. We recommend creating a token for the
user in your Zendesk's API settings.

=head1 METHODS

=head2 create_ticket( \%ticket_data, %extra_options )

    $zen->create_ticket(
        {
            requester => {
                name  => 'The Customer',
                email => 'thecustomer@example.com',
            },
            subject => 'My printer is on fire!',
            comment => {
                body => 'The smoke is very colorful.'
            },
        },
        async => 'true',
    );

Use this method to create a single ticket. The example above includes all
required fields. Please refer to
L<Zendesk's documentation|https://developer.zendesk.com/rest_api/docs/core/tickets>
for a comprehensive list of all accepted fields.

B<DO NOT PASS> the C<ticket> root argument, just its contents, like in the
provided example above.

If you provide the extra option C<< async => 'true' >>, Zendesk's API will give the
response back quickly and queue a background job to do the actual work. This
might be an important speedup because ticket creation sometimes takes a while.

Finally, you may also set other extra options like C<< include => 'comment_count' >>
to include the C<comment_count> property in the returned json data.

=head2 search( \%params )

    my $result = $zen->search({
        type     => 'ticket',
        status   => ['new', 'open'],
        priority => { '>=' => 'normal' },
        created  => { '>' => '2017-01-23', '<' => '2017-03-01' },
        subject  => 'photo*',
        assignee => undef,
        -tags    => 'invoice',
        sort     => 'asc',
        order_by => 'ticket_type',
    });

Use this method to search for tickets, users and organizations. Zendesk's
search queries have their own unique syntax, so hopefully this method will
provide a good enough abstraction that you won't have to learn it :)

The example above illustrates all possible keyword manipulations. Let's
get into more detail:

B<filter by equality>:

    status => 'open'
    status => { '=' => 'open' } # same thing

    status => ['new', 'open'],            # new OR open
    status => { '=' => ['open', 'new'] }  # same
    status => { 'or' => ['open', 'new'] } # same

    tags => { 'and' => ['foo', 'bar'] }   # foo AND bar

B<filter by inequality>:

    priority => { '>' => 'normal' }
    created  => { '>=' => '2017-01-01', '<' => DateTime->today->ymd }

Note: when searching by date and time, use C<YYYY-MM-DD> or
ISO8601 syntax (C<YYYY-MM-DDThh:mm:ss+hh:mm>). You can also specify
times relative to the present moment using I<hours>, I<minutes>, I<days>,
I<weeks>, I<months> or I<years>, e.g. C<< created { '>' => '4hours' } >>.

B<filter by properties that contain no data>:

    assignee => undef
    assignee => 'none'   # same

B<filter by wildcard>:

    subject  => 'photo*'  # photo, photograph, photography, etc.

Note: not all fields are searcheable with wildcards. Please refer to
L<Zendesk's reference documentation|https://support.zendesk.com/hc/en-us/articles/203663226>
for the updated list of fields.

B<excluding items>:

    -tags => 'invoice'
    tags => { '!=' => 'invoice' }  # same

Just prepend the keyword with "C<->".

B<sorting and ordering>:

    order_by => 'created'
    sort     => 'desc'     # 'asc' or 'desc'

At the time of this writing you could sort ONLY by I<created>, I<commented>,
I<priority>, I<status> and I<ticket_type>. Please refer to
L<Zendesk's documentation|https://support.zendesk.com/hc/en-us/articles/203663226>
for the updated list.

=head2 make_request( $type, $path, \%params )

If you need to make a request that is not covered by a method above, you may
use this one. It takes 3 arguments:

=over 4

=item * B<$type> - either 'GET', 'POST', 'PUT' or 'DELETE'.

=item * B<$path> - the ENDING of the route to access. For example:
C<tickets/create_many.json> instead of C</api/v2/tickets/create_many.json>.

=item * B<\%params> - hashref containing the complete structure to be
converted to JSON and sent with the request.

=back

The response is a regular L<HTTP::Response> which you can check for
C<is_success>, C<decoded_content>, etc.

B<NOTE:> If you think other people might benefit from a named method
wrapping your request, please consider providing a patch to this module.
Thank you! :)

=head1 AUTHOR

Breno G. de Oliveira C<< <garu at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2017 Breno G. de Oliveira C<< <garu at cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.

