package Net::MailChimp {
    use Moo;
    use Mojo::UserAgent;
    use Carp qw/croak confess/;
    use List::Util qw/first/;
    use Mojo::Util qw/url_escape url_unescape/;
    use Digest::MD5 qw/md5_hex/;
    use namespace::clean;
    use version;
    use v5.36;

    our $VERSION = qv("v0.2.0");

    has endpoint_uri => ( is => 'ro', default => sub {
        'https://' . $_[0]->dc . '.api.mailchimp.com/' . $_[0]->api_version . '/'
    } );
    has dc => ( is => 'ro' );
    has api_key => ( is => 'ro' );
    has api_version => ( is => 'ro', default => '3.0' );
    has request_timeout => ( is => 'ro', default => sub { 20 } );
    has connect_timeout => ( is => 'ro', default => sub { 15 } );
    has ua => ( is => 'ro', lazy => 1, default => sub {
        Mojo::UserAgent->new()->connect_timeout($_[0]->connect_timeout)->inactivity_timeout($_[0]->request_timeout)
    } );

    sub BUILD {
        my ($self, $args) = @_;

        croak 'Please provide dc' if !exists $args->{dc};
        croak 'Please provide api_key' if !exists $args->{api_key};
    }

    sub request($self, $path, $method, $args = {}) {
        croak 'Please provide path' if !defined $path;
        croak 'Invalid path' if $path !~ m/\w+/xs;
        $method = $self->_validate_method($method);

        my $reqargs = {
            %$args,
        };

        my $datatransport = $method eq 'get' ? 'form' : 'json';

        my $res = $self->ua->$method( $self->endpoint_uri . "$path" =>
            {
                Authorization => 'Bearer ' . $self->api_key,
            },
            $datatransport => $reqargs
        )->result;

        # We have the caller handle errors, as some like 400-not_found can happen
        if ( !$res->is_success ) {
            return { httpstatus => $res->code, message => $res->body };
        }

        return $res->json;
    }

    sub md5($self, $string) {
        return md5_hex($string);
    }

    sub md5address($self, $string) {
        return $self->md5(lc $string);
    }

    sub _validate_method($self, $method) {
        confess 'Invalid-method' if !defined first { $_ eq uc($method) } qw/GET POST PUT DELETE/;
        return lc $method;
    }
}

1;

=head1 NAME

Net::MailChimp - Perl library with MINIMAL interface to use MailChimp API.

=head1 SYNOPSIS

    use Net::MailChimp;

    my $mc = Net::MailChimp->new(
        api_key         => 'xxxxxxxx'
        dc              => 'us21',
        version         => '3.0',      # Optional, default is 3.0
    );

    my $res;

    # md5address() turns lowerscase and returns MD5, as MailChimp wants
    my $mailhash = $mc->md5address('test@test.com');

    my $res = $mch->request('lists/00000/members/'.$mailhash, 'GET');
    # The module will never die, as most MailChimp errors require processing by the caller
    say $res->{message} if $res->{httpstatus};
    say $res->{status}; # subscribed, pending, unsubscribed, cleaned

    $mch->request('lists/00000/members/',  'POST', {
        email_address   => 'test2@test.com',
        {
            status      => 'pending',
            merge_fields => {
                FNAME       => 'Test1',
            }
        }
    });


=head1 DESCRIPTION

This is HIGHLY EXPERIMENTAL and in the works, do not use for now.

=head1 AUTHOR

Michele Beltrame, C<mb@blendgroup.it>

=head1 LICENSE

This library is free software under the Artistic License 2.0.

=cut
