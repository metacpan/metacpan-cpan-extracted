package Params::CallbackRequest;

use strict;
use Params::Validate ();
use Params::CallbackRequest::Exceptions (abbr => [qw(throw_bad_params
                                                     throw_bad_key
                                                     throw_cb_exec)]);

use vars qw($VERSION);
$VERSION = '1.20';

BEGIN {
    for my $attr (qw( default_priority
                      default_pkg_key
                      redirected )) {
        no strict 'refs';
        *{$attr} = sub { $_[0]->{$attr} };
    }
}

Params::Validate::validation_options
  ( on_fail => sub { throw_bad_params join '', @_ } );

# We'll use this code reference for cb_classes parameter validation.
my $valid_cb_classes = sub {
    # Just return true if they use the string "ALL".
    return 1 if $_[0] eq 'ALL';
    # Return false if it isn't an array.
    return unless ref $_[0] || '' eq 'ARRAY';
    # Return true if the first value isn't the string "_ALL_";
    return 1 if $_[0]->[0] ne '_ALL_';
    # Return false if there's more than one element in the array.
    return if @{$_[0]} > 1;
    # Just return true.
    return 1;
};

# This is our default exception handler.
my $exception_handler = sub {
    my $err = shift;
    rethrow_exception($err) if ref $err;
    throw_cb_exec error          => "Error thrown by callback: $err",
                  callback_error => $err;
};

# Set up the valid parameters to new().
my %valid_params = (
    default_priority => {
        type      => Params::Validate::SCALAR,
        callbacks => {
            'valid priority' => sub { $_[0] =~ /^\d$/ }
        },
        default => 5,
    },

    default_pkg_key => {
        type    => Params::Validate::SCALAR,
        default => 'DEFAULT',
    },

    callbacks => {
        type     => Params::Validate::ARRAYREF,
        optional => 1,
    },

    pre_callbacks => {
        type     => Params::Validate::ARRAYREF,
        optional => 1,
    },

    post_callbacks => {
        type     => Params::Validate::ARRAYREF,
        optional => 1,
    },

    cb_classes => {
        type      => Params::Validate::ARRAYREF | Params::Validate::SCALAR,
        callbacks => { 'valid cb_classes' => $valid_cb_classes },
        optional  => 1,
    },

    ignore_nulls => {
        type    => Params::Validate::BOOLEAN,
        default => 0,
    },

    exception_handler => {
        type    => Params::Validate::CODEREF,
        default => $exception_handler
    },

    leave_notes => {
        type    => Params::Validate::BOOLEAN,
        default => 0,
    },
);

BEGIN {
    # Load up any callback class definitions.
    require Params::Callback;
    Params::Callback::_find_names();
}

sub new {
    my $proto = shift;
    my %p = Params::Validate::validate(@_, \%valid_params);

    # Grab any class callback specifications.
    @p{qw(_cbs _pre _post)} = Params::Callback->_load_classes($p{cb_classes})
      if $p{cb_classes};

    # Process parameter-triggered callback specs.
    if (my $cb_specs = delete $p{callbacks}) {
        my %cbs;
        foreach my $spec (@$cb_specs) {
            # Set the default package key.
            $spec->{pkg_key} ||= $p{default_pkg_key};

            # Make sure that we have a callback key.
            throw_bad_params "Missing or invalid callback key"
              unless $spec->{cb_key};

            # Make sure that we have a valid priority.
            if (defined $spec->{priority}) {
                throw_bad_params "Not a valid priority: '$spec->{priority}'"
                  unless $spec->{priority} =~ /^\d$/;
            } else {
                # Or use the default.
                $spec->{priority} = $p{default_priority};
            }

            # Make sure that we have a code reference.
            throw_bad_params "Callback for package key '$spec->{pkg_key}' " .
              "and callback key '$spec->{cb_key}' not a code reference"
              unless ref $spec->{cb} eq 'CODE';

            # Make sure that the key isn't already in use.
            throw_bad_params "Callback key '$spec->{cb_key}' already used " .
              "by package key '$spec->{pkg_key}'"
              if $p{_cbs}{$spec->{pkg_key}}->{$spec->{cb_key}};

            # Set it up.
            $p{_cbs}{$spec->{pkg_key}}->{$spec->{cb_key}} =
              { cb => $spec->{cb}, priority => $spec->{priority} };
        }
    }

    # Now validate and store any request callbacks.
    foreach my $type (qw(pre post)) {
        if (my $cbs = delete $p{$type . '_callbacks'}) {
            my @gcbs;
            foreach my $cb (@$cbs) {
                # Make it an array unless Params::Callback has already
                # done so.
                $cb = [$cb, 'Params::Callback']
                  unless ref $cb eq 'ARRAY';
                # Make sure that we have a code reference.
                throw_bad_params "Request $type callback not a code reference"
                  unless ref $cb->[0] eq 'CODE';
                push @gcbs, $cb;
            }
            # Keep 'em.
            $p{"_$type"} = \@gcbs;
        }
    }

    # Warn 'em if they're not using any callbacks.
    unless ($p{_cbs} or $p{_pre} or $p{_post}) {
        require Carp;
        Carp::carp("You didn't specify any callbacks.");
    }

    # Set up the notes hash.
    $p{notes} = {};

    # Let 'em have it.
    return bless \%p, ref $proto || $proto;
}

