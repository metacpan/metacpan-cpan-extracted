package OpenFrame::AppKit::App;

use strict;
use warnings::register;

our $VERSION=3.03;

use Storable qw ( dclone );
use OpenFrame::AppKit::Segment::DispatchOnURI;
use base qw ( OpenFrame::AppKit::Segment::DispatchOnURI );

sub init {
  my $self = shift;

  $self->{'::appkit'} = undef;

  $self->config( {} ); ## initialize the configuration

  $self->uri( '/' );             ## create a default place for it to execute on
  $self->namespace( 'default' ); ## create a default namespace for it to execute with

  $self->SUPER::init( @_ );
}

sub request {
  my $self = shift;
  my $req  = shift;
  if (defined($req)) {
    $self->{'::appkit'}->{request} = $req;
    return $self;
  } else {
    return $self->{'::appkit'}{request};
  }
}

#sub uri {
#  my $self     = shift;
#  my $pattern  = shift;
#  if ( defined( $pattern ) ) {
#    if( ref($pattern) ) {
#      $self->{'::appkit'}->{ execute_on_uris_matching } = $pattern;
#      return $self;
#    } else {
#      return $self->uri( qr/$pattern/ );
#    }
#  } else {
#    return $self->{'::appkit'}->{ execute_on_uris_matching };
#  }
#}

sub namespace {
  my $self = shift;
  my $ns   = shift;
  if (defined( $ns )) {
    $self->{'::appkit'}{ ns } = $ns;
    return $self;
  } else {
    return $self->{'::appkit'}->{ns};
  }
}

sub _copy_app_from_namespace {
  my $self = shift;
  my $session = shift;
  my $namespace = $self->namespace || '';

  $self->emit("namespace is $namespace");
  
  if ($session->{application}->{ $namespace }) {
    my $copy = dclone($session->{application}->{ $namespace });
    foreach my $key (keys %$copy) {
      $self->{$key} = $copy->{ $key };
    }
  }
}

sub dispatch_on_uri {
  my $self = shift;
  my $pipe = shift;

  my $store   = $pipe->store();
  my $request = $store->get('OpenFrame::Request');

  if (!$request) { return undef; }

  my $session = $self->get_session( $store );
  delete $session->{ app };

  $self->_copy_app_from_namespace( $session );

  $self->request( $request ); ## set the request

  my @results = $self->_enter( $store );

  $self->request('');         ## clear the request

  my $namespace = $self->namespace || '';
  my %hashcopy  = %{$self};
  $session->{app}                         = \%hashcopy;
  $session->{application}->{ $namespace } = \%hashcopy;

  return @results;
}

sub get_session {
  my $self = shift;
  my $store = shift;
  my $session = $store->get('OpenFrame::AppKit::Session');
  return $session;
}

sub get_entry {
  my $self  = shift;
  my $store = shift;

  my $args = $store->get('OpenFrame::Request')->arguments();
  my $epnt = $self->_get_entry_points();

  my $dispatch = "get_entry_" . ref($epnt);
  my $method;
  eval { 
    $method   = $self->$dispatch( $args, $epnt );
  };
  if ($@) {
    $self->emit("could not call $dispatch");
  }

  return $method || 'default';
}

sub get_entry_HASH {
  my $self = shift;
  my $args = shift;
  my $epnt = shift;
  my $method;
  foreach my $point ( keys %$epnt ) {
    ## we have a hash
    if ($self->_match_hash_arguments( $args, $epnt->{ $point } )) {
      $method = $point;
      last;
    }
  }
  return $method;
}

sub _enter {
  my $self = shift;
  my $store   = shift;

  my $method = $self->get_entry( $store );

  my $sub = $self->can($method);
  if ($sub) {
    return ($sub->($self, $store));
  } else {
    ## can't do anything
  }
}

sub default {}

