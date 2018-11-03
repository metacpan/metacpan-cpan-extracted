package Net::OpenStack::Client::Request;
$Net::OpenStack::Client::Request::VERSION = '0.1.4';
use strict;
use warnings;

use base qw(Exporter);
use Readonly;

Readonly our @SUPPORTED_METHODS => qw(DELETE GET PATCH POST PUT);
Readonly our @METHODS_REQUIRE_OPTIONS => qw(PATCH POST PUT);

our @EXPORT = qw(mkrequest);
our @EXPORT_OK = qw(parse_endpoint @SUPPORTED_METHODS @METHODS_REQUIRE_OPTIONS $HDR_X_AUTH_TOKEN);

use overload bool => '_boolean';

Readonly our $HDR_ACCEPT => 'Accept';
Readonly our $HDR_ACCEPT_ENCODING => 'Accept-Encoding';
Readonly our $HDR_CONTENT_TYPE => 'Content-Type';
Readonly our $HDR_X_AUTH_TOKEN => 'X-Auth-Token';
Readonly our $HDR_X_SUBJECT_TOKEN => 'X-Subject-Token';


Readonly my %DEFAULT_HEADERS => {
    $HDR_ACCEPT => 'application/json, text/plain',
    $HDR_ACCEPT_ENCODING => 'identity, gzip, deflate, compress',
    $HDR_CONTENT_TYPE => 'application/json',
};


=head1 NAME

Net::OpenStack::Client::Request is an request class for Net::OpenStack.

Boolean logic is overloaded using C<_boolean> method (as inverse of C<is_error>).

=head2 Public functions

=over

=item mkrequest

A C<Net::OpenStack::Client::Request> factory

=cut

sub mkrequest
{
    return Net::OpenStack::Client::Request->new(@_);
}

=item parse_endpoint

Parse C<endpoint> and look for templates and parameters.

Return (possibly modified) endpoint, arrayref of template names
and arrayref of parameter names.

If C<logger> is passed, report an error and return; else die on failure.

=cut

sub parse_endpoint
{
    my ($origendpoint, $logger) = @_;

    # strip parameters
    my ($endpoint, $paramtxt) = $origendpoint =~ /^([^?]+)(?:\?([^?]+))?$/;

    # List of key names that have to be passed
    my (@templates, @params);
    foreach my $template ($endpoint =~ m#\{([^/]+)}#g) {
        # only add once; order is not that relevant
        push(@templates, $template) if (!grep {$_ eq $template} @templates);
    };

    foreach my $kv (split(/&/, $paramtxt || '')) {
        if ($kv =~ m/^([^=]+)=/) {
            push(@params, $1);
        } else {
            # invalid
            my $msg = "invalid parameter kv $kv for origendpoint $origendpoint";
            if ($logger) {
                $logger->error($msg);
                return;
            } else {
                die $msg;
            }
        }
    }

    return $endpoint, \@templates, \@params;
}


=pod

=back

=head2 Public methods

=over

=item new

Create new request instance from options for command C<endpoint>
and REST HTTP C<method>.

The C<endpoint> is the URL to use (can be templated with C<tpls>)

Options

=over

=item tpls: template names and values

=item opts: optional arguments

=item error: an error (no default)

=item service: service name

=item version: service version

=item result: result path for the response

=back

=cut

sub new
{
    my ($this, $endpoint, $method, %opts) = @_;
    my $class = ref($this) || $this;
    my $self = {
        endpoint => $endpoint,

        tpls => $opts{tpls} || {},
        params => $opts{params} || {},
        opts => $opts{opts} || {},
        paths => $opts{paths} || {},
        raw => $opts{raw},

        rest => $opts{rest} || {}, # options for rest

        error => $opts{error}, # no default

        service => $opts{service},
        version => $opts{version},
        result => $opts{result},
    };

    if (grep {$method eq $_} @SUPPORTED_METHODS) {
        $self->{method} = $method;
    } else {
        $self->{error} = "Unsupported method $method";
    }

    bless $self, $class;

    return $self;
};

