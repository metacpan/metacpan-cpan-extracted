#!/usr/bin/perl 
package SQL::QueryBuilder::Pretty::Handler::DBI::db::mysql;
use base qw(SQL::QueryBuilder::Pretty::Database::MySQL);

1;
__END__
=head1 NAME

SQL::QueryBuilder::Pretty::Handler::DBI::db::mysql - DBI::mysql driver handler
extension for SQL::QueryBuilder::Pretty::DBI::db.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Directly: 

    use SQL::QueryBuilder::Pretty::Handler::DBI::db::mysql;

    my $pretty = SQL::QueryBuilder::Pretty::Handler::DBI::db::mysql->new();

    print $pretty->print('SELECT * FROM table WHERE col1 = NOW()');

or indirecly using SQL::QueryBuilder::Pretty:

    use SQL::QueryBuilder::Pretty;

    my $pretty = SQL::QueryBuilder::Pretty->new(
        '-handler' => $dbh_mysql,
    );

    print $pretty->print('SELECT * FROM table WHERE col1 = NOW()');

=head1 INHERITANCE

Is a L<SQl::QueryBuilder::Pretty::Database::MySQL>.

=head1 DESCRIPTION

MySQL extension for SQL::QueryBuilder::Pretty.

=head1 SEE ALSO

L<SQL::QueryBuilder::Pretty::Database::MySQL>.

=head1 AUTHOR

André Rivotti Casimiro, C<< <rivotti at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by André Rivotti Casimiro. Published under the terms of 
the Artistic License 2.0.

=cut
