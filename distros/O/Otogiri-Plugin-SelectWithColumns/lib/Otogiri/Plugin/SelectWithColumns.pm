package Otogiri::Plugin::SelectWithColumns;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Otogiri;
use Otogiri::Plugin;

our @EXPORT = qw(select_with_columns search_with_columns);

sub select_with_columns {
    my ($self, $table, $columns, $param, @opts) = @_;
    my ($sql, @binds) = $self->maker->select($table, $columns, $param, @opts);
    $self->search_by_sql($sql, \@binds, $table);
}

*search_with_columns = *select_with_columns;

1;
__END__

=encoding utf-8

=head1 NAME

Otogiri::Plugin::SelectWithColumns - Otogiri plugin to search row-data that contains only specific columns from database

=head1 SYNOPSIS

    use Otogiri;
    use Otogiri::Plugin;
    my $db = Otogiri->new(connect_info => [...]);
    $db->load_plugin('SelectWithColumns');
    
    ## SELECT `id`, `name` FROM `some_table` WHERE `author`="ytnobody" ORDER BY id ASC
    my @rows = $db->select_with_columns(
        'some_table', 
        ['id', 'name'], 
        {'author' => 'ytnobody'}, 
        {order_by => 'id ASC'}
    );
    
    my $row = $rows[0];
    print join(", ", keys($row)) . "\n"; ## --> "id, name\n"


=head1 DESCRIPTION

Otogiri::Plugin::SelectWithColumns is plugin for L<Otogiri> to search row-data that contains only specific columns from database。

=head1 LICENSE

Copyright (C) Satoshi Azuma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Satoshi Azuma E<lt>ytnobody@gmail.comE<gt>

=cut

