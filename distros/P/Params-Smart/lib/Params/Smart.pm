package Params::Smart;

use 5.006;
use strict;
use warnings; # ::register __PACKAGE__;

use Carp;
use Regexp::Common qw( delimited );

require Exporter;

our @ISA         = qw( Exporter );
our @EXPORT      = qw( Params );
our @EXPORT_OK   = qw( Params ParamsNC );
our %EXPORT_TAGS = ( all => \@EXPORT_OK ); 

our $VERSION = '0.08';

sub parse_param {
  my $self  = shift;
  my $param = shift;

  local ($_);
  if (ref($param) eq "HASH") {
    # we only want to pass supported parameters
    my $info = {
      _parsed => 0,
    };
    foreach (qw( 
         name type default required name_only slurp
         callback comment needs
     )) {
      $info->{$_} = $param->{$_};
    }
    return $info;
  } elsif (!ref($param)) {
    $param =~ /^([\?\+\*]+)?([\@\$\%\&])?([\w\|]+)(\=.+)?/;
    my $mod  = $1 || "";
    my $type = $2;
    my $name = $3;
    my $def  = substr($4,1) if (defined $4);

    if ((defined $def) &&
	($def =~ /$RE{quoted}{-keep}/)) {
      $def = $3;
    }

    unless (defined $name) {
      croak "malformed parameter $param";
    }
    if ($name =~ /^\_\w+/) {
      croak "parameter $name cannot begin with an underscore";
    }

    if (exists $self->{names}->{$name}) {
      croak "parameter $name already specified";
    }
    else {
      my $info = {
        name      => $name,
        type      => $type,
        default   => $def,
        required  => (($mod !~ /\?/) || 0),
        name_only => (($mod =~ /\+/) || 0),
	slurp     => (($mod =~ /\*/) || 0),
        callback  => undef, # sub { return $_[2]; },
        comment   => $name,
        needs     => undef,
        _parsed   => 1,
      };
      return $info;
    }
  } else {
    croak "invalid parameter";
  }
  return;
}

sub set_param {
  my $self = shift;
  my $info = shift;
  croak "invalid parameter" unless (ref($info) eq "HASH");

  # TODO - name_only should be set if this is dynamic

  $self->{dynamic}   ||= ($self->{lock});
  $info->{name_only} ||= ($self->{dynamic});

  my @names = split /\|/, $info->{name};
  $info->{name} = undef;

  do {
    my $name = shift @names;
    $info->{name} = $name, unless (defined $info->{name});
    if (exists $self->{names}->{$name}) {
      $self->{names}->{$name} = $info;
    }
    else {
      my $index = scalar(@{$self->{order}});
      unless ($info->{name_only}) {
        $info->{_index} = $index;
        $self->{order}->[$index] = $name;
      }
      $self->{names}->{$name} = $info;
    }
    if (@names) {
      $info->{name_only} ||= 1;
      $info->{required}    = 0;
      delete $info->{default};
    }
  } while (@names);
  return $info;
}

sub new {
  my $class = shift;
  my $self  = {
    names   => { },
    order   => [ ],
    lock    => 0,
    dynamic => 0,
  };
  bless $self, $class;

  my $index = 0;
  my $last;
 SLURP: while (my $param = shift) {

    my $info = $self->parse_param($param);
    if ($info) {
      if ($info->{slurp}) {
	croak "no parameters can follow a slurp" if (@_);
      }
      if ($last && $info->{required} && (!$last->{required})) {
	croak "a required parameter cannot follow an optional parameter";
      }
      if ($info->{name_only} && $info->{slurp}) {
	croak "a parameter cannot be named_only and a slurp";
      }
      if ($last && ($info->{_parsed} != $last->{_parsed})) {
        croak "cannot mix parsed and non-parsed parameters";
      }
      $self->set_param($info);
      $last = $info;
    }
    else {
      croak "unknown error";
    }
    $index++;
  }

  $self->{lock} = 1;
  return $self;
}

# We have the exported Params() function rather than requiring calls
# to Params::Smart->new() so that the code looks a lot cleaner.  It's
# also a wrapper for a home-grown memoization function. (We cannot use
# Memoize because callbacks become problematic.)

my %Memoization = ( );

sub Params {
  my $key = join $;, map { $_||""} (caller);
  return  $Memoization{$key} ||= __PACKAGE__->new(@_);
}

sub ParamsNC {
  return __PACKAGE__->new(@_);
}

# Note: usage does not display aliases, nor named_only parameters

