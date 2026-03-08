package OpenAPI::Linter::Location;

$OpenAPI::Linter::Location::VERSION   = '0.19';
$OpenAPI::Linter::Location::AUTHORITY = 'cpan:MANWAR';

use strict;
use warnings;
use overload
    '""'     => \&to_string,
    fallback => 1;

=head1 NAME

OpenAPI::Linter::Location - File location information for OpenAPI spec issues

=head1 VERSION

Version 0.19

=head1 SYNOPSIS

    use OpenAPI::Linter::Location;

    my $loc = OpenAPI::Linter::Location->new(
        file   => 'openapi.yaml',
        path   => 'paths./users.get.responses',
        line   => 42,
        column => 5,
    );

    print $loc;             # "paths./users.get.responses"  (stringifies to path)
    print $loc->to_string;  # "paths./users.get.responses"
    print $loc->file;       # "openapi.yaml"
    print $loc->line;       # 42
    print $loc->column;     # 5
    print $loc->position;   # "openapi.yaml:42:5"

=head1 DESCRIPTION

Represents a specific location within an OpenAPI specification file, combining
a dot-separated schema path (e.g. C<paths./users.get>) with an optional file
name, line number, and column number.

The object stringifies to its C<path> value, so existing code that treats
issue locations as plain strings continues to work without modification.

=head1 METHODS

=head2 new

    my $loc = OpenAPI::Linter::Location->new(%args);

Named arguments:

=over 4

=item C<path> (required)

Dot-separated path within the spec, e.g. C<paths./users.get.responses.200>.

=item C<file> (optional)

The spec file name or C<internal_data> for in-memory specs.

=item C<line> (optional)

1-based line number within the file. C<0> means unknown.

=item C<column> (optional)

1-based column number within the file. C<0> means unknown.

=back

=cut

sub new {
    my ($class, %args) = @_;
    return bless {
        path   => $args{path}   // '',
        file   => $args{file}   // 'unknown',
        line   => $args{line}   // 0,
        column => $args{column} // 0,
    }, $class;
}

=head2 to_string

Returns the dot-separated path string. This is also what the object produces
when used in string context.

=cut

sub to_string { $_[0]->{path} }

=head2 file

Returns the file name associated with this location.

=cut

sub file   { $_[0]->{file}   }

=head2 line

Returns the line number (1-based). Returns C<0> if unknown.

=cut

sub line   { $_[0]->{line}   }

=head2 column

Returns the column number (1-based). Returns C<0> if unknown.

=cut

sub column { $_[0]->{column} }

=head2 position

Returns the full C<file:line:column> position string, e.g.
C<openapi.yaml:42:5>. Returns C<unknown> if line information is unavailable.

=cut

sub position {
    my ($self) = @_;
    return 'unknown' unless $self->{line};
    return sprintf '%s:%d:%d', $self->{file}, $self->{line}, $self->{column};
}

=head1 OVERLOADING

The object stringifies to its C<path> value via C<"">. This preserves
backwards compatibility with code that compares or prints C<$issue->{location}>
as a plain string.

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/OpenAPI-Linter>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/OpenAPI-Linter/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OpenAPI::Linter::Location

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/OpenAPI-Linter/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/OpenAPI-Linter>

=item * Search MetaCPAN

L<https://metacpan.org/dist/OpenAPI-Linter/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:
L<http://www.perlfoundation.org/artistic_license_2_0>
Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.
If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.
This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.
This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.
Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of OpenAPI::Linter::Location
