package SqlBatch;

# ABSTRACT: The SqlBatch distribution

use v5.16;
use strict;
use warnings;
use utf8;

1;

__END__

=head1 NAME

SqlBatch

=head1 DESCRIPTION

The SqlBatch distribution is a distribution for the 'sqlbatch' program.

=head1 SEE ALSO

=over

=item L<sqlbatch>

The program that runs the SQL-batch script

=item L<SqlBatch::InstructionBase>

Base class for creating special Perl-based SQL-batch instructions

=item L<SqlBatch::Configuration>

Class defining the configuration to be executed

=item L<SqlBatch::RunState>

Class defining the runstate for an instruction

=back

=head1 AUTHOR

Sascha Dibbern (sascha at dibbern.info)

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
