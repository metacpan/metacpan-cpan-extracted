# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Sql::Analyzer - Analyse von SQL-Code

=head1 BASE CLASS

L<Quiq::Dbms>

=head1 SYNOPSIS

  use Quiq::Sql::Analyzer;
  
  my $aly = Quiq::Sql::Analyzer->new($dbms);
  my $aly = Quiq::Sql::Analyzer->new($dbms,$version);

=cut

# -----------------------------------------------------------------------------

package Quiq::Sql::Analyzer;
use base qw/Quiq::Dbms/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Objektmethoden

=head3 isCreateFunction() - Prüfe auf CREATE FUNCTION

=head4 Synopsis

  $bool = $aly->isCreateFunction($stmt);

=head4 Arguments

=over 4

=item $stmt

SQL-Statement.

=back

=head4 Returns

Boolean

=head4 Description

Prüfe, ob SQL-Statement $stmt ein C<CREATE FUNCTION> oder C<CREATE OR
REPLACE FUNCTION> Statement enthält. Wenn ja, liefere 1, andernfalls 0.

=cut

# -----------------------------------------------------------------------------

sub isCreateFunction {
    my ($self,$stmt) = @_;
    return $stmt =~ /CREATE\s+(OR\s+REPLACE\s+)?FUNCTION/i? 1: 0;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.228

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2025 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
