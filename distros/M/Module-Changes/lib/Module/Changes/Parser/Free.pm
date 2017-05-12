package Module::Changes::Parser::Free;

use warnings;
use strict;
use DateTime::Format::DateParse;
use DateTime::Format::W3CDTF;
use Module::Changes;
use Perl::Version;


our $VERSION = '0.05';


use base 'Module::Changes::Parser';


sub parse_string {
    my ($self, $content) = @_;

    my $changes = Module::Changes->make_object_for_type('entire');

    my @parts = split /\n\n(?=\w)/ => $content;
    for (@parts) { 1 while chomp }

    (my $name = shift @parts) =~ s/.*\s//;
    $changes->name($name);

    for my $part (@parts) {
        my ($version_line, $rel_change_lines) = split /\n/, $part, 2;

        my ($version, $date_str) = split /\s+/, $version_line, 2;

        # rudimentary support for german dates; a bit arbitrary, I know...

        my %map = (
            Mo  => 'Mon',
            Di  => 'Tue',
            Mi  => 'Wed',
            Do  => 'Thu',
            Fr  => 'Fri',
            Sa  => 'Sat',
            So  => 'Sun',
            Mai => 'May',
            Okt => 'Oct',
            Dez => 'Dec',
        );

        while (my ($orig, $replacement) = each %map) {
            $date_str =~ s/\b\Q$orig\E\b/$replacement/g;
        }

        my $date = DateTime::Format::DateParse->parse_datetime($date_str);

        my $release = Module::Changes->make_object_for_type('release');
        $release->version(Perl::Version->new($version));
        $release->date($date);

        my @rel_changes = split /^(?=\s+- )/m, $rel_change_lines;

        for my $rel_change (@rel_changes) {
            1 while chomp $rel_change;
            if ($rel_change =~ /^(\s+-\s+)/) {

                # take off an equal amount of indenting from each line

                my $indent = length $1;
                my @lines = split /\n/ => $rel_change;
                substr($_, 0, $indent, '') for @lines;
                $release->changes_push(join ' ' => @lines);
            } else {
                die "can't determine indent from\n$rel_change\n";
            }
        }

        $changes->releases_push($release);
    }

    $changes;
}


1;


__END__

=head1 NAME

Module::Changes::Parser::Free - rudimentary freeform Changes file parser

=head1 SYNOPSIS

    use Module::Changes;
    my $parser = Module::Changes->make_object_for_type('parser_free');
    my $changes = $parser->parse_from_file('Changes');

=head1 DESCRIPTION

This class attempts to parse a freeform Changes file into an object hierarchy
representing the Changes.

It can cope with this kind of format:

    Revision history for Perl extension Web::Scraper

    0.17  Wed Sep 19 19:12:25 PDT 2007
            - Reverted Term::Encoding support since it causes segfaults
              (double utf-8 encoding) in some environment

    0.16  Tue Sep 18 04:48:47 PDT 2007
            - Support 'RAW' and 'TEXT' for TextNode object
            - Call Term::Encoding from scraper shell if installed

The distribution name is expected to be the last word on the first line. The
indenting of the change lines is expected to be consistent.

There's also basic support for dealing with german-style dates, so it will
turn C<Do Okt 18 10:09:39 CEST 2007> into C<Thu Oct 18 10:09:39 CEST 2007> and
take it from there.

The parser is by no means robust; it's more intended as quick hack to parse
existing Changes files. Patches welcome.

=head1 METHODS

This class inherits all methods from L<Module::Changes::Parser>.

=over 4

=item parse_string

    $parser->parse_string($string);

Takes a string containing the freeform Changes and returns a Changes object
that contains all the information about releases and so on.

=back

=head1 TAGS

If you talk about this module in blogs, on del.icio.us or anywhere else,
please use the C<modulechanges> tag.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-module-changes@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit <http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see <http://www.perl.com/CPAN/authors/id/M/MA/MARCEL/>.

=head1 AUTHOR

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

