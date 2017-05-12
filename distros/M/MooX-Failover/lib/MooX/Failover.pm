package MooX::Failover;
$MooX::Failover::VERSION = 'v0.3.3';
use strict;
use warnings;

require Moo;

use Carp;
use Class::Load qw/ try_load_class /;
use Sub::Defer qw/ undefer_sub /;
use Sub::Quote qw/ quote_sub /;

{
    use version 0.77;
    $MooX::Failover::VERSION = version->declare('v0.3.3');
}

# RECOMMEND PREREQ: Class::Load::XS

=head1 NAME

MooX::Failover - Instantiate Moo classes with failover

=for readme plugin version

=head1 SYNOPSIS

  # In your class:

  package MyClass;

  use Moo;
  use MooX::Failover;

  has 'attr' => ( ... );

  # after attributes are defined:

  failover_to 'OtherClass';

  ...

  # When using the class

  my $obj = MyClass->new( %args );

  # If %args contains missing or invalid values or new otherwise
  # fails, then $obj will be of type "OtherClass".

=begin :readme

=head1 INSTALLATION

See
L<How to install CPAN modules|http://www.cpan.org/modules/INSTALL.html>.

=for readme plugin requires heading-level=2 title="Required Modules"

=for readme plugin changes

=end :readme

=head1 DESCRIPTION

This module provides constructor failover for L<Moo> classes.

For example, if a class cannot be instantiated because of invalid arguments
(perhaps from an untrusted source), then instead it returns the
failover class (passing the same arguments to that class).

