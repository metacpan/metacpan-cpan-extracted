package Plack::App::FakeApache;
use Try::Tiny;
use strict;
use warnings;

use Plack::Util;
use Plack::Util::Accessor qw( authen_handler authz_handler response_handler handler dir_config root logger request_args request_class);
use CGI::Emulate::PSGI;

use parent qw( Plack::Component );
use attributes;

use Carp;
use Module::Load;
use Scalar::Util qw( blessed );
use Apache2::Const qw(OK DECLINED HTTP_OK HTTP_UNAUTHORIZED HTTP_NOT_FOUND);

our $VERSION = 0.06;

sub _get_phase_handlers
{
    my $self = shift;
    my $phase = shift;
    my $accessor = $phase.'_handler';
    my $handlers = $self->$accessor or return;
    return @{$handlers};
}

# RUN_FIRST
# Run until a handler returns something other than DECLINED...
sub _run_first
{
    my $self = shift;
    my $phase = shift;
    my $fake_req = shift;
    my $fallback_status = shift;


	# NOTE.  I don't think this will mess people around who don't use
	# CGI, but if it does this could be conditionally applied with a
	# boolean $fake_req->shim_cgi_brain_damage or something.

	# Mangle env to cope with certain kinds of CGI brain damage.
	my $env = $fake_req->plack_request->env;
	local %ENV = (%ENV, CGI::Emulate::PSGI->emulate_environment($env));
	# and stdin!
	local *STDIN  = $env->{'psgi.input'};


    my $status = OK;
    foreach my $handler ($self->_get_phase_handlers($phase))
    {
        try {
			$status = $handler->($fake_req);
		}
		  catch { 
			  die $_ unless $_ =~ /^EXIT 0$/;
		  };
        last if $status != DECLINED;
    }
    return (defined($status) and $status != DECLINED) ? $status : $fallback_status; # mod_perl seems to do this if all handlers decline
}

sub call {
    my ($self, $env) = @_;

    my %args = (
        env => $env,
        dir_config => $self->dir_config,
        request_class => $self->request_class || 'Plack::App::FakeApache::Request',
        %{$self->request_args || {}}
    );

    $args{root} = $self->root if defined $self->root;

    if ( $self->logger ) {
        my $logger  = $self->logger;
        $args{log} = $logger if blessed($logger) and !$logger->isa('IO::Handle');
        $args{log} ||= Plack::FakeApache::Log->new( logger => sub { print $logger @_ } );
    }
    my $request_class = $args{request_class};
    my $fake_req = $request_class->new(%args);

    my $status = $self->_run_handlers($fake_req);

    $fake_req->status($status == OK ? HTTP_OK : $status);
    return $fake_req->finalize;
}

sub _run_handlers
{
    my $self = shift;
    my $fake_req = shift;
    my $status;

    # TODO: More request phases here...

    $status = $self->_run_first('authen', $fake_req, HTTP_UNAUTHORIZED);
    return $status if $status != OK;

    $status = $self->_run_first('authz', $fake_req, HTTP_UNAUTHORIZED);
    return $status if $status != OK;

    # we wrap the call to $handler->( ... ) in tie statements so 
    # prints, etc are caught and sent to the right place
    tie *STDOUT, "Plack::App::FakeApache::Tie", $fake_req;
    $status = $self->_run_first('response', $fake_req, HTTP_NOT_FOUND);
    untie *STDOUT;
    return $status if $status != OK;

    # TODO: More request phases here...

    return OK;
}

sub prepare_app {
    my $self = shift;
    my $request_class = $self->request_class || 'Plack::App::FakeApache::Request';
    load $request_class;

    $self->response_handler($self->response_handler || $self->handler);

    foreach my $accessor ( qw(authen_handler authz_handler response_handler) )
    {
        my $handlers = $self->$accessor or next;
        my @handlers = ref($handlers) eq 'ARRAY' ? @{$handlers} : ($handlers);
        @handlers = map({ $self->_massage_handler($_) } @handlers);
        $self->$accessor([ @handlers ]);
    }

    carp "handler or response_handler not defined" unless $self->response_handler;

    # Workaround for mod_perl handlers doing CGI->new($r). CGI doesn't
    # know our fake request class, so we hijack CGI->new() and explicitly
    # pass the request query string instead...
    my $new = CGI->can('new');
    no warnings qw(redefine);
    *CGI::new = sub {
        my $request_class = $self->request_class || 'Plack::App::FakeApache::Request';

        if (blessed($_[1]) and $_[1]->isa($request_class)) {
            return $new->(CGI => $_[1]->env->{QUERY_STRING} || $_[1]->plack_request->content);
        }
        return $new->(@_);
    };

    return;
}

