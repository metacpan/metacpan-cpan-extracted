package Teng::Plugin::TextTable;
use strict;
use warnings;
use 5.010001;
our $VERSION = '0.03';
use Text::SimpleTable;
use Carp ();
use List::Util ();

our @EXPORT = qw/draw_text_table/;

sub draw_text_table {
    my ($self, $table_name, $where, $opts, $cols) = @_;
    my $table = $self->schema->get_table($table_name)
        or Carp::croak("Unknown table: $table_name");
    unless ($cols) {
        $cols = $table->columns();
    }

    my $iter = $self->search($table_name, $where, $opts);
    $iter->suppress_object_creation(1);
    my @rows = $iter->all;

    my @headers = map { [length($_) || 1, $_] } @$cols;
    for my $i (0..@$cols-1) {
        for my $row (@rows) {
            $headers[$i]->[0] = List::Util::max($headers[$i]->[0], length($row->{$cols->[$i]}) || 1);
        }
    }
    my $tt = Text::SimpleTable->new(@headers);
    for my $row (@rows) {
        $tt->row(map { $row->{$_} || '' } @$cols);
    }
    return $tt->draw;
}


1;
__END__

=encoding utf8

=head1 NAME

Teng::Plugin::TextTable - Make text table from database.

=head1 SYNOPSIS

    package My::DB;
    __PACKAGE__->load_plugin('TextTable');

    package main;
    my $db = My::DB->new(...);
    print $db->draw_text_table('user', {id => { '>', 50 }});

    # or, you want to use this plugin for just debugging...
    # You can use without load to db class.
    sub dump_table {
        my $table_name = shift;
        require Teng::Plugin::TextTable;
        return c->db->Teng::Plugin::TextTable::draw_text_table($table_name);
    }

=head1 DESCRIPTION

Teng::Plugin::TextTable is text table renderer plugin for L<Teng>.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

L<Teng>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
