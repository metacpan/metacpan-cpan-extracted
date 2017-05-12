#
# This file is part of MooseX-EasyAcc
#
# This software is Copyright (c) 2011 by Edward J. Allen III.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
use strict; use warnings;
package MooseX::EasyAcc::Role::Attribute;
BEGIN {
  $MooseX::EasyAcc::Role::Attribute::VERSION = '0.001';
}
BEGIN {
  $MooseX::EasyAcc::Role::Attribute::AUTHORITY = 'cpan:EALLENIII';
}
#ABSTRACT: Attribute trait for L<MooseX::EasyAcc>
use Moose::Role;
before _process_options => sub {
    my ($class, $name,$options) = @_;


    # This is based on MooseX::FollowPBP::Role::Attribute .. loosely.
    if ( ( exists $options->{is} ) && ( $options->{is} ne 'bare' ) ) {
        # Everything gets a predicate
        if ( ! exists $options->{predicate} ) {
            my $has = ( $name =~ m{^_} ) ?  '_has_'
                                         :  'has_';
            $options->{predicate} = $has . $name;
        }
        # Everything gets a reader (SemiAffordable style... 
        #   objects have things, you don't get things!)
        if (( ! exists $options->{reader}  ) || (! $options->{reader})) {
            $options->{reader} = $name;
        }
        # And finally, everything, even ro, gets a writer.
        # TODO : create a writer that checks who you are, making it truly private.
        if ( ! exists $options->{writer} ) {
            my $set = (( $name =~ m{^_} ) || ($options->{is} eq 'ro')) ?  '_set_'
                                                                       :  'set_';
            $options->{writer} = $set . $name;
        }
        delete $options->{is};
    }
};

1;


__END__
=pod

=for :stopwords Edward Allen J. III

=encoding utf-8

=head1 NAME

MooseX::EasyAcc::Role::Attribute - Attribute trait for L<MooseX::EasyAcc>

=head1 VERSION

  This document describes v0.001 of MooseX::EasyAcc::Role::Attribute - released June 13, 2011 as part of MooseX-EasyAcc.

=head1 SYNOPSIS

See L<MooseX::EasyAcc>, or if you like more work for yourself:

    package MyApp;
    use Moose;
    use MooseX::EasyAcc::Role::Attribute;

    has 'everything' => (
        is => 'rw',
        isa => 'Str',
        traits => ['MooseX::EasyAcc::Role::Attribute'],
    );
    # Creates methods everything, set_everything, and has_everything

=head1 DESCRIPTION

This is the trait that is applied to attributes.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooseX::EasyAcc|MooseX::EasyAcc>

=back

=head1 AUTHOR

Edward Allen <ealleniii@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Edward J. Allen III.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

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