sub request {
    my ($self, $params) = (shift, shift);
    return $self unless $params;
    throw_bad_params "Parameter '$params' is not a hash reference"
      unless UNIVERSAL::isa($params, 'HASH');

    # Use an array to store the callbacks according to their priorities. Why
    # an array when most of its indices will be undefined? Well, because I
    # benchmarked it vs. a hash, and found a very negligible difference when
    # the array had only element five filled (with no 6-9 elements) and the
    # hash had only one element. Furthermore, in all cases where the array had
    # two elements (with the other 8 undef), it outperformed the two-element
    # hash every time. But really this just starts to come down to very fine
    # differences compared to the work that the callbacks will likely be
    # doing, anyway. And in the meantime, the array is just easier to use,
    # since the priorities are just numbers, and its easist to unshift and
    # push on the request callbacks than to stick them onto a hash. In short,
    # the use of arrays is cleaner, easier to read and maintain, and almost
    # always just as fast or faster than using hashes. So that's the way it'll
    # be.
    my (@cbs, %cbhs);
    if ($self->{_cbs}) {
        foreach my $k (keys %$params) {
            # Strip off the '.x' that an <input type="image" /> tag creates.
            (my $chk = $k) =~ s/\.x$//;
            if ((my $key = $chk) =~ s/_cb(\d?)$//) {
                # It's a callback field. Grab the priority.
                my $priority = $1;

                # Skip callbacks without values, if necessary.
                next if $self->{ignore_nulls} &&
                  (! defined $params->{$k} || $params->{$k} eq '');

                if ($chk ne $k) {
                    # Some browsers will submit $k.x and $k.y instead of just
                    # $k for <input type="image" />, which is a field that can
                    # only be submitted once for a given page. So skip it if
                    # we've already seen this parameter.
                    next if exists $params->{$chk};
                    # Otherwise, add the unadorned key to $params with a true
                    # value.
                    $params->{$chk} = 1;
                }

                # Find the package key and the callback key.
                my ($pkg_key, $cb_key) = split /\|/, $key, 2;
                next unless $pkg_key;

                # Find the callback.
                my $cb;
                my $class = $self->{_cbs}{$pkg_key} or
                  throw_bad_key error        => "No such callback package " .
                                                "'$pkg_key'",
                                callback_key => $chk;

                if (ref $class) {
                    # It's a functional callback. Grab it.
                    $cb = $class->{$cb_key}{cb} or
                      throw_bad_key error        => "No callback found for " .
                                                    "callback key '$chk'",
                                    callback_key => $chk;

                    # Get the specified priority if none was included in the
                    # callback key.
                    $priority = $class->{$cb_key}{priority}
                      unless $priority ne '';
                    $class = 'Params::Callback';
                } else {
                    # It's a method callback. Get it from the class.
                    $cb = $class->_get_callback($cb_key, \$priority) or
                      throw_bad_key error        => "No callback found for " .
                                                    "callback key '$chk'",
                                    callback_key => $chk;
                }

                # Push the callback onto the stack, along with the parameters
                # for the construction of the Params::Callback object that
                # will be passed to it.
                $cbhs{$class} ||= $class->new( @_,
                                               params  => $params,
                                               cb_request => $self );
                push @{$cbs[$priority]},
                  [ $cb, $cbhs{$class},
                    [ $priority, $cb_key, $pkg_key, $chk, $params->{$k} ]
                  ];
            }
        }
    }

    # Put any pre and post request callbacks onto the stack.
    if ($self->{_pre} or $self->{_post}) {
        my $params = [ @_,
                       params  => $params,
                       cb_request => $self ];
        unshift @cbs,
          [ map { [ $_->[0], $cbhs{$_} || $_->[1]->new(@$params), [] ] }
            @{$self->{_pre}} ]
          if $self->{_pre};

        push @cbs,
          [ map { [ $_->[0], $cbhs{$_} || $_->[1]->new(@$params), [] ] }
            @{$self->{_post}} ]
          if $self->{_post};
    }

    # Now execute the callbacks.
    eval {
        foreach my $cb_list (@cbs) {
            # Skip it if there are no callbacks for this priority.
            next unless $cb_list;
            foreach my $cb_data (@$cb_list) {
                my ($cb, $cbh, $cbargs) = @$cb_data;
                # Cheat! But this keeps them read-only for the client.
                @{$cbh}{qw(priority cb_key pkg_key trigger_key value)} =
                  @$cbargs;
                # Execute the callback.
                $cb->($cbh);
            }
        }
    };

    # Clear out the redirected attribute, the status, and notes.
    my $redir = delete $self->{redirected};
    my $status = delete $self->{_status};
    %{$self->{notes}} = () unless $self->{leave_notes};

    if (my $err = $@) {
        # Just pass the exception to the exception handler unless it's an
        # abort.
        return $status if isa_cb_exception($err, 'Abort');
        $self->{exception_handler}->($err);
    }

    # We now return to normal processing.
    return $redir ? $status : $self;
}

