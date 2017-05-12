package Params::Callback;

use strict;
require 5.006;
use Params::Validate ();
use Params::CallbackRequest::Exceptions (abbr => [qw(throw_bad_params)]);

use vars qw($VERSION);
$VERSION = '1.20';
use constant DEFAULT_PRIORITY => 5;
use constant REDIRECT => 302;

# Set up an exception to be thrown by Params::Validate, and allow extra
# parameters not specified, since subclasses may add others.
Params::Validate::validation_options
  ( on_fail     => sub { throw_bad_params join '', @_ },
    allow_extra => 1 );

my $is_num = { 'valid priority' => sub { $_[0] =~ /^\d$/ } };

# Use Apache2?::RequestRec for mod_perl 2
use constant APREQ_CLASS => exists $ENV{MOD_PERL_API_VERSION}
    ? $ENV{MOD_PERL_API_VERSION} >= 2
        ? 'Apache2::RequestRec'
        : 'Apache::RequestRec'
    : 'Apache';

BEGIN {
    # The object-oriented interface is only supported with the use of
    # Attribute::Handlers in Perl 5.6 and later. We'll use Class::ISA
    # to get a list of all the classes that a class inherits from so
    # that we can tell ApacheHandler::WithCallbacks that they exist and
    # are loaded.
    unless ($] < 5.006) {
        require Attribute::Handlers;
        require Class::ISA;
    }

    # Build read-only accessors.
    for my $attr (qw(
        cb_request
        params
        apache_req
        priority
        cb_key
        pkg_key
        requester
        trigger_key
        value
    )) {
        no strict 'refs';
        *{$attr} = sub { $_[0]->{$attr} };
    }
    *class_key = \&pkg_key;
}

my %valid_params = (
    cb_request => { isa => 'Params::CallbackRequest' },

    params => {
        type => Params::Validate::HASHREF,
    },

    apache_req => {
        isa      => APREQ_CLASS,
        optional => 1,
    },

    priority => {
        type      => Params::Validate::SCALAR,
        callbacks => $is_num,
        optional  => 1,
        desc      => 'Priority'
    },

    cb_key => {
        type     => Params::Validate::SCALAR,
        optional => 1,
        desc     => 'Callback key'
    },

    pkg_key => {
        type     => Params::Validate::SCALAR,
        optional => 1,
        desc     => 'Package key'
    },

    trigger_key => {
        type     => Params::Validate::SCALAR,
        optional => 1,
        desc     => 'Trigger key'
    },

    value => {
        optional => 1,
        desc     => 'Callback value'
    },

    requester => {
        optional => 1,
        desc     => 'Requesting object'
    }
);

sub new {
    my $proto = shift;
    my %p = Params::Validate::validate(@_, \%valid_params);
    return bless \%p, ref $proto || $proto;
}

##############################################################################
# Subclasses must use register_subclass() to register the subclass. They can
# also use it to set up the class key and a default priority for the subclass,
# But base class CLASS_KEY() and DEFAULT_PRIORITY() methods can also be
# overridden to do that.
my (%priorities, %classes, %pres, %posts, @reqs, %isas, @classes);
sub register_subclass {
    shift; # Not needed.
    my $class = caller;
    return unless UNIVERSAL::isa($class, __PACKAGE__)
      and $class ne __PACKAGE__;
    my $spec = {
        default_priority => {
            type      => Params::Validate::SCALAR,
            optional  => 1,
            callbacks => $is_num
        },
        class_key => {
            type      => Params::Validate::SCALAR,
            optional  => 1
        },
    };

    my %p = Params::Validate::validate(@_, $spec);

    # Grab the class key. Default to the actual class name.
    my $ckey = $p{class_key} || $class;

    # Create the CLASS_KEY method if it doesn't exist already.
    unless (defined &{"$class\::CLASS_KEY"}) {
        no strict 'refs';
        *{"$class\::CLASS_KEY"} = sub { $ckey };
    }
    $classes{$class->CLASS_KEY} = $class;

    if (defined $p{default_priority}) {
        # Override any base class DEFAULT_PRIORITY methods.
        no strict 'refs';
        *{"$class\::DEFAULT_PRIORITY"} = sub { $p{default_priority} };
    }

    # Push the class into an array so that we can be sure to process it in
    # the proper order later.
    push @classes, $class;
}

##############################################################################

# This method is called by subclassed methods that want to be
# parameter-triggered callbacks.

