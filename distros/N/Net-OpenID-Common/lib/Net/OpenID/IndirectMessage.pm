
package Net::OpenID::IndirectMessage;
$Net::OpenID::IndirectMessage::VERSION = '1.20';
use strict;
use Carp;
use Net::OpenID::Common;

sub new {
    my $class = shift;
    my $what = shift;
    my %opts = @_;

    my $self = bless {}, $class;

    $self->{minimum_version} = delete $opts{minimum_version};

    Carp::croak("Unknown options: " . join(", ", keys %opts)) if %opts;

    my $getter;
    my $enumer;
    if (ref $what eq "HASH") {
        # In this case it's the caller's responsibility to determine
        # whether the method is GET or POST.
        $getter = sub { $what->{$_[0]}; };
        $enumer = sub { keys(%$what); };
    }
    elsif (ref $what eq "Apache") {
        my %get;
        if ($what->method eq 'POST') {
            %get = $what->content;
        }
        else {
            %get = $what->args;
        }
        $getter = sub { $get{$_[0]}; };
        $enumer = sub { keys(%get); };
    }
    elsif (ref $what eq "Plack::Request") {
        my $p = $what->method eq 'POST' ? $what->body_parameters : $what->query_parameters;
        $getter = sub { $p->get($_[0]); };
        $enumer = sub { keys %{$p}; };
    }
    elsif (ref $what ne "CODE") {
        # assume an object that follows the CGI interface and has a param() method
        # CGI does the right thing and omits query parameters if this is a POST
        # others (Apache::Request, Apache2::Request) mix query and body params.
        $getter = sub { scalar $what->param($_[0]); };
        $enumer = sub { $what->param; };
    }

    else {
        # CODE reference
        my @keys = ();
        my $enumerated;
        $getter = $what;
        $enumer = sub {
            unless ($enumerated) {
                $enumerated = 1;
                # In Consumer/Common 1.03 and predecessors, coderefs
                # did not have to be able to enumerate all keys.
                # Therefore, we must cope with legacy coderefs being
                # passed in which don't expect to be called with no
                # arguments, and then, most likely, fail in one of
                # three ways:
                #   (1) return empty list
                #   (2) retrieve undef/'' value for undef/'' key.
                #   (3) raise an error
                # We normalize these all to empty list, which our
                # caller can then recognize as obviously wrong
                # and do something about it.
                eval { @keys = $what->() };
                @keys = ()
                  if (@keys == 1 &&
                      !(defined($keys[0]) && length($keys[0])));
            }
            return @keys;
        }
    }
    $self->{getter} = $getter;
    $self->{enumer} = $enumer;

    # Now some quick pre-configuration of a few bits

    # Is this an OpenID message at all?
    # All OpenID messages have an openid.mode value...
    return undef unless $self->get('mode');

    # Is this an OpenID 2.0 message?
    my $ns = $self->get('ns');


    # The 2.0 spec section 4.1.2 requires that we support these namespace values
    # but act like it's a normal 1.1 request.
    # We do this by just pretending that ns wasn't set at all.
    if ($ns && ($ns eq 'http://openid.net/signon/1.1' || $ns eq 'http://openid.net/signon/1.0')) {
        $ns = undef;
    }

    if (defined($ns) && $ns eq OpenID::util::version_2_namespace()) {
        $self->{protocol_version} = 2;
    }
    elsif (! defined($ns)) {
        # No namespace at all means a 1.1 message
        if (($self->{minimum_version}||0) <= 1) {
            $self->{protocol_version} = 1;
        }
        else {
            # Pretend we don't understand the message.
            return undef;
        }
    }
    else {
        # Unknown version is the same as not being an OpenID message at all
        return undef;
    }

    # This will be populated in on demand
    $self->{extension_prefixes} = undef;

    return $self;
}

sub protocol_version {
    return $_[0]->{protocol_version};
}

sub mode {
    my $self = shift;
    return $self->get('mode');
}

sub get {
    my $self = shift;
    my $key = shift or Carp::croak("No argument name supplied to get method");

    # Arguments can only contain letters, numbers, underscores and dashes
    Carp::croak("Invalid argument key $key") unless $key =~ /^[\w\-]+$/;
    Carp::croak("Too many arguments") if scalar(@_);

    return $self->{getter}->("openid.$key");
}

sub raw_get {
    my $self = shift;
    my $key = shift or Carp::croak("No argument name supplied to raw_get method");

    return $self->{getter}->($key);
}

sub getter {
    my $self = shift;

    return $self->{getter};
}

# NOTE RE all_parameters():
#
# It was originally thought that enumeration of URL parameters was
# unnecessary except to support extensions, i.e., that support of the
# core protocol did not need it.  While this is true in OpenID 1.1, it
# is not the case in OpenID 2.0 where check_authentication requires
# sending back a complete copy of the positive assertion message
# that was received indirectly.
#
# In cases where legacy client code is not supplying a real enumerator,
# this routine will return an empty list and callers will need to
# check for this.  Recall that actual messages in all versions of the
# Openid protocol (thus far) are guaranteed to have at least an
# 'openid.mode' parameter.

