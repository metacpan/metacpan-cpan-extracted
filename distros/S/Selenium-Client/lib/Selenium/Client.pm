package Selenium::Client;
$Selenium::Client::VERSION = '1.02';
# ABSTRACT: Module for communicating with WC3 standard selenium servers

use strict;
use warnings;

use v5.28;

no warnings 'experimental';
use feature qw/signatures/;

use JSON::MaybeXS();
use HTTP::Tiny();
use Carp qw{confess};
use File::Path qw{make_path};
use File::HomeDir();
use File::Slurper();
use File::Spec();
use Sub::Install();
use Net::EmptyPort();
use Capture::Tiny qw{capture_merged};

use Selenium::Specification;


sub new($class,%options) {
    $options{version}    //= 'stable';
    $options{port}       //= 4444;

    #XXX geckodriver doesn't bind to localhost lol
    $options{host}       //= '127.0.0.1';
    $options{host} = '127.0.0.1' if $options{host} eq 'localhost';

    $options{nofetch}    //= 1;
    $options{scheme}     //= 'http';
    $options{prefix}     //= '';
    $options{ua}         //= HTTP::Tiny->new();
    $options{client_dir} //= File::HomeDir::my_home()."/.selenium";
    $options{driver}     //= "SeleniumHQ::Jar";
    $options{post_callbacks} //= [];
    $options{auto_close} //= 1;
    $options{browser}    //= '';
    $options{headless}   //= 1;

    #create client_dir and log-dir
    my $dir = File::Spec->catdir( $options{client_dir},"perl-client" );
    make_path($dir);
    #Grab the spec
    $options{spec}= Selenium::Specification::read($options{client_dir},$options{version},$options{nofetch});

    my $self = bless(\%options, $class);
    $self->{sessions} = [];

    $self->_build_subs();
    $self->_spawn() if $options{host} eq '127.0.0.1';
    return $self;
}


sub catalog($self,$printed=0) {
    return $self->{spec} unless $printed;
    foreach my $method (keys(%{$self->{spec}})) {
        print "$method: $self->{spec}{$method}{href}\n";
    }
    return $self->{spec};
}

my %browser_opts = (
    firefox       => {
        name => 'moz:firefoxOptions',
        headless => sub ($c) {
            $c->{args} //= [];
            push(@{$c->{args}}, '-headless');
        },
    },
    chrome        => {
        name => 'goog:chromeOptions',
        headless => sub ($c) {
            $c->{args} //= [];
            push(@{$c->{args}}, 'headless');
        },
    },
    MicrosoftEdge => {
        name =>'ms:EdgeOptions',
        headless => sub ($c) {
            $c->{args} //= [];
            push(@{$c->{args}}, 'headless');
        },
    },
);

sub _build_caps($self,%options) {
    $options{browser}  = $self->{browser}  if $self->{browser};
    $options{headless} = $self->{headless} if $self->{headless};

    my $c = {
        browserName  => $options{browser},
    };
    my $browser = $browser_opts{$options{browser}};

    if ($browser) {
        my $browseropts = {};
        foreach my $k (keys %$browser) {
            next if $k eq 'name';
            $browser->{$k}->($browseropts) if $options{$k};
        }
        $c->{$browser->{name}} = $browseropts;
    }

    return (
        capabilities => {
            alwaysMatch => $c,
        },
    );
}

sub _build_subs($self) {
    foreach my $sub (keys(%{$self->{spec}})) {
        Sub::Install::install_sub(
            {
                code => sub {
                    my $self = shift;
                    return $self->_request($sub,@_);
                },
                as   => $sub,
                into => "Selenium::Client",
            }
        ) unless "Selenium::Client"->can($sub);
    }
}

#Check if server already up and spawn if no
sub _spawn($self) {
    return $self->Status() if Net::EmptyPort::wait_port( $self->{port}, 1 );

    # Pick a random port for the new server
    $self->{port} = Net::EmptyPort::empty_port();

    my $driver_file = "Selenium/Driver/$self->{driver}.pm";
    $driver_file =~ s/::/\//g;
    eval { require $driver_file } or confess "Could not load $driver_file, check your PERL5LIB: $@";
    my $driver = "Selenium::Driver::$self->{driver}";

    $driver->build_spawn_opts($self);
    return $self->_do_spawn();
}

