package Net::Fluidinfo;
use Moose;

use LWP::UserAgent;
use HTTP::Request;
use URI;
use Digest::MD5 'md5_base64';

use Net::Fluidinfo::Object;
use Net::Fluidinfo::Namespace;
use Net::Fluidinfo::Tag;
use Net::Fluidinfo::Permission;
use Net::Fluidinfo::User;

our $VERSION           = '0.45';
our $USER_AGENT        = "Net::Fluidinfo/$VERSION ($^O)";
our $DEFAULT_PROTOCOL  = 'HTTP';
our $DEFAULT_HOST      = 'fluiddb.fluidinfo.com';
our $SANDBOX_HOST      = 'sandbox.fluidinfo.com';
our $JSON_CONTENT_TYPE = 'application/json';

has protocol => (is => 'rw', isa => 'Str', default => $DEFAULT_PROTOCOL);
has host     => (is => 'rw', isa => 'Str', default => $DEFAULT_HOST);
has username => (is => 'rw', isa => 'Maybe[Str]', default => sub { $ENV{FLUIDINFO_USERNAME} });
has password => (is => 'rw', isa => 'Maybe[Str]', default => sub { $ENV{FLUIDINFO_PASSWORD} });
has ua       => (is => 'ro', isa => 'LWP::UserAgent', writer => '_set_ua');
has user     => (is => 'ro', isa => 'Net::Fluidinfo::User', lazy_build => 1);
has md5      => (is => 'rw', isa => 'Bool');

sub BUILD {
    my ($self, $attrs) = @_;

    my $ua = LWP::UserAgent->new(agent => $USER_AGENT);
    if ($attrs->{trace_http} || $attrs->{trace_http_requests}) {
        $ua->add_handler("request_send",  sub { shift->dump; return });
    }
    if ($attrs->{trace_http} || $attrs->{trace_http_responses}) {
        $ua->add_handler("response_done",  sub { shift->dump; return });
    }
    $self->_set_ua($ua);
}

sub _build_user {
    my $self = shift;
    Net::Fluidinfo::User->get($self, $self->username);
}

sub new_for_testing {
    my ($class, %attrs) = @_;
    $class->new(username => 'test', password => 'test', host => $SANDBOX_HOST, %attrs);
}

sub _new_for_net_fluidinfo_test_suite {
    my ($class, %attrs) = @_;
    $class->new(username => 'net-fluidinfo', password => 'ai3hs45kl2', %attrs);
}

sub get {
    shift->request("GET", @_);
}

sub post {
    shift->request("POST", @_);
}

sub head {
    shift->request("HEAD", @_);
}

sub put {
    shift->request("PUT", @_);
}

sub delete {
    shift->request("DELETE", @_);
}

sub request {
    my ($self, $method, %opts) = @_;

    my $request = HTTP::Request->new;
    $request->authorization_basic($self->username, $self->password);
    $request->method($method);
    $request->uri($self->uri_for(%opts));

    if (exists $opts{headers}) {
        while (my ($header, $value) = each %{$opts{headers}}) {
            $request->header($header => $value);
        }
    }

    if (defined $opts{payload}) {
        $request->content($opts{payload});
        if ($self->md5) {
            # md5_base64 returns a string with 22 characters, we add padding
            # up to the next multiple of 4 by hand.
            $request->header('Content-MD5' => md5_base64($request->content) . '==');
        }
    }

    my $response = $self->ua->request($request);
    if ($response->is_success) {
        if (exists $opts{on_success}) {
            $opts{on_success}->($response);
        } else {
            1;
        }
    } else {
        if (exists $opts{on_failure}) {
            $opts{on_failure}->($response);
        } else {
            print STDERR $response->as_string;
            0;
        }
    }
}

sub uri_for {
    my ($self, %opts) = @_;

    my $uri = URI->new;
    $uri->scheme(lc $self->protocol);
    $uri->host($self->host);
    $uri->path($opts{path});
    $uri->query_form($opts{query}) if exists $opts{query};
    $uri;
}

sub headers_for_json {
    return {
        'Accept'       => $JSON_CONTENT_TYPE,
        'Content-Type' => $JSON_CONTENT_TYPE
    };
}

sub accept_header_for_json {
    return {
        'Accept' => $JSON_CONTENT_TYPE
    }
}

sub content_type_header_for_json {
    return {
        'Content-Type' => $JSON_CONTENT_TYPE
    }
}

#
# -- Convenience shortcuts ----------------------------------------------------
#

sub get_object {
    print STDERR "get_object has been deprecated and will be removed, please use get_object_by_id instead\n";
    &get_object_by_id;
}

sub get_object_by_id {
    Net::Fluidinfo::Object->get_by_id(@_);
}

sub get_object_by_about {
    Net::Fluidinfo::Object->get_by_about(@_);
}

sub search {
    Net::Fluidinfo::Object->search(@_);
}

sub get_namespace {
    Net::Fluidinfo::Namespace->get(@_);
}

sub get_tag {
    Net::Fluidinfo::Tag->get(@_);
}

sub get_permission {
    Net::Fluidinfo::Permission->get(@_);
}

