package Otogiri::Plugin::DeleteCascade;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.04";

use Otogiri;
use Otogiri::Plugin;
use DBIx::Inspector;

our @EXPORT = qw(delete_cascade);

sub delete_cascade {
    my ($self, $table_name, $cond_href) = @_;

    my @parent_rows = $self->select($table_name, $cond_href);
    my $inspector = DBIx::Inspector->new(dbh => $self->dbh);
    my $iter = $inspector->table($table_name)->pk_foreign_keys();
    my $affected_rows = 0;
    while( my $child_table_fk_info = $iter->next ) {
        $affected_rows += _delete_child($self, $child_table_fk_info, @parent_rows);
    }
    $affected_rows += $self->delete($table_name, $cond_href);
    return $affected_rows;
}

sub _delete_child {
    my ($db, $child_table_fk_info, @parent_rows) = @_;
    my $affected_rows = 0;
    for my $parent_row ( @parent_rows ) {
        my $child_table_name   = $child_table_fk_info->fktable_name;
        my $parent_column_name = $child_table_fk_info->pkcolumn_name;
        my $child_column_name  = $child_table_fk_info->fkcolumn_name;

        my $child_delete_condition = {
            $child_column_name => $parent_row->{$parent_column_name},
        };
        $affected_rows += $db->delete_cascade($child_table_name, $child_delete_condition);
    }
    return $affected_rows;
}


1;
__END__

=encoding utf-8

=head1 NAME

Otogiri::Plugin::DeleteCascade - Otogiri Plugin for cascading delete by following FK columns

=head1 SYNOPSIS

    use Otogiri;
    use Otogiri::Plugin;

    Otogiri->load_plugin('DeleteCascade');

    my $db = Otogiri->new( connect_info => $connect_info );
    $db->insert('parent_table', { id => 123, value => 'aaa' });
    $db->insert('child_table',  { parent_id => 123, value => 'bbb'}); # child.parent_id referes parent_table.id(FK)

    $db->delete_cascade('parent_table', { id => 123 }); # both parent_table and child_table are deleted.

=head1 DESCRIPTION

Otogiri::Plugin::DeleteCascade is plugin for L<Otogiri> which provides cascading delete feature.
loading this plugin, C<delete_cascade> method is exported. C<delete_cascade> follows Foreign Keys(FK) and
delete data referred in these key.

=head1 NOTICE

Please DO NOT USE this module in production code and data. This module is intended to be used for data maintenance
in development environment or cleanup data for test code.

This module does not support multiple foreign key. It causes unexpected data lost if you delete data in
multiple foreign key table.

This module uses L<DBIx::Inspector> to access metadata(foreign keys). In some environment, database administrator
does not allow to access these metadata, In this case this module can't be used.

=head1 METHOD

=head2 $self->delete_cascade($table_name, $cond_href);

Delete rows that matched to $cond_href and child table rows that can be followed by Foreign Keys.

=head1 LICENSE

Copyright (C) Takuya Tsuchida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takuya Tsuchida E<lt>tsucchi@cpan.orgE<gt>

=cut

