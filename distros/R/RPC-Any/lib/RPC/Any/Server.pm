package RPC::Any::Server;
use Moose;
use Moose::Util::TypeConstraints;
use Class::MOP;
use Scalar::Util qw(tainted blessed);
use Taint::Util qw(taint);
use RPC::Any::Exception;

has dispatch  => (is => 'rw', isa => 'HashRef', default => sub { {} });
has allow_constants => (is => 'rw', isa => 'Bool', default => 0);
has package_base => (is => 'rw', isa => 'Str');

sub handle_input {
    my ($self, $input) = @_;
    
    # Everything inside of this method is a call to other methods.
    # This makes it much easier to override the behavior of RPC::Any::Server
    # in subclasses (which is one of the major goals of RPC::Any).

    # A short summary of this method is:
    # 1. get and parse input into a data structure.
    # 2. call the method, passing it any arguments.
    # 3. return some text that's a return value.

    my $retval;
    eval {
        $input = $self->get_input($input);
        my $input_info = $self->check_input($input);
        my $input_object = $self->decode_input_to_object($input);
        my $data = $self->input_object_to_data($input_object);
        $self->fix_data($data, $input_info);
        my $method_info = $self->get_method($data);
        my $method_result = $self->call_method($data, $method_info);
        my $collapsed_result = $self->collapse_result($method_result);
        my $output_object = $self->output_data_to_object($collapsed_result);
        my $output_string = $self->encode_output_from_object($output_object);
        $retval = $self->produce_output($output_string);
    };
    
    return $retval if defined $retval;
    # The only way that we can get here is by something throwing an error.
    return $self->handle_error($@);
}

sub get_input {
    my ($self, $input) = @_;
    if (!defined $input) {
        $input = \*STDIN;
    }
    if (ref($input) eq 'GLOB' or eval { $input->isa('IO::Handle') }) {
        local $/;
        return <$input>;
    }
    return $input;
}

sub check_input {
    my ($self, $input) = @_;
    return { tainted => tainted($input) };
}

sub fix_data {
    my ($self, undef, $info) = @_;
    $self->taint_data($_[1], $info->{tainted});
}

sub taint_data {
    my ($self, $data, $is_tainted) = @_;
    return if !$is_tainted;
    # Make sure not to taint references--it can cause strange failures
    # (for example, overload.pm fails, saying that the address of references
    # is tainted in sprintf).
    $self->walk_data($data, sub { taint($_[0]) if !ref $_[0] });
}

# This is a very simplistic walker, because we're only ever parsing basic
# data structures.
sub walk_data {
    my ($self, $item, $callback) = @_;
    
    if (ref($item) eq 'HASH' or eval { $item->isa('HASH') }) {
        foreach my $key (keys %$item) {
            $self->walk_data($item->{$key}, $callback);
        }
    }
    elsif (ref($item) eq 'ARRAY' or eval { $item->isa('ARRAY') }) {
        foreach my $array_item (@$item) {
            $self->walk_data($array_item, $callback);
        }
    }

    # Run the callback on the actual variable passed into us,
    # not on the copy of it. (This way we taint the actual
    # variable, not our local copy.)
    $callback->($_[1]);
}

sub call_method {
    my ($self, $data, $method_info) = @_;
    my ($module, $method) = @$method_info{qw(module method)};

    my $new_isa = $self->get_package_isa($module);
    no strict 'refs';
    local @{"${module}::ISA"} = @$new_isa;
    my @result = $module->$method(@{ $data->{arguments} });
    return \@result;
}

sub get_package_isa {
    my ($self, $module) = @_;
    my $original_isa;
    { no strict 'refs'; $original_isa = \@{"${module}::ISA"}; }
    my @new_isa = @$original_isa;
    
    my $base = $self->package_base;
    if (not $module->isa($base)) {
        Class::MOP::load_class($base);
        push(@new_isa, $base);
    }
    return \@new_isa;
}

