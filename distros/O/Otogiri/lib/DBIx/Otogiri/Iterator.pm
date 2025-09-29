package DBIx::Otogiri::Iterator;
use strict;
use warnings;
use Class::Accessor::Lite (
    new => 0,
    ro => [qw/db sql binds table/],
    rw => [qw/sth fetched_count/],
);

sub new {
    my ($class, %opts) = @_;
    $opts{sth} = $opts{db}->dbh->prepare($opts{sql});
    $opts{sth}->execute($opts{binds} ? @{$opts{binds}} : ());
    $opts{fetched_count} = 0;
    bless {%opts}, $class;
}

sub next {
    my $self = shift;
    my $row = $self->sth->fetchrow_hashref;
    unless ($row) {
        $self->sth->finish;
        $self->{sth} = undef;
        return;
    }
    $self->{fetched_count}++;
    ($row) = $self->db->_inflate_rows($self->table, $row);
    return $row;
}

1;
__END__

=encoding utf-8

=head1 NAME

DBIx::Otogiri::Iterator - Iterator class for Otogiri

=head1 SYNOPSIS

    use Otogiri;
    my $db = Otogiri->new(connect_info => ['dbi:SQLite:...', '', '']);
    my $iter = $db->select(book => {price => {'>=' => 500}});
    
    while (my $row = $iter->next) {
        printf "Title: %s \nPrice: %s yen\n", $row->{title}, $row->{price};
    }
    
    printf "rows = %s\n", $iter->fetched_count;

=head1 DESCRIPTION

Iterator class for Otogiri. DO NOT USE THIS CLASS DIRECTLY.

=head1 METHODS

=head2 next

    my $row = $iter->next;

Returns a row data as single hashref. Then, increment internal value "fetched_count".

=head2 fetched_count

    my $count = $iter->fetched_count;

Returns a current "fetched_count".

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=head1 SEE ALSO

L<DBIx::Otogiri>

=cut