sub notes {
    my $self = shift;
    return $self->{notes} unless @_;
    my $key = shift;
    return @_
      ? $self->{notes}{$key} = shift
      : $self->{notes}{$key};
}

sub clear_notes {
    %{shift->{notes}} = ();
}

1;
__END__

=head1 NAME

Params::CallbackRequest - Functional and object-oriented callback architecture

=head1 SYNOPSIS

Functional parameter-triggered callbacks:

  use strict;
  use Params::CallbackRequest;

  # Create a callback function.
  sub calc_time {
      my $cb = shift;
      my $params = $cb->params;
      my $val = $cb->value;
      $params->{my_time} = localtime($val || time);
  }

  # Set up a callback request object.
  my $cb_request = Params::CallbackRequest->new(
      callbacks => [ { cb_key  => 'calc_time',
                       pkg_key => 'myCallbacker',
                       cb      => \&calc_time } ]
  );

  # Request callback execution.
  my %params = ('myCallbacker|calc_time_cb' => 1);
  $cb_request->request(\%params);

  # Demonstrate the result.
  print "The time is $params{my_time}\n";

Or, in a subclass of Params::Callback:

  package MyApp::Callback;
  use base qw(Params::Callback);
  __PACKAGE__->register_subclass( class_key => 'myCallbacker' );

  # Set up a callback method.
  sub calc_time : Callback {
      my $self = shift;
      my $params = $self->request_params;
      my $val = $cb->value;
      $params->{my_time} = localtime($val || time);
  }

And then, in your application:

  # Load order is important here!
  use MyApp::Callback;
  use Params::CallbackRequest;

  my $cb_request = Params::Callback->new( cb_classes => [qw(myCallbacker)] );
  my %params = ('myCallbacker|calc_time_cb' => 1);
  $cb_request->request(\%params);
  print "The time is $params{my_time}\n";

=begin comment

=head1 ABSTRACT

Params::CallbackRequest provides functional and object-oriented callbacks to
method and function parameters. Callbacks can either be "request callbacks,"
triggered for every call to C<request()> method; or can be triggered by
special parameter hash key names. Although potentially useful in any Perl
application, Params::CallbackRequest was designed to be used with web
applications, where the parameters submitted by the browser may be configured
specifically to trigger callbacks on the server.

=end comment

=head1 DESCRIPTION

Params::CallbackRequest provides functional and object-oriented callbacks to
method and function parameters. Callbacks may be either code references
provided to the C<new()> constructor, or methods defined in subclasses of
Params::Callback. Callbacks are triggered either for every call to the
Params::CallbackRequest C<request()> method, or by specially named keys in the
parameters to C<request()>.

The idea behind this module is to provide a sort of plugin architecture for
Perl templating systems. Callbacks are triggered by the contents of a request
to the Perl templating server, before the templating system itself executes.
This approach allows you to carry out logical processing of data submitted
from a form, to affect the contents of the request parameters before they're
passed to the templating system for processing, and even to redirect or abort
the request before the templating system handles it.

=head1 JUSTIFICATION

Why would you want to do this? Well, there are a number of reasons. Some I can
think of offhand include:

=over 4

