package Plack::App::CGIBin::Streaming;

use 5.014;
use strict;
use warnings;
our $VERSION = '0.06';

BEGIN {
    # this works around a bug in perl

    # In Perl (at least up to 5.18.0) the first assignment to $SIG{CHLD}
    # or $SIG{CLD} determines which name is later passed to the signal handler
    # on systems like Linux that support both names.
    # This hack tries to be the first such assignment in the perl program
    # and thus pin down that name.
    # Net::Server based servers like starman rely on "CHLD" to be passed to
    # the signal handler.
    local $SIG{CHLD}=$SIG{CHLD};
}

use parent qw/Plack::App::File/;
use CGI;
use CGI::Compile;
use File::Spec;
use Plack::App::CGIBin::Streaming::Request;
use Plack::App::CGIBin::Streaming::IO;

use Plack::Util::Accessor qw/request_class
                             request_params
                             preload/;

sub allow_path_info { 1 }

sub prepare_app {
    my $self=shift;

    # warn "\n\nprepare_app [@{$self->preload}]\n\n";

    $self->SUPER::prepare_app;
    return unless $self->preload;

    for my $pattern (@{$self->preload}) {
        my $pat=($pattern=~m!^/!
                 ? $pattern
                 : $self->root.'/'.$pattern);
        # warn "  pat=$pat\n";
        for my $fn (glob $pat) {
            # warn "preloading $fn\n";
            $self->{_compiled}->{$fn} = do {
                local $0 = $fn;            # keep FindBin happy

                $self->mkapp(CGI::Compile->compile($fn));
            };
        }
    }
}

our $R;
sub request { return $R }

