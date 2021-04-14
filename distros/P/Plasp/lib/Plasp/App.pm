package Plasp::App;

use Devel::StackTrace;
use Encode;
use File::Temp qw(tempdir);
use HTTP::Date qw(time2str);
use Path::Tiny;
use Plack::Request;
use Plasp;
use Scalar::Util qw(blessed);
use Try::Catch;

use Role::Tiny;
use namespace::clean;

=head1 NAME

Plasp::App - Create Plasp Plack App!

=head1 SYNOPSIS

In C<MyApp.pm>

  package MyApp;

  use Moo;

  with 'Plasp::App';

  around new => sub {
    my ( $orig, $class ) = ( shift, shift );
    $class->$orig( @_ );
  };

  1;

In C<app.psgi>

  use MyApp;

  $app = MyApp->new;

=head1 DESCRIPTION

Use L<Plasp::App> as a L<Role::Tiny> to create a new PSGI app. Call the C<new>
class method and get a subroutine in return which will serve a PSGI application.

=head1 CLASS METHODS

=over

=item $class->new(%config)

You can pass in the configuration in C<new>

  $app = MyApp->new(
    ApplicationRoot => '/var/www',
    DocumentRoot    => 'root',
    Global          => 'lib',
    GlobalPackage   => 'MyApp',
    IncludesDir     => 'templates',
    MailHost        => 'localhost',
    MailFrom        => 'myapp@localhost',
    XMLSubsMatch    => '(?:myapp):\w+',
    Error404Path    => '/error404.asp',
    Error500Path    => '/error500.asp',
    Debug           => 0,
  );

=cut

around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;

    # Don't pass args to constructor. Instead pass to
    $class->config( @args );

    return $class->$orig();
};

sub new {
    my ( $class, @args ) = @_;

    $class->config( @args );

    return $class->psgi_app;
}

=item $class->config(%config)

You can even set or override the configuration in another context either before
or after initialization;

  $app = MyApp->new;

  MyApp->config(ApplicationRoot => '/var/www');
  MyApp->config(DocumentRoot    => 'html');
  MyApp->config(Global          => 'lib');
  MyApp->config(GlobalPackage   => 'MyApp');
  MyApp->config(IncludesDir     => 'templates');

=cut

# Create config global variable in order to configure app as class method
my %_config;

sub config {
    my ( $class, @args ) = @_;

    if ( @args ) {
        my %hash = ref $args[0] eq 'HASH' ? %{ $args[0] } : @args;
        my $last;
        for my $attr ( keys %hash ) {
            $_config{$attr} = $hash{$attr};
        }
        return defined $last ? $_config{$last} : undef;
    } else {
        return \%_config;
    }
}

=item $class->psgi_app

Alternatively, you can just call the C<psgi_app> class method, which is the
same as calling C<< $class->new >> without passing in any configuration.

  MyApp->config(
    ApplicationRoot => '/var/www',
    DocumentRoot    => 'root',
    Global          => 'lib',
    GlobalPackage   => 'MyApp',
    IncludesDir     => 'templates',
  );

  $app = MyApp->psgi_app;

=cut

my %_error_docs = (
    'plasp_error' => '<!DOCTYPE html>
<html>
<head>
    <title>Error</title>
</head>
<body>
    <h1>Internal Server Error</h1>
    %s
</body>
</html>',

    '500_error' => '<!DOCTYPE html>
<html>
<head>
<title>Error</title>
</head>
<body>
    <h1>Internal Server Error</h1>
    <p>
        Sorry, the page you are looking for is currently unavailable.<br/>
        Please try again later.
    </p>
</body>
</html>',

    '404_not_found' => '<!DOCTYPE html>
<html>
<head>
    <title>Page Not Found</title>
</head>
<body>
    <h1>Page Not Found</h1>
    <p>Sorry, the page you are looking does not exist.</p>
</body>
</html>'
);

# Create a global variable to cache ASP object
my $_asp;