=item Stricter separation of logic from presentation

While some Perl templating systems enforce separation of application logic
from presentation (e.g., TT, HTML::Template), others do not (e.g.,
HTML::Mason, Apache::ASP). Even in the former case, application logic is often
put into scripts that are executed alongside the presentation templates, and
loaded on-demand under mod_perl. By moving the application logic into Perl
modules and then directing the templating system to execute that code as
callbacks, you obviously benefit from a cleaner separation of application
logic and presentation.

=item Widgitization

Thanks to their ability to preprocess parameters, callbacks enable developers
to develop easier-to-use, more dynamic widgets that can then be used in any
and all templating systems. For example, a widget that puts many related
fields into a form (such as a date selection widget) can have its fields
preprocessed by a callback (for example, to properly combine the fields into a
unified date parameter) before the template that responds to the form
submission gets the data. See L<Params::Callback|Params::Callbck/"Subclassing
Examples"> for an example solution for this very problem.

=item Shared Memory

If you run your templating system under mod_perl, callbacks are just Perl
subroutines in modules loaded at server startup time. Thus the memory they
consume is all in the Apache parent process, and shared by the child
processes. For code that executes frequently, this can be much less
resource-intensive than code in templates, since templates are loaded
separately in each Apache child process on demand.

=item Performance

Since they're executed before the templating architecture does much
processing, callbacks have the opportunity to short-circuit the template
processing by doing something else. A good example is redirection. Often the
application logic in callbacks does its thing and then redirects the user to a
different page. Executing the redirection in a callback eliminates a lot of
extraneous processing that would otherwise be executed before the redirection,
creating a snappier response for the user.

=item Testing

Templating system templates are not easy to test via a testing framework such
as Test::Harness. Subroutines in modules, on the other hand, are fully
testable. This means that you can write tests in your application test suite
to test your callback subroutines.

=back

And if those aren't enough reasons, then just consider this: Callbacks are
just I<way cool.>

=head1 USAGE

Params::CallbackRequest supports two different types of callbacks: those
triggered by a specially named parameter keys, and those executed for every
request.

=head2 Parameter-Triggered Callbacks

Parameter-triggered callbacks are triggered by specially named parameter
keys. These keys are constructed as follows: The package name followed by a
pipe character ("|"), the callback key with the string "_cb" appended to it,
and finally an optional priority number at the end. For example, if you
specified a callback with the callback key "save" and the package key "world",
a callback field might be specified like this:

  my $params = { "world|save_cb" => 'Save World' };

When the parameters hash $params is passed to Params::CallbackRequest's
C<request()> method, the C<world|save_cb> parameter would trigger the callback
associated with the "save" callback key in the "world" package. If such a
callback hasn't been configured, then Params::CallbackRequest will throw a
Params::CallbackRequest::Exceptions::InvalidKey exception. Here's how to configure a
functional callback when constructing your Params::CallbackRequest object so
that that doesn't happen:

  my $cb_request = Params::CallbackRequest->new
    ( callbacks => [ { pkg_key => 'world',
                       cb_key  => 'save',
                       cb      => \&My::World::save } ] );

With this configuration, the C<world|save_cb> parameter key will trigger the
execution of the C<My::World::save()> subroutine during a callback request:

  # Execute parameter-triggered callback.
  $cb_request->request($params);

=head3 Functional Callback Subroutines

Functional callbacks use a code reference for parameter-triggered callbacks,
and Params::CallbackRequest executes them with a single argument, a
Params::Callback object. Thus, a callback subroutine will generally look
something like this:

  sub foo {
      my $cb = shift;
      # Do stuff.
  }

The Params::Callback object provides accessors to data relevant to the
callback, including the callback key, the package key, and the parameter
hash. It also includes an C<abort()> method. See the
L<Params::Callback|Params::Callback> documentation for all the goodies.

Note that Params::CallbackRequest installs an exception handler during the
execution of callbacks, so if any of your callback subroutines C<die>,
Params::CallbackRequest will throw an Params::Callback::Exception::Execution
exception. If your callback subroutines throw their own exception objects,
Params::CallbackRequest will simply rethrow them. If you don't like this
configuration, use the C<exception_handler> parameter to C<new()> to install
your own exception handler.

=head3 Object-Oriented Callback Methods

