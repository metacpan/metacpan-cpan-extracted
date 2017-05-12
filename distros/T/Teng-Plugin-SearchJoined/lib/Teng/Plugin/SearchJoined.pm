package Teng::Plugin::SearchJoined;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.05";

use Teng::Plugin::SearchJoined::Iterator;
use SQL::Maker;
SQL::Maker->load_plugin('JoinSelect');

our @EXPORT = qw/search_joined/;

sub search_joined {
    my ($self, $base_table, $join_conditions, $where, $opt) = @_;

    my @table_names = ($base_table);
    my $i = 0;
    while (my $table = $join_conditions->[$i]) {
        push @table_names, $table;
        $i += 2;
    }
    my @tables = map { $self->{schema}->get_table($_) } @table_names;

    my $name_sep = $self->{sql_builder}{name_sep};
    my @fields;
    for my $table (@tables) {
        my $table_name = $table->name;
        my @columns = map { "$table_name$name_sep$_" } @{ $table->columns };
        push @fields, @columns;
    }

    my ($sql, @binds) = $self->{sql_builder}->join_select($base_table, $join_conditions, \@fields, $where, $opt);
    my $sth = $self->execute($sql, \@binds);
    my $itr = Teng::Plugin::SearchJoined::Iterator->new(
        teng        => $self,
        sth         => $sth,
        sql         => $sql,
        table_names => \@table_names,
        suppress_object_creation => $self->{suppress_row_objects},
        fields      => \@fields,
    );

    $itr;
}

1;
__END__

=encoding utf-8

=head1 NAME

Teng::Plugin::SearchJoined - Teng plugin for Joined query

=head1 SYNOPSIS

    package MyDB;
    use parent qw/Teng/;
    __PACKAGE__->load_plugin('SearchJoined');
    
    package main;
    my $db = MyDB->new(...);
    my $itr = $db->search_joined(user_item => [
        user => {'user_item.user_id' => 'user.id'},
        item => {'user_item.item_id' => 'item.id'},
    ], {
        'user.id' => 2,
    }, {
        order_by => 'user_item.item_id',
    });
    
    while (my ($user_item, $user, $item) = $itr->next) {
        ...
    }

=head1 DESCRIPTION

Teng::Plugin::SearchJoined is a Plugin of Teng for joined query.

=head1 INTERFACE

=head2 Method

=head3 C<< $itr:Teng::Plugin::SearchJoined::Iterator = $db->search_joined($table, $join_conds, \%where, \%opts) >>

Return L<Teng::Plugin::SearchJoined::Iterator> object.

C<$table>, C<\%where> and C<\%opts> are same as arguments of L<Teng>'s C<search> method.

C<$join_conds> is same as argument of L<SQL::Maker::Plugin::JoinSelect>'s C<join_select> method.

=head1 SEE ALSO

L<Teng>

L<SQL::Maker::Plugin::JoinSelect>

=head1 LICENSE

Copyright (C) Masayuki Matsuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=cut