sub mkapp {
    my ($self, $sub) = @_;

    return sub {
        my $env = shift;
        return sub {
            my $responder = shift;

            local $env->{SCRIPT_NAME} = $env->{'plack.file.SCRIPT_NAME'};
            local $env->{PATH_INFO}   = $env->{'plack.file.PATH_INFO'};

            my @env_keys = grep !/^(?:plack|psgi.*)\./, keys %$env;
            local @ENV{@env_keys} = @{$env}{@env_keys};

            select STDOUT;
            $|=0;
            binmode STDOUT, 'via(Plack::App::CGIBin::Streaming::IO)';

            my $class = ($self->request_class //
                         'Plack::App::CGIBin::Streaming::Request');
            local $R = $class->new
                (
                 env => $env,
                 responder => $responder,
                 @{$self->request_params//[]},
                );

            local *STDIN = $env->{'psgi.input'};
            binmode STDIN, 'via(Plack::App::CGIBin::Streaming::IO)';

            # CGI::Compile localizes $0 and %SIG and calls
            # CGI::initialize_globals.
            my $err = eval {
                local ($/, $\) = ($/, $\);
                $sub->() // '';
            };
            my $exc = $@;
            $R->suppress_flush=1;   # turn off normal flush behavior
            $R->binmode_ok=1;       # allow binmode to remove the layer
            {
                no warnings 'uninitialized';
                binmode STDOUT;
                binmode STDIN;
            }
            unless (defined $err) {
                warn "$env->{REQUEST_URI}: It's too late to set a HTTP status"
                    if $R->status_written;
                $R->status(500);
            }
            $R->finalize;
            unless (defined $err) { # $sub died
                warn "$env->{REQUEST_URI}: $exc";
            }
        };
    };
}

sub serve_path {
    my($self, $env, $file) = @_;

    die "need a server that supports streaming" unless $env->{'psgi.streaming'};

    my $app = $self->{_compiled}->{$file} ||= do {
        local $0 = $file;            # keep FindBin happy

        $self->mkapp(CGI::Compile->compile($file));
    };

    $app->($env);
}

1;

__END__

=encoding utf-8

=head1 NAME

Plack::App::CGIBin::Streaming - allow old style CGI applications to use
the plack streaming protocol

=head1 SYNOPSIS

in your F<app.psgi>:

 use Plack::App::CGIBin::Streaming;

 Plack::App::CGIBin::Streaming->new(root=>...)->to_app;

=head1 DESCRIPTION

With L<Plack> already comes L<Plack::App::CGIBin>.
C<Plack::App::CGIBin::Streaming> serves a very similar purpose.

So, why do I need another module? The reason is that L<Plack::App::CGIBin>
first collects all the output from your CGI scripts before it prints the
first byte to the client. This renders the following simple clock script
useless:

 use strict;
 use warnings;

 $|=0;

 my $boundary='The Final Frontier';
 print <<"EOF";
 Status: 200
 Content-Type: multipart/x-mixed-replace;boundary="$boundary";

 EOF

 $boundary="--$boundary\n";

 my $mpheader=<<'HEADER';
 Content-type: text/html; charset=UTF-8;

 HEADER

 for(1..100) {
     print ($boundary, $mpheader,
            '<html><body><h1>'.localtime()."</h1></body></html>\n");
     $|=1; $|=0;
     sleep 1;
 }

 print ($boundary);

Although multipart HTTP messages are quite exotic, there are situations
where you rather want to prevent this buffering. If your document is very
large for example, each instance of your plack server allocates the RAM
to buffer it. Also, you might perhaps send out the C<< <head> >> section
of your HTTP document as fast as possible to enable the browser load JS and
CSS while the plack server is still busy with producing the actual document.

C<Plack::App::CGIBin::Streaming> compiles the CGI scripts using
L<CGI::Compile> and provides a runtime environment similar to
C<Plack::App::CGIBin>. Compiled scripts are cached. For production
environments, it is possible to precompile and cache scripts at server
start time, see the C<preload> option below.

Every single request is represented as an object that inherits from
L<Plack::App::CGIBin::Streaming::Request>. This class mainly provides
means for handling response headers and body.

=head2 Options

The plack app is built as usual:

 $app=Plack::App::CGIBin::Streaming->new(@options)->to_app;

C<@options> is a list of key/value pairs configuring the app. The
C<Plack::App::CGIBin::Streaming> class inherits from L<Plack::App::File>.
So, everything recognized by this class is accepted. In particular, the
C<root> parameter is used to specify the directory where your CGI programs
reside.

Additionally, these parameters are accepted:

=over 4

=item request_class

specifies the class of the request object to construct for every request.
This class should implement the interface described in
L<Plack::App::CGIBin::Streaming::Request>. Best if your request class
inherits from L<Plack::App::CGIBin::Streaming::Request>.

This parameter is optional. By default
C<Plack::App::CGIBin::Streaming::Request> is used.

=item request_params

specifies a list of additional parameters to be passed to the request
constructor.

By default the request constructor is passed 2 parameters. This list is
appended to the parameter list like:

 $R = $class->new(
     env => $env,
     responder => $responder,
     @{$self->request_params//[]},
 );

=item preload

In a production environment, you probably want to use a (pre)forking server
to run the application. In this case is is sensible to compile as much
perl code as possible at server startup time by the parent process because
then all the children share the RAM pages where the code resides (by
copy-on-write) and you utilize your server resources much better.

One way to achieve that is to keep your CGI applications very slim and put
all the actual work into modules. These modules are then C<use>d or
C<require>d in your F<app.psgi> file.

As a simpler alternative you can specify a list of C<glob> patterns as
C<preload> value. C<Plack::App::CGIBin::Streaming> will then load and
compile all the scripts matching all the patterns when the app object is
created.

This technique has benefits and drawbacks:

=over 4

=item pro: more concurrent worker children in less RAM

see above

=item con: no way to reload the application on the fly

when your scripts change you have to restart the server. Without preloading
anything you could just kill all the worker children (or signal them to do
so after the next request).

=item pro/con: increased privileges while preloading

the HTTP standard port is 80 and, thus, requires root privileges to bind to.
scripts are preloaded before the server opens the port. So, even if it later
drops privilges, at preload time you still are root.

=back

=back

=head2 Runtime environment

Additional to the environment provided by L<CGI::Compile>, this module
provides:

=over 4

=item the global variable C<$Plack::App::CGIBin::Streaming::R>

For the request lifetime it contains the actual request object. This variable
is C<local>ized. There is also a way to access this variable as class method.

If you use a L<Coro> based plack server, make sure to replace the guts
of this variable when switching threads, see C<swap_sv()> in L<Coro::State>.

=item C<< Plack::App::CGIBin::Streaming->request >> or
C<Plack::App::CGIBin::Streaming::request>

This function/method returns the current request object or C<undef> if
called outside the request loop.

=item C<%ENV> is populated

everything from the plack environment except keys starting with C<plack>
or C<psgi.> is copied to C<%ENV>.

=item C<STDIN> and C<STDOUT>

Both, C<STDIN> and C<STDOUT> are configured to use the
L<Plack::App::CGIBin::Streaming::IO> PerlIO layer.
On output, the layer captures the data and sends it to the
request object. Flushing via C<$|> is also supported.
On input, the layer simply converts calls like C<readline STDIN>
into a method call on the underlying object.

You can use PerlIO layers to turn the handles into UTF8 mode.
However, refrain from using a simple C<binmode> to reverse the
effects of a prior C<binmode STDOUT, ':utf8'>. This won't pop
the L<Plack::App::CGIBin::Streaming::IO> layer but neither
will it turn off UTF8 mode. This is considered a bug that I don't
know how to fix. (See also below)

Reading from C<STDIN> using UTF8 mode is also supported.

=back

=head2 Pitfalls and workarounds

=head3 SIGCHLD vs. SIGCLD

During the implementation I found a wierd bug. At least on Linux, perl
supports C<CHLD> and C<CLD> as name of the signal that is sent when a child
process exits. Also, when Perl calls a signal handler, it passes the signal
name as the first parameter. Now the question arises, which name is passed
when a child exits. As it happens the first assignment to C<%SIG{CHLD}>
or C<$SIG{CLD}> determines that name for the rest of the lifetime of the
process. Now, several plack server implementations, e.g. L<Starman>,
rely on that name to be C<CHLD>.

As a workaround, C<Plack::App::CGIBin::Streaming> contains this code:

 BEGIN {
     local $SIG{CHLD}=$SIG{CHLD};
 }

If your server dies when it receives a SIGCHLD, perhaps the module is loaded
too late.

=head3 binmode

Sometimes one needs to switch STDOUT into UTF8 mode and back. Especially the
I<back> is problematic because the way it is done is often simply
C<binmode STDOUT>. Currently, this won't revert the effect of a previous
C<binmode STDOUT, ':utf8'>.

Instead use:

 binmode STDOUT, ':bytes';

=head1 EXAMPLE

This distribution contains a complete example in the F<eg/> directory.
After building the module by

 perl Build.PL
 ./Build

you can try it out:

 (cd eg && starman -l :5091 --workers=2 --preload-app app.psgi) &

Then you should be able to access

=over 4

=item * L<http://localhost:5091/clock.cgi?30>

=item * L<http://localhost:5091/flush.cgi>

=back

The clock example is basically the script displayed above. It works in Firefox.
Other browsers don't support multipart HTTP messages.

The flush example demonstrates filtering. It has been tested wich Chromium
35 on Linux. The script first prints a part of the page that contains the
HTML comment C<< <!-- FlushHead --> >>. The filter recognizes this token
and pushes the page out. You should see a red background and the string
C<loading -- please wait>. After 2 seconds the page should turn green and
the string should change to C<loaded>.

All of this very much depends on browser behavior. The intent is not to
provide an example that works for all of them. Instead, the capabilities
of this module are shown. You can also test these links with C<curl>
instead.

The example PSGI file also configures an F<access_log> and an F<error_log>.

=head1 AUTHOR

Torsten Förtsch E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT

Copyright 2014 Binary.com

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). A copy of the full
license is provided by the F<LICENSE> file in this distribution and can
be obtained at

L<http://www.perlfoundation.org/artistic_license_2_0>

=head1 SEE ALSO

=over 4

=item * L<Plack::App::CGIBin>

=item * L<CGI::Compile>

=item * L<Plack::App::CGIBin::Streaming::Request>

=item * L<Plack::App::CGIBin::Streaming::IO>

=back

=cut
