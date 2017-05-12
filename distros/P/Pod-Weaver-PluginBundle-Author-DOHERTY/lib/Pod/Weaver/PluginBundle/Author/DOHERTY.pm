package Pod::Weaver::PluginBundle::Author::DOHERTY;
# ABSTRACT: Pod::Weaver configuration the way DOHERTY does it
use strict;
use warnings;
our $VERSION = '0.009'; # VERSION

use Pod::Weaver::Config::Assembler;

sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

sub mvp_bundle_config {
    return (
        [ '@Author::DOHERTY/CorePrep',              _exp('@CorePrep'),          {} ],
        [ '@Author::DOHERTY/SingleEncoding',        _exp('-SingleEncoding'),    {} ],
        [ '@Author::DOHERTY/Name',                  _exp('Name'),               {} ],
        [ '@Author::DOHERTY/Version',               _exp('Version'),            {} ],

        [ '@Author::DOHERTY/Prelude',               _exp('Region'),             {region_name => 'prelude'} ],

        [ 'SYNOPSIS',                               _exp('Generic'),            {} ],
        [ 'DESCRIPTION',                            _exp('Generic'),            {} ],
        [ 'OVERVIEW',                               _exp('Generic'),            {} ],
        [ 'OPTIONS',                                _exp('Generic'),            {} ],

        [ 'METHODS',                                _exp('Generic'),            {} ],
        [ 'FUNCTIONS',                              _exp('Generic'),            {} ],

        [ '@Author::DOHERTY/Leftovers',             _exp('Leftovers'),          {} ],

        [ '@Author::DOHERTY/Availability',          _exp('Availability'),       {} ],
        [ '@Author::DOHERTY/SourceGitHub',          _exp('SourceGitHub'),       {} ],
        [ '@Author::DOHERTY/BugsAndLimitations',    _exp('BugsAndLimitations'), {} ],
        [ 'COMPATIBILITY',                          _exp('Generic'),            {} ],

        [ 'CREDITS',                                _exp('Generic'),            {} ],
        [ '@Author::DOHERTY/Authors',               _exp('Authors'),            {} ],
        [ '@Author::DOHERTY/Legal',                 _exp('Legal'),              {} ],
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::Author::DOHERTY - Pod::Weaver configuration the way DOHERTY does it

=head1 VERSION

version 0.009

=for Pod::Coverage mvp_bundle_config

=head1 AVAILABILITY

The project homepage is L<http://metacpan.org/release/Pod-Weaver-PluginBundle-Author-DOHERTY/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Pod::Weaver::PluginBundle::Author::DOHERTY/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/Pod-Weaver-PluginBundle-Author-DOHERTY>
and may be cloned from L<git://github.com/doherty/Pod-Weaver-PluginBundle-Author-DOHERTY.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/Pod-Weaver-PluginBundle-Author-DOHERTY/issues>.

=head1 AUTHOR

Mike Doherty <doherty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