sub _massage_handler
{
    my $self = shift;
    my $handler = shift;
    my ($class, $method);
    if ( blessed $handler ) {
        $handler = sub { $handler->handler( @_ ) };
    } elsif ( my ($class, $method) = $handler =~ m/(.+)->(.+)/ ) {
        Plack::Util::load_class( $class );
        $handler = sub { $class->$method( @_ ) };
    } else {
        my $class  = $handler;
        Plack::Util::load_class( $class );
        my $method = eval { $class->can("handler") };
        if ( grep { $_ eq 'method' } attributes::get($method) ) {
            $handler = sub { $class->handler( @_ ) };
        } else {
            $handler = $method;
        }
    }
    return $handler;
}

package Plack::App::FakeApache::Tie;

sub TIEHANDLE {
    my $class = shift;
    my $r = shift;
    return bless \$r, $class;
}

sub PRINT  { my $r = ${ shift() }; $r->print(@_) }
sub WRITE  { my $r = ${ shift() }; $r->write(@_) }

1;

__END__

=head1 NAME

Plack::App::FakeApache - Wrapping mod_perl2 applications in Plack

=head1 SYNOPSIS

  use Plack::App::FakeApache;

  my $app = Plack::App::FakeApache->new( 
    response_handler => "My::ResponseHandler"
    dir_config => { ... }
  )->to_app;    

=head1 DESCRIPTION

Plack::App::FakeApache transforms a mod_perl2 application into
a PSGI application

=head1 NOTICE

This is Proof of Concept code originating in the mocking code developed to
test an internal very non-trivial mod_perl2 application. Features have been
added on a need to have basis.

This code has been extended to make a different non-trivial mod_perl
app work under plack too.  If you need to use this module for serious
work you will almost certainly need to read and modify the source.
Contributions welcomed.

=head1 CONFIGURATION

*_handler arguments support multiple "stacked" handlers if passed as an arrayref.

=over 4

=item authen_handler

=item authz_handler

=item response_handler (required)

=item handler (alias for response_handler)

Handlers for the respective request phases. Pass a blessed object, a class
name or use the C<Class-E<gt>method> syntax. See the mod_perl docs for calling
conventions.

=request_class

If you want to subclass Plack::App::FakeApache::Request do so here.
Make sure that your subclass inherits from
Plack::App::FakeApache::Request (duh).  This is for use in situations
where you've subclasssed Apache2::Request and want to make it work
under PSGI.

=item dir_config

Hash used to resolve $req->dir_config() requests

=item root

Root directory of the file system (optional, defaults to the current
working directory)

=item logger

The destination of the log messages (i.e. the errorlog). This should be a
file handle

=item request_args

Aditional args passed to the fake request object. E.g. auth_name and auth_type.

=back

=head1 APACHE METHODS

The following methods from L<Apache2::RequestRec> and mixins are supported:

=over 4

=item headers_in

=item headers_out

=item subprecess_env

=item dir_config

=item method

=item unparsed_uri

=item uri

=item user

=item hostname

=item content_type

=item content_encoding

=item status

=item log_reason (implemented as a no-op)

=item read

=item print

=item write

=item filename

=item construct_url

=item auth_type

=item auth_name

=item is_initial_req

=back

=head1 PLACK METHODS

A few methods have been added to the interface to enable interaction with
Plack:

=over 4

=item plack_request

Returns the underling L<Plack::Request> object

=item plack_response

Returns the underlying L<Plack::Response> object. During the request phase
this is incomplete.

=item finalize

Fills information into the response object and finalizes it.

=back

=head1 MOD_PERL OVERRIDES

mod_perl overrides exit with L<ModPerl::Util>.  The way I've handled
(kd) this was that in order to override the horrors of overriding
CORE::GLOBAL::EXIT was to have a subroutine main::legacy_exit defined
in the startup.pl or in the .psgi file which calls die "EXIT $number".
Meanwhile this specific exception is ignored by
Plack::APP::FakeApache.


=head1 AUTHOR

Peter Makholm, L<peter@makholm.net>

Override subrequest, more cgi.pm support and exit support by Kieren Diment L<zarquon@cpan.org>.

=cut