sub all_parameters {
    my $self = shift;

    return $self->{enumer}->();
}

sub get_ext {
    my $self = shift;
    my $namespace = shift or Carp::croak("No namespace URI supplied to get_ext method");
    my $key = shift;

    Carp::croak("Too many arguments") if scalar(@_);

    $self->_compute_extension_prefixes() unless defined($self->{extension_prefixes});

    my $alias = $self->{extension_prefixes}{$namespace};
    return $key ? undef : {} unless $alias;

    if ($key) {
        return $self->{getter}->("openid.$alias.$key");
    }
    else {
        my $prefix = "openid.$alias.";
        my $prefixlen = length($prefix);
        my $ret = {};
        foreach my $key ($self->all_parameters) {
            next unless substr($key, 0, $prefixlen) eq $prefix;
            $ret->{substr($key, $prefixlen)} = $self->{getter}->($key);
        }
        return $ret;
    }
}

sub has_ext {
    my $self = shift;
    my $namespace = shift or Carp::croak("No namespace URI supplied to get_ext method");

    Carp::croak("Too many arguments") if scalar(@_);

    $self->_compute_extension_prefixes() unless defined($self->{extension_prefixes});

    return defined($self->{extension_prefixes}{$namespace}) ? 1 : 0;
}

sub _compute_extension_prefixes {
    my ($self) = @_;

    # return unless $self->{enumer};

    $self->{extension_prefixes} = {};
    if ($self->protocol_version != 1) {
        foreach my $key ($self->all_parameters) {
            next unless $key =~ /^openid\.ns\.(\w+)$/;
            my $alias = $1;
            my $uri = $self->{getter}->($key);
            $self->{extension_prefixes}{$uri} = $alias;
        }
    }
    else {
        # Synthesize the SREG namespace as it was used in OpenID 1.1
        $self->{extension_prefixes}{"http://openid.net/extensions/sreg/1.1"} = "sreg";
    }
}

1;

=head1 NAME

Net::OpenID::IndirectMessage - Class representing a collection of namespaced arguments

=head1 VERSION

version 1.20

=head1 DESCRIPTION

This class acts as an abstraction layer over a collection of flat URL arguments
which supports namespaces as defined by the OpenID Auth 2.0 specification.

It also recognises when it is given OpenID 1.1 non-namespaced arguments and
acts as if the relevant namespaces were present. In this case, it only
supports the basic OpenID 1.1 arguments and the extension arguments
for Simple Registration.

This class can operate on
a normal hashref,
a L<CGI> object or any object with a C<param> method that behaves similarly
(L<Apache::Request>, L<Apache2::Request>, L<Mojo::Parameters>,...),
an L<Apache> object,
a L<Plack::Request> object, or
an arbitrary C<CODE> ref that when given a key name as its first parameter
and returns a value and if given no arguments returns a list of all keys present.

If you pass in a hashref or a coderef it is your responsibility as the caller
to check the HTTP request method and pass in the correct set of arguments.
For the other kinds of objects, this module will do the right thing automatically.

=head1 SYNOPSIS

    use Net::OpenID::IndirectMessage;

    # Pass in something suitable for the underlying flat dictionary.
    # Will return an instance if the request arguments can be understood
    # as a supported OpenID Message format.
    # Will return undef if this doesn't seem to be an OpenID Auth message.
    # Will croak if the $argumenty_thing is not of a suitable type.
    my $args = Net::OpenID::IndirectMessage->new($argumenty_thing);

    # Determine which protocol version the message is using.
    # Currently this can be either 1 for 1.1 or 2 for 2.0.
    # Expect larger numbers for other versions in future.
    # Most callers don't really need to care about this.
    my $version = $args->protocol_version();

    # Get a core argument value ("openid.mode")
    my $mode = $args->get("mode");

    # Get an extension argument value
    my $nickname = $args->get_ext("http://openid.net/extensions/sreg/1.1", "nickname");

    # Get hashref of all arguments in a given namespace
    my $sreg = $args->get_ext("http://openid.net/extensions/sreg/1.1");

Most of the time callers won't need to use this class directly, but will instead
access it through a L<Net::OpenID::Consumer> instance.

=head1 METHODS

=over 4

=item B<protocol_version>

Currently returns 1 or 2, according as this is an OpenID 1.0/1.1 or an OpenID 2.0 message.

=item B<has_ext>

Takes an extension namespace and returns true if the named extension is used in this message.

=item B<get_ext>

Takes an extension namespace and an optional parameter name, returns the parameter value,
or if no parameter given, the parameter value.

=back