sub _usage {
  my $self  = shift;
  my $error = shift;
  my $named = shift || 0;

  local($_);

  my $caller = (caller(2))[3] || "";

  my $usage = $error . ";\nusage: $caller(";

  # TODO - handle named parameters etc.

  $usage .=
      join(", ", map {
        my $name = $_;
        $name = "?$name", unless ($self->{names}->{$name}->{required});
        $name = "*$name", if ($self->{names}->{$name}->{slurp});
        $name;
      } @{$self->{order}}) . ") ";


  croak $usage;
}

# The callback is expected to coerce the data or return an error

sub _run_callback {
  my $self = $_[0];
  my $name = $_[1];
  my $callback = $_[0]->{names}->{$name}->{callback};
  if (ref($callback) eq "CODE") {
    return &{$callback}(@_);
  }
  else {
    croak "expected code reference for callback";
  }
}

sub args {
  my $self = shift;

  # TODO - return a reference to $self in the values

  my %vals = ( );

  # $vals{_args} = [ @_ ];

  my $named = !(@_ % 2);

  # For even number positional parameter with undef in them. 
  for (my $i=0; ($named && ($i < @_)); $i += 2) {
    if (!defined $_[$i]) { $named = 0 }
  }

  if ($named) {
    my %unknown = ( );
    my $i = 0;
    while ($named && ($i < @_)) {
      my $n = $_[$i];
      $n = substr($n,1) if ($n =~ /^\-/);
      if (exists $self->{names}->{$n}) {
        my $truename = $self->{names}->{$n}->{name};
	$vals{$truename} = $_[$i+1];
        if ($self->{names}->{$truename}->{callback}) {
	  $@ = undef;
	  eval {
	    $vals{$truename} =
	      $self->_run_callback($truename, $vals{$truename}, \%vals);
	  };
	  $self->_usage($@,$named) if ($@);
	}
      } else {
	$unknown{$n} = $i;
      }
      $i += 2;
    }

    # As long as there are unknown keys and dynamically-added
    # parameters, we'll keep re-checking.

    while ($self->{dynamic}) {
      $self->{dynamic} = 0;
      if ($named && (keys %unknown)) {
        foreach my $n (keys %unknown) {
	  if (exists $self->{names}->{$n}) {
            my $truename = $self->{names}->{$n}->{name};
	    $vals{$truename} = $_[$unknown{$n}+1];
	    if ($self->{names}->{$truename}->{callback}) {
	      $@ = undef;
	      eval {
		$vals{$truename} =
		  $self->_run_callback($truename, $vals{$truename}, \%vals);
	      };
	      $self->_usage($@,$named) if ($@);
	    }
	    delete $unknown{$n};
	  }
        }
      }
    }

    if ($named && (keys %unknown) && (keys %vals)) {
      $self->_usage("unrecognized parameters: " .
	join(" ", map { "\"$_\"" } keys %unknown), $named);
    }
    elsif ($named && (keys %unknown)) {
      $named = 0;
      %vals = ( );
    }
  }

  unless ($named) {
    my $i = 0;
    while ($i < @_) {
      my $n = $self->{order}->[$i];
      unless (defined $n) {
	$self->_usage("too many arguments",$named);
      }
      my $truename = $self->{names}->{$n}->{name};
      if ($self->{names}->{$truename}->{slurp}) {
	$vals{$truename} = [ @_[$i..$#_] ];
	$i = $#_; # we don't want to use 'last'
      } else {
	$vals{$truename} = $_[$i];
      }
      if ($self->{names}->{$truename}->{callback}) {
	$@ = undef;
	eval {
	  $vals{$truename} =
	    $self->_run_callback($truename, $vals{$truename}, \%vals);
	};
	$self->_usage($@,$named) if ($@);
      }
      $i++;
    }
  }

  # validation stage

  foreach my $name (keys %{ $self->{names} }) {
    my $info = $self->{names}->{$name};
    unless (exists($vals{$name})) {
      $vals{$name} = $info->{default},
        if (($name eq $info->{name}) && (defined $info->{default}));
    }
    if ($info->{required} && !exists($vals{$name})) {
      $self->_usage("missing required parameter \"$name\"", $named);
    }
    if (defined $info->{needs}) {
      # convert a scalar into a list with one element
      if (!ref $info->{needs}) { $info->{needs} = [ $info->{needs} ] }

      foreach my $dep (@{ $info->{needs} }) {
        unless (exists($vals{$dep})) {
          $self->_usage("missing required parameter \"$dep\" (needed by \"$name\")", $named);
        }
      }

    }
  }

  $vals{_named} = $named;

  return %vals;
}


1;

__END__


=head1 NAME

Params::Smart - use both positional and named arguments in a subroutine

=begin readme

=head1 REQUIREMENTS

The following non-core modules are required:

  Regexp::Common

=head1 INSTALLATION

Installation can be done using the traditional Makefile.PL or the newer
Build.PL methods.

Using Makefile.PL:

  perl Makefile.PL
  make test
  make install

(On Windows platforms you should use C<nmake> instead.)

Using Build.PL (if you have Module::Build installed):

  perl Build.PL
  perl Build test
  perl Build install

=end readme

=head1 SYNOPSIS

  use Params::Smart 0.04;

  sub my_sub {
    %args = Params(qw( foo bar ?bo ?baz ))->args(@_);
    ...
  }

  my_sub( foo=> 1, bar=>2, bo=>3 );  # call with named arguments

  my_sub(1, 2, 3);                   # same, with positional args

=head1 DESCRIPTION

This module provides "smart" parameter handling for subroutines without
having to use a changed syntax or source filters. Features include:

=over

=item *

Mixed use of named and positional parameters.

=item *

Type checking and coercion through callbacks.

=item *

Dyanmic parameters configured from callbacks.

=item *

Memoization of parameter templates.

=back

=for readme stop

Usage is as follows:

  sub my_sub {
    %vals = Params( @template )->args( @args );
    ...
  }

The C<@template> specifies the names of parameters in the order that they
should be given in subroutine calls, and C<@args> is the list of argument
to be parsed: usually you just specify the void list C<@_>.

The keys in the returned hash C<%vals> are assigned to the appropriate
arguments, irrespective of calling style.

Names may be called with an optional initial dash, as with
L<Getargs::Mixed>:

  my_sub( -first => 1, -second => 2 );

Smart parameters can be used for method calls:

  sub my_method {
    my $self = shift;
    %vals = Params( @template )->args( @args );
    ...
  }

The values may also contain additional keys which begin with an
underscore.  These are internal/diagnostic values:

=over

=item _named

True if the parameters were treated as named, false if positional. See
L</CAVEATS> below.

=back

To improve performance, C<Params> memoizes parameter templates
when they are parsed, based on where the call to C<Params> was
made.

This may be problematic if templates are changed dynamically. To
override memoization, use ParamsNC function:

  %vals = ParamsNC( @template )->args( @_ );

There are two styles of templates, L</Simple Parameter Templates> with a Perl6-like
syntax, and L</Complex Parameter Templates> which allow more options to be specified
using hashes.

=head2 Simple Parameter Templates

Simple parameter templates contain a list of key names in the order
that they are expected for positional calls:

  sub my_sub {
    %vals = Params(qw( first second third ))->args(@_);
     ...
  }

Calling the subroutine with the following

  my_sub(1, 2, 3);

sets the values

  %vals = (
    first  => 1,
    second => 2,
    third  => 3
  );

Parameters are required by default.  To make a parameter optional,
add a question mark before it:

  %vals = Params(qw( first second ?third ))->args(@_);

Note that no required parameters may follow an optional parameter.

If one wants to "slurp" all remaining arguments into one value, add an
asterisk before it:

  %vals = Params(qw( first *second ))->args(@_);

So the above example call would set the values

  %vals = (
    first  => 1,
    second => [ 2, 3 ]
  );

Note that the slurp argument is required unless it also includes a
question-mark:

  %vals = Params(qw( first *?second ))->args(@_);

You can also mark options as being allowed when called with named
parameters only by adding a plus sign before them:

  %vals = Params(qw( common +?obscure +?strange +?weird ))->args(@_);

This is useful when there are many options which are rarely needed
(and too awkward to use in positional calling), or may have dangerous
side effects if accidentally specified with a positional calling
style.  (The order of named-only parameters does not matter.)

You can also enforce named-only calling conventions on a subroutine
by omitting question-marks from at least one parameter:

  %vals = Params(qw( +first +second ))->args(@_);

As of version 0.04, default values can also be specified:

  %vals = Params(qw( first=1 second=2 ))->args(@_);

Defaults can be delimited with quotes:

  %vals = Params( 'first="some string"' ))->args(@_);

You can also specify aliases by separating them with a vertical bar:

  %vals = Params(qw( hour|hh minute|min|mm seconds|sec|ss ))->args(@_);

All named parameter calls using aliases will be stored using the
first name.

In general use of aliases are I<not> recommended for subroutines. (This
feature is a hook for implementing script-wide "getopts"-like functions.)

=head2 Complex Parameter Templates

You may use more complex templates if you need to specify additional
information, such as callbacks:

  %vals = Params(
    {
      name     => "first",
      required => 1,
      callback => sub { ... },
      comment  => "first parameter",
    },
    {
      name     => "next",
      slurp    => 1,
      comment  => "second parameter",
    },
  )->args(@_);

Each parameter is specified by a hash reference with the following keys:

=over

=item name

The name of the parameter. May include aliases, separated by vertical bars.

=item required

The parameter is required if true.

=item default

A default value of the parameter.

=item slurp

This parameter slurps the remaining arguments if true. The parameter
will be an array reference.

=item name_only

This parameter may be specified using named-calls only if true.

=item needs

This parameter needs these other parameters to be specified (either as a
list reference, or a string for a single required parameter).

=item type

Not yet implemented. Use the callback to validate the value.

=item callback

An optional callback which validates and coerces the parameter.  The
callback is passed the parameter-parsing object, the name of the
parameter, and the value:

  callback => sub {
    my ($self, $name, $value) = @_;
    ...
    return $value;
  },

The C<$name> is the primary name for the parameter, and not any
aliases which might have been used.

It is expected to return the coerced value, or die if there is a
problem:

  callback => sub {
    my ($self, $name, $value, $hashref) = @_;
    die "$name must be >= 0"
      if ($value < 0);
    return $value || 1;
  },

Callbacks can also update the acceptable parameters:

  callback => sub {
    my ($self, $name, $value, $hashref) = @_;
    if ($value eq "zip") {
      $self->set_param( {
        name    => "compression_level",
        default => 6,
      } );
    }
    return $value;
  },

One can use this to change or add new named parameters based on the
values of existing parameters.  However, one should use C<ParamsNC>
so that the modified template is not cached.

In many cases you should use the L</needs> option and avoid dynamically
updating the parameters.

Note that dynamically-added parameters cannot dynamically add other
parameters (at least not in this version).

The C<$hashref> is a reference to the values being returned.  One may
not be able to rely on a specific parameter being set before the
callback is executed, however.

Note that the order that callbacks are called is not determined, so do
not rely on one callback being called before another.

Do not call any internal methods aside from those documented here, as they
do not have a defined behavior and may change in future versions.

=item comment

An optional comment describing the field. This is currently unused but
may be displayed in error messages in future versions.

=back

=for readme continue

=head2 Compatability with Previous Versions

Note that the formatting for simple parameter templates has changed
since version 0.03, and the complex parameter templates were not
implemented until version 0.04, so it is best to specify a minimum
version in use statements

  use Params::Smart 0.04;

=for readme stop

=begin readme

=head1 REVISION HISTORY

A brief list of changes since the previous release:

=for readme include file="Changes" start="0.08" stop="0.07" type="text"

For a detailed history see the F<Changes> file included in this distribution.

=end readme

=head1 CAVEATS

Because Perl5 treats hashes as lists, this module attempts to interpret
the arguments as a hash of named parameters first.  If some hash keys
match, and some do not, then it assumes there has been an error. If
no keys match, then it assumes that it the arguments are positional.

In theory one can pass positional arguments where every other argument
matches a hash key, or one can pass a hash with the wrong keys (possible
if one copies/pastes code from the wrong call) and so it is treated as
a positional argument.

This is probably uncommon for most data, but subroutines should take
extra care to check if values are within allowed ranges.  There may
even be security issues if users can blindly specify data that they
know can cause this confusion.  If the application is critical
enough, then this may not be an appropriate module to use (at least
not until the ability to distinguish between lists and hashes is
improved).

To diagnose potential bugs, or to enforce named or positional calling
one can check the L</_named> parameter.

A future version might make use of Perl internals to get around this
problem.

=for readme continue

=head1 SEE ALSO

This module is superficially similar in function to L<Getargs::Mixed>
but does not require named parameters to have an initial dash ('-').

L<Class::NamedParams> provides a framework for implementing named
parameters in classes.

L<Sub::NamedParams> will create a named-parameter wrapper around subroutines
which use positional parameters.

The syntax of the parameter templates is inspired by L<Perl6::Subs>,
though not necessarily compatible. (See also I<Apocalypse 6> in
L<Perl6::Bible>).

L<Sub::Usage> inspired the error-messages returned by calls to arg().

L<Params::Validate> is useful for (additional) parameter validation
beyond what this module is capable of.

L<Class::ParmList> provides a framework for parameter validation as well.

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>

=head2 Suggestions and Bug Reporting

Feedback is always welcome.  Please use the CPAN Request Tracker at
L<http://rt.cpan.org> to submit bug reports.

=head1 LICENSE

Copyright (c) 2005-2007 Robert Rothenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
