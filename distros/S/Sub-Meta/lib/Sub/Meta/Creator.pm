package Sub::Meta::Creator;
use strict;
use warnings;

our $VERSION = "0.13";

use List::Util ();
use Sub::Meta;

sub _croak { require Carp; goto &Carp::croak }

sub new {
    my ($class, @args) = @_;
    my %args = @args == 1 ? %{$args[0]} : @args;

    unless (exists $args{finders}) {
        _croak 'required finders';
    }

    unless (ref $args{finders} && ref $args{finders} eq 'ARRAY') {
        _croak 'finders must be an arrayref'
    }

    unless (List::Util::all { ref $_ && ref $_ eq 'CODE' } @{$args{finders}}) {
        _croak 'elements of finders have to be a code reference'
    }

    return bless \%args => $class;
}

sub sub_meta_class { return 'Sub::Meta' }

sub finders { my $self = shift; return $self->{finders} }

sub find_materials {
    my ($self, $sub) = @_;
    for my $finder (@{$self->finders}) {
        my $materials = $finder->($sub);
        return $materials if defined $materials;
    }
    return;
}

sub create {
    my ($self, $sub) = @_;
    if (my $materials = $self->find_materials($sub)) {
        return $self->sub_meta_class->new($materials)
    }
    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sub::Meta::Creator - creator of Sub::Meta by code reference

=head1 SYNOPSIS

    use Sub::Meta::Creator;

    sub finder {
        my $sub = shift;
        return +{ sub => $sub }
    }

    my $creator = Sub::Meta::Creator->new(
        finders => [ \&finder ],
    );

    sub foo { }
    my $meta = $creator->create(\&foo);

=head1 DESCRIPTION

This module provides convenient ways to create Sub::Meta.
The purpose of this module is to make it easier to associate Sub::Meta with information of code references.
For example, Function::Parameters can retrieve not only subroutine names and packages from code references,
but also argument type information, etc. Sub::Meta::Creator can be generated Sub::Meta with such information:

    use Sub::Meta::Creator;
    use Sub::Meta::Finder::FunctionParameters;

    my $creator = Sub::Meta::Creator->new(
        finders => [ \&Sub::Meta::Finder::FunctionParameters::find_materials ]
    );

    use Function::Parameters;
    use Types::Standard -types;

    fun hello(Str $msg) { }
    my $meta = $creator->create(\&hello);
    my $args = $meta->args; # [ Sub::Meta::Param->new(name => '$msg', type => Str) ]

=head1 METHODS

=head2 new

Constructor of C<Sub::Meta::Creator>. This constructor requires finders:
    
    my $creator = Sub::Meta::Creator->new(
        finders => [ sub { my $sub = shift; +{ sub => $sub } } ]
    );

=head2 finders

Return elements of finder.
The type of finders is C<ArrayRef[CodeRef]>.
C<CodeRef>, an element of finders, finds information from the code reference of the first argument,
processes the information to become the argument of C<Sub::Meta#new>, and returns it.

=head2 find_materials($sub)

From the code reference, find the material for C<Sub::Meta#new>.

=head2 create($sub)

From the code reference, create the instance of C<Sub::Meta>.

=head2 sub_meta_class

Returns class name of Sub::Meta. default: Sub::Meta
Please override for customization.

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut
