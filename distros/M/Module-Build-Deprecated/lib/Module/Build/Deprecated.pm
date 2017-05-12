package Module::Build::Deprecated;
$Module::Build::Deprecated::VERSION = '0.4210';
use strict;
use warnings;

# ABSTRACT: A collection of modules removed from Module-Build


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Build::Deprecated - A collection of modules removed from Module-Build

=head1 VERSION

version 0.4210

=head1 DESCRIPTION

This module contains a number of module that have been removed from Module-Build:

=over 4

=item * Module::Build::ModuleInfo

This has been superceded by L<Module::Metadata|Module::Metadata>

=item * Module::Build::Version

This has been replaced by L<version|version>

=item * Module::Build::YAML

This has been replaced by L<CPAN::Meta::YAML>

=back

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