sub Callback : ATTR(CODE, BEGIN) {
    my ($class, $symbol, $coderef, $attr, $data, $phase) = @_;
    # Validate the arguments. At this point, there's only one allowed,
    # priority. This is to set a priority for the callback method that
    # overrides that set for the class.
    my $spec = {
        priority => {
            type      => Params::Validate::SCALAR,
            optional  => 1,
            callbacks => $is_num
        },
    };
    my %p = Params::Validate::validate(@$data, $spec);
    # Get the priority.
    my $priority = exists $p{priority} ? $p{priority} :
      $class->DEFAULT_PRIORITY;
    # Store the priority under the code reference.
    $priorities{$coderef} = $priority;
}

##############################################################################

# These methods are called by subclassed methods that want to be request
# callbacks.

sub PreCallback : ATTR(CODE, BEGIN) {
    my ($class, $symbol, $coderef) = @_;
    # Just return if we've been here before. This is to prevent hiccups when
    # mod_perl loads packages twice.
    return if $pres{$class} and ref $pres{$class}->[0];
    # Store a reference to the code in a temporary location and a pointer to
    # it in the array.
    push @reqs, $coderef;
    push @{$pres{$class}}, $#reqs;
}

sub PostCallback : ATTR(CODE, BEGIN) {
    my ($class, $symbol, $coderef) = @_;
    # Just return if we've been here before. This is to prevent hiccups when
    # mod_perl loads packages twice.
    return if $posts{$class} and ref $posts{$class}->[0];
    # Store a reference to the code in a temporary location and a pointer to
    # it in the array.
    push @reqs, $coderef;
    push @{$posts{$class}}, $#reqs;
}

##############################################################################
# This method is called by Params::CallbackRequest to find the names of all
# the callback methods declared with the PreCallback and PostCallback
# attributes (might handle those declared with the Callback attribute at some
# point, as well -- there's some of it in CVS Revision 1.21 of
# MasonX::CallbackHandler). This is necessary because, in a BEGIN block, the
# symbol isn't defined when the attribute callback is called. I would use a
# CHECK or INIT block, but mod_perl ignores them. So the solution is to have
# the callback methods save the code references for the methods, make sure
# that Params::CallbackRequest is loaded _after_ all the classes that inherit
# from Params::Callback, and have it call this function to go back and find
# the names of the callback methods. The method names will then of course be
# used for the callback names. In mod_perl2, we'll likely be able to call this
# method from a PerlPostConfigHandler instead of making
# Params::CallbackRequest do it, thus relieving the enforced loading order.
# http://perl.apache.org/docs/2.0/user/handlers/server.html#PerlPostConfigHandler

sub _find_names {
    foreach my $class (@classes) {
        # Find the names of the request callback methods.
        foreach my $type (\%pres, \%posts) {
            # We've stored an index pointing to each method in the @reqs
            # array under __TMP in PreCallback() and PostCallback().
            for (@{$type->{$class}}) {
                my $code = $reqs[$_];
                # Grab the symbol hash for this code reference.
                my $sym = Attribute::Handlers::findsym($class, $code)
                  or die "Anonymous subroutines not supported. Make " .
                  "sure that Params::CallbackRequest loads last";
                # Params::CallbackRequest wants an array reference.
                $_ = [ sub { goto $code }, $class, *{$sym}{NAME} ];
            }
        }
        # Copy any request callbacks from their parent classes. This is to
        # ensure that rquest callbacks act like methods, even though,
        # technically, they're not.
        $isas{$class} = _copy_meths($class);
    }
     # We don't need these anymore.
    @classes = ();
    @reqs = ();
}

##############################################################################
# This little gem, called by _find_names(), mimics inheritance by copying the
# request callback methods declared for parent class keys into the children.
# Any methods declared in the children will, of course, override. This means
# that the parent methods can never actually be called, since request
# callbacks are called for every request, and thus don't have a class
# association. They still get the correct object passed as their first
# parameter, however.

sub _copy_meths {
    my $class = shift;
    my %seen_class;
    # Grab all of the super classes.
    foreach my $super (grep { UNIVERSAL::isa($_, __PACKAGE__) }
                       Class::ISA::super_path($class)) {
        # Skip classes we've already seen.
        unless ($seen_class{$super}) {
            # Copy request callback code references.
            foreach my $type (\%pres, \%posts) {
                if ($type->{$class} and $type->{$super}) {
                    # Copy the methods, but allow newer ones to override.
                    my %seen_meth;
                    $type->{$class} =
                      [ grep { not $seen_meth{$_->[2]}++ }
                        @{$type->{$class}}, @{$type->{$super}} ];
                } elsif ($type->{$super}) {
                    # Just copy the methods.
                    $type->{$class} = [ @{ $type->{$super} } ];
                }
            }
            $seen_class{$super} = 1;
        }
    }

    # Return an array ref of the super classes.
    return [keys %seen_class];
}