sub _do_spawn($self) {

    #XXX on windows we will *never* terminate if we are listening for *anything*
    #XXX so we have to just bg & ignore, unfortunately (also have to system())
    if (_is_windows()) {
        $self->{pid} = qq/$self->{driver}:$self->{port}/;
        my @cmdprefix = ("start /MIN", qq{"$self->{pid}"});

        # Selenium JAR controls it's own logging because Java
        my @cmdsuffix;
        @cmdsuffix = ('>', $self->{log_file}, '2>&1') unless $self->{driver_class} eq 'Selenium::Driver::SeleniumHQ::Jar';

        my $cmdstring = join(' ', @cmdprefix, @{$self->{command}}, @cmdsuffix );
        print "$cmdstring\n" if $self->{debug};
        system($cmdstring);
        return $self->_wait();
    }

    print "@{$self->{command}}\n" if $self->{debug};
    my $pid = fork // confess("Could not fork");
    if ($pid) {
        $self->{pid} = $pid;
        return $self->_wait();
    }
    open(my $fh, '>>', $self->{log_file});
    capture_merged { exec(@{$self->{command}}) } stdout => $fh;
}

sub _wait ($self) {
    print "Waiting for port to come up..." if $self->{debug};
    Net::EmptyPort::wait_port( $self->{port}, 30 )
      or confess("Server never came up on port $self->{port} after 30s!");
    print "done\n" if $self->{debug};
    return $self->Status();
}

sub DESTROY($self) {
    return unless $self->{auto_close};

    print "Shutting down active sessions...\n" if $self->{debug};
    #murder all sessions we spawned so that die() cleans up properly
    if ($self->{ua} && @{$self->{sessions}}) {
        foreach my $session (@{$self->{sessions}}) {
            # An attempt was made.  The session *might* already be dead.
            eval { $self->DeleteSession( sessionid => $session ) };
        }
    }

    #Kill the server if we spawned one
    return unless $self->{pid};
    print "Attempting to kill server process...\n" if $self->{debug};

    if (_is_windows()) {
        my $killer = qq[taskkill /FI "WINDOWTITLE eq $self->{pid}"];
        print "$killer\n" if $self->{debug};
        #$killer .= ' > nul 2&>1' unless $self->{debug};
        system($killer);
        return 1;
    }

    my $sig = 'TERM';
    kill $sig, $self->{pid};

    print "Issued SIG$sig to $self->{pid}, waiting...\n" if $self->{debug};
    return waitpid( $self->{pid}, 0 );
}

sub _is_windows {
    return grep { $^O eq $_ } qw{msys MSWin32};
}

#XXX some of the methods require content being null, some require it to be an obj with no params LOL
our @bad_methods = qw{AcceptAlert DismissAlert Back Forward Refresh ElementClick MaximizeWindow MinimizeWindow FullscreenWindow SwitchToParentFrame ElementClear};

#Exempt some calls from return processing
our @no_process = qw{Status GetWindowRect GetElementRect GetAllCookies};

