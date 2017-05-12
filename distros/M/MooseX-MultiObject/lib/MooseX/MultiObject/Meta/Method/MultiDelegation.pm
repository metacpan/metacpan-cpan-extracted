package MooseX::MultiObject::Meta::Method::MultiDelegation;
BEGIN {
  $MooseX::MultiObject::Meta::Method::MultiDelegation::VERSION = '0.03';
}
# ABSTRACT: method that delegates to a set of objects
use strict;
use warnings;
use true;
use namespace::autoclean;
use Carp qw(confess);

use parent 'Moose::Meta::Method', 'Class::MOP::Method::Generated';

# i hate class mop

sub new {
    my $class   = shift;
    my %options = @_;

    confess 'You must supply an object_getter method name'
        unless exists $options{object_getter};

    confess 'You must supply a delegate_to method or coderef'
        unless exists $options{delegate_to};

    exists $options{curried_arguments}
        || ( $options{curried_arguments} = [] );

    ( $options{curried_arguments} &&
        ( 'ARRAY' eq ref $options{curried_arguments} ) )
        || confess 'You must supply a curried_arguments which is an ARRAY reference';

    my $self = $class->_new( \%options );

    $self->_initialize_body;

    return $self;
}

sub _new {
    my $class = shift;
    my $options = @_ == 1 ? $_[0] : {@_};

    return bless $options, $class;
}

sub object_getter { $_[0]->{object_getter} }
sub curried_arguments { $_[0]->{curried_arguments} }
sub delegate_to { $_[0]->{delegate_to} }

sub _initialize_body {
    my $meta = shift;

    my $object_getter = $meta->object_getter;
    my @extra_args    = @{$meta->curried_arguments};
    my $delegate_to   = $meta->delegate_to;

    $meta->{body} = sub {
        my $self = shift;
        unshift @_, @extra_args;
        my @objects = $self->$object_getter;
        return map { scalar $_->$delegate_to(@_) } @objects;
    };
}



=pod

=head1 NAME

MooseX::MultiObject::Meta::Method::MultiDelegation - method that delegates to a set of objects

=head1 VERSION

version 0.03

=head1 SYNOPSIS

Given a class that C<has> a set of objects:

    my $meta = Moose::Meta::Class->create( ... );
    $meta->add_attribute ( objects => (
        is => 'ro', isa => 'Set', handles => ['members'],
    );

Make a method foo to call foo on every element of the set:

    my $foo_metamethod = MooseX::MultiObject::Meta::Method::MultiDelegation->new(
        object_getter => 'members',
        delegate_to   => 'foo',
    );

    $meta->add_method( foo => $foo_metamethod );

Then you can write:

    my $class = $meta->name->new( objects => [ $a, $b ] );
    my @results = $class->foo;

Which is equivalent to:

    my $set = set($a, $b);
    my @results = map { $_->foo } $set->members;

=head1 DESCRIPTION

This is a C<Moose::Meta::Method> and C<Class::MOP::Method::Generated>
that works like C<Moose::Meta::Method::Delegation>, except it
delegates to a collection of objects instead of just one.

=head1 INITARGS

=head2 curried_arguments

=head2 delegate_to

=head2 object_getter

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

