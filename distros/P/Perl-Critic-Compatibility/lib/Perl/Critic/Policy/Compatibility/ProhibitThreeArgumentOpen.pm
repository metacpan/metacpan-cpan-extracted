#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic-Compatibility/lib/Perl/Critic/Policy/Compatibility/ProhibitThreeArgumentOpen.pm $
#     $Date: 2008-06-07 22:26:28 -0500 (Sat, 07 Jun 2008) $
#   $Author: clonezone $
# $Revision: 2425 $

package Perl::Critic::Policy::Compatibility::ProhibitThreeArgumentOpen;

use 5.006;

use strict;
use warnings;

our $VERSION = '1.001';

use Readonly ();
use version ();

use Perl::Critic::Utils qw< :severities is_function_call parse_arg_list >;

use base 'Perl::Critic::Policy';

Readonly::Scalar my $DESCRIPTION => 'Three-argument form of open used';
Readonly::Scalar my $EXPLANATION => 'Three-argument open is not available until perl 5.6.';

Readonly::Scalar my $MINIMUM_VERSION => version->new(5.006);

sub supported_parameters { return ();                  }
sub default_severity     { return $SEVERITY_HIGHEST;   }
sub default_themes       { return qw( compatibility ); }
sub applies_to           { return 'PPI::Token::Word'   }

sub violates {
    my ( $self, $element, $document ) = @_;

    return if $element->content() ne 'open';
    return if not is_function_call($element);

    my $version = $document->highest_explicit_perl_version();
    return if $version && $version >= $MINIMUM_VERSION;

    my @arguments = parse_arg_list($element);

    if ( scalar @arguments > 2 ) {
        return $self->violation( $DESCRIPTION, $EXPLANATION, $element );
    }

    return;
} # end violates()

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::Compatibility::ProhibitThreeArgumentOpen - Don't allow three-argument open unless the code uses a version of perl that supports it.


=head1 AFFILIATION

This policy is part of L<Perl::Critic::Compatibility>.


=head1 VERSION

This document describes
Perl::Critic::Policy::Compatibility::ProhibitThreeArgumentOpen version
1.001.


=head1 SYNOPSIS

Don't allow three-argument C<open> unless the module declares a
dependency upon perl 5.6 or higher.


=head1 DESCRIPTION

Perls prior to 5.6 don't support the three-argument form of C<open>.
If you want your code to remain compatible with those versions of
perl, you can't use it.

If your code explicitly declares a requirement on a version of perl
greater than or equal to 5.6, then three-argument C<open> is fine.

    open FILE, '<', 'blah';             # not ok

    use 5.006;
    open FILE, '<', 'blah';             # ok

    require 5.8.8;
    open FILE, '<', 'blah';             # ok


=head1 INTERFACE

Standard for a L<Perl::Critic::Policy>.


=head1 DIAGNOSTICS

None.


=head1 CONFIGURATION AND ENVIRONMENT

This policy has no configuration options beyond the standard ones.


=head1 DEPENDENCIES

L<Perl::Critic>


=head1 INCOMPATIBILITIES

This policy directly contradicts
L<Perl::Critic::Policy::InputOutput::ProhibitTwoArgOpen>.  If you don't
declare perl version requirements, then you cannot have both of these
policies enabled at the same time (unless you like getting
violations).


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-perl-critic-compatible@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.


=head1 ACKNOWLEDGMENTS

Adam Kennedy for inspiring this.  Nay, demanding it.


=head1 AUTHOR

Elliot Shank  C<< <perl@galumph.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c)2008, Elliot Shank C<< <perl@galumph.com> >>. All rights
reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.


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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.


=cut

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
