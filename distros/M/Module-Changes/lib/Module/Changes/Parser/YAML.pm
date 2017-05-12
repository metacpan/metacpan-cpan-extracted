package Module::Changes::Parser::YAML;

use warnings;
use strict;
use YAML;
use Module::Changes;
use DateTime::Format::W3CDTF;
use Perl::Version;


our $VERSION = '0.05';


use base 'Module::Changes::Parser';


sub parse_string {
    my ($self, $content) = @_;
    my $spec = Load($content);

    my $changes = Module::Changes->make_object_for_type('entire');

    $changes->name($spec->{global}{name});
    for my $rel_spec (@{ $spec->{releases} || []}) {
        $changes->releases_push(Module::Changes
            ->make_object_for_type('release',
            version => Perl::Version->new($rel_spec->{version}),
            date    => DateTime::Format::W3CDTF->new->parse_datetime(
                        $rel_spec->{date}),
            author  => $rel_spec->{author},
            changes => $rel_spec->{changes},
            tags    => $rel_spec->{tags},
        ));
    }

    $changes;
}


1;


__END__

=head1 NAME

Module::Changes::Parser::YAML - Parse a YAML Changes file into objects

=head1 SYNOPSIS

    use Module::Changes;
    my $parser = Module::Changes->make_object_for_type('parser_yaml');
    my $changes = $parser->parse_from_file('Changes');

=head1 DESCRIPTION

This class can parse a YAML Changes file or string and return an object
hierarchy representing the Changes.

=head1 METHODS

This class inherits all methods from L<Module::Changes::Parser>.

=over 4

=item parse_string

    $parser->parse_string($yaml_string);

Takes a string containing YAML and returns a Changes object that contains all
the information about releases and so on.

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