sub _request($self, $method, %params) {
    my $subject = $self->{spec}->{$method};

    #TODO handle compressed output from server
    my %options = (
        headers => {
            'Content-Type'    => 'application/json; charset=utf-8',
            'Accept'          => 'application/json; charset=utf-8',
            'Accept-Encoding' => 'identity',
        },
    );
    $options{content} = '{}' if grep { $_ eq $method } @bad_methods;

    my $url = "$self->{scheme}://$self->{host}:$self->{port}$subject->{uri}";

    # Remove parameters to inject into child objects
    my $inject_key   = exists $params{inject} ? delete $params{inject} : undef;
    my $inject_value = $inject_key ? $params{$inject_key} : '';
    my $inject;
    $inject = { to_inject => { $inject_key => $inject_value } } if $inject_key && $inject_value;

    # Keep sessions for passing to grandchildren
    $inject->{to_inject}{sessionid} = $params{sessionid} if exists $params{sessionid};

    #If we have no extra params, and this is getSession, simplify
    %params = $self->_build_caps() if $method eq 'NewSession' && !%params;

    foreach my $param (keys(%params)) {
        confess "$param is required for $method" unless exists $params{$param};
        delete $params{$param} if $url =~ s/{\Q$param\E}/$params{$param}/g;
    }

    if (%params) {
        $options{content} = JSON::MaybeXS::encode_json(\%params);
        $options{headers}{'Content-Length'} = length($options{content});
    }

    print "$subject->{method} $url\n" if $self->{debug};
    print "Body: $options{content}\n" if $self->{debug} && exists $options{content};

    my $res = $self->{ua}->request($subject->{method}, $url, \%options);

    my @cbret;
    foreach my $cb (@{$self->{post_callbacks}}) {
        if ($cb && ref $cb eq 'CODE') {
            @options{qw{url method}} = ($url,$subject->{method});
            $options{content} = \%params if %params;
            my $ret = $cb->($self, $res, \%options);
            push(@cbret,$ret) if $ret;
        }
        return $cbret[0] if @cbret == 1;
        return @cbret if @cbret;
    }

    print "$res->{status} : $res->{content}\n" if $self->{debug} && ref $res eq 'HASH';

    my $decoded_content = eval { JSON::MaybeXS::decode_json($res->{content}) };
    confess "$res->{reason} :\n Consult $subject->{href}\nRaw Error:\n$res->{content}\n" unless $res->{success};

    if (grep { $method eq $_ } @no_process) {
        return @{$decoded_content->{value}} if ref $decoded_content->{value} eq 'ARRAY';
        return $decoded_content->{value};
    }
    return $self->_objectify($decoded_content,$inject);
}

our %classes = (
    capabilities => { class => 'Selenium::Capabilities' },
    sessionId    => {
        class => 'Selenium::Session',
        destroy_callback => sub {
                my $self = shift;
                $self->DeleteSession() unless $self->{deleted};
        },
        callback => sub {
            my ($self,$call) = @_;
            $self->{deleted} = 1 if $call eq 'DeleteSession';
        },
    },
    # Whoever thought this parameter name was a good idea...
    'element-6066-11e4-a52e-4f735466cecf' => {
        class => 'Selenium::Element',
    },
);

sub _objectify($self,$result,$inject) {
    my $subject = $result->{value};
    return $subject unless grep { ref $subject eq $_ } qw{ARRAY HASH};
    $subject = [$subject] unless ref $subject eq 'ARRAY';

    my @objs;
    foreach my $to_objectify (@$subject) {
        # If we have just data return it
        return @$subject if ref $to_objectify ne 'HASH';

        my @objects = keys(%$to_objectify);
        foreach my $object (@objects) {
            my $has_class = exists $classes{$object};

            my $base_object = $inject // {};
            $base_object->{lc($object)} = $to_objectify->{$object};
            $base_object->{sortField} = lc($object);

            my $to_push = $has_class ?
                $classes{$object}{class}->new($self, $base_object ) :
                $to_objectify;
            $to_push->{sortField} = lc($object);
            # Save sessions for destructor
            push(@{$self->{sessions}}, $to_push->{sessionid}) if ref $to_push eq 'Selenium::Session';
            push(@objs,$to_push);
        }
    }
    @objs = sort { $a->{sortField} cmp $b->{sortField} } @objs;
    return $objs[0] if @objs == 1;
    return @objs;
}

1;


package Selenium::Capabilities;
$Selenium::Capabilities::VERSION = '1.02';
use parent qw{Selenium::Subclass};
1;
package Selenium::Session;
$Selenium::Session::VERSION = '1.02';
use parent qw{Selenium::Subclass};
1;
package Selenium::Element;
$Selenium::Element::VERSION = '1.02';
use parent qw{Selenium::Subclass};
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Selenium::Client - Module for communicating with WC3 standard selenium servers

=head1 VERSION

version 1.02

=head1 CONSTRUCTOR

=head2 new(%options) = Selenium::Client

Either connects to a driver at the specified host and port, or spawns one locally.