##############################################################################
# This method is called by Params::CallbackRequest to find methods for
# callback classes. This is because Params::Callback stores this list of
# callback classes, not Params::CallbackRequest. Its arguments are the
# callback class, the name of the method (callback), and a reference to the
# priority. We'll only assign the priority if it hasn't been assigned one
# already -- that is, it hasn't been _called_ with a priority.

sub _get_callback {
    my ($class, $meth, $p) = @_;
    # Get the callback code reference.
    my $c = UNIVERSAL::can($class, $meth) or return;
    # Get the priority for this callback. If there's no priority, it's not
    # a callback method, so skip it.
    return unless defined $priorities{$c};
    my $priority = $priorities{$c};
    # Reformat the callback code reference.
    my $code = sub { goto $c };
    # Assign the priority, if necessary.
    $$p = $priority unless $$p ne '';
    # Create and return the callback.
    return $code;
}

##############################################################################
# This method is also called by Params::CallbackRequest, where the cb_classes
# parameter passes in a list of callback class keys or the string "ALL" to
# indicate that all of the callback classes should have their callbacks loaded
# for use by Params::CallbacRequest.

sub _load_classes {
    my ($pkg, $ckeys) = @_;
    # Just return success if there are no classes to be loaded.
    return unless defined $ckeys;
    my ($cbs, $pres, $posts);
    # Process the class keys in the order they're given, or just do all of
    # them if $ckeys eq 'ALL' or $ckeys->[0]  eq '_ALL_' (checked by
    # Params::CallbackRequest).
    foreach my $ckey (
        ref $ckeys && $ckeys->[0] ne '_ALL_' ? @$ckeys : keys %classes
    ) {
        my $class = $classes{$ckey} or
          die "Class with class key '$ckey' not loaded. Did you forget use"
            . " it or to call register_subclass()?";
        # Map the class key to the class for the class and all of its parent
        # classes, all for the benefit of Params::CallbackRequest.
        $cbs->{$ckey} = $class;
        foreach my $c (@{$isas{$class}}) {
            next if $c eq __PACKAGE__;
            $cbs->{$c->CLASS_KEY} = $c;
        }
        # Load request callbacks in the order they're defined. Methods
        # inherited from parents have already been copied, so don't worry
        # about them.
        push @$pres, @{ $pres{$class} } if $pres{$class};
        push @$posts, @{ $posts{$class} } if $posts{$class};
    }
    return ($cbs, $pres, $posts);
}

##############################################################################

sub redirect {
    my ($self, $url, $wait, $status) = @_;
    $status ||= REDIRECT;
    my $cb_request = $self->cb_request;
    $cb_request->{_status} = $status;
    $cb_request->{redirected} = $url;

    if (my $r = $self->apache_req) {
        $r->method('GET');
        $r->headers_in->unset('Content-length');
        $r->err_headers_out->add( Location => $url );
    }
    $self->abort($status) unless $wait;
}

##############################################################################

sub redirected { $_[0]->cb_request->redirected }

##############################################################################

sub abort {
    my ($self, $aborted_value) = @_;
    $self->cb_request->{_status} = $aborted_value;
    Params::Callback::Exception::Abort->throw
      ( error         => ref $self . '->abort was called',
        aborted_value => $aborted_value );
}

##############################################################################

sub aborted {
    my ($self, $err) = @_;
    $err = $@ unless defined $err;
    return Params::CallbackRequest::Exceptions::isa_cb_exception( $err, 'Abort' );
}

##############################################################################

sub notes {
    shift->{cb_request}->notes(@_);
}

1;
__END__

=head1 NAME

Params::Callback - Parameter callback base class

=head1 SYNOPSIS

Functional callback interface:

  sub my_callback {
      # Sole argument is a Params::Callback object.
      my $cb = shift;
      my $params = $cb->params;
      my $value = $cb->value;
      # Do stuff with above data.
  }

Object-oriented callback interface:

  package MyApp::Callback;
  use base qw(Params::Callback);
  use constant CLASS_KEY => 'MyHandler';
  use strict;

  sub my_callback : Callback {
      my $self = shift;
      my $params = $self->params;
      my $value = $self->value;
      # Do stuff with above data.
  }

