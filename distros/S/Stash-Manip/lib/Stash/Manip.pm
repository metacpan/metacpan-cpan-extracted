package Stash::Manip;
BEGIN {
  $Stash::Manip::VERSION = '0.02';
}
use strict;
use warnings;

use Carp qw(confess);
use Scalar::Util qw(reftype);

=head1 NAME

Stash::Manip - routines for manipulating stashes

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  my $stash = Stash::Manip->new('Foo');
  $stash->add_package_symbol('%foo', {bar => 1});
  # $Foo::foo{bar} == 1
  $stash->has_package_symbol('$foo') # false
  my $namespace = $stash->namespace;
  *{ $namespace->{foo} }{HASH} # {bar => 1}

=head1 DESCRIPTION

Manipulating stashes (Perl's symbol tables) is occasionally necessary, but
incredibly messy, and easy to get wrong. This module hides all of that behind a
simple API.

NOTE: Most methods in this class require a variable specification that includes
a sigil. If this sigil is absent, it is assumed to represent the IO slot.

=head1 METHODS

=cut

=head2 new $package_name

Creates a new C<Stash::Manip> object, for the package given as the only
argument.

=cut

sub new {
    my $class = shift;
    my ($namespace) = @_;
    return bless { 'package' => $namespace }, $class;
}

=head2 name

Returns the name of the package that this object represents.

=cut

sub name {
    return $_[0]->{package};
}

=head2 namespace

Returns the raw stash itself.

=cut

sub namespace {
    # NOTE:
    # because of issues with the Perl API 
    # to the typeglob in some versions, we 
    # need to just always grab a new 
    # reference to the hash here. Ideally 
    # we could just store a ref and it would
    # Just Work, but oh well :\    
    no strict 'refs';
    return \%{$_[0]->name . '::'};
}

{
    my %SIGIL_MAP = (
        '$' => 'SCALAR',
        '@' => 'ARRAY',
        '%' => 'HASH',
        '&' => 'CODE',
        ''  => 'IO',
    );

    sub _deconstruct_variable_name {
        my ($self, $variable) = @_;

        (defined $variable && length $variable)
            || confess "You must pass a variable name";

        my $sigil = substr($variable, 0, 1, '');

        if (exists $SIGIL_MAP{$sigil}) {
            return ($variable, $sigil, $SIGIL_MAP{$sigil});
        }
        else {
            return ("${sigil}${variable}", '', $SIGIL_MAP{''});
        }
    }
}

=head2 add_package_symbol $variable $value

Adds a new package symbol, for the symbol given as C<$variable>, and optionally
gives it an initial value of C<$value>. C<$variable> should be the name of
variable including the sigil, so

  Stash::Manip->new('Foo')->add_package_symbol('%foo')

will create C<%Foo::foo>.

=cut

sub _valid_for_type {
    my $self = shift;
    my ($value, $type) = @_;
    if ($type eq 'HASH' || $type eq 'ARRAY'
     || $type eq 'IO'   || $type eq 'CODE') {
        return reftype($value) eq $type;
    }
    else {
        my $ref = reftype($value);
        return !defined($ref) || $ref eq 'SCALAR' || $ref eq 'REF' || $ref eq 'LVALUE';
    }
}

sub add_package_symbol {
    my ($self, $variable, $initial_value) = @_;

    my ($name, $sigil, $type) = ref $variable eq 'HASH'
        ? @{$variable}{qw[name sigil type]}
        : $self->_deconstruct_variable_name($variable);

    if (@_ > 2) {
        $self->_valid_for_type($initial_value, $type)
            || confess "$initial_value is not of type $type";
    }

    my $pkg = $self->name;

    no strict 'refs';
    no warnings 'redefine', 'misc', 'prototype';
    *{$pkg . '::' . $name} = ref $initial_value ? $initial_value : \$initial_value;
}

=head2 remove_package_glob $name

Removes all package variables with the given name, regardless of sigil.

=cut

sub remove_package_glob {
    my ($self, $name) = @_;
    no strict 'refs';
    delete ${$self->name . '::'}{$name};
}

# ... these functions deal with stuff on the namespace level

=head2 has_package_symbol $variable

Returns whether or not the given package variable (including sigil) exists.

=cut

sub has_package_symbol {
    my ($self, $variable) = @_;

    my ($name, $sigil, $type) = ref $variable eq 'HASH'
        ? @{$variable}{qw[name sigil type]}
        : $self->_deconstruct_variable_name($variable);

    my $namespace = $self->namespace;

    return unless exists $namespace->{$name};

    my $entry_ref = \$namespace->{$name};
    if (reftype($entry_ref) eq 'GLOB') {
        if ( $type eq 'SCALAR' ) {
            return defined ${ *{$entry_ref}{SCALAR} };
        }
        else {
            return defined *{$entry_ref}{$type};
        }
    }
    else {
        # a symbol table entry can be -1 (stub), string (stub with prototype),
        # or reference (constant)
        return $type eq 'CODE';
    }
}

=head2 get_package_symbol $variable

Returns the value of the given package variable (including sigil).

=cut

sub get_package_symbol {
    my ($self, $variable) = @_;

    my ($name, $sigil, $type) = ref $variable eq 'HASH'
        ? @{$variable}{qw[name sigil type]}
        : $self->_deconstruct_variable_name($variable);

    my $namespace = $self->namespace;

    if (!exists $namespace->{$name}) {
        # assigning to the result of this function like
        #   @{$stash->get_package_symbol('@ISA')} = @new_ISA
        # makes the result not visible until the variable is explicitly
        # accessed... in the case of @ISA, this might never happen
        # for instance, assigning like that and then calling $obj->isa
        # will fail. see t/005-isa.t
        if ($type eq 'ARRAY' && $name ne 'ISA') {
            $self->add_package_symbol($variable, []);
        }
        elsif ($type eq 'HASH') {
            $self->add_package_symbol($variable, {});
        }
        else {
            # FIXME
            $self->add_package_symbol($variable)
        }
    }

    my $entry_ref = \$namespace->{$name};

    if (ref($entry_ref) eq 'GLOB') {
        return *{$entry_ref}{$type};
    }
    else {
        if ($type eq 'CODE') {
            no strict 'refs';
            return \&{ $self->name . '::' . $name };
        }
        else {
            return undef;
        }
    }
}

=head2 remove_package_symbol $variable

Removes the package variable described by C<$variable> (which includes the
sigil); other variables with the same name but different sigils will be
untouched.

=cut

sub remove_package_symbol {
    my ($self, $variable) = @_;

    my ($name, $sigil, $type) = ref $variable eq 'HASH'
        ? @{$variable}{qw[name sigil type]}
        : $self->_deconstruct_variable_name($variable);

    # FIXME:
    # no doubt this is grossly inefficient and 
    # could be done much easier and faster in XS

    my ($scalar_desc, $array_desc, $hash_desc, $code_desc, $io_desc) = (
        { sigil => '$', type => 'SCALAR', name => $name },
        { sigil => '@', type => 'ARRAY',  name => $name },
        { sigil => '%', type => 'HASH',   name => $name },
        { sigil => '&', type => 'CODE',   name => $name },
        { sigil => '',  type => 'IO',     name => $name },
    );

    my ($scalar, $array, $hash, $code, $io);
    if ($type eq 'SCALAR') {
        $array  = $self->get_package_symbol($array_desc)  if $self->has_package_symbol($array_desc);
        $hash   = $self->get_package_symbol($hash_desc)   if $self->has_package_symbol($hash_desc);
        $code   = $self->get_package_symbol($code_desc)   if $self->has_package_symbol($code_desc);
        $io     = $self->get_package_symbol($io_desc)     if $self->has_package_symbol($io_desc);
    }
    elsif ($type eq 'ARRAY') {
        $scalar = $self->get_package_symbol($scalar_desc);
        $hash   = $self->get_package_symbol($hash_desc)   if $self->has_package_symbol($hash_desc);
        $code   = $self->get_package_symbol($code_desc)   if $self->has_package_symbol($code_desc);
        $io     = $self->get_package_symbol($io_desc)     if $self->has_package_symbol($io_desc);
    }
    elsif ($type eq 'HASH') {
        $scalar = $self->get_package_symbol($scalar_desc);
        $array  = $self->get_package_symbol($array_desc)  if $self->has_package_symbol($array_desc);
        $code   = $self->get_package_symbol($code_desc)   if $self->has_package_symbol($code_desc);
        $io     = $self->get_package_symbol($io_desc)     if $self->has_package_symbol($io_desc);
    }
    elsif ($type eq 'CODE') {
        $scalar = $self->get_package_symbol($scalar_desc);
        $array  = $self->get_package_symbol($array_desc)  if $self->has_package_symbol($array_desc);
        $hash   = $self->get_package_symbol($hash_desc)   if $self->has_package_symbol($hash_desc);
        $io     = $self->get_package_symbol($io_desc)     if $self->has_package_symbol($io_desc);
    }
    elsif ($type eq 'IO') {
        $scalar = $self->get_package_symbol($scalar_desc);
        $array  = $self->get_package_symbol($array_desc)  if $self->has_package_symbol($array_desc);
        $hash   = $self->get_package_symbol($hash_desc)   if $self->has_package_symbol($hash_desc);
        $code   = $self->get_package_symbol($code_desc)   if $self->has_package_symbol($code_desc);
    }
    else {
        confess "This should never ever ever happen";
    }

    $self->remove_package_glob($name);

    $self->add_package_symbol($scalar_desc => $scalar);
    $self->add_package_symbol($array_desc  => $array)  if defined $array;
    $self->add_package_symbol($hash_desc   => $hash)   if defined $hash;
    $self->add_package_symbol($code_desc   => $code)   if defined $code;
    $self->add_package_symbol($io_desc     => $io)     if defined $io;
}

=head2 list_all_package_symbols $type_filter

Returns a list of package variable names in the package, without sigils. If a
C<type_filter> is passed, it is used to select package variables of a given
type, where valid types are the slots of a typeglob ('SCALAR', 'CODE', 'HASH',
etc).

=cut

sub list_all_package_symbols {
    my ($self, $type_filter) = @_;

    my $namespace = $self->namespace;
    return keys %{$namespace} unless defined $type_filter;

    # NOTE:
    # or we can filter based on 
    # type (SCALAR|ARRAY|HASH|CODE)
    if ($type_filter eq 'CODE') {
        return grep {
            (ref($namespace->{$_})
                ? (ref($namespace->{$_}) eq 'SCALAR')
                : (ref(\$namespace->{$_}) eq 'GLOB'
                   && defined(*{$namespace->{$_}}{CODE})));
        } keys %{$namespace};
    } else {
        return grep { *{$namespace->{$_}}{$type_filter} } keys %{$namespace};
    }
}

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-stash-manip at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Stash-Manip>.

=head1 SEE ALSO

L<Class::MOP::Package> - this module is a factoring out of code that used to
live here

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Stash::Manip

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Stash-Manip>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Stash-Manip>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Stash-Manip>

=item * Search CPAN

L<http://search.cpan.org/dist/Stash-Manip>

=back

=head1 AUTHOR

  Jesse Luehrs <doy at tozt dot net>

Mostly copied from code from L<Class::MOP::Package>, by Stevan Little and the
Moose Cabal.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;