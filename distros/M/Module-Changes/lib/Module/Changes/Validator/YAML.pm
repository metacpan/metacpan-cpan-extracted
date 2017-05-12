package Module::Changes::Validator::YAML;

use warnings;
use strict;
use Kwalify ();
use YAML;;


our $VERSION = '0.05';


use base 'Module::Changes::Base';


my $schema = Load(<<EOSCHEMA);
type: map
mapping:
    global:
        type: map
        mapping:
            name:
                type: str
                required: yes
    releases:
        type: seq
        sequence:
            - type: map
              mapping:
                  version:
                      type: scalar
                      required: yes
                  author:
                      type: str
                      required: yes
                  changes:
                      type: seq
                      sequence:
                        - type: str
                  date:
                      type: str
                      required: yes
                  tags:
                      type: seq
                      sequence:
                        - type: str
EOSCHEMA


sub validate {
    my ($self, $yaml) = @_;
    Kwalify::validate($schema, $yaml);
}


1;

__END__

=head1 NAME

Module::Changes::Formatter::YAML - format a Changes object as YAML

=head1 SYNOPSIS

    use Module::Changes;
    my $formatter = Module::Changes->make_object_for_type('formatter_yaml');
    $formatter->format($changes);

=head1 DESCRIPTION

This class can format a Changes object as YAML. The layout of the YAML file is
documented in L<Module::Changes>.

=head1 METHODS

This class inherits all methods from L<Module::Changes::Formatter>.

=over 4

=item format

    print $formatter->format($changes);

Takes a changes object and formats it as YAML, then returns the result string.

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

