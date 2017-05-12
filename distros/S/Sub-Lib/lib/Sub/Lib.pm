package Sub::Lib;

use strict;
use warnings;
use v5.8.8;

our $VERSION = '0.03';

sub new {
  my ($class, @args) = @_;

  my $args;
  if(1 == @args) {
    die "reference argument to new() must be a HASH\n"
      unless 'HASH' eq ref $args[0];
    $args = $args[0];
  }
  else {
    die "non-reference argument list to new() must have an even number of elements\n"
      unless 0 == @args % 2;
    $args = {@args};
  }

  # \o/ Lobe den Abgrund
  my $self = bless do {
    my $_lib = { };
    sub {
      my ($name, $sub) = @_;

      return $_lib
        unless defined $name;

      if(defined $sub) {
        die "sub-routine ($name) is not a sub-routine?\n"
          unless 'CODE' eq ref $sub;
        die "sub-routine ($name) already installed in library\n"
          if exists $_lib->{$name};

        $_lib->{$name} = $sub;
      }
      else {
        die "sub-routine ($name) not installed in library\n"
          unless exists $_lib->{$name};
      }

      return $_lib->{$name};
    }
  }, $class;

  $self->($_, $args->{$_})
    for keys %$args;
  return $self;
}

sub has {
  my ($self, $name) = @_;

  my $_lib = $self->();
  return $_lib->{$name};
}

sub run {
  my ($self, $name, @args) = @_;

  return $self->($name)->(@args);
}

sub call {
  my ($self, $name, $object, @args) = @_;

  my $sub = $self->($name);
  return $object->$sub(@args);
}

sub void {
  my ($self, $name) = @_;

  my $_lib = $self->();
  my $sub = exists $_lib->{$name}
    ? $_lib->{$name}
    : sub { return }
  ;

  return $sub;
}

sub curry {
  my ($self, $name, @args) = @_;

  my $sub = $self->($name);
  return sub { $sub->(@args, @_) };
}

sub o {
  my ($self, $name, $object, @args) = @_;

  my $sub = $self->($name);
  return sub { $object->$sub(@args, @_) };
}

sub y {
  my ($self, $name, $sub, @args) = @_;

  die "code reference required for lambda\n"
    unless 'CODE' eq ref $sub;

  return sub { $sub->( $self->($name), @args, @_ ) }
}


1
__END__

=pod

=head1 NAME

Sub::Lib - Stuff sub-routines into a run-time namespace.  Because.  Reasons.

=head1 SYNOPSIS

  use Sub::Lib;

  # create a library
  my $lib = Sub::Lib->new({
    'log' => sub {print join(' ', localtime. ':', @_), "\n"},
  });

  # add methods
  $lib->('info',  sub {$lib->('log')->('info:', @_)});
  $lib->('warn',  sub {$lib->('log')->('warn:', @_)});

  # call them directly
  $lib->('info')->('This is for information');

  # or via some sugar
  $lib->run('warn', 'This is for warnings');

  # or via some oo sugar
  $lib->('method', sub {
    my ($self, $name, @args) = @_;
    $self->run($name, @args);
  });
  # calls the 'method' sub-routine from the library as an object
  # method on $lib.  attaches to objects like a virus.
  $lib->call('method', $lib, 'info', "Have you seen?  Oh I've seen.");

  # cheeseburger
  {
    my $sub = $lib->has('warn');
    $sub->('I can has.')
      if $sub;
  }

  # in case you don't like exceptions
  $lib->void('info')->('This has a high probability of working');
  $lib->void('ofni')->('Hidden messages go here');

  # why not?
  $lib->curry('warn', 'I know stuff now')->('and later');

  # why not?  for objects.
  my $o = $lib->o('method', $lib, 'info');
  $o->('I think I am confused');

  # closures allow bending time
  my $y = $lib->y('apex', sub {
    my ($sub, @args) = @_;
    $sub->('I can see forever', @args);
  }, 'or something.');
  $lib->('apex',  sub {$lib->('log')->('apex:', @_)});
  $y->('can you?');

  # you have been warned
  $lib->('info')->('installed subs:', join(', ', keys %{$lib->()}));

=head1 DESCRIPTION

Sub::Lib allows you to store sub-routines into a common library which
can then passed around as a variable.  It's a run-time namespace.

=head1 USAGE

=head2 C<new([HASHREF | LIST])>

Creates a library object and initializes it with entries that may be
passed in as either a C<HASH> reference or C<LIST> of key-value pairs.
The object created is itself a sub-routine that can be called directly
in order to run sub-routines stored in the library:

  $lib->('sub-routine name goes here')->(qw(sub routine args go here));

Additional sub-routines may be added by providing a C<CODE> reference:

  $lib->('a new sub-routine', sub {
    # code goes here
  });

If no arguments are passed, the internal library is returned:

  my $_lib = $lib->();

=head2 C<has($name)>

Returns the sub-routine installed in the library identified by C<$name> or
undef if it does not exist.

=head2 C<run($name, [LIST])>

Runs the sub-routine stored in the library identified by C<$name>.  An
exception will be thrown if no sub-routine by that name can be found.
Any additional arguments are passed to the sub-routine.

=head2 C<call($object, $name, [LIST])>

Calls the sub-routine stored in the library identified by C<$name> as
a method to the object in C<$object>.  This is similar to C<run()> above
but uses Perl's object semantics.  Additional arguments are passed to
the method.

=head2 C<void($name)>

Either returns the sub-routine installed in the library identified by
C<$name> or returns a void sub-routine.  This is useful if you want
to blindly call sub-routines and not worry if they exist.  It is
debatable how useful that is in itself.

=head2 C<curry($name, [LIST])>

Returns a sub-routine that, when called, will execute the sub-routine
installed in the library identified by C<$name> with arguments in C<LIST>
prepended.  Additional arguments to the call itself are also appended.

=head2 C<o($name, $object, [LIST])>

Similar to C<curry()> but the sub-routine that is returned will execute a
method call on the object specified by C<$object>.

=head2 C<y($name, $sub, [LIST])>

Creates an anonymous sub-routine that, when executed, will run the C<CODE>
reference identified by C<$sub> passing in the sub-routine installed in
the library under C<$name>.  Arguments passed in C<LIST> will be curried
along with arguments to the call itself.  Unlike other methods, C<y()>
does not require C<$name> to be installed when called in order to delay
execution for as long as possible.

=head1 AUTHOR

jason hord E<lt>pravus@cpan.orgE<gt>

=head1 LICENSE

This software is information.
It is subject only to local laws of physics.

=cut