=head1 DESCRIPTION

Params::Callback provides the interface for callbacks to access parameter
hashes Params::CallbackRequest object, and callback metadata, as well as for
executing common request actions, such as aborting a callback execution
request. There are two ways to use Params::Callback: via functional-style
callback subroutines and via object-oriented callback methods.

For functional callbacks, a Params::Callback object is constructed by
Params::CallbackRequest for each call to its C<request()> method, and passed
as the sole argument for every execution of a callback function. See
L<Params::CallbackRequest|Params::CallbackRequest> for details on how to
create a Params::CallbackRequest object to execute your callback code.

In the object-oriented callback interface, Params::Callback is the parent
class from which all callback classes inherit. Callback methods are declared
in such subclasses via C<Callback>, C<PreCallback>, and C<PostCallback>
attributes to each method declaration. Methods and subroutines declared
without one of these callback attributes are not callback methods, but normal
methods or subroutines of the subclass. Read L<subclassing|"SUBCLASSING"> for
details on subclassing Params::Callback.

=head1 INTERFACE

Params::Callback provides the parameter hash accessors and utility methods that
will help manage a callback request (where a "callback request" is considered
a single call to the C<request()> method on a Params::CallbackRequest object).
Functional callbacks always get a Params::Callback object passed as their
first argument; the same Params::Callback object will be used for all
callbacks in a single request. For object-oriented callback methods, the first
argument will of course always be an object of the class corresponding to the
class key used in the callback key (or, for request callback methods, an
instance of the class for which the request callback method was loaded), and
the same object will be reused for all subsequent callbacks to the same class
in a single request.

=head2 Accessor Methods

All of the Params::Callback accessor methods are read-only. Feel free to add
other attributes in your Params::Callback subclasses if you're using the
object-oriented callback interface.

=head3 cb_request

  my $cb_request = $cb->cb_request;

Returns a reference to the Params::CallbackRequest object that executed the
callback.

=head3 params

  my $params = $cb->params;

Returns a reference to the request parameters hash. Any changes you make to
this hash will propagate beyond the lifetime of the request.

=head3 apache_req

  my $r = $cb->apache_req;

Returns the Apache request object for the current request, provided you've
passed one to C<< Params::CallbackRequest->request >>. This will be most
useful in a mod_perl environment, of course. Use Apache:FakeRequest in
tests to emmulate the behavior of an Apache request object.

=head3 requester

  my $r = $cb->requester;

Returns the object that executed the callback by calling C<request()> on a
Params::CallbackRequest object. Only available if the C<requester> parameter
is passed to C<< Params::CallbackRequest->request >>. This can be useful for
callbacks to get access to the object that executed the callbacks.

=head3 priority

  my $priority = $cb->priority;

Returns the priority level at which the callback was executed. Possible values
range from "0" to "9", and may be set by a default priority setting, by the
callback configuration or method declaration, or by the parameter callback
trigger key. See L<Params::CallbackRequest|Params::CallbackRequest> for
details.

=head3 cb_key

  my $cb_key = $cb->cb_key;

Returns the callback key that triggered the execution of the callback. For
example, this callback-triggering parameter hash:

  my $params = { "DEFAULT|save_cb" => 'Save' };

Will cause the C<cb_key()> method in the relevant callback to return "save".

=head3 pkg_key

  my $pkg_key = $cb->pkg_key;

Returns the package key used in the callback trigger parameter key. For
example, this callback-triggering parameter hash:

  my $params = { "MyCBs|save_cb" => 'Save' };

Will cause the C<pkg_key()> method in the relevant callback to return "MyCBs".

=head3 class_key

  my $class_key = $cb->class_key;

An alias for C<pkg_key>, only perhaps a bit more appealing for use in
object-oriented callback methods.

=head3 trigger_key

  my $trigger_key = $cb->trigger_key;

Returns the complete parameter key that triggered the callback. For example,
if the parameter key that triggered the callback looks like this:

  my $params = { "MyCBs|save_cb6" => 'Save' };

Then the value returned by C<trigger_key()> method will be "MyCBs|save_cb6".

B<Note:> Most browsers will submit "image" input fields with two arguments,
one with ".x" appended to its name, and the other with ".y" appended to its
name. Because Params::CallbackRequest is designed to be used with Web form
fields populating a parameter hash, it will ignore these fields and either use
the field that's named without the ".x" or ".y", or create a field with that
name and give it a value of "1". The reasoning behind this approach is that
the names of the callback-triggering fields should be the same as the names
that appear in the HTML form fields. If you want the actual x and y image
click coordinates, access them directly from the request parameters:

  my $params = $cb->params;
  my $trigger_key = $cb->trigger_key;
  my $x = $params->{"$trigger_key.x"};
  my $y = $params->{"$trigger_key.y"};

