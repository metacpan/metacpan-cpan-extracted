#
# This file is part of ORDB-CPAN-Mageia
#
# This software is copyright (c) 2012 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package ORDB::CPAN::Mageia::Module;
{
  $ORDB::CPAN::Mageia::Module::VERSION = '1.121690';
}
# ABSTRACT: orlite for module table in database

# -- attributes




1;


=pod

=head1 NAME

ORDB::CPAN::Mageia::Module - orlite for module table in database

=head1 VERSION

version 1.121690

=head1 DESCRIPTION

This class models the C<module> table in the database. It can be used
either with class methods, or as objects mapping one row of the table.

=head1 ATTRIBUTES

=head2 module

The name of the module, eg C<ORDB::CPAN::Mageia>.

=head2 version

The version of the module (neither the dist, nor the package). It may be
null.

=head2 dist

This is the CPAN distribution the module is part of, eg
C<ORDB-CPAN-Mageia>. It may be null.

=head2 pkgname

This is the name of the package holding this module in Mageia Linux
distribution. Chances are that it looks like C<perl-ORDB-CPAN-Mageia>.

=for Pod::Coverage base
    count
    iterate
    rowid
    select
    table(_info)?

=head1 METHODS

Refere to L<ORLite> module, section B<TABLE PACKAGE METHODS>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

