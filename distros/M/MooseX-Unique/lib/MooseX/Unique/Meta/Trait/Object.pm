#
# This file is part of MooseX-Unique
#
# This software is copyright (c) 2011 by Edward J. Allen III.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package MooseX::Unique::Meta::Trait::Object;
BEGIN {
  $MooseX::Unique::Meta::Trait::Object::VERSION = '0.005';
}
BEGIN {
  $MooseX::Unique::Meta::Trait::Object::AUTHORITY = 'cpan:EALLENIII';
}
#ABSTRACT:  MooseX::Unique base class role
use 5.10.0;
use Moose::Role;
use strict; use warnings;

sub new_or_matching {
    my ($class,@opts) = @_;
    my $instance = $class->find_matching(@opts);
    return $instance ? $instance : $class->new(@opts);
};

sub find_matching {
    my ($class,@opts) = @_;
    if ( $class->meta->_has_match_attributes ) {
        my $params =   ( ref $opts[0] )      ?  $opts[0]  
                     : ( !scalar @opts % 2 ) ?  {@opts}   
                     :  undef;
        if ($params) {
            for my $instance ( $class->meta->instances ) {
                my ($match,$potential) = (0,0);
                MATCH_ATTR:
                for my $match_attr ( $class->meta->match_attributes ) {
                    if ( ref $match_attr ) {
                        $match_attr = $match_attr->name;
                    }
                    my $attr = $class->meta->find_attribute_by_name($match_attr);
                    if (  $attr->has_value($instance) )  {
                        if ( $attr->get_value($instance) ~~ $params->{$match_attr} )  {
                            $match++;
                        }
                        $potential++;    
                    }
                }
                my $required = $class->meta->match_requires;
                if (($required) && ($match >= $required)) {
                    return $instance; 
                }
                elsif ((! $required) && ($match == $potential)) {
                    return $instance; 
                }
            }
        }
    }
    return;
}


1;


=pod

=for :stopwords Edward Allen J. III BUILDARGS params readonly MetaRole metaclass

=encoding utf-8

=head1 NAME

MooseX::Unique::Meta::Trait::Object - MooseX::Unique base class role

=head1 VERSION

  This document describes v0.005 of MooseX::Unique::Meta::Trait::Object - released June 22, 2011 as part of MooseX-Unique.

=head1 SYNOPSIS

See L<MooseX::Unique|MooseX::Unique>;

=head1 DESCRIPTION

This adds the methods new_or_matching and find_matching to your base
class.  For use with MooseX::Unique;

=head1 METHODS

=head2 $class->new_or_matching

Wrapper around your new method that looks up the attribute for you.  Please
note that this module does not process your BUILDARGS before looking for an
instance.  So, values must be passed as a hash or hash reference. Any
attribute that is not flagged as unique will be ignored in the case of an
existing instance.

=head2 $class->find_matching(%PARAMS)

Given a set of params, finds a matching instance if available.

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

