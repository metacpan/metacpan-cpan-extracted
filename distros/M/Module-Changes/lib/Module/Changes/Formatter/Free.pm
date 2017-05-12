package Module::Changes::Formatter::Free;

use warnings;
use strict;
use DateTime::Format::Mail;
use YAML;


our $VERSION = '0.05';


use base 'Module::Changes::Formatter';


__PACKAGE__->mk_scalar_accessors(qw(indent));


use constant DEFAULTS => (
    indent => 4,
);


sub format_line {
    my ($self, $text) = @_;
    # FIXME handle long text by correctly wrapping it
    sprintf "%s - %s\n", ' ' x $self->indent, $text;
}


sub format_release {
    my ($self, $release) = @_;
    my $text = sprintf "%s  %s (%s)\n",
        $release->version_as_string,
        DateTime::Format::Mail->new->format_datetime($release->date),
        $release->author;
    $text .= $self->format_line($_) for grep { defined } $release->changes;
    if (grep { defined } $release->tags) {
        $text .= $self->format_line(
            sprintf 'tags: %s',
            join ', ' =>
            grep { defined }
            $release->tags
        );
    }
    $text;
}


sub format {
    my ($self, $changes) = @_;

    my $text = sprintf "Revision history for Perl extension %s\n\n",
        $changes->name;

    $text .=
        join "\n" =>
        map { $self->format_release($_) }
        $changes->releases;

    $text;
}


1;

__END__

=head1 NAME

Module::Changes::Formatter::Free - format a Changes object in freeform

=head1 SYNOPSIS

    use Module::Changes;
    my $formatter = Module::Changes->make_object_for_type('formatter_free',
        indent => 4
    );
    $formatter->format($changes);

=head1 DESCRIPTION

This class can format a Changes object in a kind of I<freeform> format. This
makes the Changes file look more or less like traditional Changes files do.

=head1 METHODS

This class inherits all methods from L<Module::Changes::Formatter>.

=over 4

=item indent

    $formatter->indent(4);
    my $indent = $formatter->indent;

Set or get the indent used to format individual changes and tags lines. The
default is an indent of 4.

=item format_line

    print $formatter->format_line('Added foobar()');

Takes a changes string and formats it to look like they do in traditional
Changes files, with an indent and a leading dash. The resulting string is
returned.

Long change strings, spanning multiple lines, aren't handled gracefully yet.

This method is used internally; most likely you will not need to use it.

=item format_release

    print $formatter->format_release($release);

Takes a release object and formats it, then returns the result string.

This method is used internally; most likely you will not need to use it.

=item format

    print $formatter->format($changes);

Takes a changes object and formats it, then returns the result string.

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