sub get_user {
    Net::Fluidinfo::User->get(@_);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;


__END__

=head1 NAME

Net::Fluidinfo - A Perl interface to Fluidinfo

=head1 SYNOPSIS

 use Net::Fluidinfo;

 # Predefined Fluidinfo client for playing around, points
 # to the sandbox with user test/test
 $fin = Net::Fluidinfo->new_for_testing;
 $fin = Net::Fluidinfo->new_for_testing(trace_http => 1);

 # Fluidinfo client pointing to production
 $fin = Net::Fluidinfo->new(username => 'username', password => 'password');

 # Fluidinfo taking credentials from environment variables
 # FLUIDINFO_USERNAME and FLUIDINFO_PASSWORD
 $fin = Net::Fluidinfo->new;

 # Content-MD5 headers with checksums for requests with payload
 $fin = Net::Fluidinfo->new(md5 => 1)

 # Resource getters
 $object     = $fin->get_object_by_id($id, about => 1);
 $object     = $fin->get_object_by_about($about);
 $ns         = $fin->get_namespace($path, description => 1);
 $tag        = $fin->get_tag($path, description => 1);
 $permission = $fin->get_permission($category, $path_or_has_path, $action);
 $user       = $fin->get_user($username);

 # Object search
 @ids = $fin->search("has fxn/rating");

=head1 DESCRIPTION

C<Net::Fluidinfo> provides an interface to the Fluidinfo API.

The documentation of Net::Fluidinfo does not explain Fluidinfo, though there are
links to relevant pages in the documentation of each class.

If you want to get familiar with Fluidinfo please check these pages:

=over

=item Fluidinfo high-level description

L<http://doc.fluidinfo.com/fluidDB/>

=item Fluidinfo API documentation

L<http://doc.fluidinfo.com/fluidDB/api/>

=item Fluidinfo API specification

L<http://api.fluidinfo.com/fluidDB/api/*/*/*>

=item Fluidinfo Essence blog posts

L<http://blogs.fluidinfo.com/fluidDB/category/essence/>

=head1 USAGE

=head2 Class Methods

=over

=item Net::Fluidinfo->new(%attrs)

Returns an object for communicating with Fluidinfo.

This is a wrapper around L<LWP::UserAgent> and does not validate
credentials in the very constructor. If they are wrong requests
will fail when performed.

Attributes and options are:

=over

=item username

Your username in Fluidinfo. If not present uses the value of the
environment variable FLUIDINFO_USERNAME.

=item password

Your password in Fluidinfo. If not present uses the value of the
environment variable FLUIDINFO_PASSWORD.

=item protocol

Either 'HTTP' or 'HTTPS'. Defaults to 'HTTP'.

=item host

The Fluidinfo host. Defaults to I<fluiddb.fluidinfo.com>.

=item md5

If this flag is true requests with payload get a Content-MD5
header with a checksum.

=item trace_http_requests

A flag, logs all HTTP requests if true.

=item trace_http_responses

A flag, logs all HTTP responses if true.

=item trace_http

A flag, logs all HTTP requests and responses if true. (Shorthand for
enabling the two above.)

=back

=item Net::Fluidinfo->new_for_testing

Returns a C<Net::Fluidinfo> instance pointing to the sandbox with
"test"/"test". The host of the sandbox can be checked in the package
variable C<$Net::Fluidinfo::SANDBOX_HOST>.

=back

=head1 Instance Methods

=over

=item $fin->username

=item $fin->username($username)

Gets/sets the username.

=item $fin->password

=item $fin->password($password)

Gets/sets the password.

=item $fin->protocol

=item $fin->protocol($protocol)

Gets/sets the protocol, either 'HTTP' or 'HTTPS'.

=item $fin->ua

Returns the instance of L<LWP::UserAgent> used to communicate with Fluidinfo.

=item $fin->user

Returns the user on behalf of whom fin is doing calls. This attribute
is lazy loaded.

=item $fin->get_object_by_id

Convenience shortcut for C<Net::Fluidinfo::Object::get_by_id>, see L<Net::Fluidinfo::Object>.

=item $fin->get_object_by_about

Convenience shortcut for C<Net::Fluidinfo::Object::get_by_about>, see L<Net::Fluidinfo::Object>.

=item $fin->search

Convenience shortcut for C<Net::Fluidinfo::Object::search>, see L<Net::Fluidinfo::Object>.

=item $fin->get_namespace

Convenience shortcut for C<Net::Fluidinfo::Namespace::get>, see L<Net::Fluidinfo::Namespace>.

=item $fin->get_tag

Convenience shortcut for C<Net::Fluidinfo::Tag::get>, see L<Net::Fluidinfo::Tag>.

=item $fin->get_permission

Convenience shortcut for C<Net::Fluidinfo::Permission::get>, see L<Net::Fluidinfo::Permission>.

=item $fin->get_user

Convenience shortcut for C<Net::Fluidinfo::User::get>, see L<Net::Fluidinfo::User>.

=back

=head1 AUTHOR

Xavier Noria (FXN), E<lt>fxn@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2012 Xavier Noria

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
