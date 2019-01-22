package Teng::Plugin::TmpSuppressRowObjects;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.04";

our @EXPORT;

{
    my @origs = qw(
        insert
        single
        single_by_sql
        single_named
        search
        search_named
    );
    my $suffix = '_hashref';

    no strict 'refs';
    for my $orig (@origs) {
        my $method = $orig . $suffix;
        push @EXPORT, $method;
        *{__PACKAGE__ . '::' . $method} = sub {
            my $self = shift;
            local $self->{suppress_row_objects} = 1;
            $self->$orig(@_);
        };
    }
    push @EXPORT, qw(
        search_by_sql_hashref
    );
}

sub search_by_sql_hashref {
    my ($self, $sql, $bind, $table_name) = @_;

    wantarray and return @{ $self->dbh->selectall_arrayref($sql, +{ Slice => +{} }, @$bind) };
    local $self->{suppress_row_objects} = 1;
    $self->search_by_sql($sql, $bind, $table_name);
}


1;
__END__

=encoding utf-8

=head1 NAME

Teng::Plugin::TmpSuppressRowObjects - add methods with temporary use of suppress_row_objects

=head1 SYNOPSIS

    #  In your Model ...
    package Your::Model;
    use parent qw(Teng);

    __PACKAGE__->load_plugin('TmpSuppressRowObjects');


    #  In case suppress_row_objects = 0 ...
    my $teng = Your::Model->new(dbh => $dbh, suppress_row_objects => 0);
    my @rows;

    #  same usage with original 'search'
    @rows = $teng->search_hashref(test_table => +{ id => 100 });     #  elements in @rows are hashref

    #  does not affect original 'search'
    @rows = $teng->search(test_table => +{ id => 100 });     #  elements in @rows are row object


=head1 DESCRIPTION

This plugin adds some methods, which return hashref as a result, rather than row objects, even when C<suppress_row_objects> is 0.
It is useful when we want row objects as default, and lightweight hashref in some cases to improve performance.


=head1 METHODS

    insert_hashref
    search_hashref
    single_hashref
    search_by_sql_hashref
    single_by_sql_hashref
    search_named_hashref
    single_named_hashref

Usage of those methods are the same to original methods (without C<_hashref>).


=head1 LICENSE

Copyright (C) egawata.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

egawata E<lt>egawa.takashi@gmail.comE<gt>

=cut

