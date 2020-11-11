package TablesRole::Source::Iterator;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-11-10'; # DATE
our $DIST = 'TablesRoles-Standard'; # DIST
our $VERSION = '0.006'; # VERSION

use 5.010001;
use Role::Tiny;
use Role::Tiny::With;
with 'TablesRole::Spec::Basic';
with 'TablesRole::Util::CSV';

sub _new {
    my ($class, %args) = @_;

    my $gen_iterator = delete $args{gen_iterator} or die "Please specify 'gen_iterator' argument";
    my $gen_iterator_params = delete $args{gen_iterator_params} // {};

    die "Unknown argument(s): ". join(", ", sort keys %args)
        if keys %args;

    bless {
        gen_iterator => $gen_iterator,
        gen_iterator_params => $gen_iterator_params,
        iterator => undef,
        # buffer => undef,
        # column_names => undef,
        # column_idxs  => undef,
    }, $class;
}

# as_csv from TablesRole::Util::CSV

sub _get_row {
    # get a row from iterator or buffer, and empty the buffer
    my $self = shift;
    if ($self->{buffer}) {
        my $row = delete $self->{buffer};
        if (!ref($row) && $row == -1) {
            return undef;
        } else {
            return $row;
        }
    } else {
        $self->reset_iterator unless $self->{iterator};
        return $self->{iterator}->();
    }
}

sub _peek_row {
    # get a row from iterator, put it in buffer. will return the existing buffer
    # content if it exists.
    my $self = shift;
    unless ($self->{buffer}) {
        $self->reset_iterator unless $self->{iterator};
        $self->{buffer} = $self->{iterator}->() // -1;
    }
    if (!ref($self->{buffer}) && $self->{buffer} == -1) {
        return undef;
    } else {
        return $self->{buffer};
    }
}

sub get_column_count {
    my $self = shift;
    $self->get_column_names;
    scalar(@{ $self->{column_names} });
}

sub get_column_names {
    my $self = shift;
    unless ($self->{column_names}) {
        my $row = $self->_peek_row;
        unless ($row) {
            return wantarray ? () : [];
        }
        my $i = -1;
        $self->{column_names} = [];
        $self->{column_idxs} = {};
        for (sort keys %$row) {
            push @{ $self->{column_names} }, $_;
            $self->{column_idxs}{$_} = ++$i;
        }
    }
    wantarray ? @{ $self->{column_names} } : $self->{column_names};
}

sub get_row_arrayref {
    my $self = shift;
    $self->get_column_names;
    my $row_hashref = $self->_get_row;
    return undef unless $row_hashref;
    my $row_aryref = [];
    for (keys %$row_hashref) {
        my $idx = $self->{column_idxs}{$_};
        next unless defined $idx;
        $row_aryref->[$idx] = $row_hashref->{$_};
    }
    $row_aryref;
}

sub get_row_count {
    my $self = shift;
    $self->reset_iterator;
    unless (defined $self->{row_count}) {
        my $i = 0;
        $i++ while $self->_get_row;
        $self->{row_count} = $i;
    }
    $self->{row_count};
}

sub get_row_hashref {
    my $self = shift;
    $self->_get_row;
}

sub reset_iterator {
    my $self = shift;
    $self->{iterator} = $self->{gen_iterator}->(%{ $self->{gen_iterator_params} });
}

1;
# ABSTRACT: Get table data from an iterator

__END__

=pod

=encoding UTF-8

=head1 NAME

TablesRole::Source::Iterator - Get table data from an iterator

=head1 VERSION

This document describes version 0.006 of TablesRole::Source::Iterator (from Perl distribution TablesRoles-Standard), released on 2020-11-10.

=head1 SYNOPSIS

 package Tables::YourTable;
 use Role::Tiny::With;
 with 'TablesRole::Source::Iterator';

 sub new {
     my $class = shift;
     $class->init(
         gen_iterator => sub {
             return sub {
                 ...
             };
         },
     );
 }

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 ROLES MIXED IN

L<TablesRole::Spec::Basic>

=head1 METHODS

=head2 _new

Create object. This should be called by a consumer's C<new>. Usage:

 my $table = $CLASS->init(%args);

Arguments:

=over

=item * gen_iterator

Coderef. Required. Must return another coderef which is the iterator. Iterator
must return row on each call; the row must be a hashref.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TablesRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TablesRoles-Standard>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TablesRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Tables>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
