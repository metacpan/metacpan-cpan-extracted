# -*- perl -*- --------------------------------------------------
#
# Resource::Loader - load different resources depending...
#
# Joshua Keroes
#
# This number is *not* the $VERSION (see below):
# $Id: Loader.pm,v 1.10 2003/04/28 23:28:19 jkeroes Exp $

package Resource::Loader;

use strict;
use warnings;
use Carp;
use vars qw/$VERSION/;

$VERSION = '0.03';

# In:  hash-style args. See docs.
# Out: object
sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self  = {};

    bless $self, $class;

    $self->_init( @_ );
}

# In:  hash-style args. See docs for new()
# Out: object
sub _init {
    my $self = shift;
    my %args = @_;

    while ( my ( $method, $args ) = each %args ) {
	$self->$method( $args );
    }

    return $self;
}


# In:  array or arrayref. See docs.
# Out: array or arrayref of resources.
sub resources {
    my $self = shift;

    if ( @_ ) {
	undef $self->{resources};

	for ( ref $_[0] eq 'ARRAY' ? @{ $_[0] } : $_[0] ) {
	    croak "Malformed resource. Needs 'name', 'when', and 'what' args"
		unless defined $_->{name}
		    && defined $_->{when}
	            && defined $_->{what};

	    croak "Malformed resource. 'when' and 'what' need to be coderefs."
		unless ref $_->{what} eq "CODE"
		    && ref $_->{when} eq "CODE";

	    croak "Malformed resource. 'whatargs' needs to be an arrayref."
		if $_->{whatargs}
		    && ref $_->{whatargs} ne "ARRAY";

	    croak "Malformed resource. 'whenargs' needs to be an arrayref."
		if $_->{whenargs}
		    && ref $_->{whenargs} ne "ARRAY";

	    push @{ $self->{resources} }, $_;
	}	
    }

    return wantarray ? @{ $self->{resources} } : $self->{resources};
}

# In:  optional new value
# Out: current value
sub testing {
    my $self = shift;
    $self->{testing} = shift if @_;
    return defined $ENV{RMTESTING} ? $ENV{RMTESTING} : $self->{testing};
}

# In:  optional new value
# Out: current value
sub verbose {
    my $self = shift;
    $self->{verbose} = shift if @_;
    return defined $ENV{RMVERBOSE} ? $ENV{RMVERBOSE} :  $self->{verbose};
}

# In:  optional new value
# Out: current value
sub cont {
    my $self = shift;
    $self->{cont} = shift if @_;
    return defined $ENV{RMCONT} ? $ENV{RMCONT} : $self->{cont};
}

# In:  n/a
# Out: hashref of our environment variables
sub env {
    my $self = shift;
    return { RMTESTING => $ENV{RMTESTING},
	     RMVERBOSE => $ENV{RMVERBOSE},
	     RMSTATES  => $ENV{RMSTATES},
	     RMCONT    => $ENV{RMCONT},
	   };
}

# In:  n/a
# Out: hashref of loaded states and their returns values.
sub loaded {
    my $self = shift;
    return $self->{loaded};
}

# In:  n/a
# Out: status report
#
# Runs the appropriate resources()
sub load {
    my $self = shift;

    # clear out loaded() and status() tables.
    undef $self->{loaded};
    undef $self->{status};
    $self->{status} = { map { $_->{name} => 'inactive' } @{ $self->{resources} } };

    for( @{ $self->{resources} } ) {
	my $name = $_->{name};


	if ( defined $ENV{RMSTATES} ) {
	    if ( grep { $_ eq $name } split /:/, $ENV{RMSTATES} ) {
		print __PACKAGE__ . " state '$name' present in RMSTATES environment var\n";
	    } else {
		print __PACKAGE__ . " state '$name' skipped due to RMSTATES environment var\n";
		$self->{status}{$name} = 'skipped';
		next;
	    }
	}

	if ( $_->{when}->( ref $_->{whenargs} eq "ARRAY"
			   ? @{ $_->{whenargs} }
			   : () ) ) {
	    print __PACKAGE__ . " state '$name' active\n" if $self->verbose;

	    if ( $self->testing ) {
		print __PACKAGE__ . " in testing: won't run code for state '$name'\n" if $self->verbose;
		$self->{status}{$name} = 'notrun';
	    } else {
		$self->{loaded}{$name} = $_->{what}->( ref $_->{whatargs} eq "ARRAY"
						       ? @{ $_->{whatargs} }
						       : () );
		$self->{status}{$name} = 'loaded';
	    }

	    last unless $self->cont;
	} else {
	    print __PACKAGE__ . " state '$name' inactive\n" if $self->verbose;
	    $self->{status}{$name} = 'inactive';
	}
    }

    return $self->loaded;
}