Object-oriented callback methods, which are supported under Perl 5.6 or later,
are defined in subclasses of Params::Callback, and identified by attributes in
their declarations. Unlike functional callbacks, callback methods are not
called with a Params::Callback object, but with an instance of the callback
subclass. These classes inherit all the goodies provided by Params::Callback,
so you can essentially use their instances exactly as you would use the
Params::Callback object in functional callback subroutines. But because
they're subclasses, you can add your own methods and attributes. See
L<Params::Callback|Params::Callback/"SUBCLASSING"> for all the gory details on
subclassing, along with a few examples. Generally, callback methods will look
like this:

  sub foo : Callback {
      my $self = shift;
      # Do stuff.
  }

As with functional callback subroutines, method callbacks are executed with a
custom exception handler. Again, see the C<exception_handler> parameter to
install your own exception handler.

B<Note:> Under mod_perl, it's important that you C<use> any and all
Params::Callback subclasses I<before> you C<use Params::CallbackRequest>. This
is to get around an issue with identifying the names of the callback methods
in mod_perl. Read the comments in the Params::Callback source code if you're
interested in learning more.

=head3 The Package Key

The use of the package key is a convenience so that a system with many
functional callbacks can use callbacks with the same keys but in different
packages. The idea is that the package key will uniquely identify the module
in which each callback subroutine is found, but it doesn't necessarily have to
be so. Use the package key any way you wish, or not at all:

  my $cb_request = Params::CallbackRequest->new
    ( callbacks => [ { cb_key  => 'save',
                       cb      => \&My::World::save } ] );

But note that if you don't specify the package key, you'll still need to
provide one in the parameter hash passed to C<request()>. By default, that key
is "DEFAULT". Such a callback parameter would then look like this:

  my $params = { "DEFAULT|save_cb" => 'Save World' };

If you don't like the "DEFAULT" package name, you can set an alternative
default using the C<default_pkg_name> parameter to C<new()>:

  my $cb_request = Params::CallbackRequest->new
    ( callbacks        => [ { cb_key  => 'save',
                              cb      => \&My::World::save } ],
      default_pkg_name => 'MyPkg' );

Then, of course, any callbacks without a specified package key of their own
must then use the custom default:

  my $params = { "MyPkg|save_cb" => 'Save World' };
  $cb_request->request($params);

=head3 The Class Key

The class key is essentially a synonym for the package key, but applies more
directly to object-oriented callbacks. The difference is mainly that it
corresponds to an actual class, and that all Params::Callback subclasses are
I<required> to have a class key; it's not optional as it is with functional
callbacks. The class key may be declared in your Params::Callback subclass
like so:

  package MyApp::CallbackHandler;
  use base qw(Params::Callback);
  __PACKAGE__->register_subclass( class_key => 'MyCBHandler' );

The class key can also be declared by implementing a C<CLASS_KEY> subroutine,
like so:

  package MyApp::CallbackHandler;
  use base qw(Params::Callback);
  __PACKAGE__->register_subclass;
  use constant CLASS_KEY => 'MyCBHandler';

If no class key is explicitly defined, Params::Callback will use the subclass
name, instead. In any event, the C<register_callback()> method B<must> be
called to register the subclass with Params::Callback. See the
L<Params::Callback|Params::Callback/"Callback Class Declaration">
documentation for complete details.

=head3 Priority

Sometimes one callback is more important than another. For example, you might
rely on the execution of one callback to set up variables needed by another.
Since you can't rely on the order in which callbacks are executed (the
parameters are passed via a hash, and the processing of a hash is, of course,
unordered), you need a method of ensuring that the setup callback executes
first.

In such a case, you can set a higher priority level for the setup callback
than for callbacks that depend on it. For functional callbacks, you can do it
like this:

  my $cb_request = Params::CallbackRequest->new
    ( callbacks        => [ { cb_key   => 'setup',
                              priority => 3,
                              cb       => \&setup },
                            { cb_key   => 'save',
                              cb       => \&save }
                          ] );

For object-oriented callbacks, you can define the priority right in the
callback method declaration:

  sub setup : Callback( priority => 3 ) {
      my $self = shift;
      # ...
  }

  sub save : Callback {
      my $self = shift;
      # ...
  }

In these examples, the "setup" callback has been configured with a priority
level of "3". This ensures that it will always execute before the "save"
callback, which has the default priority of "5". Obviously, this is true
regardless of the order of the fields in the hash:

  my $params = { "DEFAULT|save_cb"  => 'Save World',
                 "DEFAULT|setup_cb" => 1 };

In this configuration, the "setup" callback will always execute first because
of its higher priority.

