package MooseX::Exception::Base;

# Created on: 2012-07-11 10:25:25
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use version;
use Carp qw/longmess/;
use MooseX::Exception::Base::Stringify;

use overload '""' => 'verbose';

our $VERSION     = version->new('0.0.6');

has error => (
    is             => 'rw',
    isa            => 'Str',
    traits         => [qw{MooseX::Exception::Stringify}],
);
has _stack => (
    is  => 'rw',
    isa => 'Str',
);
has _verbose => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

sub throw {
    my $class = shift;
    my %args  = @_ == 1 ? %{$_[0]} : @_;

    $args{_stack} = longmess('');

    die $class->new(%args);
}

sub _stringify_attributes {
    my ($self) = @_;
    my $meta = $self->meta;

    my @parent_nodes;
    my @supers = $meta->superclasses;
    for my $super (@supers) {
        if ( $super->can('_stringify_attributes') ) {
            push @parent_nodes, $super->_stringify_attributes;
        }
    }

    return @parent_nodes, map {
            $meta->get_attribute($_)
        }
        sort {
            $meta->get_attribute($a)->insertion_order <=> $meta->get_attribute($b)->insertion_order
        }
        grep {
            $meta->get_attribute($_)->does('MooseX::Exception::Stringify')
        }
        $meta->get_attribute_list;
};

sub verbose {
    my ($self, $verbose) = @_;
    my @errors;
    my @attributes = $self->_stringify_attributes;

    for my $attribute (@attributes) {
        my $name = $attribute->name;
        next if !defined $self->$name;

        local $_ = $self->$name;
        push @errors,
            ( $attribute->has_stringify_pre ? $attribute->stringify_pre : '' )
            . ( $attribute->has_stringify ? $attribute->stringify->($_) : $_ )
            . ( $attribute->has_stringify_post ? $attribute->stringify_post : '' );
    }
    my $error = join "\n", @errors;

    $verbose = defined $verbose ? $verbose : $self->_verbose;
    my $stack
        = $verbose == 0     ? ''
        : $verbose == 1     ? (split /\n/, $self->_stack)[0]
        :                     $self->_stack;

    return $error . $stack;
}

1;

__END__

=head1 NAME

MooseX::Exception::Base - Base class for exceptions

=head1 VERSION

This documentation refers to MooseX::Exception::Base version 0.0.6.

=head1 SYNOPSIS

   package MyException;
   use Moose;
   extends 'MooseX::Exception::Base';

   has code => ( is => 'rw', isa => 'Num' );

   package MyOtherException;
   use Moose;
   extends 'MooseX::Exception::Base';

   has message => (
       is             => 'rw',
       isa            => 'Str',
       traits         => [qw{MooseX::Exception::Stringify}],
       stringify_pre  => 'prefix string ',
       stringify_post => ' postfix string',
       # a subroutine that returns a stringified value eg custom DateTime formatting
       stringify      => sub {return $_},
   );

   # ... else where

   use MyException;

   sub mysub {
       MyException->throw( error => 'My error', code => 666 );
   }

   eval { mysub() };
   if ($@) {
       warn "ERROR : $e\n";
       # or
       warn $e->verbose;
   }

   sub myother {
       MyOtherException->throw(
           message => "Custom error message",
       );
   }

   eval { myother() };
   if ($@) {
       warn "ERROR : $e\n";
       # or
       warn $e->verbose;
   }

=head1 DESCRIPTION

This module provides basic helpers to make Moose exception objects, is is
somewhat similar to L<Exception::Class> in usage.

=head1 SUBROUTINES/METHODS

=over 4

=item C<throw (%args)>

Throw an exception with object with the parameters from C<%args>

=item C<verbose ([$verbosity])>

Stringifys the exception object, if C<$verbosidy> is not passed the classes
attribute _verbose is used.

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 ALSO SEE

L<Throwable> probably should be use rather than this module for new projects
as it's now best practice.

L<Moose>, L<Exception::Class>

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 CONTRIBUTORS

Adam Herzog - adam@adamherzog.com

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 Ivan Wills (14 Mullion Close Hornsby Heights NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
