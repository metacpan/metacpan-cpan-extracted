use strict;
use warnings;
use utf8;

package Pod::Weaver::PluginBundle::Author::RTHOMPSON;
# ABSTRACT: A bundle that implements RTHOMPSON's preferred L<Pod::Weaver> config
$Pod::Weaver::PluginBundle::Author::RTHOMPSON::VERSION = '0.151680';
use namespace::autoclean;

use Pod::Weaver::Config::Assembler;
sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }


sub mvp_bundle_config {
  return (
    [ '@Author::RTHOMPSON/CorePrep',     _exp('@CorePrep'),    {} ],
    [ '@Author::RTHOMPSON/Name',         _exp('Name'),         {} ],
    [ '@Author::RTHOMPSON/Version',      _exp('Version'),      {} ],

    [ '@Author::RTHOMPSON/prelude',      _exp('Region'),       { region_name => 'prelude'  } ],
    [ 'SYNOPSIS',                _exp('Generic'),      {} ],
    [ 'OVERVIEW',                _exp('Generic'),      {} ],
    [ 'DESCRIPTION',             _exp('Generic'),      {} ],

    [ 'ATTRIBUTES',              _exp('Collect'),      { command => 'attr'     } ],
    [ 'OPTIONS',                 _exp('Collect'),      { command => 'option'   } ],
    [ 'METHODS',                 _exp('Collect'),      { command => 'method'   } ],
    [ 'FUNCTIONS',               _exp('Collect'),      { command => 'function' } ],

    [ '@Author::RTHOMPSON/Leftovers',    _exp('Leftovers'),    {} ],

    [ '@Author::RTHOMPSON/postlude',     _exp('Region'),       { region_name => 'postlude' } ],

    [ '@Author::RTHOMPSON/Installation', _exp('Installation'), {} ],
    [ '@Author::RTHOMPSON/Authors',      _exp('Authors'),      {} ],
    [ '@Author::RTHOMPSON/Legal',        _exp('Legal'),        {} ],
    [ '@Author::RTHOMPSON/WarrantyDisclaimer', _exp('WarrantyDisclaimer'), {} ],

    [ '@Author::RTHOMPSON/-Transformer', _exp('-Transformer'), { transformer => 'List' } ],
    [ '@Author::RTHOMPSON/-EnsureUniqueSections', _exp('-EnsureUniqueSections'), {} ],
 );
}

1; # Magic true value required at end of module

__END__

=pod

=head1 NAME

Pod::Weaver::PluginBundle::Author::RTHOMPSON - A bundle that implements RTHOMPSON's preferred L<Pod::Weaver> config

=head1 VERSION

version 0.151680

=head1 SYNOPSIS

In F<weaver.ini>:

    [@Author::RTHOMPSON]

=head1 OVERVIEW

This is the bundle used by RTHOMPSON when using L<Pod::Weaver> to
generate documentation for Perl modules.

It is nearly equivalent to the following:

    [@CorePrep]

    [Name]
    [Version]

    [Region / prelude]

    [Generic / SYNOPSIS]
    [Generic / OVERVIEW]
    [Generic / DESCRIPTION]

    [Collect / ATTRIBUTES]
    command = attr

    [Collect / OPTIONS]
    command = option

    [Collect / METHODS]
    command = method

    [Collect / FUNCTIONS]
    command = function

    [Leftovers]

    [Region / postlude]

    [Installation]

    [Authors]
    [Legal]
    [WarrantyDisclaimer]

    [-Transformer]
    transformer = List

    [-EnsureUniqueSections]

=for Pod::Coverage mvp_bundle_config

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<rct+perlbug@thompsonclan.org>.

=head1 SEE ALSO

=over 4

=item *

L<Pod::Weaver>

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHOR

Ryan C. Thompson <rct@thompsonclan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ryan C. Thompson.

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