sub get_method {
    my ($self, $data) = @_;
    
    my $full_name = $data->{method};

    $full_name =~ /^(\S+)\.([^\.]+)$/;
    my ($package, $method) = ($1, $2);

    if (!$package || !$method) {
        $self->exception('NoSuchMethod',
                         "'$full_name' is not a valid method. It must"
                         . " contain a package name, followed by a period,"
                         . " followed by a method name.");
    }
    
    $self->validate_method_name($method, $full_name);

    my $module = $self->get_module($package);
    if (!$module) {
        $self->exception('NoSuchMethod',
                         "There is no method package named '$package'.");
    }

    Class::MOP::load_class($module);

    if (!$module->can($method)) {
        $self->exception('NoSuchMethod',
                         "There is no method named '$method' in the"
                         . " '$package' package.");
    }
    return { module => $module, method => $method };
}

# This is factored out into a separate subroutine in case subclasses
# want to use it in their own get_method implementation.
sub validate_method_name {
    my ($self, $method, $full_name) = @_;
    
    # Don't allow access to private subroutines.
    if ($method =~ /^_/) {
        $self->exception('NoSuchMethod',
            "'$full_name' has a method name that starts with an"
            . " underscore. Methods whose names start with an"
            . " underscore are considered private and may not be"
            . " called using this interface.");
    }
    
    # Don't allow access to constants.
    if ($method =~ /^[A-Z_0-9]+$/ and !$self->allow_constants) {
        $self->exception('NoSuchMethod',
            "'$full_name' has a method name that is all capital letters."
            . " Methods whose names are all capital letters are considered"
            . " to be private constants and may not be called using this"
            . " interface.");
    }
    
    # Make sure that the method is a valid simple identifier.
    if ($method !~ /^[\w+]+$/) {
        $self->exception('NoSuchMethod',
            "'$method' (from '$full_name') cannot be used as a method name,"
            . " because it is not a valid Perl identifier.");
    }
}

sub get_module {
    my ($self, $package) = @_;
    return $self->dispatch->{$package};
}

sub collapse_result {
    my ($self, $result) = @_;
    if (@$result == 0) {
        return undef;
    }
    elsif (@$result == 1) {
        return $result->[0];
    }
    return $result;
}

sub produce_output { return $_[1]; }

sub handle_error {
    my ($self, $error) = @_;
    
    unless (blessed $error and $error->isa('RPC::Any::Exception')) {
        $error = RPC::Any::Exception::PerlError->new(message => $error);
    }
    my $output;
    eval {
        my $encoded_error = $self->encode_output_from_exception($error);
        $output = $self->produce_output($encoded_error);
    };
    
    return $output if $output;
    
    die "$error\n\nAlso, an error was encountered while trying to send"
        . " this error: $@\n";
}

##############
# Exceptions #
##############

