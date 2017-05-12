use 5.008;
use strict;
use warnings;

package Pod::Weaver::PluginBundle::MARCEL;
BEGIN {
  $Pod::Weaver::PluginBundle::MARCEL::VERSION = '1.102460';
}

# ABSTRACT: Build POD documentation like MARCEL
use namespace::autoclean;
use Pod::Weaver::Config::Assembler;

# plugins used
use Pod::Weaver::Section::Availability;
use Pod::Weaver::Section::BugsAndLimitations;
use Pod::Weaver::Section::Installation;

sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

sub mvp_bundle_config {
    return (
        [ '@Default/CorePrep', _exp('@CorePrep'), {} ],
        [ '@Default/prelude', _exp('Region'),  { region_name => 'prelude' } ],
        [ '@Default/Name',    _exp('Name'),    {} ],
        [ '@Default/Version', _exp('Version'), {} ],
        [ 'SYNOPSIS',         _exp('Generic'), {} ],
        [ 'DESCRIPTION',      _exp('Generic'), {} ],
        [ 'OVERVIEW',         _exp('Generic'), {} ],
        [ 'ATTRIBUTES',       _exp('Collect'), { command     => 'attr' } ],
        [ 'METHODS',          _exp('Collect'), { command => 'method' } ],
        [ 'FUNCTIONS',        _exp('Collect'), { command => 'function' } ],
        [ '@Default/Leftovers', _exp('Leftovers'), {} ],
        [ '@Default/postlude', _exp('Region'), { region_name => 'postlude' } ],
        [ '@Default/Installation',       _exp('Installation'),       {} ],
        [ '@Default/BugsAndLimitations', _exp('BugsAndLimitations'), {} ],
        [ '@Default/Availability',       _exp('Availability'),       {} ],
        [ '@Default/Authors',            _exp('Authors'),            {} ],
        [ '@Default/Legal',              _exp('Legal'),              {} ],
    );
}
1;


__END__
=pod

=for stopwords MARCEL

=for test_synopsis 1;
__END__

=head1 NAME

Pod::Weaver::PluginBundle::MARCEL - Build POD documentation like MARCEL

=head1 VERSION

version 1.102460

=head1 SYNOPSIS

In C<weaver.ini>:

    [@MARCEL]

=head1 DESCRIPTION

This is the bundle used by default for my distributions. It is nearly
equivalent to the following:

    [@CorePrep]

    [Name]
    [Version]

    [Region  / prelude]

    [Generic / SYNOPSIS]
    [Generic / DESCRIPTION]
    [Generic / OVERVIEW]

    [Collect / ATTRIBUTES]
    command = attr

    [CollectWithAutoDoc / METHODS]
    command = method

    [Collect / FUNCTIONS]
    command = function

    [Leftovers]

    [Region  / postlude]

    [Installation]
    [BugsAndLimitations]
    [Availability]
    [Authors]
    [Legal]

=head1 FUNCTIONS

=head2 mvp_bundle_config

Defines the bundle's contents.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Pod-Weaver-PluginBundle-MARCEL/>.

The development version lives at L<http://github.com/hanekomu/Pod-Weaver-PluginBundle-MARCEL>
and may be cloned from L<git://github.com/hanekomu/Pod-Weaver-PluginBundle-MARCEL>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHOR

Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

