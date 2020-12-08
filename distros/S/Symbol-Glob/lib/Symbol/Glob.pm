package Symbol::Glob;

our $VERSION = '0.04';

use warnings;
use strict;
use Carp;

use Scalar::Util qw(reftype);

{
  my (%hash_of, %code_of, %array_of, %scalar_of, %io_of, %format_of, %name_of);

  my %Slot_To_Storage_Of = (
    SCALAR => \%scalar_of,
    ARRAY  => \%array_of,
    HASH   => \%hash_of,
    CODE   => \%code_of,
    IO     => \%io_of,
    FORMAT => \%format_of,
  );

  my %Slot_To_Method_Of = (
    SCALAR => 'scalar',
    ARRAY  => 'array',
    HASH   => 'hash',
    CODE   => 'sub',
    IO     => 'io',
    FORMAT => 'format',
  );

  my %Method_To_Slot_Of = reverse %Slot_To_Method_Of;

  sub new {
      my($class, $arg_ref) = @_;
      my $self = {};
      bless $self, $class;
      $self->BUILD($arg_ref);
      return $self;
  }

  sub BUILD {
    my ($self, $arg_ref) = @_;

    die "Argument to Symbol::Glob->new() must be hash reference"
        if not ref $arg_ref eq 'HASH';
    my $name = $arg_ref->{'name'};
    die "No typeglob name supplied" unless $name;

    $name_of{$self} = $name;

  CHECK_SLOTS:
    for my $slot (keys %Slot_To_Storage_Of) {
      my $slot_of = $Slot_To_Storage_Of{$slot};
      my $method  = $Slot_To_Method_Of{$slot};

      # Copy out the original glob's contents if they exist.
      my $contents;
      {
        no strict 'refs';
        $contents = *{ $name }{$slot};
      }

      if (defined $contents) {
        if ($method eq 'scalar') {
          # We should have gotten a reference to the scalar value here.
          $contents = $$contents;
          # special case: undef scalar is \undef.
          next CHECK_SLOTS if !defined $contents;
        }

        $self->$method($contents);
      }

      # Arguments supplied to new() override
      # the glob contents.
      next CHECK_SLOTS if !exists $arg_ref->{$method};

      my $override = $arg_ref->{$method};

      if (defined $override) {
        $self->$method($override);
      }
    }

    # Object and glob are now in sync.
    return $self;
  }

  sub scalar {
    my ($self, $value) = @_;

    if (defined $value) {
      $self->_reslot(\$value, \%scalar_of, 'SCALAR');
    }

    my $return_value = $scalar_of{$self};
    return   !defined $return_value ? undef
           : !ref $return_value     ? $return_value
           : $$return_value;
  }

  sub hash {
    my ($self, $value) = @_;
    if (defined $value) {
      wantarray ? %{$self->_reslot($value, \%hash_of, 'HASH')}
                : $self->_reslot($value, \%hash_of, 'HASH');
    }
    else {
      wantarray ? %{$hash_of{$self}} : $hash_of{$self};
    }
  }

  sub array {
    my ($self, $value) = @_;
    if (defined $value) {
      wantarray ? @{$self->_reslot($value, \%array_of, 'ARRAY')}
                : $self->_reslot($value, \%array_of, 'ARRAY');
    }
    else {
      wantarray ? @{$array_of{$self}} : $array_of{$self};
    }
  }

  sub sub {
    my ($self, $value) = @_;
    if (defined $value) {
      $self->_reslot($value, \%code_of, 'CODE');
    }
    else {
      $code_of{$self};
    }
  }

  sub _reslot {
    my ($self, $value, $slot_of_ref, $slot_to_be_replaced) = @_;
    if ($slot_to_be_replaced eq 'SCALAR') {
      $slot_of_ref->{$self} = $$value;
    }
    else {
      $slot_of_ref->{$self} = $value;
    }

    croak "You can't fill a $slot_to_be_replaced with a " .  reftype($value)
      unless (reftype($value) eq $slot_to_be_replaced) or
             (reftype($value) eq 'REF' and $slot_to_be_replaced eq 'SCALAR');

    # Handy way to reference the glob.
    my $dest = $name_of{$self};

    {
      no strict;
      no warnings 'redefine';
      *{$dest} = $value;
    }

    return $slot_of_ref->{$self};
  }

  sub delete {
    my ($self, $slot_to_delete) = @_;
    my $storage_ref;

    # delete the slot in the object, and
    # then copy the object back into the
    # glob again as we do duing BUILD.
    if (defined $slot_to_delete) {
      my $glob_slot = $Method_To_Slot_Of{$slot_to_delete};
      $storage_ref = $Slot_To_Storage_Of{$glob_slot};

      delete $storage_ref->{$self};
    }

    # Delete the glob so it can be reconstituted.
    my $dest = $name_of{$self};
    my ($package, $symbol) = ($dest =~ /(.*::)*(.*)/);
    $package = __PACKAGE__.'::' unless $package;
    my $globref;

    {
      no strict;
      $globref = \%{$package};
      undef *{$dest};
    }

    # If no argument, deleting everything.
    return unless defined $slot_to_delete;

    for my $method (keys %Method_To_Slot_Of) {
      next if $method eq $slot_to_delete;

      $storage_ref = $Slot_To_Storage_Of{$Method_To_Slot_Of{$method}};
      my $value = $storage_ref->{$self};
      $value = \$value if $method eq 'scalar';

      {
        no warnings 'redefine';
        no strict 'refs';

        $globref->{$symbol} = $value
          if defined $storage_ref->{$self};
      }
    }
  }
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Symbol::Glob - remove items from the symbol table, painlessly


=head1 VERSION

This document describes Symbol::Glob version 0.01

=head1 SYNOPSIS

    use Symbol::Glob;
    # assumes current package unless specified
    my $glob = Symbol::Glob->new({ name => 'foo' });

    $glob->scalar(14);
    $glob->sub( sub { return 'this is a sub' });
    print $Some::Package::foo; # prints 14

    $glob->delete('scalar');
    print $Some::Package::foo; # undefined
    print $glob->sub->();      # prints 'this is a sub'

    $glob->delete;             # removes entire glob

=head1 DESCRIPTION

C<Symbol::Glob> provides a simple interface to manipulate Perl's symbol
table. You can define and undefine symbol table entries for scalars,
arrays, hashes, and subs via simple method calls.

This module does not (currently) attempt to mess with filehandles,
dirhandles, or formats.

=head1 INTERFACE

=head2 new

Creates the new C<Symbol::Glob> object. This method is automatically
generated by C<Class::Std>.

=head3 Arguments

Arguments are supplied as key/value pairs in an anonymous hash
as per C<Class::Std> interface standards.

=over 4

=item * name

The name of the glob you wish to manipulate. In this release,
we suggest you fully qualify the name of the glob. The use of
C<__PACKAGE__> is handy for this purpose.

=item * scalar

A scalar value to be assigned to the corresponding scalar
variable associated with this glob.

=item * array

An anonymous array or array reference whose contents are placed
into the array associated with this glob.

=item * hash

An anonymous hash or hash reference whose contents are placed
into the hash associated with this glob.

=item * sub

An anonymous sub or subroutine reference to be associated with
the subroutine name defined by this glob.

=back

=head2 BUILD

Called by C<Class::Std>'s C<new> method; you should not call this
method directly yourself. Performs the necessary object initialization.

=head2 scalar

When supplied a scalar value, sets the scalar entry in this typeglob
to the given value. As a side effect, the scalar variable associated
with this typeglob name comes into being if it did not already exist,
and is assigned the same value.

When supplied no value, the value of the scalar associated with
this slot (if any) is returned.

=head2 hash

When supplied a hash value, sets the hash entry in this typeglob
to the given value. As a side effect, the hash variable associated
with this typeglob name comes into being if it did not already exist.

When supplied no value, a reference to the hash associated with
this slot (if any) is returned in scalar context; the contents are
returned in list context.

=head2 array

When supplied a array value, sets the array entry in this typeglob
to the given value. As a side effect, the array variable associated
with this typeglob name comes into being if it did not already exist.

When supplied no value, a reference to the array associated with
this slot (if any) is returned in scalar context; the array contents
are returned in list context.

=head2 sub

When supplied a code reference, sets the sub entry in this typeglob
to the given value. As a side effect, the subroutine associated
with this typeglob name comes into being if it did not already exist.

When supplied no value, a reference to the sub associated with
this slot (if any) is returned in either scalar or list context.

=head2 delete

If no argument is supplied, the entire typeglob (and all associated
variables and code) is deleted.

If an argument is supplied, it must be one of 'scalar', 'hash',
'array', or 'sub'. The corresponding slot in the typeglob is
deleted, removing that item from the symbol table.

=head1 DIAGNOSTICS

=over

=item C<< No typeglob name supplied >>

You did not specify a C<name> in your call to C<new>.
You must name the typeglob you want to access to create
a C<Symbol::Glob> object.

=item C<< You can't fill in a %s with a %s >>

You will see this message if you try to supply an argument
that doesn't match to a C<Symbol::Glob> method; for example,
trying to put a hash into an array slot.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Symbol::Glob requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-symbol-glob@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Joe McMahon  C<< <mcmahon@yahoo-inc.com > >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Joe McMahon C<< <mcmahon@yahoo-inc.com > >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
