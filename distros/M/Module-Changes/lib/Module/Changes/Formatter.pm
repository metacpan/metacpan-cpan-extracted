package Module::Changes::Formatter;

use warnings;
use strict;


our $VERSION = '0.05';


use base 'Module::Changes::Base';


__PACKAGE__->mk_abstract_accessors(qw(format));


sub format_to_file {
    my ($self, $changes, $filename) = @_;
    open my $fh, '>', $filename or
        die "can't open $filename for writing: $!\n";
    print $fh $self->format($changes);
    close $fh or die "can't close $filename: $!\n";
}


1;

__END__

=head1 NAME

Module::Changes::Formatter - base class for formatters

=head1 SYNOPSIS

None.

=head1 DESCRIPTION

This is a base class for formatters. See L<Module::Changes::Formatter::YAML>
and L<Module::Changes::Formatter::Free> for examples.

=head1 METHODS

This class inherits all methods from L<Module::Changes::Formatter>.

=over 4

=item format

An abstract method that is used to format a changes object. Individual
formatters need to override and implement this method.

=item format_to_file

    $formatter->format_to_file($changes, 'Changes');

Takes a changes object and a filename and uses C<format()> to format the
changes object, then writes the resulting string to the indicated file.

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

