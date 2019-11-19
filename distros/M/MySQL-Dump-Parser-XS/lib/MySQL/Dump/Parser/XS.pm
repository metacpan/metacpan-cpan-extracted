package MySQL::Dump::Parser::XS;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.04";

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__

=encoding utf-8

=for stopwords mysqldump

=head1 NAME

MySQL::Dump::Parser::XS - mysqldump SQL parser

=head1 SYNOPSIS

    use MySQL::Dump::Parser::XS;

    open my $fh, '<:encoding(utf-8)', 'backup.sql' or die $!;

    my %rows;
    my $parser = MySQL::Dump::Parser::XS->new;
    while (my $line = <$fh>) {
        my @rows  = $parser->parse($line);
        my $table = $parser->current_target_table();
        push @{ $rows{$table} } => @rows if $table;
    }

    for my $table ($parser->tables()) {
        my @columns = $parser->columns($table);
        my $row     = $rows{$table};
        print "[$table] id:$row->{id}\n";
    }

=head1 DESCRIPTION

MySQL::Dump::Parser::XS is C<mysqldump> parser written in C/XS.
This module provides schema/data loader from C<mysqldump> output SQL directly. No need C<mysqld>.

=head1 METHODS

=head2 CLASS METHODS

=head3 C<new()>

Creates a new parser instance.
This manages parsing states and table's meta information in the parsing context.

=head2 INSTANCE METHODS

=head3 C<reset()>

Re-initialize parsing context.

=head3 C<parse($line)>

Parse a line of C<mysqldump> output.

=head3 C<current_target_table()>

Get current target table name in the parsing context.

=head3 C<columns($table_name)>

Get column names as LIST for the table of C<$table_name>.
This method can get columns from already parsed tables only.

=head3 C<tables()>

Get table names as LIST.
This method can get tables from already parsed tables only.

=head1 FAQ

=head3 How to get column details?

Some C<mysqldump> output include poor table schema information only.
So if you just need rich table schema information, I suggest using L<DBIx::Inspector> to solve the problem.

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

