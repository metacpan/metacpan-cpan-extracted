package MooseX::Accessors::ReadWritePrivate::Role::Attribute;

use 5.008;
use utf8;

use strict;
use warnings;


use version; our $VERSION = qv('v1.4.0');


use Moose::Role 2.0;


my $TRUE  = 1;
my $FALSE = 0;


before _process_options => sub {
    my ($class, $name, $options) = @_;

    my $is = $options->{is};
    if (
            $is
        and not ( exists $options->{reader} and exists $options->{writer} )
        and $is =~ m<
            \A
            (?:
                    r (p)? w (p)?
                |   ( [rw] ) o (p)?
            )
            \z
        >xms
    ) {
        my ($read_private, $write_private, $read_or_write_only, $only_private) =
            ($1, $2, $3, $4);

        if (
            $name =~ m<
                \A
                ( _* )
                ( [^_] .* )?
                \z
            >xms
        ) {
            my ($scope, $base) = ($1, $2);

            my $generate_selector = not exists $options->{reader};
            my $generate_mutator = not exists $options->{writer};
            if ($read_or_write_only) {
                if ($read_or_write_only eq 'r') {
                    $read_private = $only_private;
                    $generate_mutator = $FALSE;
                } else {
                    $write_private = $only_private;
                    $generate_selector = $FALSE;
                } # end if
            } # end if

            if ($generate_selector) {
                my $read_scope = $read_private ? '_' : $scope;

                my $type = $options->{isa};
                my $prefix;
                if ( $type and ($type eq 'Bool' or $type eq 'Maybe[Bool]') ) {
                    $prefix = q<>;
                } else {
                    $prefix = 'get_';
                } # end if

                $options->{reader} = "$read_scope$prefix$base";
            } # end if

            if ($generate_mutator) {
                if ($write_private) {
                    $options->{writer} = "_set_$base";
                } else {
                    $options->{writer} = "${scope}set_$base";
                } # end if
            } # end if

            delete $options->{is};
        } # end if
    } # end if

    return;
}; # end before _process_options()


no Moose::Role;

1;

__END__

=pod

=encoding utf8

=for stopwords

=head1 NAME

MooseX::Accessors::ReadWritePrivate::Role::Attribute - Names (non Bool) accessors affordance style.


=head1 SYNOPSIS

None.  This is part of the implementation of L<MooseX::Accessors::ReadWritePrivate>.


=head1 VERSION

This document describes MooseX::Accessors::ReadWritePrivate::Role::Attribute
version 1.4.0.


=head1 DESCRIPTION

This role applies a method modifier to the C<_process_options()>
method, and tweaks the reader and writer parameters so that they
end up with affordance names, unless they are C<Bool>s, in which case the
names are semi-affordance.


=head1 DIAGNOSTICS

None.


=head1 CONFIGURATION AND ENVIRONMENT

None other than what you specify for your attributes.


=head1 DEPENDENCIES

perl 5.8

L<Moose::Role>

L<version>


=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright ©2009-2010, Elliot Shank C<< <perl@galumph.com> >>.

Based upon L<MooseX::FollowPBP>, copyright ©2008 Dave Rolsky.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut


# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