=item endpoint

Parses the endpoint attribute, look for any templates, and replace them with values
from C<tpls> attribute hashref.
Any parameters defined in the endpoint are removed, and only those that
are present in the C<params> attribute are readded with the values from the attribute.

The data can contain more keys than what is required
for templating, those keys and their values will be ignored.

This does not modify the endpoint attribute.

Return templated endpoint on success or undef on failure.

If host is defined, try to make a full URL

=over

=item if you provide only fqdn, make a https://<fqdn>/v<version/<endpoint>

=item if you provide URL, check for version suffix, return <url>/<endpoint>

=back

=cut


sub endpoint
{
    my ($self, $host) = @_;

    # reset error attribute
    $self->{error} = undef;

    my ($endpoint, $templates, $params) = parse_endpoint($self->{endpoint});
    foreach my $template (@$templates) {
        my $pattern = '\{' . $template . '\}';
        if (exists($self->{tpls}->{$template})) {
            $endpoint =~ s#$pattern#$self->{tpls}->{$template}#g;
        } else {
            $self->{error} = "Missing template $template data to replace endpoint $self->{endpoint}";
            return;
        }
    }

    my @fparams;
    foreach my $param (sort @$params) {
        if (exists($self->{params}->{$param})) {
            push(@fparams, "$param=".$self->{params}->{$param});
        }
    }

    if (@fparams) {
        $endpoint =~ s/\/+$//;
        $endpoint .= '?'.join('&', @fparams);
    }

    if ($host) {
        my $url = $host;

        my $version_suffix = "v$self->{version}";
        $version_suffix =~ s/^v+/v/;

        if ($host !~ m/^http/) {
            $url = "https://$url/$version_suffix";
        } elsif ($host !~ m#/v[\d.]+/?$#) {
            $url .= "/$version_suffix";
        }

        $url =~ s#/+$##;
        $endpoint =~ s#^/+##;
        $endpoint = "$url/$endpoint";
    }

    return $endpoint;
}

=item opts_data

Generate hashref from options, to be used for JSON encoding.
If C<raw> attribute is defined, ignore all options and return it.

Returns empty hasref, even if no options existed.

=cut

sub opts_data
{
    my ($self) = @_;

    my $root;

    if ($self->{raw}) {
        # ignore all options passed
        $root = $self->{raw};
    } else {
        $root = {};
        foreach my $key (sort keys %{$self->{opts}}) {
            my @paths = @{$self->{paths}->{$key}};
            my $lastpath = pop(@paths);
            my $here = $root;
            foreach my $path (@paths) {
                # build tree
                $here->{$path} = {} if !exists($here->{$path});
                $here = $here->{$path};
            }
            # no intermediate variable with value
            $here->{$lastpath} = $self->{opts}->{$key};
        }
    }

    return $root;
}

=item headers

Return headers for the request.

Supported options:

=over

=item token: authentication token stored in X-Auth-Token

=item headers: hashref with headers to add that take precedence over the defaults.
Headers with an undef value will be removed.

=back

=cut

sub headers
{
    my ($self, %opts) = @_;

    my $headers = {%DEFAULT_HEADERS};

    while (my ($hdr, $value) = each %{$opts{headers} || {}}) {
        if (defined($value)) {
            $headers->{$hdr} = $value;
        } else {
            delete $headers->{$hdr};
        }
    }

    $headers->{$HDR_X_AUTH_TOKEN} = $opts{token} if defined $opts{token};

    return $headers;
}


=item is_error

Test if this is an error or not (based on error attribute).

=cut

sub is_error
{
    my $self = shift;
    return $self->{error} ? 1 : 0;
}

# Overloaded boolean, inverse of is_error
sub _boolean
{
    my $self = shift;
    return ! $self->is_error();
}

=pod

=back

=cut

1;
