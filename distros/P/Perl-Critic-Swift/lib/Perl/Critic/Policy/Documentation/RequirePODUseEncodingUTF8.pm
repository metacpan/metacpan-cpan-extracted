package Perl::Critic::Policy::Documentation::RequirePODUseEncodingUTF8;

use utf8;
use 5.006;
use strict;
use warnings;

use version; our $VERSION = qv('v1.0.3');

use List::MoreUtils qw{ any };

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

my $ENCODING_REGEX = qr/ ^ =encoding \s+ utf8 /xms;
my $DESCRIPTION    = 'POD does not include "=encoding utf8" declaration';
## no critic (ValuesAndExpressions::RestrictLongStrings)
my $EXPLANATION    =
    'Need to ensure that POD processors understand that the documentation may contain Unicode';
## use critic

sub supported_parameters { return ();                  }
sub default_severity     { return $SEVERITY_MEDIUM;    }
sub default_themes       { return qw( swift unicode ); }
sub applies_to           { return 'PPI::Document';     }

sub violates {
    my ( $self, undef, $document ) = @_;

    my $pod_sections_ref = $document->find('PPI::Token::Pod');
    return if not $pod_sections_ref;

    return if any { m/$ENCODING_REGEX/xms } @{ $pod_sections_ref };

    return $self->violation( $DESCRIPTION, $EXPLANATION, $document );
} # end violates()

1;

__END__

=pod

=encoding utf8

=head1 NAME

Perl::Critic::Policy::Documentation::RequirePODUseEncodingUTF8 - Require that all modules that contain POD have a C<=encoding utf8> declaration.

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Swift>.


=head1 VERSION

This document describes
Perl::Critic::Policy::Documentation::RequirePODUseEncodingUTF8 version 1.0.3.


=head1 SYNOPSIS

Require that all modules that contain POD have a C<=encoding utf8>
declaration.


=head1 DESCRIPTION

POD parsers need to be told if they are going to be dealing with anything that
isn't ASCII.  This policy ensures that they are notified that the
documentation may contain Unicode characters.

English speakers need to be brought into the 21st century and note that not
every character fits into 7 bits.


=head1 INTERFACE

Standard for a L<Perl::Critic::Policy>.


=head1 DIAGNOSTICS

None.


=head1 CONFIGURATION AND ENVIRONMENT

This policy has no configuration options beyond the standard ones.


=head1 DEPENDENCIES

L<Perl::Critic>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-perl-critic-swift@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Elliot Shank  C<< <perl@galumph.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright ©2007-2008, Elliot Shank C<< <perl@galumph.com> >>. All rights
reserved.

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
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
