use strict;
use warnings;
package Package::Generator;
{
  $Package::Generator::VERSION = '1.106';
}
use 5.008;
# ABSTRACT: generate new packages quickly and easily

use Carp ();
use Scalar::Util ();


my $i = 0;
my $unique_part = sub { $i++ };
my $make_unique = sub { sprintf "%s::%u", $_[0], $_[1]->() };

sub new_package {
  my ($self, $arg) = @_;
  $arg->{base} ||= 'Package::Generator::__GENERATED__';
  $arg->{unique_part} ||= $unique_part;
  $arg->{make_unique} ||= $make_unique;
  $arg->{max_tries} ||= 1;

  my $package;
  for (my $i = 1; 1; $i++) {
    $package = $arg->{make_unique}->($arg->{base}, $arg->{unique_part});
    last unless $self->package_exists($package);
    Carp::croak "couldn't generate a pristene package under $arg->{base}"
      if $i >= $arg->{max_tries};
  }

  my @data = $arg->{data} ? @{ $arg->{data} } : ();

  push @data, (
    ($arg->{isa} ? (ISA => (ref $arg->{isa} ? $arg->{isa} : [ $arg->{isa} ]))
                 : ()),
    ($arg->{version} ? (VERSION => $arg->{version}) : ()),
  );

  if (@data) {
    $self->assign_symbols($package, \@data);
  } else {
    # This ensures that even without symbols, the package is created so that it
    # will not be detected as pristene by package_exists.  Without this line of
    # code, non-unique tests will fail. -- rjbs, 2006-04-14
    {
      ## no critic (ProhibitNoStrict)
      no strict qw(refs);
      no warnings qw(void);
      %{$package . '::'};
    }
  }

  return $package;
}


sub assign_symbols {
  my ($self, $package, $key_value_pairs) = @_;

  Carp::croak "list of key/value pairs must be even!" if @$key_value_pairs % 2;

  ## no critic (ProhibitNoStrict)
  no strict 'refs';
  while (my ($name, $value) = splice @$key_value_pairs, 0, 2) {
    my $full_name = "$package\:\:$name";

    if (!ref($value) or Scalar::Util::blessed($value)) {
      ${$full_name} = $value;
    } else {
      *{$full_name} = $value;
    }
  }
}


sub package_exists {
  my ($self, $package) = @_;

  return defined *{$package . '::'};
}

# My first attempt!  How silly I felt when I threw in some Data::Dumper and saw
# that the above would suffice. -- rjbs, 2006-04-14
#
#  my @parts = split /::/, $package;
#
#  my $current_pkg = 'main';
#  for (@parts) {
#    my $current_stash = do { no strict 'refs'; \%{$current_pkg . "::"} };
#    return unless exists $current_stash->{$_ . "::"};
#    $current_pkg .= "::$_"
#  }
#  return 1;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Package::Generator - generate new packages quickly and easily

=head1 VERSION

version 1.106

=head1 SYNOPSIS

    use Package::Generator;

    my $package = Package::Generator->new_package;
    ...

=head1 DESCRIPTION

This module lets you quickly and easily construct new packages.  It gives them
unused names and sets up their package data, if provided.

=head1 INTERFACE

=head2 new_package

  my $package = Package::Generator->new_package(\%arg);

This returns the newly generated package.  It can be called with no arguments,
in which case it just returns the name of a pristene package.  The C<base>
argument can be provided to generate the package under an existing namespace.
A C<make_unique> argument can also be provided; it must be a coderef which will
be passed the base package name and returns a unique package name under the
base name.

A C<data> argument may be passed as a reference to an array of pairs.  These
pairs will be used to set up the data in the generated package.  For example,
the following call will create a package with a C<$foo> set to 1 and a C<@foo>
set to the first ten counting numbers.

  my $package = Package::Generator->new_package({
    data => [
      foo => 1,
      foo => [ 1 .. 10 ],
    ]
  });

For convenience, C<isa> and C<version> arguments may be passed to
C<new_package>.  They will set up C<@ISA>, C<$VERSION>, or C<&VERSION>, as
appropriate.  If a single scalar value is passed as the C<isa> argument, it
will be used as the only value to assign to C<@ISA>.  (That is, it will not
cause C<$ISA> to be assigned;  that wouldn't be very helpful.)

=head2 assign_symbols

  Package::Generator->assign_symbols($package, \@key_value_pairs);

This routine is used by C<L</new_package>> to set up the data in a package.

=head2 package_exists

  ... if Package::Generator->package_exists($package);

This method returns true if something has already created a symbol table for
the named package.  This is equivalent to:

  ... if defined *{$package . '::'};

It's just a little less voodoo-y.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
