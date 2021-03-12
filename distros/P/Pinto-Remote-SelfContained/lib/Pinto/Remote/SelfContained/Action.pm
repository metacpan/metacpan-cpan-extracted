package
    Pinto::Remote::SelfContained::Action; # hide from PAUSE

use v5.10;
use Moo;

use JSON::MaybeXS qw(encode_json);
use Pinto::Remote::SelfContained::Request;
use Pinto::Remote::SelfContained::Result;
use Pinto::Remote::SelfContained::Types qw(Chrome Uri Username);
use Pinto::Remote::SelfContained::Util qw(current_time_offset);
use Types::Standard qw(ArrayRef Bool HashRef InstanceOf Maybe Str);
use URI;

use namespace::clean;

our $VERSION = '1.000';

with qw(
    Pinto::Remote::SelfContained::HasHttptiny
);

has chrome => (is => 'ro', isa => Chrome, required => 1);

has name => (is => 'ro', isa => Str, required => 1);
has root => (is => 'ro', isa => Uri, coerce => 1, required => 1);
has args => (is => 'ro', isa => HashRef, default => sub { {} });

has username => (is => 'ro', isa => Username, required => 1);
has password => (is => 'ro', isa => Maybe[Str], required => 1);

has error => (is => 'rw');

sub execute {
    my ($self, $streaming_callback) = @_;

    my $request = $self->_make_request;
    my $response = $self->_send_request($request, $streaming_callback);

    return $self->_make_result($response);
}

sub _make_result {
    my ($self, $response) = @_;

    return Pinto::Remote::SelfContained::Result->new
        if $response->{success};

    $self->error( $response->{content} );
    return Pinto::Remote::SelfContained::Result->new(was_successful => 0);
}

sub _make_request {
    my ($self, $action_name) = @_;

    $action_name //= $self->name;

    my $uri = URI->new( $self->root );
    $uri->path_segments('', 'action', lc $action_name);

    return Pinto::Remote::SelfContained::Request->new(
        username => $self->username,
        password => $self->password,
        method => 'POST',
        uri => $uri,
        body_parts => $self->_make_body_parts,
    );
}

sub _make_body_parts {
    my ($self) = @_;

    return [$self->_chrome_args, $self->_pinto_args, $self->_action_args];
}

sub _chrome_args {
    my ($self) = @_;

    my $chrome_args = {
        verbose => $self->chrome->verbose,
        color   => $self->chrome->color,
        palette => $self->chrome->palette,
        quiet   => $self->chrome->quiet,
    };

    return { name => 'chrome', data => encode_json($chrome_args) };
}

sub _pinto_args {
    my ($self) = @_;

    my $pinto_args = {
        username => $self->username,
        time_offset => current_time_offset(),
    };

    return { name => 'pinto', data => encode_json($pinto_args) };
}

sub _action_args {
    my ($self) = @_;

    my $action_args = $self->args;

    return { name => 'action', data => encode_json($action_args) };
}

sub _send_request {
    my ($self, $request, $streaming_callback) = @_;

    $request //= $self->_make_request;

    my $status = 0;
    my $buffer = '';
    my $callback = sub { $self->_response_callback( $streaming_callback, \$status, \$buffer, @_ ) };
    my $response = $self->httptiny->request( $request->as_request_items($callback) );

    $self->chrome->progress_done;

    return $response;
}

sub _response_callback {
    my ($self, $streaming_callback, $status_ref, $buffer_ref, $new_data, $partial_result) = @_;

    $partial_result->{content} .= $new_data;
    $$buffer_ref .= $new_data;

    while ($$buffer_ref =~ s/\A (.*) \n//x) {
        my $line = $1;
        if ($line eq '## Status: ok') {
            $$status_ref = 1;
        }
        elsif ($line eq '## -- ##') {
            # Null message; discard
        }
        elsif ($line eq '## . ##') {
            # Progress message
            $self->chrome->show_progress;
        }
        elsif ($line =~ m{^## (.*)}) {
            # Diagnostic message; emit as warning
            $self->chrome->diag("$1");
        }
        else {
            # Other: emit as text, and send to any streaming callback
            $self->chrome->show($line);
            $streaming_callback->($line) if $streaming_callback;
        }
    }
}

1;
__END__

=head1 NAME

Pinto::Remote::SelfContained::Action - base class for remote Actions

=head2 C<execute>

Runs this Action on the remote server by serializing itself and
sending a POST request to the server.

=head1 AUTHOR

Aaron Crane, E<lt>arc@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2020 Aaron Crane.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.

=cut