It is roughly equivalent to using

  my $obj = eval { MyClass->new(%args) //
     OtherClass->new( %args, error => $@ );

This allows for cleaner design, by not forcing you to duplicate type
checking for constructor parameters.

=begin :readme

See the module documentation for L<MooX::Failover> for more information.

=end :readme

=for readme stop

=head2 Use Cases

A use case for this module is for instantiating
L<Web::Machine::Resource> objects, where a resource class's attributes
correspond to URL arguments.  A type failure would normally cause an
internal serror error (HTTP 500).  Using L<MooX::Failover>, we can
return a different resource object that examines the error, and
returns a more appropriate error code, e.g. bad request (HTTP 400).

Another use case for this module is for instantiating objects based on
their data sources.  For example, to restrieve an object from a cache,
or to fail and retrieve it from the database instead.

=head2 Design Considerations

Your failover class should support the same methods as the original
class, so that it (roughly) satisfies the Liskov Substitution
Principle, where all provable properties of the original class are
also provable of the failover class.  In practice, we only care about
the properties (methods and attributes) that are actually used in our
programs.

=head1 EXPORTS

The following function is always exported:

=head2 C<failover_to>

  failover_to $class => %options;

This specifies the class to instantiate if the constructor dies.

It should be specified I<after> all of the attributes have been
declared.

Chained failovers are allowed:

  failover_to $first  => %options1;
  failover_to $second => %options2;
  ...

The following options are supported.

=over

=item C<class>

The name of the class to fail over to.  It defaults to C<$class>.

=item C<constructor>

The name of the constructor method in the failover class. It defaults
to "new".

=item C<from_constructor>

The name of the constructor in the class that you are adding failover
to. It defaults to "new".

Note that you can add failovers to multiple constructors. Suppose your
class has a "new" constructor, as well as a "new_from_file"
constructor that loads information from a file and then calls "new".
You can specify failovers for both of the constructors:

  failover_to 'OtherClass';

  failover_to 'OtherClass' => (
    from_constructor => 'new_from_file',
  );

This option was added in v0.3.0.

=item C<args>

The arguments to pass to the failover class. When omitted, it will
pass the same arguments as the original class.

This can be a scalar (single argument), hash reference or array
reference.

Note that the options are treated are treated as raw Perl code.  To
use specify options, you need to explicitly add quotes to symbols, for
example:

  failover_to 'OtherClass' => (
    args => [ map { "'$_'" } ( foo => 'bar' ) ],
  );

This option did not work properly until v0.3.0.

=item C<err_arg>

This is the name of the constructor argument to pass the error to (it
defaults to "error".  This is useful if the failover class can inspect
the error and act appropriately.

For example, if the original class is a handler for a website, where
the attributes correspond to URL parameters, then the failover class
can return HTTP 400 responses if the errors are for invalid
parameters.

To disable it, set it to C<undef>.

=item C<class_arg>

This is the name of the constructor argument to pass the name of the
original class that failed.  It defaults to "class".

To disable it, set it to C<undef>.

For chained failovers, it always contains the name of the original
class.

=item C<orig_arg>

This is the name of the constructor to pass an array reference of the
original arguments passed to class.  It is C<undef> by default.

The original arguments are already passed to the failover class, but
this can be used to pass them all in a specific parameter.

If you do not want the original arguments passed to the failover class
separately, set the C<args> option to be empty:

  failover_to 'OtherClass' => (
    args      => [ ],
    orig_args => 'failed_args',
  );

This option was added in v0.3.0.

=back

Note that unimporting L<Moo> using

  no Moo;

will also unimport L<MooX::Failover>.

=head1 ATTRIBUTES

None. Since v0.2.0, there is no longer a C<failover_to> attribute.

=cut

sub import {
    my $caller = caller;
    my $name   = 'failover_to';
    my $code   = \&failover_to;
    my $this   = __PACKAGE__ . "::${name}";
    my $that   = "${caller}::${name}";
    $Moo::MAKERS{$caller}{exports}{$name} = $code;
    Moo::_install_coderef( $that, $this => $code );
}

sub unimport {
    my $caller = caller;
    Moo::_unimport_coderefs( $caller,
        { exports => { 'failover_to' => \&failover_to } } );
}

sub _ref_to_list {
    my ($next) = @_;

    my $args = $next->{args} // ['@_'];
    if ( my $ref = ref $args ) {

        return ( @{$args} ) if $ref eq 'ARRAY';
        return ( %{$args} ) if $ref eq 'HASH';

        croak "args must be an ArrayRef, HashRef or Str";

    }
    else {

        return ($args);

    }

}

sub failover_to {
    my $class = shift;
    my %next  = @_;

    $next{class} //= $class;

    $next{class} or croak "no class defined";

    try_load_class( $next{class} )
      or croak "unable to load " . $next{class};

    my $caller = caller;
    croak "cannot failover to self" if $next{class} eq $caller;

    $next{from_constructor} //= 'new';
    $next{constructor} //= 'new';

    croak $next{class} . ' cannot ' . $next{constructor}
      unless $next{class}->can( $next{constructor} );

    $next{err_arg}   //= 'error' unless exists $next{err_arg};
    $next{class_arg} //= 'class' unless exists $next{class_arg};

    my $orig_name = $caller . '::' . $next{from_constructor};
    my $orig_code = undefer_sub \&{$orig_name};

    my $next_name = $next{class} . '::' . $next{constructor};
    my $next_code = undefer_sub \&{$next_name};

    my @args = _ref_to_list(\%next);
    push @args, $next{err_arg} . ' => $@' if defined $next{err_arg};
    push @args, $next{class_arg} . " => '${caller}'"
      if defined $next{class_arg};
    push @args, $next{orig_arg} . ' => [@_]' if defined $next{orig_arg};

    my $code_str =
        'eval { shift->$orig(@_); }' . ' // ' . $next{class} . '->$cont('
      . join( ',', @args ) . ')';

    quote_sub $orig_name, $code_str, {
	'$orig' => \$orig_code,
	'$cont' => \$next_code,
    };
}

=for readme continue

=head1 SEE ALSO

This was originally a L<Moo> port of L<MooseX::Failover>.  The
interface was redesigned significantly, to be more efficient.

=head1 AUTHOR

Robert Rothenberg C<<rrwo@thermeon.com>>

=head2 Acknowledgements

=over

=item Thermeon.

=item Piers Cawley.

=item Gareth Kirwan.

=back

=head1 COPYRIGHT

Copyright 2014 Thermeon Worldwide, PLC.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

1;
