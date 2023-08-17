package TableDataRole::Source::Iterator;

use 5.010001;
use strict;
use warnings;

use Role::Tiny;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-06-14'; # DATE
our $DIST = 'TableDataRoles-Standard'; # DIST
our $VERSION = '0.016'; # VERSION

with 'TableDataRole::Spec::Basic';

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
        pos => 0,
        # buffer => undef,
        # column_names => undef,
        # column_idxs  => undef,
    }, $class;
}

sub _get_row {
    # get a row from iterator or buffer, and empty the buffer
    my $self = shift;
    if ($self->{buffer}) {
        my $row = delete $self->{buffer};
        if (!ref($row) && $row == -1) {
            return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
        } else {
            return $row;
        }
    } else {
        $self->reset_iterator unless $self->{iterator};
        my $row = $self->{iterator}->();
        return undef unless $row; ## no critic: Subroutines::ProhibitExplicitReturnUndef
        return $row;
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
        return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
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

sub has_next_item {
    my $self = shift;
    $self->_peek_row ? 1:0;
}

sub get_next_item {
    my $self = shift;
    $self->get_column_names;
    my $row_hashref = $self->_get_row;
    die "StopIteration" unless $row_hashref;
    my $row_aryref = [];
    for (keys %$row_hashref) {
        my $idx = $self->{column_idxs}{$_};
        next unless defined $idx;
        $row_aryref->[$idx] = $row_hashref->{$_};
    }
    $self->{pos}++;
    $row_aryref;
}

sub get_next_row_hashref {
    my $self = shift;
    my $row_hashref = $self->_get_row;
    die "StopIteration" unless $row_hashref;
    $self->{pos}++;
    $row_hashref;
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

sub reset_iterator {
    my $self = shift;
    $self->{iterator} = $self->{gen_iterator}->(%{ $self->{gen_iterator_params} });
    delete $self->{buffer};
    $self->{pos} = 0;
}

sub get_iterator_pos {
    my $self = shift;
    $self->{pos};
}

1;
# ABSTRACT: Get table data from an iterator

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Source::Iterator - Get table data from an iterator

=head1 VERSION

This document describes version 0.016 of TableDataRole::Source::Iterator (from Perl distribution TableDataRoles-Standard), released on 2023-06-14.

=head1 SYNOPSIS

 package TableData::YourTable;
 use Role::Tiny::With;
 with 'TableDataRole::Source::Iterator';

 sub new {
     my $class = shift;
     $class->_new(
         gen_iterator => sub {
             return sub {
                 ...
             };
         },
     );
 }

=head1 DESCRIPTION

This role retrieves rows from an iterator. Iterator must return row must return
hashref row on each call.

C<reset_iterator()> will regenerate a new iterator.

=for Pod::Coverage ^(.+)$

=head1 ROLES MIXED IN

L<TableDataRole::Spec::Basic>

=head1 METHODS

=head2 _new

Create object. This should be called by a consumer's C<new>. Usage:

 my $table = $CLASS->_new(%args);

Arguments:

=over

=item * gen_iterator

Coderef. Required. Must return another coderef which is the iterator.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataRoles-Standard>.

=head1 SEE ALSO

L<TableData>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