Spawns a server on a random port in the event the host is "localhost" (or 127.0.0.1) and nothing is reachable on the provided port.

Returns a Selenium::Client object with all WC3 methods exposed.

To view all available methods and their documentation, the catalog() method is provided.

Remote Server options:

=over 4

=item C<version> ENUM (stable,draft,unstable) - WC3 Spec to use.

Default: stable

=item C<host> STRING - hostname of your server.

Default: localhost

=item C<prefix> STRING - any prefix needed to communicate with the server, such as /wd, /hub, /wd/hub, or /grid

Default: ''

=item C<port> INTEGER - Port which the server is listening on.

Default: 4444
Note: when spawning, this will be ignored and a random port chosen instead.

=item C<scheme> ENUM (http,https) - HTTP scheme to use

Default: http

=item C<nofetch> BOOL - Do not check for a newer copy of the WC3 specifications on startup if we already have them available.

Default: 1

=item C<client_dir> STRING - Where to store specs and other files downloaded when spawning servers.

Default: ~/.selenium

=item C<debug> BOOLEAN - Whether to print out various debugging output.

Default: false

=item C<auto_close> BOOLEAN - Automatically close spawned selenium servers and sessions.

Only turn this off when you are debugging.

Default: true

=item C<post_callbacks> ARRAY[CODE] - Executed after each request to the selenium server.

Callbacks are passed $self, an HTTP::Tiny response hashref and the request hashref.
Use this to implement custom error handlers, testing harness modifications etc.

Return a truthy value to immediately exit the request subroutine after all cbs are executed.
Truthy values (if any are returned) are returned in order encountered.

=back

When using remote servers, you should take extra care that they automatically clean up after themselves.
We cannot guarantee the state of said servers after interacting with them.

Spawn Options:

=over 4

=item C<driver> STRING - Plug-in module used to spawn drivers when needed.

Included are 'Auto', 'SeleniumHQ::Jar', 'Gecko', 'Chrome', 'Edge'
Default: Auto

The 'Auto' Driver will pick whichever direct driver looks like it will work for your chosen browser.
If we can't find one, we'll fall back to SeleniumHQ::Jar.

=item C<browser> STRING - desired browser.  Used by the 'Auto' Driver.

Default: Blank

=item C<headless> BOOL - Whether to run the browser headless.  Ignored by 'Safari' Driver.

Default: True

=item C<driver_version> STRING - Version of your driver software you wish to download and run.

Blank and Partial versions will return the latest sub-version available.
Only relevant to Drivers which auto-download (currently only SeleniumHQ::Jar).

Default: Blank

=back

Driver modules should be in the Selenium::Driver namespace.
They may implement additional parameters which can be passed into the options hash.

=head1 METHODS

=head2 Most of the methods are dynamic based on the selenium spec

This means that the Selenium::Client class can directly call all selenium methods.
We provide a variety of subclasses as sugar around this:

    Selenium::Session
    Selenium::Capabilities
    Selenium::Element

Which will simplify correctly passing arguments in the case of sessions and elements.
However, this does not change the fact that you still must take great care.
We do no validation whatsoever of the inputs, and the selenium server likes to hang when you give it an invalid input.
So take great care and understand this is what "script hung and died" means -- you passed the function an unrecognized argument.

This is because Selenium::Specification cannot (yet!) parse the inputs and outputs for each endpoint at this time.
As such we can't just filter against the relevant prototype.

In any case, all subs will look like this, for example:

    $client->Method( key => value, key1 => value1, ...) = (@return_per_key)

The options passed in are basically JSON serialized and passed directly as a POST body (or included into the relevant URL).
We return a list of items which are a hashref per item in the result (some of them blessed).
For example, NewSession will return a Selenium::Capabilities and Selenium::Session object.
The order in which they are returned will be ordered alphabetically.

=head2 Passing Capabilities to NewSession()

By default, we will pass a set of capabilities that satisfy the options passed to new().

If you want *other* capabilities, pass them directly to NewSession as documented in the WC3 spec.

However, this will ignore what you passed to new().  Caveat emptor.

For the general list of options supported by each browser, see here:

=over 4

