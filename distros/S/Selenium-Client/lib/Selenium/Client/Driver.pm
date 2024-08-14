package Selenium::Client::Driver;
$Selenium::Client::Driver::VERSION = '2.01';
use strict;
use warnings;

use parent qw{Selenium::Remote::Driver};

no warnings qw{experimental};
use feature qw{signatures state};

# ABSTRACT: Drop-In replacement for Selenium::Remote::Driver that supports selenium 4

use Scalar::Util;
use Carp::Always;
use Data::Dumper;
use JSON;

use Selenium::Client;
use Selenium::Client::Commands;
use Selenium::Client::WebElement;
use Selenium::Client::WDKeys;


#Getters/Setters

sub _param ( $self, $default, $param, $value = undef ) {
    $self->{$param} //= $default;
    $self->{$param} = $value if defined $value;
    return $self->{$param};
}

sub driver ( $self, $driver = undef ) {
    return $self->_param( undef, 'driver', $driver );
}

sub base_url ( $self, $url = undef ) {
    return $self->_param( '', 'base_url', $url );
}

sub remote_server_addr ( $self, $addr = undef ) {
    return $self->_param( 'localhost', 'remote_server_addr', $addr );
}

sub port ( $self, $port = undef ) {
    return $self->_param( 4444, 'port', $port );
}

sub browser_name ( $self, $name = undef ) {
    return $self->_param( 'firefox', 'browser_name', $name );
}

sub platform ( $self, $platform = undef ) {
    return $self->_param( 'ANY', 'platform', $platform );
}

sub version ( $self, $version = undef ) {
    return $self->_param( '', 'version', $version );
}

sub webelement_class ( $self, $class = undef ) {
    return $self->_param( 'Selenium::Client::WebElement', 'webelement_class', $class );
}

sub default_finder ( $self, $finder = undef ) {
    return $self->_param( 'xpath', 'default_finder', $finder );
}

sub session ( $self, $session = undef ) {
    return $self->_param( undef, 'session', $session );
}

sub session_id ( $self, $id = undef ) {
    return $self->session->{sessionId};
}

sub remote_conn ( $self, $conn = undef ) {
    return $self->_param( undef, 'remote_conn', $conn );
}

sub error_handler ( $self, $handler = undef ) {
    $handler //= sub {
        my ( undef, $msg, $params ) = @_;
        die "Internal Death: $msg\n" . Dumper($params);
    };
    die "error handler must be subroutine ref" unless ref $handler eq 'CODE';
    return $self->_param( sub { }, 'error_handler', $handler );
}

sub ua ( $self, $ua = undef ) {
    return $self->_param( undef, 'ua', $ua );
}

sub commands ($self) {
    $self->{commands} //= Selenium::Client::Commands->new;
    return $self->{commands};
}

sub auto_close ( $self, $ac = undef ) {
    return $self->_param( JSON::true, 'auto_close', $ac ? JSON::true : JSON::false );
}

# Only here for compatibility
sub pid {
    return $$;
}

#TODO these bools may need JSONizing
sub javascript ( $self, $js = undef ) {
    return $self->_param( JSON::true, 'javascript', $js ? JSON::true : JSON::false );
}

sub accept_ssl_certs ( $self, $ssl = undef ) {
    return $self->_param( JSON::true, 'accept_ssl_certs', $ssl ? JSON::true : JSON::false );
}