=head3 value

  my $value = $cb->value;

Returns the value of the parameter that triggered the callback. This value can
be anything that can be stored in a hash value -- that is, any scalar
value. Thus, in this example:

  my $params = { "DEFAULT|save_cb" => 'Save',
                 "DEFAULT|open_cb" => [qw(one two)] };

C<value()> will return the string "Save" in the save callback, but the array
reference C<['one', 'two']> in the open callback.

Although you may often be able to retrieve the value directly from the hash
reference returned by C<params()>, if multiple callback keys point to the same
subroutine or if the parameter that triggered the callback overrode the
priority, you may not be able to determine which value was submitted for a
particular callback execution. So Params::Callback kindly provides the value
for you. The exception to this rule is values submitted under keys named for
HTML "image" input fields. See the note about this under the documentation for
the C<trigger_key()> method.

=head3 redirected

  $cb->redirect($url) unless $cb->redirected;

If the request has been redirected, this method returns the redirection
URL. Otherwise, it returns false. This method is useful for conditions in
which one callback has called C<< $cb->redirect >> with the optional C<$wait>
argument set to a true value, thus allowing subsequent callbacks to continue
to execute. If any of those subsequent callbacks want to call
C<< $cb->redirect >> themselves, they can check the value of
C<< $cb->redirected >> to make sure it hasn't been done already.

=head2 Other Methods

Params::Callback offers has a few other publicly accessible methods.

=head3 notes

  $cb->notes($key => $value);
  my $val = $cb->notes($key);
  my $notes = $cb->notes;

Shortcut for C<< $cb->cb_request->notes >>. It provides a place to store
application data, giving developers a way to share data among multiple
callbacks. See L<C<notes()>|Params::CallbackRequest/"notes"> for more
information.

=head3 redirect

  $cb->redirect($url);
  $cb->redirect($url, $wait);
  $cb->redirect($url, $wait, $status);

This method can be used to redirect a request in a mod_perl environment,
provided that an Apache request object has been passed to
C<< Params::CallbackRequest->new >>.
Outide of a mod_perl environment or without an Apache request object,
C<redirect()> will still set the proper value for the the C<redirected()>
method to return, and will still abort the callback request.

Given a URL, this method generates a proper HTTP redirect for that URL. By
default, the status code used is "302", but this can be overridden via the
C<$status> argument. If the optional C<$wait> argument is true, any callbacks
scheduled to be executed after the call to C<redirect> will continue to be
executed. In that case, C<< $cb->abort >> will not be called; rather,
Params::CallbackRequest will finish executing all remaining callbacks and then
return the abort status. If the C<$wait> argument is unspecified or false,
then the request will be immediately terminated without executing subsequent
callbacks or. This approach relies on the execution of C<< $cb->abort >>.

Since C<< $cb->redirect >> calls C<< $cb->abort >>, it will be trapped by an
C<eval {}> block. If you are using an C<eval {}> block in your code to trap
exceptions, you need to make sure to rethrow these exceptions, like this:

  eval {
      ...
  };

  die $@ if $cb->aborted;

  # handle other exceptions

=head3 abort

  $cb->abort($status);

Aborts the current request without executing any more callbacks. The
C<$status> argument specifies a request status code to be returned to by
C<< Params::CallbackRequest->request() >>.

C<abort()> is implemented by throwing a Params::Callback::Exception::Abort
object and can thus be caught by C<eval{}>. The C<aborted()> method is a
shortcut for determining whether an exception was generated by C<abort()>.

=head3 aborted

  die $err if $cb->aborted;
  die $err if $cb->aborted($err);

Returns true or C<undef> to indicate whether the specified C<$err> was
generated by C<abort()>. If no C<$err> argument is passed, C<aborted()>
examines C<$@>, instead.

In this code, we catch and process fatal errors while letting C<abort()>
exceptions pass through:

  eval { code_that_may_die_or_abort() };
  if (my $err = $@) {
      die $err if $cb->aborted($err);

      # handle fatal errors...
  }

C<$@> can lose its value quickly, so if you're planning to call
C<< $cb->aborted >> more than a few lines after the C<eval>, you should save
C<$@> to a temporary variable and explicitly pass it to C<aborted()> as in the
above example.

