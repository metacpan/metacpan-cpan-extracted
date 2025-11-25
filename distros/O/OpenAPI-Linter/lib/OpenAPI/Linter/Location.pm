package OpenAPI::Linter::Location;

$OpenAPI::Linter::VERSION   = '0.13';
$OpenAPI::Linter::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

OpenAPI::Linter::Location - Represents file location information for OpenAPI specification issues

=head1 VERSION

Version 0.13

=cut

our $VERSION = '0.13';

=head1 SYNOPSIS

    use OpenAPI::Linter::Location;

    # Create a location object
    my $location = OpenAPI::Linter::Location->new('openapi.yaml', 10, 5);

    # Convert to string representation
    print $location->to_string;  # "openapi.yaml:10:5"

    # Access location components directly
    print $location->{file};    # "openapi.yaml"
    print $location->{line};    # 10
    print $location->{column};  # 5

=head1 DESCRIPTION

C<OpenAPI::Linter::Location> represents a specific location within an OpenAPI specification
file. It tracks the file name, line number, and column number where an issue or element
is located.

This class is used internally by L<OpenAPI::Linter> to provide precise location
information for validation errors and linting issues, making it easier for developers
to locate and fix problems in their OpenAPI specifications.

=head1 METHODS

=head2 new

Creates a new C<OpenAPI::Linter::Location> instance.

It returns a blessed hash reference containing the location information.

Parameters:

=over 4

=item * file

The file path where the issue occurred. This can be a relative or absolute path.

=item * line

The line number within the file (1-based).

=item * column

The column number within the line (1-based).

=back

    my $location = OpenAPI::Linter::Location->new($file, $line, $column);

=cut

use strict;
use warnings;

sub new {
    my ($class, $file, $line, $column) = @_;
    return bless {
        file   => $file,
        line   => $line,
        column => $column
    }, $class;
}

=head2 to_string

Returns a string representation of the location in the format C<file:line:column>.

This format is commonly used by development tools, IDEs, and command-line utilities
to quickly navigate to specific locations in source files.

Example:

    my $location_str = $location->to_string;

    openapi.yaml:15:8
    spec.json:42:3
    input:1:1

=cut

sub to_string {
    my ($self) = @_;
    return $self->{file} . ":" . $self->{line} . ":" . $self->{column};
}

=head1 ACCESSORS

While C<OpenAPI::Linter::Location> uses a simple blessed hash structure rather
than formal accessors, the following hash keys are available:

=over 4

=item * file

The file path associated with this location.

=item * line

The line number (1-based).

=item * column

The column number (1-based).

=back

Example:

    print "File: $location->{file}\n";
    print "Line: $location->{line}\n";
    print "Column: $location->{column}\n";

=head1 Usage with OpenAPI::Linter

Location objects are automatically created and used by L<OpenAPI::Linter>
when processing OpenAPI specifications. Each issue returned by C<find_issues>
or C<validate_schema> includes a location field:

    my $linter = OpenAPI::Linter->new(spec => 'openapi.yaml');
    my @issues = $linter->find_issues;

    foreach my $issue (@issues) {
        print "Issue at $issue->{location}: $issue->{message}\n";
        # Example: "Issue at openapi.yaml:10:5: Missing info.title"
    }

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

Copyright (C) 2025 Mohammad Sajid Anwar.

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