# In:  n/a
# Out: status report, e.g. { name => status, ... }
sub status {
    my $self = shift;

    return unless $self->{status}
	&& ref    $self->{status} eq "HASH";

    return $self->{status};
}

1;

__END__

=head1 NAME

Resource::Loader - Load different resources depending...

=head1 SYNOPSIS

  use Resource::Loader;

  $loader = Resource::Loader->new(
    testing => 0,
    verbose => 0,
    cont    => 0,
    resources =>
      [
	{ name => 'never',
	  when => sub { 0 },
	  what => sub { die "this will never be loaded" },
	},
	{ name => 'sometimes 50%',
	  when => sub { int rand 2 > 0 },
	  what => sub { "'sometimes' was loaded. args: [@_]" },
	  whatargs => [ qw/foo bar baz/ ],
	},
	{ name => 'sometimes 66%',
	  when => sub { int rand @_ },
	  whenargs => [ 0, 1, 2 ],
	  what => sub { "'sometimes' was loaded. args: [@_]" },
	  whatargs => [ qw/foo bar baz/ ],
	},
	{ name => 'always',
	  when => sub { 1 },
	  what => sub { "always' was loaded" },
	},
      ],
  );

  $loaded = $loader->load;
  $status = $loader->status;

=head1 DESCRIPTION

Resource::Loader is simple at its core: You give it a list of
resources. Each resource knows when it should be triggered and if
it's triggered, will run its code segment.

Both the I<when> and the I<what> are coderefs, so you can be as
devious as you want in determining when a resource will be loaded and
what, exactly, it does.

I originally wrote this to solve a simple problem but realized that
the class is probably applicable to a whole slew of problems. I look
forward to hearing to what devious ends you push this module.  Really,
send me an email - I love hearing about people using my toys.

Want to know what my 'simple problem' was? See the L<EXAMPLES>.

=head1 METHODS

=head2 new()

Create a new object.

  $loader = Resource::Loader->new(
    testing => 0,
    verbose => 0,
    cont    => 0,
    resources =>
      [
	{ name => 'never',
	  when => sub { 0 },
	  what => sub { die "this will never be loaded" },
	},
	{ name => 'sometimes 50%',
	  when => sub { int rand 2 > 0 },
	  what => sub { "'sometimes' was loaded. args: [@_]" },
	  whatargs => [ qw/foo bar baz/ ],
	},
	{ name => 'sometimes 66%',
	  when => sub { int rand @_ },
	  whenargs => [ 0, 1, 2 ],
	  what => sub { "'sometimes' was loaded. args: [@_]" },
	  whatargs => [ qw/foo bar baz/ ],
	},
	{ name => 'always',
	  when => sub { 1 },
	  what => sub { "always' was loaded" },
	},
      ],
  );

Note: I<testing>, I<verbose>, I<cont> all default to zero.

=head2 resources()

What to run and when to run it.

  # arrayref style
  $loader->resources(
    [
     { name => 'never',
       when => sub { 0 },
       what => sub { die "this will never be loaded" },
     },
     { name => 'sometimes 50%',
       when => sub { int rand 2 > 0 },
       what => sub { "'sometimes' was loaded. args: [@_]" },
       whatargs => [ qw/foo bar baz/ ],
     },
     { name => 'sometimes 66%',
       when => sub { int rand @_ },
       whenargs => [ 0, 1, 2 ],
       what => sub { "'sometimes' was loaded. args: [@_]" },
       whatargs => [ qw/foo bar baz/ ],
     },
     { name => 'always',
       when => sub { 1 },
       what => sub { "always' was loaded" },
     }
    ]
   );

  # list style
  $loader->resources(
     { name => 'never',
       when => sub { 0 },
       what => sub { die "this will never be loaded" },
     },
     { name => 'sometimes 50%',
       when => sub { int rand 2 > 0 },
       what => sub { "'sometimes' was loaded. args: [@_]" },
       whatargs => [ qw/foo bar baz/ ],
     },
     { name => 'sometimes 66%',
       when => sub { int rand @_ },
       whenargs => [ 0, 1, 2 ],
       what => sub { "'sometimes' was loaded. args: [@_]" },
       whatargs => [ qw/foo bar baz/ ],
     },
     { name => 'always',
       when => sub { 1 },
       what => sub { "always' was loaded" },
     }
   );

Each resource is a hashref that takes the same arguments:

=over 10

=item name

what is this resource called?

=item when

a coderef that controls whether the resource will be activated

=item whenargs

an optional arrayref of arguments that are passed to the I<when>.

=item what

a coderef that is only run if the I<when> coderef returns true

=item whatargs

an optional arrayref of arguments that are passed to the I<what>.

=back

Note: using colons in your I<name>s is not recommended. It will break
the $ENV{RMSTATES} handling. Keep It Simple.

=head2 load()

  $loaded = $loader->load;

Load the resources.

Walks through the resources() in order. For each resource, if the
I<when> coderef returns true, then the I<what> coderef will be run as
well.

That behaviour can be changed with the cont() and testing() methods
as well as the analagous I<RMCONT> and I<RMTESTING> environment variables.

load() returns the output of loaded(); a hashref of I<name>s that
loaded successfully and the respective return values.

Note: Running this method will overwrite any preexisting status() and
loaded() tables with current info.

Note: Don't confuse this with loaded(). load() loads the resources,
loaded() tells you what loaded.

=head2 cont()

  $will_continue = $loader->cont( 1 );
  $will_continue = $loader->cont( 0 ); # default
  $will_continue = $loader->cont;

Do you want to continue loading resources after the first one is
loaded?  Sometimes you want the first successful resource to load and
then skip all the others. That's the default behaviour. If you set
cont() to 1, then load() will keep checking (and loading resources).

When true, all states with true I<when> coderefs will be loaded.

When false, execution of states will stop after the first. (default)

The I<RMCONT> environment variable value takes precedence to any
value that this method is set to.

cont() will return true if either I<$ENV{RMCONT}> or this method has
been set to true.

=head2 testing()

  $is_testing = $loader->testing( 1 );
  $is_testing = $loader->testing( 0 ); # default
  $is_testing = $loader->testing;

When true, don't actually run the I<what> resources.

When false, it will.

The I<RMTESTING> environment variable value takes precedence to any value
that this is set to.  It will return true if either I<$ENV{RMTESTING}> or
this method has been set to true.

When testing() is on, status() results will be set to I<skipped> if the
I<when> coderef if true but the I<what> coderef wasn't run.

=head2 verbose()

  $is_verbose = $loader->verbose( 1 );
  $is_verbose = $loader->verbose( 0 ); # default
  $is_verbose = $loader->verbose;

When true, print internal processing messages to STDOUT

When false, run quietly.

The I<RMVERBOSE> environment variable value takes precedence to any value
that this is set to. It will return true if either I<$ENV{RMVERBOSE}> or
this method has been set to true.

=head2 status()

  $status = $loader->status;

Returns a hashref of which resources loading stati. Maps I<name>s
to one of these values: Don't forget to call load() first!

=over 10

=item loaded

The I<when> succeeded so I<what> was run

=item skipped

I<$ENV{RMSTATES}> is defined but this state I<name> wasn't isn't in it so 
neither I<when> nor I<what> was run

=item notrun

I<when> succeeded and but I<what> wasn't run because we're in testing mode.

=item inactive

I<what> wasn't run.

=back

=head2 loaded()

  $loaded = $loader->loaded;

Returns a hashref that maps state I<name>s to the return values of
loaded resources.

Note: Don't confuse this with load(). load() loads the resources,
loaded() tells you what loaded.

=head2 env()

  $env = $loader->env;

Returns a hashref of the Resource::Loader-related environment
variables and their current values. Probably only useful for
debugging.

=head1 ENVIRONMENT

Use these environment variables to override the local behavior of the
object (e.g. to test your Resource::Loader's responses)

=head2 RMSTATES

Colon-separated list of states to run resources for. The I<when>
coderefs won't even be run if the state I<name>s aren't listed here.

=head2 RMCONT

See cont()

=head2 RMTESTING

See testing()

=head2 RMVERBOSE

See verbose()

=head1 EXAMPLES

I originally wrote this to handle our software deployment needs. The
software starts its life on our development machine. From there, it's
pushed to a test machine. If it tests clean there, we pushed it to one
or more production machine(s). The test and production machines are
supposed to be as similar as possible to prevent surprises when the
software hits production.

We don't want to mix environments by, say, testing code on the dev
box with the production database. Accidentally mangling a production
database would be, how you say, dumb.

The source code for this is in the examples/ directory.

There are other examples in that directory, check them out!

=head1 SEE ALSO

Abstract Factory design pattern. This isn't a factory but it's similar.

=head1 AUTHOR

Joshua Keroes, E<lt>skunkworks@eli.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Joshua Keroes

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
