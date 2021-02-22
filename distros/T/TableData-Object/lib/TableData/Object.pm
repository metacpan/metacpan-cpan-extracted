package TableData::Object;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-10'; # DATE
our $DIST = 'TableData-Object'; # DIST
our $VERSION = '0.113'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Check::Structure qw(is_aos is_aoaos is_aohos);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(table);

sub table { __PACKAGE__->new(@_) }

sub new {
    my ($class, $data, $spec) = @_;
    if (!defined($data)) {
        die "Please specify table data";
    } elsif (ref($data) eq 'HASH') {
        require TableData::Object::hash;
        TableData::Object::hash->new($data);
    } elsif (is_aoaos($data, {max=>10})) {
        require TableData::Object::aoaos;
        TableData::Object::aoaos->new($data, $spec);
    } elsif (is_aohos($data, {max=>10})) {
        require TableData::Object::aohos;
        TableData::Object::aohos->new($data, $spec);
    } elsif (ref($data) eq 'ARRAY') {
        require TableData::Object::aos;
        TableData::Object::aos->new($data);
    } else {
        die "Unknown table data form, please supply array of scalar, ".
            "array of array-of-scalar, or array of hash-of-scalar";
    }
}

1;
# ABSTRACT: Manipulate data structure via table object

__END__

=pod

=encoding UTF-8

=head1 NAME

TableData::Object - Manipulate data structure via table object

=head1 VERSION

This document describes version 0.113 of TableData::Object (from Perl distribution TableData-Object), released on 2021-01-10.

=for Pod::Coverage ^$

=head1 FUNCTIONS

=head2 table($data[ , $spec ]) => obj

Shortcut for C<< TableData::Object->new(...) >>.

=head1 METHODS

=head2 new($data[ , $spec ]) => obj

Detect the structure of C<$data> and create the appropriate
C<TableData::Object::FORM> object.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableData-Object>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData-Object>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-TableData-Object/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<TableData::Object::Base> for list of available methods.

L<TableData::Object::aos>

L<TableData::Object::aoaos>

L<TableData::Object::aohos>

L<TableData::Object::hash>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