=head1 SUBCLASSING

Under Perl 5.6.0 and later, Params::Callback offers an object-oriented
callback interface. The object-oriented approach is to subclass
Params::Callback, add the callback methods you need, and specify a class key
that uniquely identifies your subclass across all Params::Callback subclasses
in your application. The key is to use Perl method attributes to identify
methods as callback methods, so that Params::Callback can find them and
execute them when the time comes. Here's an example:

  package MyApp::CallbackHandler;
  use base qw(Params::Callback);
  use strict;

  __PACKAGE__->register_subclass( class_key => 'MyHandler' );

  sub build_utc_date : Callback( priority => 2 ) {
      my $self = shift;
      my $params = $self->params;
      $params->{date} = sprintf "%04d-%02d-%02dT%02d:%02d:%02d",
        delete @{$params}{qw(year month day hour minute second)};
  }

This parameter-triggered callback can then be executed via a parameter hash
such as this:

  my $params = { "MyHandler|build_utc_date_cb" => 1 };

Think of the part of the name preceding the pipe (the package key) as the
class name, and the part of the name after the pipe (the callback key) as the
method to call (plus '_cb'). If multiple parameters use the "MyHandler" class
key in a single request, then a single MyApp::CallbackHandler object instance
will be used to execute each of those callback methods for that request.

To configure your Params::CallbackRequest object to use this callback, use its
C<cb_classes> constructor parameter:

  my $cb_request = Params::CallbackRequest->new
    ( cb_classes => [qw(MyHandler)] );
  $cb_request->request($params);

Now, there are a few of things to note in the above callback class example.
The first is the call to C<< __PACKAGE__->register_subclass >>. This step is
B<required> in all callback subclasses in order that Params::Callback will
know about them, and thus they can be loaded into an instance of a
Params::CallbackRequest object via its C<cb_classes> constructor parameter.

Second, a callback class key B<must> be declared for the class. This can be
done either by implementing the C<CLASS_KEY()> class method or constant in
your subclass, or by passing the C<class_key> parameter to
C<< __PACKAGE__->register_subclass >>, which will then create the
C<CLASS_KEY()> method for you. If no callback key is declared, then
Params::Callback will throw an exception when you try to load your subclass'
callback methods into a Params::CallbackRequest object.

One other, optional parameter, C<default_priority>, may also be passed to
C<register_subclass()>. The value of this parameter (an integer between 0 and
9) will be used to create a C<DEFAULT_PRIORITY()> class method in the
subclass. You can also explicitly implement the C<DEFAULT_PRIORITY()> class
method or constant in the subclass, if you'd rather. All parameter-triggered
callback methods in that class will have their priorities set to the value
returned by C<DEFAULT_PRIORITY()>, unless they override it via their
C<Callback> attributes.

And finally, notice the C<Callback> attribute on the C<build_utc_date> method
declaration in the example above. This attribute is what identifies
C<build_utc_date> as a parameter-triggered callback. Without the C<Callback>
attribute, any subroutine declaration in your subclass will just be a
subroutine or a method; it won't be a callback, and it will never be executed
by Params::CallbackRequest. One parameter, C<priority>, can be passed via the
C<Callback> attribute. In the above example, we pass C<< priority => 2 >>,
which sets the priority for the callback. Without the C<priority> parameter,
the callback's priority will be set to the value returned by the
C<DEFAULT_PRIORITY()> class method. Of course, the priority can still be
overridden by adding it to the callback trigger key. For example, here we
force the callback priority for the execution of the C<build_utc_date>
callback method for this one field to be the highest priority, "0":

  my $params = { "MyHandler|build_utc_date_cb0" => 1 };

Other parameters to the C<Callback> attribute may be added in future versions
of Params::Callback.

Request callbacks can also be implemented as callback methods using the
C<PreCallback> and C<PostCallback> attributes, which currently support no
parameters.

=head2 Subclassing Examples

At this point, you may be wondering what advantage the object-oriented
callback interface offer over functional callbacks. There are a number of
advantages. First, it allows you to make use of callbacks provided by other
users without having to reinvent the wheel for yourself. Say someone has
implemented the above class with its exceptionally complex C<build_utc_date()>
callback method. You need to have the same functionality, only with fractions
of a second added to the date format so that you can insert them into your
database without an error. (This is admittedly a contrived example, but you
get the idea.) To make it happen, you merely have to subclass the above class
and override the C<build_utc_date()> method to do what you need:

  package MyApp::Callback::Subclass;
  use base qw(MyApp::CallbackHandler);
  use strict;

  __PACKAGE__->register_subclass;

  # Implement CLASS_KEY ourselves.
  use constant CLASS_KEY => 'SubHandler';

  sub build_utc_date : Callback( priority => 1 ) {
      my $self = shift;
      $self->SUPER::build_utc_date;
      my $params = $self->params;
      $params->{date} .= '.000000';
  }