sub psgi_app {
    my $class = shift;

    # Return a subroutine, which is called the PSGI app
    return sub {
        my $env = shift;

        # Create localized ENV because ASP modifies and assumes ENV being
        # populated with Request headers as in CGI
        local %ENV = %ENV;

        # Initialize and keep compiled code in this scope;
        my ( $compiled, $error_response );

        my $success = try {

            # Create new Plack::Request object
            my $req = Plack::Request->new( $env );

            # Reuse cached Plasp object, else create new
            if ( $_asp ) {
                $_asp->req( $req );
                $_asp->_cleaned_up( 0 );
            } else {
                $_asp = Plasp->new( %{ $class->config }, req => $req );
            }

            # Parse and compile the ASP code
            $compiled = $_asp->compile_file(
                path( $_asp->DocumentRoot, $req->path_info )->stringify
            );

            1;
        } catch {

            if ( $_asp && blessed( $_ ) ) {

                # Handle not found exception
                if ( $_->isa( 'Plasp::Exception::NotFound' ) ) {
                    $error_response = _not_found_response();
                } else {

                    # Handle code or compilation exception by loggin it
                    $_asp->error( sprintf( "Encountered %s error: %s",
                            $_->isa( 'Plasp::Exception::Code' )
                            ? 'application code'
                            : 'unknown compilation',
                            $_
                    ) ) unless $_asp->has_errors;

                    $error_response = _error_response( undef, '500_error' );
                }

            } else {

                # Plasp error due to error in Plasp code. $asp and $Response is
                # not reliable. This implies a bug in Plasp.
                Plasp->log->fatal( "Plasp error: $_" );

                $error_response = _error_response(
                    undef,
                    'plasp_error',
                    $class->config->{Debug} ? "<pre>$_</pre>" : ''
                );
            }

            # Ensure return value is false to signify failure
            return;
        };

        unless ( $success ) {
            $_asp->cleanup;

            return $error_response;
        }

        # Define a callback once server is ready to write data to client. The
        # callback is called and passed subroutine called a responder.
        my $callback = sub {

            # Setup a hash here holding references to various objects at this
            # scope, so that the closures for calling the responder will be
            # able to write to this scope.
            my %refs = ( responder => shift );

            # If a responder is passed in, that means streaming response is
            # supported so pass a closure to write out headers and body
            if ( $refs{responder} ) {
                $_asp->Response->_headers_writer(
                    sub { $refs{writer} = $refs{responder}->( \@_ ) }
                );
                $_asp->Response->_content_writer(
                    sub { $refs{writer}->write( @_ ) }
                );
            }

            # Keep the stacktrace available for exception processing
            my $stack_trace;
            $success = try {
                local $SIG{__DIE__} = sub {
                    $stack_trace = Devel::StackTrace->new(
                        skip_frames    => 1,
                        indent         => 1,
                        ignore_package => __PACKAGE__,
                    )->as_string;
                };
                local $SIG{__WARN__} = sub {
                    $_asp->log->warn(
                        $_[0],
                        stack_trace => Devel::StackTrace->new(
                            skip_frames    => 1,
                            indent         => 1,
                            ignore_package => __PACKAGE__,
                        )->as_string
                    );
                };

                # Execute the code, render the ASP page
                $_asp->GlobalASA->Script_OnStart;
                $_asp->execute( $compiled->{code} );

                1;
            } catch {
                if ( blessed( $_ ) ) {
                    if ( $_->isa( 'Plasp::Exception::Code' )
                        || ( !$_->isa( 'Plasp::Exception::End' )
                            && !$_->isa( 'Plasp::Exception::Redirect' ) ) ) {
                        $_asp->error(
                            "Encountered application error: $_",
                            stack_trace => $stack_trace,
                        );
                    }

                    # Plasp application reported errors
                    $error_response = _error_response(
                        $refs{responder},
                        '500_error'
                    ) if $_asp->has_errors;
                }

                return;
            } finally {
                if ( $_asp ) {

                    # Do one final $Response->Flush
                    my $resp = $_asp->Response;
                    $resp->Flush;

                    if ( $refs{writer} ) {

                        # Close the writer so as to conclude the response to the
                        # client
                        $refs{writer}->close;

                    } else {

                        # If not using streaming response, then save response
                        # for reference later
                        $refs{status}  = $resp->Status;
                        $refs{headers} = $resp->Headers;
                        $refs{body}    = [ $resp->Output ];
                    }

                    # Ensure destruction!
                    $_asp->cleanup;
                }
            };

            # If a responder was passed in, then no need to return anything,
            # but otherwise need to return the PSGI three-element array
            unless ( $refs{responder} ) {
                return $success
                    ? \( @refs{qw(status headers body)} )
                    : $error_response;
            }
        };

        if ( $_asp->req->env->{'psgi.streaming'} ) {

            # Return the callback subroutine if streaming is supported
            return $callback;
        } else {

            # Manually call the callback to get response
            return $callback->();
        }

    }
}

# Construct error response
sub _error_response {
    my $responder  = shift;
    my $error_type = shift;

    my $body = sprintf( $_error_docs{$error_type}, @_ );
    if ( $_asp ) {
        $_asp->Response->Status( 500 );
        $_asp->Response->ContentType( 'text/html' );

        if ( $_asp->Error500Path ) {
            my $compiled = $_asp->compile_file(
                path( $_asp->DocumentRoot, $_asp->Error500Path )->stringify
            );
            $_asp->execute( $compiled->{code} );

            $body = $_asp->Response->Output;
        } else {

            $_asp->Response->Output( $body );
        }
    }

    # If a responder is defined, then the responder would already have written
    # out the error Response, but otherwise return the three-element array
    unless ( $responder ) {
        return [ 500, [ 'Content-Type' => 'text/html' ], [$body] ];
    }
}

# Construct not found response
sub _not_found_response {
    my $body;
    if ( $_asp && $_asp->Error404Path ) {

        my $compiled = $_asp->compile_file(
            path( $_asp->DocumentRoot, $_asp->Error404Path )->stringify
        );
        $_asp->execute( $compiled->{code} );

        $body = $_asp->Response->Output;
    } else {
        $body = $_error_docs{'404_not_found'};
    }

    return [ 404, [ 'Content-Type' => 'text/html' ], [$body] ];
}


1;

=back

=head1 SEE ALSO

=over

=item * L<Plasp>

=back