sub exception {
    my ($self, $type, $message) = @_;
    my $class = "RPC::Any::Exception::$type";
    my $exception = $class->new(message => $message);
    die $exception;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

RPC::Any::Server - The RPC Server

=head1 SYNOPSIS

 use RPC::Any::Server::XMLRPC;
 # Create a server where calling Foo.bar will call My::Module->bar.
 my $server = RPC::Any::Server::XMLRPC->new(
    dispatch => { 'Foo' => 'My::Module' }
 );
 # Read from STDIN and print result to STDOUT.
 print $server->handle_input();

=head1 DESCRIPTION

This is an RPC "server" that can call methods and return a result
to a client. Unlike other RPC modules, C<RPC::Any::Server> doesn't actually
start a listening daemon, it just reads the input that you give it and
gives you output that you can send to your client any way that you
like. This may sound like a bit of additional complexity, but in fact it
makes it much I<simpler> to use than other RPC modules.

This module itself doesn't do anything--it just acts as a base class
for other Server modules, like L<RPC::Any::Server::XMLRPC> and so on.
(They are all listed in the L</SEE ALSO> section below.) However, all
Server types have certain things in common, and those things are documented
here, in this POD.

C<RPC::Any::Server> is designed to be subclassed and easily customized
for your environment. Look at the C<handle_input> method in its code
to understand how it works and all the methods that you can override.

C<RPC::Any::Server> uses L<Moose>, so subclasses may use all the power
of L<Moose> to adjust its behavior.

=head1 INSTANCE METHODS

=head2 handle_input

This is, normally, the only method you will call on a Server instance. It
takes a single scalar as an argument. This can be a string, in which case that
string will be treated as the input to the server. Alternately, you can
specify a filehandle which will be slurped in for input.

If you do not specify an argument, C<handle_input> reads from C<STDIN>
to get its input.

C<handle_input> returns a string that you can print directly as the
result to your client. (For example, in the HTTP and CGI servers,
the string includes all HTTP headers required.)

=head1 CLASS METHODS

The only class method is C<new>, which takes any of the
L</INSTANCE ATTRIBUTES> below as named parameters, like this:

 RPC::Any::Server::XMLRPC->new(dispatch => {}, allow_constants => 1);

It is recommended that you specify at least L</dispatch>.

=head1 INSTANCE ATTRIBUTES

All of these values can be set in C<new> and they can also be set on an
existing object by passing an argument to them
(like C<< $server->method($value) >>).

=over

=item C<dispatch>

This is a hashref that maps "package names" in RPC method requests
to actual Perl module names (in a format like C<My::Module::Name>).
For example, let's say that you have a C<dispatch> that looks like this:

 {
    'Util'     => 'Foo::Service::Util',
    'Calendar' => 'Bar::Baz'
 }

So then, calling the method C<Util.get> will call
C<< Foo::Service::Util->get >>. Calling C<Calendar.create> will call
C<< Bar::Baz->create >>. You don't have to pre-load the Perl modules,
RPC::Any::Server will load them for you when they are needed.

If you want to dispatch methods in some totally different way, then
you should override C<get_method> or C<get_package> in a subclass
of RPC::Any::Server.

See L</HOW RPC METHODS ARE CALLED> for more information on how this is used.

=item C<allow_constants>

By default, RPC::Any::Server doesn't allow you to call methods
whose names are all in caps. (So, for example, trying to call the
method C<Foo.THIS_METHOD> would throw an error.) If you would like
to allow calling methods whose names are all in caps, you can set
this to C<1>.

=item C<package_base>

Right before RPC::Any::Server calls a method, it modifies the
C<@ISA> array of the method's package so that it inherits from
this class. So, for example, let's say you have a L</dispatch>
that looks like C<< { 'Foo' => 'Bar::Baz' } >>, and somebody
calls C<Foo.some_method>. So RPC::Any::Server translates that to
a call to C<< Bar::Baz->some_method >>. Right before it calls
that method, it pushes the class listed in C<package_base> on
to the end of C<@Bar::Baz::ISA>. It remains in the C<@ISA> only
for the duration of the call, and then it is removed.

To see what functionality this gives you by default, see L</RPC::Any::Package>,
which describes the methods and functionality added to your class
immediately before the method is called.

=back

=head1 HOW RPC METHODS ARE CALLED

When RPC::Any::Server gets a request to call a method, it goes
through several steps:

=over

=item 1

We make sure that the method call has both a package and a method
name separated by a period. (If you don't want to call methods
in this way, you should subclass one of the RPC::Any::Server
implementations, and override C<get_method>.)

If there is more than one period in the name, we split at the
I<last> period, so the package name can contain multiple periods.

=item 2

We validate the method name. Private methods (methods whose names start
with an underscore) cannot be called using this interface. We also
make sure that the name isn't all uppercase, if L</allow_constants> is
off.

=item 3

We use L</dispatch> to locate and load the Perl module that contains
the method being called.

=item 4

We check that the module can execute the requested method, like
C<< $module->can($method) >>. (Because we use C<can>, if you use
C<AUTOLOAD> in your modules, you will have to explicitly declare
any sub that can be used (like C<sub something;>), or override C<can>
in your module.)

=item 5

We modify the Perl module's C<@ISA> to include the class from
L</package_base>. This lets you do
C<< $class->type('some_type', $some_value) >> inside of your methods to
explicitly type return values. See L</package_base> and L</RPC::Any::Package>
for more information.

=item 6

Your method is actually called, as a class method on the module, like
this:

 my @retval = $module->$method(@args);

Where C<@args> is the method arguments that you specified as part of the RPC
protocol.

=item 7

If you return a single item, that item is used as the return value.
If you return multiple items, they will be returned as an array.
If you return no items, then a single C<undef> will be the only
return value.

=back

=head1 RPC::Any::Package

Right before RPC::Any::Server calls your methods, it pushes
a protocol-specific class on to the C<@ISA> of your method's module.
(See L</package_base> for more details.) For example, if you are using
the XMLRPC server, it pushes C<RPC::Any::Package::XMLRPC> into your
module's C<@ISA>.

This adds a single method, L</type>, to your class, that you can
use to return explicit types of values. You don't I<have> to use
C<type> on your return values--RPC::Any will do its best to figure
out good types for them. But if you want to be explicit about your
return values, you should use C<type>.

You don't need to call C<type> for arrays and hashes--RPC::Any
always properly converts those.

=over

=item C<type>

Takes two arguments. The first is a string representing the name of
a type. The second is a scalar value. It returns an object (or sometimes
a scalar) that will be properly interpreted by RPC::Any as being the
type you specified.

You must not modify the value returned from C<type> in any way before
returning it.

In case your class already has a method named C<type>, you
can also call this method as C<rpc_type>.

Here are the valid types, and how they translate in the various
protocols:

=over

=item int

An integer. Translates to C<< <int> >> in XML-RPC, and a number without any
quotes on it in JSON-RPC.

=item double

A floating-point number. Translates to C<< <double> >> in XML-RPC and
a number without any quotes on it, in JSON-RPC. (Note, though, that
numbers like '2.0' may be convered to a literal C<2> when returned.)

=item string

A simple string. Translates to C<< <string> >> in XML-RPC and
a quoted string in JSON-RPC.

=item boolean

A true or false value. Translates to C<< <boolean> >> in XML-RPC,
with a C<0> or C<1> value. In JSON-RPC, translates to C<true> or
C<false>.

=item base64

A base64-encoded string. The input data will be encoded to base64--you
should not do the encoding yourself. This is the only way to transfer
binary data using RPC::Any. In XML-RPC, this translates to C<< <base64> >>.
In JSON-RPC it becomes a quoted string containing base64.

=item dateTime

A date and time. In XML-RPC, this translates to a C<< <dateTime.iso8601> >>
field, and will throw an error if you pass in a value that is not formatted
properly according to the XML-RPC spec. In JSON-RPC, no translation of the
passed-in value is done.

=item nil

A "null" value. If you pass C<undef> as the second argument to
C<type>, you will B<always> get this type back, regardless of what type
you requested. In XML-RPC, this translates differently depending on how
you've set L<RPC::Any::Server::XMLRPC/send_nil>. In JSON-RPC, this translates
to C<null>.

=back

=back

=head1 ERROR HANDLING

During any call to C<handle_input>, all calls to C<die> are trapped
and converted to an error format appropriate for the server being
used. (So, for example, if you are using an XML-RPC server, the
output will be an XML-RPC error if I<anything> goes wrong with the
server.)

By default, all errors are of the type L<RPC::Any::Exception/PerlError>,
meaning that they have the code -32603. If you want to specify your
own error codes (or if you don't want the C<at some/dir/foo.pl> string
in your errors), you can die with an RPC::Any::Exception, like this:

  use RPC::Any::Exception;
  die RPC::Any::Exception(code => 123, message => "I'm dead!");

And that will be translated properly by the RPC::Any::Server into
an RPC error.

=head1 TAINT BEHAVIOR

If you give RPC::Any::Server tainted input, then it will taint all
the arguments it passes to your methods.

=head1 UNICODE

For simplicity's sake, RPC::Any assumes that all I<output> from the
server will be UTF-8.

RPC::Any does its best to handle Unicode input well. However, if you expect
perfect Unicode handling, you should make sure that your input is marked
clearly as Unicode. For the basic (non-HTTP) servers, this means that you
should pass in character strings with the "utf8 bit" turned on. For HTTP
servers, this means you should send a C<charset> of C<UTF-8> in your
C<Content-Type> header.

=head1 SEE ALSO

L<RPC::Any> for general information about RPC::Any.

The various server modules:

=over

=item L<RPC::Any::Server::XMLRPC>

=item L<RPC::Any::Server::XMLRPC::HTTP>

=item L<RPC::Any::Server::XMLRPC::CGI>

=item L<RPC::Any::Server::JSONRPC>

=item L<RPC::Any::Server::JSONRPC::HTTP>

=item L<RPC::Any::Server::JSONRPC::CGI>

=back