package Otogiri::Plugin::Count;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Otogiri;
use Otogiri::Plugin;

our @EXPORT = qw(count);

sub count {
    my ($self, $table, $column, $where, $opt) = @_;

    if ( ref $column eq 'HASH' ) {
        $opt = $where;
        $where = $column;
        $column = '*';
    }

    $column ||= '*';

    my ($sql, @binds) = $self->maker->select($table, [\"COUNT($column)"], $where, $opt);

    my ($cnt) = $self->dbh->selectrow_array($sql, {}, @binds);
    return $cnt;
}

1;
__END__

=encoding utf-8

=head1 NAME

Otogiri::Plugin::Count - Otogiri plugin to count rows in database.

=head1 SYNOPSIS

    use Otogiri;
    use Otogiri::Plugin;
    my $db = Otogiri->new( connect_info => [ ... ] );
    $db->load_plugin('Count');
    my $count = $db->count('some_table'); # SELECT COUNT(*) FROM some_table

    my $count2 = $db->count('some_table', 'column1', { group_id => 123 }); # SELECT COUNT(column1) WHERE group_id=123
    my $count3 = $db->count('some_table', { group_id => 123 });            # SELECT COUNT(*) WHERE group_id=123

=head1 DESCRIPTION

Otogiri::Plugin::Count is plugin for L<Otogiri> to count database rows.

=head1 LICENSE

Copyright (C) Takuya Tsuchida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takuya Tsuchida E<lt>tsucchi@cpan.orgE<gt>

=cut

