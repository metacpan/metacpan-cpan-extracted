package Module::Version;
our $AUTHORITY = 'cpan:XSAWYERX';
# ABSTRACT: Get module versions
$Module::Version::VERSION = '0.201';
use strict;
use warnings;
use parent 'Exporter';

use Carp qw< croak >;
use ExtUtils::MakeMaker;

our @EXPORT_OK = 'get_version';

sub get_version {
    my $module = shift or croak 'Must get a module name';
    my $file   = MM->_installed_file_for_module($module);

    $file || return;

    return MM->parse_version($file);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Version - Get module versions

=head1 VERSION

version 0.201

=head1 SYNOPSIS

This module fetches the version of any other module.

It comes with a CLI program C<mversion> which does the same.

    use Module::Version 'get_version';

    print get_version('Search::GIN'), "\n";

Or using C<mversion>:

    $ mversion Search::GIN
    0.04

    $ mversion Doesnt::Exist
    Warning: module 'Doesnt::Exist' does not seem to be installed.

    $ mversion --quiet Doesnt::Exist
    (no output)

    $ mversion --full Search::GIN Moose
    Search::GIN 0.04
    Moose 1.01

    $ mversion --input modules.txt
    Search::GIN 0.04
    Data::Collector 0.03
    Moose 1.01

=head1 EXPORT

=head2 get_version

C<get_version> will be exported if explicitly specified.

    use Module::Version 'get_version';

B<Nothing> is exported by default.

=head1 SUBROUTINES/METHODS

=head2 get_version

Accepts a module name and fetches the version of the module.

If the module doesn't exist, returns undef.

=head1 BUGS

Please report bugs and other issues on the bugtracker:

L<http://github.com/xsawyerx/module-version/issues>

=head1 SUPPORT

This module sports 100% test coverage, but in case you have more issues, please
see I<BUGS> above.

=head1 AUTHOR

Sawyer X

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010-2018 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
