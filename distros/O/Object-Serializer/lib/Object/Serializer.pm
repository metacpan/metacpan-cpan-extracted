# ABSTRACT: General Purpose Object Serializer
package Object::Serializer;

use utf8;
use 5.010;
use strict;
use warnings;
use Data::Dumper ();
use Scalar::Util qw(blessed refaddr);
our %TYPES;

our $VERSION = '0.000011'; # VERSION


sub new {
    bless {}, shift
}

sub _serialization {
    my ($self, $options, $reference, $class) = @_;
    my @registries = (ref($self) || $self, __PACKAGE__);

    for my $registry (@registries) {
        my $type = $TYPES{$registry};
        next unless 'HASH' eq ref $type;
        my $coercion = $type->{$class};
        return $coercion->(bless $reference, $class)
            if 'CODE' eq ref $coercion;
    }

    # tag blessed hash references
    $reference->{$options->{marker}} = $class
        if defined $options->{marker} && 'HASH' eq ref $reference;

    return $reference;
}


sub serialize {
    my ($self, $object, %options) = @_;

    local $Data::Dumper::Terse      = 1;
    local $Data::Dumper::Indent     = 0;
    local $Data::Dumper::Useqq      = 1;
    local $Data::Dumper::Deparse    = 1;
    local $Data::Dumper::Quotekeys  = 0;
    local $Data::Dumper::Sortkeys   = 1;
    local $Data::Dumper::Deepcopy   = 1;
    local $Data::Dumper::Purity     = 0;

    my $options   = {marker => '__CLASS__', %options};
    my $execution = join '::', __PACKAGE__, 'Runtime', refaddr $self;

    no strict 'refs';
    no warnings 'redefine';

    *{$execution} = sub {
        my @arguments = @_;
        Object::Serializer::_serialization($self, $options, @arguments);
    };

    (my $target = Data::Dumper::Dumper($object // $self)) =~
        s/bless(?=(?:(?:(?:[^"\\]++|\\.)*+"){2})*+(?:[^"\\]++|\\.)*+$)/$execution/g;

    my $hash = do { no strict; eval "my \$VAR1 = $target\n" } or die $@;

    undef *{$execution};
    return $hash;
}


sub serialization_strategy_for {
    my ($self, $reftype, $routine) = @_;

    die "Couldn't register reftype serialization " .
        "strategy due to invalid arguments"
            unless $self && $reftype && 'CODE' eq ref $routine;

    return $TYPES{ref($self) || $self}{$reftype} = $routine;
}


1;

__END__

=pod

=head1 NAME

Object::Serializer - General Purpose Object Serializer

=head1 VERSION

version 0.000011

=head1 SYNOPSIS

    package Point;

    use Moo;
    use parent 'Object::Serializer';

    has 'x' => (is => 'rw');
    has 'y' => (is => 'rw');

    package main;

    my $point = Point->new(x => 10, y => 10);

    # serialize the class instance into a hash
    my $hash = $point->serialize; # { __CLASS__ => 'Point', x => 10, y => 10 }

=head1 DESCRIPTION

Getting objects into an ideal format for passing representations in and
out of applications can be a real pain. Object::Serializer is a fast and simple
pure-perl framework-agnostic type-less none-opinionated light-weight primitive
general purpose object serializer which tries to help make object serialization
easier. This module is useful in situations when you have blessed objects you
wish to produce hash representations from which you can store directly or
convert to JSON, YAML, or XML. This module does not currently support
deserialization.

=head1 METHODS

=head2 serialize

The serialize method expects an object and returns a serialized (hashified)
version of that object.

    my $hash = $self->serialize;
    my $hash = $self->serialize($object);
    my $hash = $self->serialize($object, marker => undef); # no marker

=head2 serialization_strategy_for

The serialization_strategy_for method expects a reftype and a sub-routine. This
method registers a custom serialization strategy which will be used during the
collapsing of the reference type specified.

    CLASS->serialization_strategy_for(
        REFTYPE => sub { ... }
    );

=head1 EXTENSION

Object::Serializer can be used as a serializer independently, however, it is
primarily designed to be used as a base class for your classes or roles. By
default, Object::Serializer doesn't do anything special for you in the way of
serialization, in-fact, it is little more than a wrapper around L<Data::Dumper>.
Additionally, you can hook into the serialization process by defining your
serialization strategy using your own custom serialization routines which will
be executed whenever a specific reference type is encountered. The following
syntax is what you might use to register your own custom serialization strategy.
This example registers a custom serializer that is executed globally whenever a
DateTime object is found.

    Object::Serializer->serialization_strategy_for(
        DateTime => sub { pop->iso8601 }
    );

Additionally, you can register a serialization strategy to be used only when
invoked by a specific class. The following syntax is what you might use to
register a serialization strategy to be executed only for a specific class:

    Point->serialization_strategy_for(
        DateTime => sub { pop->iso8601 }
    );

=head1 CAVEATS

Circular references are problematic and should be avoided, you can weaken or
otherwise handle them yourself then re-assemble them later as a means toward
getting around this.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
