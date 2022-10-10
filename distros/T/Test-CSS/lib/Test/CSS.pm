package Test::CSS;

$Test::CSS::VERSION = '0.09';
$Test::CSS::AUTHOR  = 'cpan:MANWAR';

=head1 NAME

Test::CSS - Interface to test CSS string and file.

=head1 VERSION

Version 0.09

=cut

use strict; use warnings;
use 5.0006;
use JSON;
use File::Share ':all';
use Test::Builder;

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(ok_css_string ok_css_file);

our $TESTER     = Test::Builder->new;
our $PROPERTIES = JSON->new->utf8(1)->decode(_read_file(dist_file('Test-CSS', 'properties.json')));

=head1 DESCRIPTION

The  one  and  only feature of the package is to validate the CSS (string / file)
structurally. Additionally it checks  if  the property name is a valid as per the
CSS specifications.

=head1 METHODS

=head2 ok_css_string($css_string, $test_name)

=cut

sub ok_css_string($;$) {
    my ($input, $test_name) = @_;

    eval { _parse_css($input) };
    if ($@) {
        $TESTER->ok(0, $test_name);
    }
    else {
        $TESTER->ok(1, $test_name);
    }
}

=head2 ok_css_file($css_file, $test_name)

=cut

sub ok_css_file($;$) {
    my ($file, $test_name) = @_;

    eval { _parse_css(_read_file($file)) };
    if ($@) {
        $TESTER->ok(0, $test_name);
    }
    else {
        $TESTER->ok(1, $test_name);
    }
}

#
#
# PRIVATE METHODS

sub _parse_css {
    my ($css) = @_;

    if (defined $css) {
        $css =~ s/\r\n|\r|\n/ /gs;
        $css =~ s!/\*.*?\*\/!!g;

        # Split selectors
        foreach ( grep { /\S/ } split /(?<=\})/, $css ) {
            die "Invalid or unexpected selector data '$_'\n"
                unless (/^\s*([^{]+?)\s*\{(.*)\}\s*$/);

            my $selector   = $1;
            my $properties = $2;
            $selector =~ s/\s{2,}/ /g;

            # Split properties
            foreach (grep { /\S/ } split /\;/, $properties) {
                # skip browser specific properties
                next if ((/^\s*[\*\-\_]/) || (/\\/));

                # check if properties are valid structurally
                die "Invalid or unexpected property '$_' in style '$selector'\n"
                    unless (/^\s*([\w._-]+)\s*:\s*(.*?)\s*$/);

                my ($name) = split /\:/,$_;
                $name  =~ s/^\s+|\s+$//g;
                (exists $PROPERTIES->{lc($name)})
                    || die "Found invalid property [$name] within selector [$selector].\n";
            }
        }
    }
    else {
        die 'No stylesheet data was found in the document';
    }
}

sub _read_file {
    my ($file) = @_;

    open my $FILE, "<", $file or die $!;
    my $css = do { local( $/ ) ; <$FILE> } ;
    close $FILE;

    return $css;
}

=head1 BUGS

None  that I am aware of. Of course, if you find a bug, let me know, and I will be
sure to fix it.  This is still a very early version, so it is always possible that
I have just "gotten it wrong" in some places.

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Test-CSS>

=head1 BUGS

Please  report  any bugs or feature requests to C<bug-test-css at rt.cpan.org>, or
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-CSS>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::CSS

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 - 2017 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
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

1; # End of Test-CSS