sub proxy ( $self, $proxy = undef ) {
    if ($proxy) {
        die "Proxy must be a hashref" unless ref $proxy eq 'HASH';
        if ( $proxy->{proxyType} =~ /^pac$/i ) {
            if ( not defined $proxy->{proxyAutoconfigUrl} ) {
                die "proxyAutoconfigUrl not provided\n";
            }
            elsif ( not( $proxy->{proxyAutoconfigUrl} =~ /^(http|file)/g ) ) {
                die "proxyAutoconfigUrl should be of format http:// or file://";
            }

            if ( $proxy->{proxyAutoconfigUrl} =~ /^file/ ) {
                my $pac_url = $proxy->{proxyAutoconfigUrl};
                my $file    = $pac_url;
                $file =~ s{^file://}{};

                if ( !-e $file ) {
                    die "proxyAutoConfigUrl file does not exist: '$pac_url'";
                }
            }
        }
    }
    return $self->_param( undef, 'proxy', $proxy );
}

#TODO what the hell is the difference between these two in practice?
sub extra_capabilities ( $self, $caps = undef ) {
    return $self->_param( undef, 'extra_capabilities', $caps );
}

sub desired_capabilities ( $self, $caps = undef ) {
    return $self->_param( undef, 'desired_capabilities', $caps );
}

sub capabilities ( $self, $caps = undef ) {
    return $self->_param( undef, 'desired_capabilities', $caps );
}

sub firefox_profile ( $self, $profile = undef ) {
    if ($profile) {
        unless ( Scalar::Util::blessed($profile) && $profile->isa('Selenium::Firefox::Profile') ) {
            die "firefox_profile must be a Selenium::Firefox::Profile";
        }
    }
    return $self->_param( undef, 'firefox_profile', $profile );
}

sub debug ( $self, $debug = undef ) {
    return $self->_param( 0, 'debug', $debug );
}

sub headless ( $self, $headless = 0 ) {
    return $self->_param( 0, 'headless', $headless );
}

sub inner_window_size ( $self, $size = undef ) {
    if ( ref $size eq 'ARRAY' ) {
        die "inner_window_size must have two elements: [ height, width ]"
          unless scalar @$size == 2;

        foreach my $dim (@$size) {
            die 'inner_window_size only accepts integers, not: ' . $dim
              unless Scalar::Util::looks_like_number($dim);
        }

    }
    return $self->_param( undef, 'inner_window_size', $size );
}

# TODO do we care about this at all?
# At the time of writing, Geckodriver uses a different endpoint than
# the java bindings for executing synchronous and asynchronous
# scripts. As a matter of fact, Geckodriver does conform to the W3C
# spec, but as are bound to support both while the java bindings
# transition to full spec support, we need some way to handle the
# difference.
sub _execute_script_suffix ( $self, $suffix = undef ) {
    return $self->_param( undef, '_execute_script_suffix', $suffix );
}

#TODO generate find_element_by crap statically
#with 'Selenium::Remote::Finders';

sub new ( $class, %options ) {
    my $self = bless( { %options, is_wd3 => 1 }, $class );

    # map the options
    my %optmap = (

        # SRD / common options
        browser_name       => 'browser',
        debug              => 'debug',
        remote_server_addr => 'host',
        port               => 'port',
        auto_close         => 'auto_close',
        ua                 => 'ua',

        # Stuff that does not work from SRD:

        # version - good luck getting random versions of browsers to work!!! LOL!!!!
        # platform - TODO currently unsupported
        # accept_ssl_certs - NOT IN THE SPEC, U CAN POUND SAND IF U AINT AN INTERMEDIATE SIGNER, HA HA HA HA.
        # firefox_provile - NOT IN THE SPEC
        # javascript      - piss off, use mechanize if you want this off
        # default_finder  - TODO currently unsupported
        # session_id      - TODO currently unsupported
        # pageLoadStrategy - NOT IN THE SPEC
        # extra_capabilities - NOT IN THE SPEC
        # base_url - TODO currently unsupported
        # inner window size - XXX well, this function doesn't even work on selenium 4 so we *can't* support it.
        # error_handler - TODO will probably have to shim this, may not be possible idk
        # webelement_class- just no.
        # proxy - TODO currently unsupported, not sure this is even in the spec.

        # SCD exclusive options
        driver         => 'driver',
        driver_version => 'driver_version',
        headless       => 'headless',
        fatal          => 'fatal',
        post_callbacks => 'post_callbacks',
        normalize      => 'normalize',
        prefix         => 'prefix',
        scheme         => 'scheme',
        nofetch        => 'nofetch',
        client_dir     => 'client_dir',
        post_callbacks => 'post_callbacks',    # TODO see error_handler note above
    );

    my $driver = $self->driver();
    if ( !$driver ) {

        my %actual;
        foreach my $option ( keys(%options) ) {
            if ( !exists $optmap{$option} ) {
                warn "Passed unsupported option '$option', which has been dropped.";
                next;
            }
            $actual{ $optmap{$option} } = $options{$option};
        }

        # Set the version explicitly, as these are conflicting names between the two modules.
        $actual{version} = 'stable';

        $driver = Selenium::Client->new(%actual);
        $self->driver($driver);
    }
    my $status = $driver->Status();
    die "Got bad status back from server!" unless $status->{ready};

    if ( !$self->session ) {
        if ( $self->desired_capabilities ) {
            $self->new_desired_session( $self->desired_capabilities );
        }
        else {
            # Connect to remote server & establish a new session
            $self->new_session( $self->extra_capabilities );
        }
    }

    if ( !( defined $self->session ) ) {
        die "Could not establish a session with the remote server\n";
    }

    if ( $self->inner_window_size ) {
        my $size = $self->inner_window_size;
        $self->set_inner_window_size(@$size);
    }

    #Set debug if needed
    $self->debug_on() if $self->debug;

    return $self;
}

sub new_from_caps ( $self, %args ) {
    if ( not exists $args{desired_capabilities} ) {
        $args{desired_capabilities} = {};
    }
    return $self->new(%args);
}

#TODO do we need this?
sub DESTROY {
}

# This is an internal method used the Driver & is not supposed to be used by
# end user. This method is used by Driver to set up all the parameters
# (url & JSON), send commands & receive processed response from the server.
sub _execute_command ( $self, $res, $params = {} ) {
    print "Executing $res->{command}\n" if $self->{debug};

    #XXX Sometimes the params are in $res.  Whee.
    foreach my $key ( keys(%$res) ) {
        $params->{$key} = $res->{$key} unless grep { $key eq $_ } qw{command sessionid elementid};
    }

    my $macguffin = $self->commands->needs_driver( $res->{command} ) ? $self->driver : $self->session;
    $macguffin = $self->commands->needs_scd( $res->{command} ) ? $self : $macguffin;
    die "Could not acquire driver/session!" unless $macguffin;
    local $@;
    my $result;
    eval {
        my $resp = $self->commands->request( $macguffin, $res->{command}, $params );
        $result = $self->commands->parse_response( $macguffin, $res->{command}, $resp );
        1;
    } or do {
        return $self->error_handler->( $macguffin, $@, { %$params, %$res } ) if $self->error_handler;
        die $@;
    };
    return $result;
}

sub has_javascript { 1 }

sub new_session ( $self, $extra_capabilities = {} ) {
    $extra_capabilities //= {};
    my $caps = {
        'platformName' => $self->platform,

        #'javascriptEnabled'    => $self->javascript,
        'version'             => $self->version // '',
        'acceptInsecureCerts' => $self->accept_ssl_certs,
        %$extra_capabilities,
    };

    $caps->{browserName} //= $self->browser_name;

    if ( defined $self->proxy ) {
        $caps->{proxy} = $self->proxy;
    }

    if (   $caps->{browserName}
        && $caps->{browserName} =~ /firefox/i
        && $self->firefox_profile ) {
        $caps->{firefox_profile} = $self->firefox_profile->_encode;
    }

    my %options = ( driver => 'auto', browser => $self->browser_name, debug => $self->debug, headless => $self->headless, capabilities => $caps );

    return $self->_request_new_session( \%options );
}

sub new_desired_session {
    my ( $self, $caps ) = @_;
    return $self->new_session($caps);
}

sub _request_new_session {
    my ( $self, $args ) = @_;

    my $ret = $self->_execute_command( { command => 'newSession' }, $args->{capabilities} );
    my ( $capabilities, $session ) = ( $ret->{capabilities}, $ret->{session} );

    #die "Failed to get caps back from newSession"    unless $capabilities->isa("Selenium::Capabilities");
    #die "Failed to get session back from newSession" unless $session->isa("Selenium::Session");
    $self->session($session);
    $self->capabilities($capabilities);

    return $self;
}

sub is_webdriver_3 {
    my $self = shift;
    return $self->{is_wd3};
}

sub debug_on ($self) {
    $self->{debug} = 1;
    $self->driver->{debug} = 1;
}

sub debug_off {
    my ($self) = @_;
    $self->{debug} = 0;
    $self->driver->{debug} = 0;
}

sub get_sessions {
    my ($self) = @_;
    return $self->driver->{sessions};
}

sub get_capabilities {
    my $self = shift;
    return $self->capabilities;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Selenium::Client::Driver - Drop-In replacement for Selenium::Remote::Driver that supports selenium 4

=head1 VERSION

version 2.01

=head1 DESCRIPTION

Drop-in replacement for L<Selenium::Remote::Driver> which supports selenium 4.

See the documentation for L<Selenium::Remote::Driver> for how to use this module unless otherwise noted below.

Also, we support all valid L<Selenium::Client> constructor arguments, so you will likely want to consult those.

There are also a number of constructor options from L<Selenium::Remote::Driver> which are either entirely incompatible with selenium 4, are unimplemented or were bad ideas in the first place:

=over 4

=item C<platform> - TODO. Will have to work in Selenium::Client first.

=item C<default_finder>  - TODO.  Will need a shim in Selenium::Client::Commands.

=item C<extra_capabilities> - TODO. Use the options relevant to Selenium::Client instead

=item C<base_url> - TODO. Will have to work in Selenium::Client first.

=item C<session_id> - TODO. I don't even know if you can do this with the W3C spec.

=item C<inner_window_size> - TODO. This function doesn't work right on any browser so we could only do a "best effort" try.

=item C<error_handler> - TODO.  While post_callbacks are supported, there is no shim to make old error_handler subs work as post_callbacks.

=item C<proxy> - TODO. not sure this is even possible with S4 caps.

=item C<accept_ssl_certs> - Not in the W3C spec.  Just make a self-signed CA and slap that sucker in /etc/ssl/certs, then use that to issue your self-signed certs.

=item C<firefox_profile> - Not in the W3C spec.  If you can't get it done with moz:firefoxOptions, it ain't getting done.

=item C<pageLoadStrategy> - Not in the W3C spec.  If you want to properly wait on page loads, you will need either a view-source based state-machine or executing scripts.  Welcome to hell.

=item C<webelement_class> - Subclass Selenium::Client::Driver instead

=item C<javascript> - Are you really using selenium to disable javascript?  Seek Help.

=item C<version> - good luck getting random versions of browsers to work!!! LOL!!!!  Playwright patches them rather than rely on perpetually broken driver binaries.

=back

Furthermore, selenium 4 totally fails at dealing with cookies and alerts.

=head1 ALTERNATIVES

My advice is to give up on this nonsense and...

    use Playwright;

Instead.  Or, wait until someone implements a WC3 compliant selenium server using playwright and we can end the madness.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Selenium::Client|Selenium::Client>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/troglodyne-internet-widgets/selenium-client-perl/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
