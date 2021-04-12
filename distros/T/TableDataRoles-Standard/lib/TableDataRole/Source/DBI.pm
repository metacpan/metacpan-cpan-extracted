package TableDataRole::Source::DBI;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-11'; # DATE
our $DIST = 'TableDataRoles-Standard'; # DIST
our $VERSION = '0.007'; # VERSION

use 5.010001;
use Role::Tiny;
use Role::Tiny::With;
with 'TableDataRole::Spec::Basic';
with 'TableDataRole::AsCSV';

sub new {
    my ($class, %args) = @_;

    my $dsn      = delete $args{dsn};
    my $user     = delete $args{user};
    my $password = delete $args{password};
    my $dbh = delete $args{dbh};
    if (defined $dbh) {
    } elsif (defined $dsn) {
        require DBI;
        $dbh = DBI->connect($dsn, $user, $password, {RaiseError=>1});
    }

    my $sth   = delete $args{sth};
    my $sth_bind_params = delete $args{sth_bind_params};
    my $query = delete $args{query};
    my $table = delete $args{table};
    if (defined $sth) {
    } else {
        die "You specify 'query' or 'table', but you don't specify ".
            "dbh/dsn+user+password, so I cannot create a statement handle"
            unless $dbh;
        if (defined $query) {
        } elsif (defined $table) {
            $query = "SELECT * FROM $table";
        } else {
            die "Please specify 'sth', 'query', or 'table' argument";
        }
        $sth = $dbh->prepare($query);
        $sth->execute(@{ $sth_bind_params // [] }); # to check query syntax
    }

    my $row_count_sth = delete $args{row_count_sth};
    my $row_count_sth_bind_params = delete $args{row_count_sth_bind_params};
    my $row_count_query = delete $args{row_count_query};
    if (defined $row_count_sth) {
    } else {
        die "You specify 'row_count_query' or 'table', but you don't specify ".
            "dbh/dsn+user+password, so I cannot create a statement handle"
            unless $dbh;
        if (defined $row_count_query) {
        } elsif (defined $table) {
            $row_count_query = "SELECT COUNT(*) FROM $table";
        } else {
            die "For getting row count, please specify 'row_count_sth', ".
                "'row_count_query', or 'table' argument";
        }
        $row_count_sth = $dbh->prepare($row_count_query);
        $sth->execute(@{ $row_count_sth_bind_params // [] }); # to check query syntax
    }

    die "Unknown argument(s): ". join(", ", sort keys %args)
        if keys %args;

    bless {
        #dbh => $dbh,
        sth => $sth,
        sth_bind_params => $sth_bind_params,
        row_count_sth => $row_count_sth,
        row_count_sth_bind_params => $row_count_sth_bind_params,

        index => 0,
    }, $class;
}

sub get_column_count {
    my $self = shift;
    $self->{sth}{NUM_OF_FIELDS};
}

sub get_column_names {
    my $self = shift;
    wantarray ? @{ $self->{sth}{NAME_lc} } : $self->{sth}{NAME_lc};
}

sub get_row_arrayref {
    my $self = shift;
    my $row = $self->{sth}->fetchrow_arrayref;
    return undef unless $row;
    $self->{index}++;
    $row;
}

sub get_row_count {
    my $self = shift;
    $self->{row_count_sth}->execute(@{ $self->{row_count_sth_bind_params} // [] });
    my ($row_count) = $self->{row_count_sth}->fetchrow_array;
    $row_count;
}

sub get_row_hashref {
    my $self = shift;
    my $row = $self->{sth}->fetchrow_hashref;
    return undef unless $row;
    $self->{index}++;
    $row;
}

sub reset_row_iterator {
    my $self = shift;
    $self->{sth}->execute(@{ $self->{sth_bind_params} // [] });
    $self->{index} = 0;
}

sub get_row_iterator_index {
    my $self = shift;
    $self->{index};
}

1;
# ABSTRACT: Role to access table data from DBI

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Source::DBI - Role to access table data from DBI

=head1 VERSION

This document describes version 0.007 of TableDataRole::Source::DBI (from Perl distribution TableDataRoles-Standard), released on 2021-04-11.

=head1 DESCRIPTION

This role expects table data in L<DBI> database table.

=for Pod::Coverage ^(.+)$

=head1 ROLES MIXED IN

L<TableDataRole::Spec::Basic>

=head1 METHODS

=head2 new

Usage:

 my $table = $CLASS->new(%args);

Arguments:

=over

=item * sth

=item * dbh

=item * query

=item * table

One of L</sth>, L</dbh>, L</query>, or L</table> is required.

=item * row_count_sth

=item * row_count_query

One of L</row_count_sth>, L</row_count_query>, or L</table> is required. If you
specify C<row_count_query> or C<table>, you need to specify L</dbh> or L</dsn>.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TablesRoles-Standard>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DBI>

L<TableData>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