=item C<Firefox> - https://developer.mozilla.org/en-US/docs/Web/WebDriver/Capabilities/firefoxOptions

=item C<Chrome> - https://sites.google.com/a/chromium.org/chromedriver/capabilities

=item C<Edge> - https://docs.microsoft.com/en-us/microsoft-edge/webdriver-chromium/capabilities-edge-options

=item C<Safari> - https://developer.apple.com/documentation/webkit/about_webdriver_for_safari

=back

=head2 catalog(BOOL verbose=0) = HASHREF

Returns the entire method catalog.
Prints out every method and a link to the relevant documentation if verbose is true.

=head1 SUBCLASSES

=head2 Selenium::Capabilities

Returned as first element from NewSession().
Query this object for various things about the server capabilities.

=head2 Selenium::Session

Returned as second element of NewSession().
Has a destructor which will automatically clean itself up when we go out of scope.
Alternatively, when the driver object goes out of scope, all sessions it spawned will be destroyed.

You can call Selenium methods on this object which require a sessionid without passing it explicitly.

=head2 Selenium::Element

Returned from find element calls.

You can call Selenium methods on this object which require a sessionid and elementid without passing them explicitly.

=head1 STUPID SELENIUM TRICKS

There are a variety of quirks with Selenium drivers that you just have to put up with, don't log bugs on these behaviors.

=head3 alerts

If you have an alert() open on the page, all calls to the selenium server will 500 until you dismiss or accept it.

Also be aware that chrome  will re-fire alerts when you do a forward() or back() event, unlike firefox.

=head3 tag names

Safari returns ALLCAPS names for tags.  amazing

=head2 properties and attributes

Many I<valid> properties/attributes will I<never> be accessible via GetProperty() or GetAttribute().

For example, getting the "for" value of a <label> element is flat-out impossible using either GetProperty or GetAttribute.
There are many other such cases, the most common being "non-standard" properties such as aria-* or things used by JS templating engines.
You are better off using JS shims to do any element inspection.

Similarly the IsElementSelected() method is quite unreliable.
We can work around this however by just using the CSS :checked pseudoselector when looking for elements, as that actually works.

It is this for these reasons that you should consider abandoning Selenium for something that can actually do this correctly such as L<Playwright>.

=head3 windows

When closing windows, be aware you will be NOT be shot back to the last window you had focused before switching to the current one.
You have to manually switch back to an existing one.

Opening _blank targeted links *does not* automatically switch to the new window.
The procedure for handling links of such a sort to do this is as follows:

    # Get current handle
    my $handle = $session->GetWindowHandle();

    # Assuming the element is an href with target=_blank ...
    $element->ClickElement();

    # Get all handles and filter for the ones that we aren't currently using
    my @handles = $session->GetWindowHandles();
    my @new_handles = grep { $handle != $_ } @handles;

    # Use pop() as it will always be returned in the order windows are opened
    $session->SwitchToWindow( handle => pop(@new_handles) );

Different browser drivers also handle window handles differently.
Chrome in particular demands you stringify handles returned from the driver.
It also seems to be a lot less cooperative than firefox when setting the WindowRect.

=head3 arguments

If you make a request of the server with arguments it does not understand it will hang for 30s, so set a SIGALRM handler if you insist on doing so.

=head2 MSWin32 issues

The default version of the Java JRE from java.com is quite simply ancient on windows, and SeleniumHQ develops against JDK 11 and better.
So make sure your JDK bin dir is in your PATH I<before> the JRE path (or don't install an ancient JRE lol)

If you don't, you'll probably get insta-explosions due to their usage of new language features.
Kind of like how you'll die if you use a perl without signatures with this module :)

Also, due to perl pseudo-forks hanging forever if anything is ever waiting on read() in windows, we don't fork to spawn binaries.
Instead we use C<start> to open a new cmd.exe window, which will show up in your task tray.
Don't close this or your test will fail for obvious reasons.

=head1 AUTHOR

George S. Baugh <george@troglodyne.net>

=head1 AUTHOR

George S. Baugh <george@troglodyne.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by George S. Baugh.

This is free software, licensed under:

  The MIT (X11) License

=cut
