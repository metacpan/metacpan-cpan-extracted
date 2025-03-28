package Selenium::Edge;
$Selenium::Edge::VERSION = '1.49';
use strict;
use warnings;

# ABSTRACT: Use EdgeDriver without a Selenium server
use Moo;
use Selenium::CanStartBinary::FindBinary qw/coerce_simple_binary/;
extends 'Selenium::Remote::Driver';


has '+browser_name' => (
    is      => 'ro',
    default => sub { 'MicrosoftEdge' }
);


has 'binary' => (
    is        => 'lazy',
    coerce    => \&coerce_simple_binary,
    default   => sub { 'msedgedriver.exe' },
    predicate => 1
);


has 'binary_port' => (
    is      => 'lazy',
    default => sub { 17556 }
);

has '_binary_args' => (
    is      => 'lazy',
    builder => sub {
        my ($self) = @_;

        my $context = $self->wd_context_prefix;
        $context =~ s{^/}{};

        return ' --port=' . $self->port . ' --url-base=' . $context . ' ';
    }
);

with 'Selenium::CanStartBinary';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Selenium::Edge - Use EdgeDriver without a Selenium server

=head1 VERSION

version 1.49

=head1 SYNOPSIS

    my $driver = Selenium::Edge->new;
    # when you're done
    $driver->shutdown_binary;

=head1 DESCRIPTION

This class allows you to use the EdgeDriver without needing the JRE
or a selenium server running. When you refrain from passing the
C<remote_server_addr> and C<port> arguments, we will search for the
edgedriver executable binary in your $PATH. We'll try to start the
binary connect to it, shutting it down at the end of the test.

If the MicrosoftWebDriver binary is not found, we'll fall back to the
default L<Selenium::Remote::Driver> behavior of assuming defaults of
127.0.0.1:4444 after waiting a few seconds.

If you specify a remote server address, or a port, we'll assume you
know what you're doing and take no additional behavior.

If you're curious whether your Selenium::Edge instance is using a
separate MicrosoftWebDriver binary, or through the selenium server, you can
check the C<binary_mode> attr after instantiation.

=head1 ATTRIBUTES

=head2 binary

Optional: specify the path to your binary. If you don't specify
anything, we'll try to find it on our own via L<File::Which/which>.

=head2 binary_port

Optional: specify the port that we should bind to. If you don't
specify anything, we'll default to the driver's default port. Since
there's no a priori guarantee that this will be an open port, this is
_not_ necessarily the port that we end up using - if the port here is
already bound, we'll search above it until we find an open one.

See L<Selenium::CanStartBinary/port> for more details, and
L<Selenium::Remote::Driver/port> after instantiation to see what the
actual port turned out to be.

=head2 custom_args

Optional: specify any additional command line arguments you'd like
invoked during the binary startup. See
L<Selenium::CanStartBinary/custom_args> for more information.

=head2 startup_timeout

Optional: specify how long to wait for the binary to start itself and
listen on its port. The default duration is arbitrarily 10 seconds. It
accepts an integer number of seconds to wait: the following will wait
up to 20 seconds:

    Selenium::Edge->new( startup_timeout => 20 );

See L<Selenium::CanStartBinary/startup_timeout> for more information.

=head2 fixed_ports

Optional: Throw instead of searching for additional ports; see
L<Selenium::CanStartBinary/fixed_ports> for more info.

=head1 METHODS

=head2 shutdown_binary

Call this method instead of L<Selenium::Remote::Driver/quit> to ensure
that the binary executable is also closed, instead of simply closing
the browser itself. If the browser is still around, it will call
C<quit> for you. After that, it will try to shutdown the browser
binary by making a GET to /shutdown and on Windows, it will attempt to
do a C<taskkill> on the binary CMD window.

    $self->shutdown_binary;

It doesn't take any arguments, and it doesn't return anything.

We do our best to call this when the C<$driver> option goes out of
scope, but if that happens during global destruction, there's nothing
we can do.

=for Pod::Coverage has_binary

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

Previous maintainers:

=over 4

=item *

Daniel Gempesaw <gempesaw@gmail.com>

=item *

Emmanuel Peroumalnaïk <peroumalnaik.emmanuel@gmail.com>

=item *

Luke Closs <cpan@5thplane.com>

=item *

Mark Stosberg <mark@stosberg.com>

=back

Original authors:

=over 4

=item *

Aditya Ivaturi <ivaturi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010-2011 Aditya Ivaturi, Gordon Child

Copyright (c) 2014-2017 Daniel Gempesaw

Copyright (c) 2018-2021 George S. Baugh

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut
