#
# This file is part of MooseX-Attribute-Chained
#
# This software is copyright (c) 2017 by Tom Hukins.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package MooseX::Attribute::ChainedClone;
$MooseX::Attribute::ChainedClone::VERSION = '1.0.3';
# ABSTRACT: Attribute that returns a cloned instance
use Moose::Util;
Moose::Util::meta_attribute_alias(
    ChainedClone => 'MooseX::Traits::Attribute::ChainedClone' );

package MooseX::Traits::Attribute::ChainedClone;
$MooseX::Traits::Attribute::ChainedClone::VERSION = '1.0.3';
use Moose::Role;

override accessor_metaclass => sub {
    'MooseX::Attribute::ChainedClone::Method::Accessor';
};

package MooseX::Attribute::ChainedClone::Method::Accessor;
$MooseX::Attribute::ChainedClone::Method::Accessor::VERSION = '1.0.3';
use Carp qw(confess);
use Try::Tiny;
use base 'Moose::Meta::Method::Accessor';

sub _generate_accessor_method_inline {
    my $self = shift;
    my $attr = $self->associated_attribute;
    my $clone
        = $attr->associated_class->has_method("clone")
        ? '$_[0]->clone'
        : 'bless { %{$_[0]} }, ref $_[0]';

    if ( $Moose::VERSION >= 1.9900 ) {
        return try {
            $self->_compile_code(
                [   'sub {',
                    'if (@_ > 1) {',
                    'my $clone = ' . $clone . ';',
                    $attr->_inline_set_value( '$clone', '$_[1]' ),
                    'return $clone;',
                    '}',
                    $attr->_inline_get_value('$_[0]'),
                    '}',
                ]
            );
        }
        catch {
            confess "Could not generate inline accessor because : $_";
        };
    }
    else {
        my ( $code, $e ) = $self->_eval_closure(
            {},
            join( "\n",
                'sub {',
                'if (@_ > 1) {',
                'my $clone = ' . $clone . ';',
                $attr->inline_set( '$clone', '$_[1]' ),
                'return $clone;',
                '}',
                $attr->inline_get('$_[0]'),
                '}' ),
        );
        confess "Could not generate inline predicate because : $e" if $e;
        return $code;
    }
}

sub _generate_writer_method_inline {
    my $self = shift;
    my $attr = $self->associated_attribute;
    my $clone
        = $attr->associated_class->has_method("clone")
        ? '$_[0]->clone'
        : 'bless { %{$_[0]} }, ref $_[0]';
    if ( $Moose::VERSION >= 1.9900 ) {
        return try {
            $self->_compile_code(
                [   'sub {',
                    'my $clone = ' . $clone . ';',
                    $attr->_inline_set_value( '$clone', '$_[1]' ),
                    'return $clone;', '}',
                ]
            );
        }
        catch {
            confess "Could not generate inline writer because : $_";
        };
    }
    else {
        my ( $code, $e ) = $self->_eval_closure(
            {},
            join( "\n",
                'sub {',
                'my $clone = ' . $clone . ';',
                $attr->inline_set( '$clone', '$_[1]' ),
                'return $clone;', '}' ),
        );
        confess "Could not generate inline writer because : $e" if $e;
        return $code;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Attribute::ChainedClone - Attribute that returns a cloned instance

=head1 VERSION

version 1.0.3

=head1 SYNOPSIS

  package Test;
  use Moose;

  has debug => (
      traits => [ 'ChainedClone' ],
      is => 'rw',
      isa => 'Bool',
      default => 0,
  );

  sub complex_method
  {
      my $self = shift;
    
      #...
    
      print "helper message" if $self->debug;
    
      #...
  }
  
  sub clone {
      my $self = shift;
      # custom clone code here
      # defaults to:
      return bless { %$self }, ref $self;
  }


  1;

Which allows for:

    my $test = Test->new;
    $test->debug(1)->complex_method; # debug enabled
                                     # complex_method is called on a cloned instance
                                     # with debug set to 1

    $test->complex_method;           # debug is still disabled on $test

    $test->debug(1); # returns a cloned $test instance with debug set to 1
    $test->debug;    # returns 0

=head1 DESCRIPTION

MooseX::Attribute::ChainedClone is a Moose Trait which allows for method chaining 
on accessors by returning a cloned instance of C<$self> on write/set operations.

If C<$self> has a C<clone> method, this method is invoked to clone the instance.
This allows for easy integration with L<MooseX::Clone> or any custom made
clone method. If no C<clone> method is available, the new instance is build
using C<< bless { %$self }, ref $self >>.

=head1 AUTHORS

=over 4

=item *

Tom Hukins <tom@eborcom.com>

=item *

Moritz Onken <onken@netcubed.de>

=item *

David McLaughlin <david@dmclaughlin.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Tom Hukins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<http://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Attribute-Chained>
or by email to L<bug-moosex-attribute-chained at
rt.cpan.org|mailto:bug-moosex-attribute-chained at rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