Although the "save" callback got the default priority of "5", this too can be
customized to a different priority level via the C<default_priority> parameter
to C<new()> for functional callbacks and the C<default_priority> to the class
declaration for object-oriented callbacks. For example, this functional
callback configuration:

  my $cb_request = Params::CallbackRequest->new
    ( callbacks        => [ { cb_key   => 'setup',
                              priority => 3,
                              cb       => \&setup },
                            { cb_key   => 'save',
                              cb       => \&save }
                          ],
      default_priority => 2 );

Or this Params::Callback subclass declaration:

  package MyApp::CallbackHandler;
  use base qw(Params::Callback);
  __PACKAGE__->register_subclass( class_key        => 'MyCBHandler',
                                  default_priority => 2 );

Will cause the "save" callback to always execute before the "setup" callback,
since its priority level will default to "2".

In addition, the priority level can be overridden via the parameter key itself
by appending a priority level to the end of the key name. Hence, this example:

  my $params = { "DEFAULT|save_cb2" => 'Save World',
                 "DEFAULT|setup_cb" => 1 };

Causes the "save" callback to execute before the "setup" callback by
overriding the "save" callback's priority to level "2". Of course, any other
parameter key that triggers the "save" callback without a priority override
will still execute the "save" callback at its configured level.

=head2 Request Callbacks

Request callbacks come in two flavors: those that execute before the
parameter-triggered callbacks, and those that execute after the
parameter-triggered callbacks. Functional request callbacks may be specified
via the C<pre_callbacks> and C<post_callbacks> parameters to C<new()>,
respectively:

  my $cb_request = Params::CallbackRequest->new
    ( pre_callbacks  => [ \&translate, \&foobarate ],
      post_callbacks => [ \&escape, \&negate ] );

Object-oriented request callbacks may be declared via the C<PreCallback> and
C<PostCallback> method attributes, like so:

  sub translate : PreCallback { ... }
  sub foobarate : PreCallback { ... }
  sub escape : PostCallback { ... }
  sub negate : PostCallback { ... }

In these examples, the C<translate()> and C<foobarate()> subroutines or
methods will execute (in that order) before any parameter-triggered callbacks
are executed (none will be in these examples, since none are specified).

Conversely, the C<escape()> and C<negate()> subroutines or methods will be
executed (in that order) after all parameter-triggered callbacks have been
executed. And regardless of what parameter-triggered callbacks may be
triggered, the request callbacks will always be executed for I<every> request
(unless an exception is thrown by an earlier callback).

Although they may be used for different purposes, the C<pre_callbacks> and
C<post_callbacks> functional callback code references expect the same argument
as parameter-triggered functional callbacks: a Params::Callback object:

  sub foo {
      my $cb = shift;
      # Do your business here.
  }

Similarly, object-oriented request callback methods will be passed an object
of the class defined in the class key portion of the callback trigger --
either an object of the class in which the callback is defined, or an object
of a subclass:

  sub foo : PostCallback {
      my $self = shift;
      # ...
  }

Of course, the attributes of the Params::Callback or subclass object will be
different than in parameter-triggered callbacks. For example, the C<priority>,
C<pkg_key>, and C<cb_key> attributes will naturally be undefined. It will,
however, be the same instance of the object passed to all other functional
callbacks -- or to all other class callbacks with the same class key -- in a
single request.

Like the parameter-triggered callbacks, request callbacks run under the nose
of a custom exception handler, so if any of them C<die>s, an
Params::Callback::Exception::Execution exception will be thrown. Use the
C<exception_handler> parameter to C<new()> if you don't like this.

=head1 INTERFACE

=head2 Parameters To The C<new()> Constructor

Params::CallbackRequest supports a number of its own parameters to the C<new()>
constructor (though none of them, sadly, trigger callbacks). The parameters to
C<new()> are as follows:

=over 4

=item C<callbacks>

Parameter-triggered functional callbacks are configured via the C<callbacks>
parameter. This parameter is an array reference of hash references, and each
hash reference specifies a single callback. The supported keys in the callback
specification hashes are:

=over 4

=item C<cb_key>

Required. A string that, when found in a properly-formatted parameter hash key,
will trigger the execution of the callback.

=item C<cb>

Required. A reference to the Perl subroutine that will be executed when the
C<cb_key> has been found in a parameter hash passed to C<request()>. Each code
reference should expect a single argument: a Params::Callback object. The same
instance of a Params::Callback object will be used for all functional
callbacks in a single call to C<request()>.

=item C<pkg_key>