sub _match_hash_arguments {
  my $self = shift;
  my $args    = shift;
  my $against = shift;

  my $count = scalar(@$against);
  my $match = 0;
  foreach my $wanted (@$against) {
    if (ref $wanted eq 'ARRAY') {
      my $wantarg =  $wanted->[0];
      my $lnot    = 0;
      if (substr($wantarg,0,1) eq '!') {
	$wantarg = substr($wantarg, 1);
	$lnot    = 1;
      }
      if (exists $args->{ $wantarg }) {
        my $argvalue = $args->{ $wantarg };
        foreach my $wantvalue (@$wanted[1..$#$wanted]) {
          if (ref $wantvalue eq 'Regexp') {
	    if ($lnot) {
	      $match--, last if $argvalue =~ $wantvalue;
	    } else {
	      $match++, last if $argvalue =~ $wantvalue;
	    }
          }
          else {
	    if ($lnot) {
	      $match--, last if $argvalue eq $wantvalue;
	    } else {
	      $match++, last if $argvalue eq $wantvalue;
	    }
          }
        }
      }
    }
    elsif ( substr($wanted,0,1) eq '!') {
      my $realwanted = substr($wanted, 1);
      if (exists $args->{ $realwanted }) {
	return 0;
      } else {
	$match++;
      }
    } elsif (exists $args->{ $wanted }) {
      $match++;
    } else {
      ## skip
    }
  }
  return 1 if $match == $count;
  return 0;
}

sub _get_entry_points {
  my $self = shift;
  return $self->entry_points();
}

sub entry_points {
  my $self  = shift;
  my $class = ref($self);
  {
    no strict;
    return $ {$class . '::epoints'};
  }
}

sub config {
  my $self = shift;
  my $conf = shift;
  if (defined( $conf )) {
    $self->{'::appkit'}{config} = $conf;
    return $self;
  } else {
    return $self->{'::appkit'}->{config};
  }
}

1;

=head1 NAME

OpenFrame::AppKit::App - The OpenFrame AppKit application class

=head1 SYNOPSIS

    package MyApplication;

    use strict;

    use OpenFrame::AppKit::App;
    use base qw ( OpenFrame::AppKit::App );

=head1 DESCRIPTION

The C<OpenFrame::AppKit::App> class is designed to be inherited from.
It provides all the basic functionality of a pipeline segment, as well
as basic functionality that applications will need to start running.

To create an application, all you need to do to get started is
subclass OpenFrame::AppKit::App.

    package MyApplication;

    use strict;

    use OpenFrame::AppKit::App;
    use base qw ( OpenFrame::AppKit::App );

In your server code you can now instantiate your application:

    my $app = MyApplication->new();

However, applications require a little more information to act in the
manner we have come to expect.  Applications in common web
applications act when a url is requested that they listen to.  Your
new application is capable of that, but you need to tell it which URIs
to match against.  You do this by using the C<uri()> method of that
OpenFrame::AppKit::App helpfully provides.  If for instance you wanted
your application to execute whenever you went to '/myapp.html' URL
then simply use the URI method to specify a regular expression to
match:

    $app->uri( qr!/myapp\.html! );

OpenFrame::AppKit::App uses the concept of namespaces to keep your
application's data seperate from other application's data in the
global session.  You can specify the namespace of your application by
using the C<namespace()> method, that once again,
OpenFrame::AppKit::App provides:

    $app->namespace( 'myapplication' );

As you have probably noticed, the work needed to set up your
applications initialization is performed through method calls to your
application.  All methods that have been demonstrated here are capable
of being chained:

    my $app = MyApplication->new()
                           ->uri( qr!/myapp\.html! )
                           ->namespace( 'myapplication' );

All this is very useful, but so far the application still does nothing
at all.  This will change.  C<OpenFrame::AppKit::App> applications act
by default as state machines.  These states are specified by
parameters sent to the OpenFrame server.  In the case of an HTTP GET
message you can see them on the end of a URL:

    http://some.server.com/test.cgi?name=value

In this case there is one parameter, C<name> and one value C<value>.
The application's state machine looks at the parameters, your
application acts on values.  To set up your state machine you create a
method in your application called C<entry_points()>.  This method
should return a hash of arrays.  In the hash, the keys represent
methods in your module, and then elements in the array represent
parameters that have to exist in order for your application to be run:

    sub entry_points {
	return {
		form_filled => [ 'name', 'age' ]
	       };
    }

Each of the keys in your hash is an entry point, and needs a
subroutine in your module to perform the work.

    sub form_filled {

    }

In the case that you want a method to be called even if there are no
parameters matched, OpenFrame automatically calls a method called
C<default()> for you.

Whenever C<OpenFrame::AppKit> calls an entry point in your application
it calls it with two parameters.  The first of the two parameters is
the Application object itself.  The second is the Pipeline store (but
I'll talk about that in a little while, its not important right now).
A method that your application will use nearly every time it is in an
entry point is the C<request()> method.  It returns the
C<OpenFrame::Request> object that you can use to find out the exact
uri that has been called as well as the paramaters and values supplied
to it.

    sub form_filled {
	my $self  = shift;
	my $store = shift;

	my $request = $self->request();
	my $uri     = $request->uri();
	my $args    = $request->arguments();
    }

For more information about the request object and what it does, you
can see the C<OpenFrame::Request> documentation.  For now we'll talk
only about the $args variable, which is a hash reference.  Lets assume
that your application is up and running, and receiving requests.  If
you were to receive a request that was represented in URI form as:

    http://some.server.com/myapp.html?name=Bob&age=34

Then you could expect to find that your $args hash would look like:

    $args = {
             name => 'Bob',
             age  => 34
            }

    my $name = $args->{name};

The $name variable would hold the value C<Bob>.

When you write an application any data that you want to provide to the
template writer (which may be yourself) should be placed inside the
$self object.  $self is a hash, and provided you don't use the
C<::appkit> key you can place whatever you'd like in there.

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2002 Fotango Ltd.

This code is released under the same terms as perl itself.

http://opensource.fotango.com/

=cut