This callback can then be triggered by a parameter hash such as this:

  my $params = { "SubHandler|build_utc_date_cb" => 1 };

Note that we've used the "SubHandler" class key. If we used the "MyHandler"
class key, then the C<build_utc_date()> method would be called on an instance
of the MyApp::CallbackHandler class, instead.

=head3 Request Callback Methods

I'll admit that the case for request callback methods is a bit more
tenuous. Granted, a given application may have 100s or even 1000s of
parameter-triggered callbacks, but only one or two request callbacks, if
any. But the advantage of request callback methods is that they encourage code
sharing, in that Params::Callback creates a kind of plug-in architecture Perl
templating architectures.

For example, say someone has kindly created a Params::Callback subclass,
Params::Callback::Unicodify, with the request callback method C<unicodify()>,
which translates character sets, allowing you to always store data in the
database in Unicode. That's all well and good, as far as it goes, but let's
say that you want to make sure that your Unicode strings are actually encoded
using the Perl C<\x{..}> notation. Again, just subclass:

  package Params::Callback::Unicodify::PerlEncode;
  use base qw(Params::Callback::Unicodify);
  use strict;

  __PACKAGE__->register_subclass( class_key => 'PerlEncode' );

  sub unicodify : PreCallback {
      my $self = shift;
      $self->SUPER::unicodify;
      my $params = $self->params;
      encode_unicode($params); # Hand waving.
  }

Now you can just tell Params::CallbackRequest to use your subclassed callback
handler:

  my $cb_request = Params::CallbackRequest->new
    ( cb_classes => [qw(PerlEncode)] );

Yeah, okay, you could just create a second pre-callback request callback to
encode the Unicode characters using the Perl C<\x{..}> notation. But you get
the idea. Better examples welcome.

=head3 Overriding the Constructor

Another advantage to using callback classes is that you can override the
Params::Callback C<new()> constructor. Since every callback for a single class
will be executed on the same instance object in a single request, you can set
up object properties in the constructor that subsequent callback methods in
the same request can then access.

For example, say you had a series of pages that all do different things to
manage objects in your application. Each of those pages might have a number of
parameters in common to assist in constructing an object:

  my $params = { class  => "MyApp::Spring",
                 obj_id => 10,
                 # ...
               };

Then the remaining parameters created for each of these pages have different
key/value pairs for doing different things with the object, perhaps with
numerous parameter-triggered callbacks. Here's where subclassing comes in
handy: you can override the constructor to construct the object when the
callback object is constructed, so that each of your callback methods doesn't
have to:

  package MyApp::Callback;
  use base qw(Params::Callback);
  use strict;
  __PACKAGE__->register_subclass( class_key => 'MyCBHandler' );

  sub new {
      my $class = shift;
      my $self = $class->SUPER::new(@_);
      my $params = $self->params;
      $self->object($params->{class}->lookup( id => $params->{obj_id} ));
  }

  sub object {
      my $self = shift;
      if (@_) {
          $self->{object} = shift;
      }
      return $self->{object};
  }

  sub save : Callback {
      my $self = shift;
      $self->object->save;
  }

=head1 SUBCLASSING INTERFACE

Much of the interface for subclassing Params::Callback is evident in the above
examples. Here is a reference to the complete callback subclassing API.

=head2 Callback Class Declaration

Callback classes always subclass Params::Callback, so of course they must
always declare such. In addition, callback classes must always call
C<< __PACKAGE__->register_subclass >> so that Params::Callback is aware of
them and can tell Params::CallbackRequest about them.

Second, callback classes B<must> have a class key. The class key can be
created either by implementing a C<CLASS_KEY()> class method or constant that
returns the class key, or by passing the C<class_key> parameter to
C<register_subclass()> method. If no C<class_key> parameter is passed to
C<register_subclass()> and no C<CLASS_KEY()> method exists,
C<register_subclass()> will create the C<CLASS_KEY()> class method to return
the actual class name. So here are a few example callback class declarations:

  package MyApp::Callback;
  use base qw(Params::Callback);
  __PACKAGE__->register_subclass( class_key => 'MyCBHandler' );