Optional. A key to uniquely identify the package in which the callback
subroutine is found. This parameter is useful in systems with many callbacks,
where developers may wish to use the same C<cb_key> for different subroutines
in different packages. The default package key may be set via the
C<default_pkg_key> parameter to C<new()>.

=item C<priority>

Optional. Indicates the level of priority of a callback. Some callbacks are
more important than others, and should be executed before the others.
Params::CallbackRequest supports priority levels ranging from "0" (highest
priority) to "9" (lowest priority). The default priority for functional
callbacks may be set via the C<default_priority> parameter.

=back

=item C<pre_callbacks>

This parameter accepts an array reference of code references that should be
executed for I<every> call to C<request()> I<before> any parameter-triggered
callbacks. They will be executed in the order in which they're listed in the
array reference. Each code reference should expect a Params::Callback object
as its sole argument. The same instance of a Params::Callback object will be
used for all functional callbacks in a single call to C<request()>. Use
pre-parameter-triggered request callbacks when you want to do something with
the parameters submitted for every call to C<request()>, such as convert
character sets.

=item C<post_callbacks>

This parameter accepts an array reference of code references that should be
executed for I<every> call to C<request()> I<after> all parameter-triggered
callbacks have been called. They will be executed in the order in which
they're listed in the array reference. Each code reference should expect a
Params::Callback object as its sole argument. The same instance of a
Params::Callback object will be used for all functional callbacks in a single
call to C<request()>. Use post-parameter-triggered request callbacks when you
want to do something with the parameters submitted for every call to
C<request()>, such as encode or escape their values for presentation.

=item C<cb_classes>

An array reference listing the class keys of all of the Params::Callback
subclasses containing callback methods that you want included in your
Params::CallbackRequest object. Alternatively, the C<cb_classes> parameter may
simply be the word "ALL", in which case I<all> Params::Callback subclasses
will have their callback methods registered with your Params::CallbackRequest
object. See the L<Params::Callback|Params::Callback> documentation for details
on creating callback classes and methods.

B<Note:> In a mod_perl environment, be sure to C<use Params::CallbackRequest>
I<only> after you've C<use>d all of the Params::Callback subclasses you need
or else you won't be able to use their callback methods.

=item C<default_priority>

The priority level at which functional callbacks will be executed. Does not
apply to object-oriented callbacks. This value will be used in each hash
reference passed via the C<callbacks> parameter to C<new()> that lacks a
C<priority> key. You may specify a default priority level within the range of
"0" (highest priority) to "9" (lowest priority). If not specified, it defaults
to "5".

=item C<default_pkg_key>

The default package key for functional callbacks. Does not apply to
object-oriented callbacks. This value that will be used in each hash reference
passed via the C<callbacks> parameter to C<new()> that lacks a C<pkg_key>
key. It can be any string that evaluates to a true value, and defaults to
"DEFAULT" if not specified.

=item C<ignore_nulls>

By default, Params::CallbackRequest will execute all callbacks triggered by
parameter hash keys. However, in many situations it may be desirable to skip
any callbacks that have no value for the callback field. One can do this by
simply checking C<< $cbh->value >> in the callback, but if you need to disable
the execution of all parameter-triggered callbacks when the callback parameter
value is undefined or the null string (''), pass the C<ignore_null> parameter
with a true value. It is set to a false value by default.

=item C<leave_notes>

By default, Params::CallbackRequest will clear out the contents of the hash
accessed via the C<notes()> method just before returning from a call to
C<request()>. There may be some circumstances when it's desirable to allow the
notes hash to persist beyond the duration of a a call to C<request()>. For
example, a templating architecture may wish to keep the notes around for the
duration of the execution of a template request. In such cases, pass a true
value to the C<leave_notes> parameter, and use the C<clear_notes()> method to
manually clear out the notes hash at the appropriate point.

=item C<exception_handler>

Params::CallbackRequest installs a custom exception handler during the
execution of callbacks. This custom exception handler will simply rethrow any
exception objects it comes across, but will throw a
Params::Callback::Exception::Execution exception object if it is passed only a
string value (such as is passed by C<die "fool!">).

But if you find that you're throwing your own exceptions in your callbacks,
and want to handle them differently, pass the C<exception_handler> parameter a
code reference to do what you need.

=back

=head2 Instance Methods

Params::CallbackRequest of course has several instance methods. I cover the most
important, first.

=head3 request

  $cb_request->request(\%params);

  # If you're in a mod_perl environment, pass in an Apache request object
  # to be passed to the Callback classes.
  $cb_request->request(\%params, apache_req => $r);

  # Or pass in argument to be passed to callback class constructors.
  $cb_request->request(\%params, @args);

