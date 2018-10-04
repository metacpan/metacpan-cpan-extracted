package Test::BOM;
$Test::BOM::VERSION = '0.001';

# ABSTRACT: Test strings and files for BOM

use strict;
use warnings;

use base qw(Test::Builder::Module);
our @EXPORT = qw(string_has_bom string_hasnt_bom file_has_bom file_hasnt_bom);

# We have subs of the same name, don't import them
use String::BOM qw();

my $CLASS  = __PACKAGE__;
my $Tester = $CLASS->builder;

sub string_has_bom {
    my ($string) = @_;

    my $ok = String::BOM::string_has_bom($string);

    $Tester->ok( $ok, q{string has BOM} );
    unless ($ok) {
        $Tester->diag('String was expected to have a BOM but did not.');
    }

    return $ok;
}

sub string_hasnt_bom {
    my ($string) = @_;

    my $ok = String::BOM::string_has_bom($string);

    $Tester->ok( !$ok, q{string hasn't BOM} );
    if ($ok) {
        $Tester->diag('String was expected not to have a BOM but it has.');
    }

    return !$ok;
}

sub file_has_bom {
    my ($string) = @_;

    my $ok = String::BOM::file_has_bom($string);

    $Tester->ok( $ok, q{file has BOM} );
    unless ($ok) {
        $Tester->diag('File was expected to have a BOM but did not.');
    }

    return $ok;
}

sub file_hasnt_bom {
    my ($string) = @_;

    my $ok = String::BOM::file_has_bom($string);

    $Tester->ok( !$ok, q{file has BOM} );
    if ($ok) {
        $Tester->diag('File was expected to not have a BOM but it has.');
    }

    return !$ok;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::BOM - Test strings and files for BOM

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Test::More;
    use Test::BOM

    string_has_bom("\x00\x00\xfe\xff");
    string_hasnt_bom("blargh");

    file_has_bom('t/data/foo');
    file_hasnt_bom('t/data/bar');

=head1 DESCRIPTION

This module helps you with testing for byte-order-marks in strings and files.

If you came across this module while looking for other ways to deal with
byte-order-marks you might find what you need in the L</"SEE ALSO"> section
below.

If you don't know anything about automated testing in Perl then you should read
about L<Test::More> before preceding.  This module uses the L<Test::Builder>
framework.

Byte-order-marks are by definition to be found at the beginning of any content,
so the functions this module provides take a look at the start of either a
string or a file. It does this by using functions from L<String::BOM> and basically just wraps them for use with L<Test::Builder>.

By default the following functions are imported into your namespace: C<string_has_bom>, C<string_hasnt_bom>, C<file_has_bom>, C<file_hasnt_bom>.

=head1 FUNCTIONS

=head2 string_has_bom ($string)

Passes if the string has a BOM, fails if not.

=head2 string_hasnt_bom ($string)

Passes if string doesn't have a BOM, fails if it has.

=head2 file_has_bom ($filename)

Passes if the file has a BOM, fails if it doesn't.

=head2 file_hasnt_bom ($filename)

Passes if the file doesn't have a BOM, fails if it has.

=head1 SEE ALSO

There are some distributions that help you dealing with BOMs in different ways:

=over 4

=item L<String::BOM> is used by this module to check for BOM.

=item L<File::BOM::Utils> contains functions to check for, add and remove BOM
from files.

=item L<File::BOM> can be used to actually read from files that have BOMs as seamlessly as possible.

=item L<PPI::Token::BOM> represents a BOM when using L<PPI> to parse perl.

=item The distribution L<Dist::Zilla::Plugin::Web> contains the module
L<Dist::Zilla::Plugin::Web::StripBOM> that strips BOM from files.

=back

Additional information about BOM and it's usage:

=over 4

=item L<http://www.unicode.org/faq/utf_bom.html#BOM> is the FAQ for the
BOM from the Unicode Consortium.

=item L<https://docs.microsoft.com/de-de/windows/desktop/Intl/using-byte-order-marks>
explains how Microsoft wants the BOM to be used. Since this document dates from
2018 (as of this writing) it's very likely to get in contact with files
containing BOM.

=back

=head1 AUTHOR

Gregor Goldbach <glauschwuffel@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gregor Goldbach.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