In this declaration C<register_subclass()> will create a C<CLASS_KEY()> class
method returning "MyCBHandler" in the MyApp::CallbackHandler class.

  package MyApp::AnotherCallback;
  use base qw(MyApp::Callback);
  __PACKAGE__->register_subclass;
  use constant CLASS_KEY => 'AnotherCallback';

In this declaration, we've created an explicit C<CLASS_KEY()> class method
(using the handy C<use constant> syntax, so that C<register_subclass()>
doesn't have to.

  package MyApp::Callback::Foo;
  use base qw(Params::Callback);
  __PACKAGE__->register_subclass;

And in this callback class declaration, we've specified neither a C<class_key>
parameter to C<register_subclass()>, nor created a C<CLASS_KEY()> class
method. This causes C<register_subclass()> to create the C<CLASS_KEY()> class
method returning the name of the class itself, i.e., "MyApp::FooHandler". Thus
any parameter-triggered callbacks in this class can be triggered by using the
class name in the trigger key:

  my $params = { "MyApp::Callback::Foo|take_action_cb" => 1 };

A second, optional parameter, C<default_priority>, may also be passed to
C<register_subclass()> in order to set a default priority for all of the
methods in the class (and for all the methods in subclasses that don't declare
their own C<default_priority>s):

  package MyApp::Callback;
  use base qw(Params::Callback);
  __PACKAGE__->register_subclass( class_key => 'MyCB',
                                  default_priority => 7 );

As with the C<class_key> parameter, the C<default_priority> parameter creates
a class method, C<DEFAULT_PRIORITY()>. If you'd rather, you can create this
class method yourself; just be sure that its value is a valid priority -- that
is, an integer between "0" and "9":

  package MyApp::Callback;
  use base qw(Params::Callback);
  use constant DEFAULT_PRIORITY => 7;
  __PACKAGE__->register_subclass( class_key => 'MyCB' );

Any callback class that does not specify a default priority via the
C<default_priority> or by implementing a <DEFAULT_PRIORITY()> class method
will simply inherit the priority returned by
C<< Params::Callback->DEFAULT_PRIORITY >>, which is "5".

B<Note:> In a mod_perl environment, it's important that you C<use> any and all
Params::Callback subclasses I<before> you C<use Params::CallbackRequest>. This is
to get around an issue with identifying the names of the callback methods in
mod_perl. Read the comments in the source code if you're interested in
learning more.

=head2 Method Attributes

These method attributes are required to create callback methods in
Params::Callback subclasses.

=head3 Callback

  sub take_action : Callback {
      my $self = shift;
      # Do stuff.
  }

This attribute identifies a parameter-triggered callback method. The callback
key is the same as the method name ("take_action" in this example). The
priority for the callback may be set via an optional C<priority> parameter to
the C<Callback> attribute, like so:

  sub take_action : Callback( priority => 5 ) {
      my $self = shift;
      # Do stuff.
  }

Otherwise, the priority will be that returned by C<< $self->DEFAULT_PRIORITY >>.

B<Note:> The priority set via the C<priority> parameter to the C<Callback>
attribute is not inherited by any subclasses that override the callback
method. This may change in the future.

=head3 PreCallback

  sub early_action : PreCallback {
      my $self = shift;
      # Do stuff.
  }

This attribute identifies a method as a request callback that gets executed
for every request I<before> any parameter-triggered callbacks are executed .
No parameters to C<PreCallback> are currently supported.

=head3 PostCallback

  sub late_action : PostCallback {
      my $self = shift;
      # Do stuff.
  }

This attribute identifies a method as a request callback that gets executed
for every request I<after> any parameter-triggered callbacks are executed . No
parameters to C<PostCallback> are currently supported.

=head1 TODO

=over

=item *

Allow methods that override parent methods to inherit the parent method's
priority?

=back

=head1 SEE ALSO

L<Params::CallbackRequest|Params::CallbackRequest> constructs Params::Callback
objects and executes the appropriate callback functions and/or methods. It's
worth a read.

=head1 SUPPORT

This module is stored in an open repository at the following address:

L<https://svn.kineticode.com/Params-CallbackRequest/trunk/>

Patches against Params::CallbackRequest are welcome. Please send bug reports
to <bug-params-callbackrequest@rt.cpan.org>.

=head1 AUTHOR

David E. Wheeler <david@justatheory.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2011 David E. Wheeler. Some Rights Reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
