package SQL::Entity::Column::LOB;

use strict;
use warnings;
use vars qw(@EXPORT_OK %EXPORT_TAGS $VERSION);

$VERSION = '0.02';

use Abstract::Meta::Class ':all';
use base qw(Exporter SQL::Entity::Column);

@EXPORT_OK = qw(sql_lob);
%EXPORT_TAGS = (all => \@EXPORT_OK);

=head1 NAME

SQL::Entity::Column::LOB - Entity LOBs column abstraction.

=head1 CLASS HIERARCHY

 SQL::Entity::Column
    |
    +----SQL::Entity::Column::LOB

=head1 SYNOPSIS

    use SQL::Entity::Column::LOB ':all';

    my $column = SQL::Entity::Column::Lob->new(name  => 'name', size_column => 'doc_size');
    or 
    my $column = sql_lob(name  => 'name', size_column => 'doc_size');

=head1 DESCRIPTION

Represents entities lob column, that maps to the table lob column and column that stores lob size.

=head2 EXPORT

None by default.

sql_column  by tag 'all'

=head2 ATTRIBUTES

=over

=item size_column

Column that stores information about lob size

=cut

has '$.size_column';

=back

=head2 METHODS

=over

=item sql_lob

=cut

sub sql_lob {
    __PACKAGE__->new(@_);
}


1;

__END__

=back

=head1 COPYRIGHT

The SQL::Entity::Column::LOB module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 SEE ALSO

L<SQL::Entity>
L<SQL::Entity::Table>
L<SQL::Entity::Condition>

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut