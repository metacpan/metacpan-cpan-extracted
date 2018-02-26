package String::ToIdentifier::EN::Unicode;
our $AUTHORITY = 'cpan:AVAR';
$String::ToIdentifier::EN::Unicode::VERSION = '0.12';
use strict;
use warnings;
use base 'String::ToIdentifier::EN';
use Exporter 'import';

=encoding UTF-8

=head1 NAME

String::ToIdentifier::EN::Unicode - Convert Strings to Unicode English Program
Identifiers

=head1 SYNOPSIS

    use utf8;
    use String::ToIdentifier::EN::Unicode 'to_identifier';

    to_identifier 'foo亰bar∑'; # foo亰BarNDashArySummation

=head1 DESCRIPTION

This module is a subclass L<String::ToIdentifier::EN>, see that module for
details.

Unlike L<String::ToIdentifier::EN>, this module will not convert the Unicode
subset of C<\w> into ASCII.

=head1 EXPORT

Optionally exports the L<to_identifier|String::ToIdentifier::EN/to_identifier>
function.

=cut

our @EXPORT_OK = qw/to_identifier/;

sub to_identifier {
    return __PACKAGE__->string_to_identifier(@_);
}

sub _non_identifier_char {
    return qr/\W/;
}

=head1 SEE ALSO

L<String::ToIdentifier::EN>,
L<Text::Unidecode>,
L<Lingua::EN::Inflect::Phrase>

=head1 AUTHOR

Rafael Kitover, C<< <rkitover@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-string-toidentifier-en at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-ToIdentifier-EN>.  I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 REPOSITORY

L<http://github.com/rkitover/string-toidentifier-en>

=head1 SUPPORT

More information on this module is available at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=String-ToIdentifier-EN>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/String-ToIdentifier-EN>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/String-ToIdentifier-EN>

=item * MetaCPAN

L<https://metacpan.org/module/String::ToIdentifier::EN>

=item * Search CPAN

L<http://search.cpan.org/dist/String-ToIdentifier-EN/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Rafael Kitover <rkitover@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of String::ToIdentifier::EN::Unicode
