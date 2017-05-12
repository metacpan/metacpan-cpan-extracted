#
# This file is part of MooseX-Unique
#
# This software is copyright (c) 2011 by Edward J. Allen III.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package MooseX::Unique::Meta::Trait::Class;
BEGIN {
  $MooseX::Unique::Meta::Trait::Class::VERSION = '0.005';
}
BEGIN {
  $MooseX::Unique::Meta::Trait::Class::AUTHORITY = 'cpan:EALLENIII';
}
#ABSTRACT:  MooseX::Unique Class MetaRole
use Moose::Role;
use List::MoreUtils qw(uniq);

has _match_attribute => (
    traits  => ['Array'],
    isa     => 'ArrayRef',
    is      => 'rw',
    lazy    => 1,
    default => sub {[]},
    handles => {
        add_match_attribute   => 'push',
        _match_attributes     => 'elements',
    },
);

sub _has_match_attributes {
    my $self = shift;
    return ($self->match_attributes) ? 1 : 0;
}

sub _is_attr_unique {
    my ($self, $attr) = @_;
    my $attr_obj = $self->get_attribute($attr);
    return (($attr_obj->can('unique')) && ($attr_obj->unique));
}

sub match_attributes {
    my $self = shift;

    return uniq $self->_match_attributes, 
                map { 
                    $self->_is_attr_unique($_) ? ($_) : () 
                } $self->get_attribute_list;
}


has match_requires => (
    isa => 'Int',
    lazy => 1,
    default => sub{1},
    reader    => 'match_requires',
    writer    => '_set_match_requires',
    predicate => '_has_match_requires',
);

sub add_match_requires {
    my ($self,$val) = @_;

    my $newval = 

       ($val == 0)                         ? 0

     : (    ($self->_has_match_requires) 
         && ($self->match_requires > 0))   ? $self->match_requires + $val

     : (    ($self->_has_match_requires) 
         && ($self->match_requires == 0))  ? 0

     :                                       $val;

    $self->_set_match_requires($newval);
}

1;


=pod

=for :stopwords Edward Allen J. III BUILDARGS params readonly MetaRole metaclass

=encoding utf-8

=head1 NAME

MooseX::Unique::Meta::Trait::Class - MooseX::Unique Class MetaRole

=head1 VERSION

  This document describes v0.005 of MooseX::Unique::Meta::Trait::Class - released June 22, 2011 as part of MooseX-Unique.

=head1 SYNOPSIS

See L<MooseX::Unique|MooseX::Unique>;

=head1 DESCRIPTION

Provides the attribute match_attribute to your metaclass.

=head1 METHODS

=head2 match_attributes

Returns a list of match attributes

=head2 add_match_attribute

Add a match attribute

=head2 match_requires

The minimum number of attributes that must match to consider two objects to be
identical.  The default is 1.  

=head2 add_match_requires

Sets the minimum number of matches required to make a match.
Setting this to 0 means that a match requires that all
attributes set to unique are matched. If you run this more than once, for
example in a role, it will add to the existing unless the existing is 0.  If
you set it to 0, it will reset it to 0 regardless of current value. 

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooseX::Unique|MooseX::Unique>

=back

=head1 AUTHOR

Edward Allen <ealleniii@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Edward J. Allen III.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut


__END__

