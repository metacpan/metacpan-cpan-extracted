package Otogiri::Plugin::InsertAndFetch;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";
our @EXPORT = qw/insert_and_fetch/;

sub insert_and_fetch {
    my ($self, $table, $param, @opts) = @_;
    if ($self->fast_insert($table, $param, @opts)) {
        $param = $self->_deflate_param($table, $param);
        return $self->single($table, $param, @opts);
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Otogiri::Plugin::InsertAndFetch - An Otogiri plugin that keep compatibility for insert method

=head1 SYNOPSIS

    use Otogiri;
    use Otogiri::Plugin;
    Otogiri->load_plugin('InsertAndFetch');
    
    my $db = Otogiri->new(...);
    
    my $row = $db->insert_and_fetch(book => {title => 'Acmencyclopedia', author => 'makamaka'});
    
    printf("title: %s\n", $row->{title}); # -> title: Acmencyclopedia

=head1 DESCRIPTION

Otogiri::Plugin::InsertAndFetch is an Otogiri plugin. It provides 'insert_and_fetch' method to Otogiri instance.

=head1 METHODS

=head2 insert_and_fetch

    my $row = $db->insert($table_name => $columns_in_hashref);

Insert data. Then, returns row data.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=head1 SEE ALSO

L<Otogiri>

=cut

