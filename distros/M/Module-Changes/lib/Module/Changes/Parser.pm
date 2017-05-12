package Module::Changes::Parser;

use warnings;
use strict;


our $VERSION = '0.05';


use base 'Module::Changes::Base';


__PACKAGE__->mk_abstract_accessors(qw(parse_string));


sub parse_from_filehandle {
    my ($self, $filehandle) = @_;
    my $content = do { local $/; <$filehandle> };
    $self->parse_string($content);
}


sub parse_from_file {
    my ($self, $filename) = @_;
    open my $fh, '<', $filename or die "can't open $filename: $!\n";
    my $changes = $self->parse_from_filehandle($fh);
    close $fh or die "can't close $filename: $!\n";
    $changes;
}


1;

__END__

=head1 NAME

Module::Changes::Parser - base class for parsers

=head1 SYNOPSIS

None.

=head1 DESCRIPTION

This is a base class for formatters. See L<Module::Changes::Parser::YAML> for
eample.

=head1 METHODS

This class inherits all methods from L<Module::Changes::Base>.

=over 4

=item parse_string

An abstract method that is used to parse a string into a Changes object.
Individual parsers need to override and implement this method.

=item parse_from_filehandle

    my $changes = $parser->parse_from_filehandle($fh);

Takes a filehandle, reads from it and parses the content and returns the
parsed Changes object.

=item parse_from_file

    my $changes = $parser->parse_from_file('Changes');

Takes a filname, reads from it and parses the content and returns the
parsed Changes object.

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

