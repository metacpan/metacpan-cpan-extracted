package Nginx::Simple::Dispatch;

use Exporter;
use strict;

use Nginx::Simple;
use Nginx::Simple::Dispatcher;

# Configure exporter.
our @ISA    = qw(Exporter Nginx::Simple::Dispatcher);
our @EXPORT = (@Nginx::Simple::HTTP_STATUS_CODES);

our $VERSION = '0.02';

=head1 NAME

Nginx::Simple::Dispatch - Easy to use dispatcher interface for "--with-http_perl_module"

=head1 SYNOPSIS

For an "instant working example" please see the ./testdrive-example directory.

MainPage.pm:

   package MainPage;

   # app_path is where the application's URI begins
   # auto_import allows for lazyloading of application modules
   use Nginx::Simple::Dispatch( app_path => '/foo', auto_import => 1 );
   use strict;

   sub index :Index {
       my $self = shift;

       $self->print('I am the main page people will see.');
   }

   sub about :Action {
       my $self = shift;

       $self->print('Let us pretend the about page goes here, shall we?');
   }

   sub error {
       my $self = shift;
       my $self->get_error;
       my @stack = $self->error_stack;

       $self->status(500);
       $self->print('Something blew up! Kaboooooom!<hr>');
       $self->print("Details: <pre>$error</pre>");

       $self->cleanup;
   }

   sub bad_dispatch {
       my $self = shift;
       my $error = shift;

       $self->status(404);
       $self->print('Page not found.');
   }

   # do something after we do something
   sub cleanup
   {
       warn "[looging dragons: good]\n";
   }

   1;

MainPage/weather.pm

   package MainPage::weather;

   use base 'MainPage';
   use strict;

   sub index :Index {
       my $self = shift;

       $self->print("zap zap ook");
   }

   sub corn :Action {
       my $self = shift;

       $self->print("men");
   }

   1;

=cut

sub import
{
    my ($class, %params) = @_;
    my $caller = caller;

    # inject a handler method
    {
        no strict 'refs';

        my $caller_isa = "$caller\::ISA";

        @{$caller_isa} = qw(
            Nginx::Simple
            Nginx::Simple::Dispatcher
        );

        *{"$caller\::handler"} = sub {
            return local_dispatch(
                shift, 
                class         => $caller,
                app_path      => $params{app_path},
                auto_import   => $params{auto_import},
                auto_redirect => $params{auto_redirect},
            );
        };
    }

    __PACKAGE__->export_to_level(1, $class);
}

# where do we dispatch to

sub local_dispatch
{
    my ($self, %params) = @_;
    my $class    = $params{class};
    my $app_path = $params{app_path};
    my $path     = $self->uri;

    # trip the app_path off $path, when applicable
    $path =~ s/^$app_path// if $app_path;

    my $dispatch_data = 
        __PACKAGE__->dig_for_dispatch(
            class       => $class,
            path        => $path,
            auto_import => $params{auto_import},
        );

    # ensure indexes always end in a slash
    if ($params{auto_redirect} and $dispatch_data->{index} and $path !~ /\/$/)
    {
        $self->status(302);
        $self->header_out(Location => $self->uri . '/');
        $self->send_http_header;

        return;
    }

    if ($dispatch_data->{error} eq 'bad_dispatch')
    {
        return dispatch(
            $self, 
            class  => $class,
            method => 'bad_dispatch',
            bless  => 1,
        );
    }
    elsif ($dispatch_data->{error})
    {
        return dispatch(
            $self, 
            class  => $class,
            method => 'error',
            error  => $dispatch_data->{error},
            bless  => 1,
        );
    }
    else # prepare to dispatch for real
    {
        return dispatch(
            $self,
            class      => $dispatch_data->{class},
            method     => $dispatch_data->{method},
            base_class => $class,
            bless      => 1,
        );
    }
}

=head1 Author

Michael J. Flickinger, C<< <mjflick@gnu.org> >>

=head1 Copyright & License

You may distribute under the terms of either the GNU General Public
License or the Artistic License.

=cut

1;