Executes the callbacks specified when the Params::CallbackRequest object was
created. It takes a single required argument, a hash reference of
parameters. Any subsequent arguments are passed to the constructor for each
callback class for which callbacks will be executed. By default, the only
extra parameter supported by the Params::Callback base class is an Apache
request object, which can be passed via the C<apache_req> parameter. Returns
the Params::CallbackRequest object on success, or the code passed to
Params::Callback's C<abort()> method if callback execution was aborted.

A single call to C<request()> is referred to as a "callback request"
(naturally!). First, all pre-request callbacks are executed. Then, any
parameter-triggered callbacks triggered by the keys in the parameter hash
reference passed as the sole argument are executed. And finally, all
post-request callbacks are executed. C<request()> returns the
Params::CallbackRequest object on successful completion of the request.

Any callback that calls C<abort()> on its Params::Callback object will prevent
any other callbacks scheduled by the request to run subsequent to its
execution from being executed (including post-request callbacks). Furthermore,
any callback that C<die>s or throws an exception will of course also prevent
any subsequent callbacks from executing, and in addition must also be caught
by the caller or the whole process will terminate:

  eval { $cb_request->request(\%params) };
  if (my $err = $@) {
      # Handle exception.
  }

=head3 notes

  $cb_request->notes($key => $value);
  my $val = $cb_request->notes($key);
  my $notes = $cb_request->notes;

The C<notes()> method provides a place to store application data, giving
developers a way to share data among multiple callbacks over the course of a
call to C<request()>. Any data stored here persists for the duration of the
request unless the C<leave_notes> parameter to C<new()> has been passed a true
value. In such cases, use C<clear_notes()> to manually clear the notes.

Conceptually, C<notes()> contains a hash of key-value pairs. C<notes($key,
$value)> stores a new entry in this hash. C<notes($key)> returns a previously
stored value. C<notes()> without any arguments returns a reference to the
entire hash of key-value pairs.

C<notes()> is similar to the mod_perl method C<< $r->pnotes() >>. The main
differences are that this C<notes()> can be used in a non-mod_perl
environment, and that its lifetime is tied to the lifetime of the call to
C<request()> unless the C<leave_notes> parameter is true.

For the sake of convenience, a shortcut to C<notes()> is provide to callback
code via the L<C<notes()>|Params::Callback/"notes"> method in
Params::Callback.

=head3 clear_notes

  $cb_request->clear_notes;

Use this method to clear out the notes hash. Most useful when the
C<leave_notes> parameter to C<new()> has been set to at true value and you
need to manage the clearing of notes yourself. This method is specifically
designed for a templating environment, where it may be advantageous for the
templating architecture to allow the notes to persist beyond the duration of a
call to C<request()>, e.g., to keep them for the duration of a call to the
templating architecture itself. See
L<MasonX::Interp::WithCallbacks|MasonX::Interp::WithCallbacks> for an example
of this strategy.

=head2 Accessor Methods

The properties C<default_priority> and C<default_pkg_key> have standard
read-only accessor methods of the same name. For example:

  my $cb_request = Params::CallbackRequest->new;
  my $default_priority = $cb_request->default_priority;
  my $default_pkg_key = $cb_request->default_pkg_key;

=head1 ACKNOWLEDGMENTS

Garth Webb implemented the original callbacks in Bricolage, based on an idea
he borrowed from Paul Lindner's work with Apache::ASP. My thanks to them both
for planting this great idea! This implementation is however completely
independent of previous implementations.

=head1 SEE ALSO

L<Params::Callback|Params::Callback> objects get passed as the sole argument
to all functional callbacks, and offer access to data relevant to the
callback. Params::Callback also defines the object-oriented callback
interface, making its documentation a must-read for anyone who wishes to
create callback classes and methods.

L<MasonX::Interp::WithCallbacks|MasonX::Intper::WithCallbacks> uses this
module to provide a callback architecture for HTML::Mason.

=head1 SUPPORT

This module is stored in an open L<GitHub
repository|http://github.com/theory/params-callbackrequest/>. Feel free to
fork and contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/theory/params-callbackrequest/issues/> or by sending
mail to
L<bug-params-callbackrequest@rt.cpan.org|mailto:bug-params-callbackrequest@rt.cpan.org>.

=head1 AUTHOR

David E. Wheeler <david@justatheory.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2011 David E. Wheeler. Some Rights Reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
