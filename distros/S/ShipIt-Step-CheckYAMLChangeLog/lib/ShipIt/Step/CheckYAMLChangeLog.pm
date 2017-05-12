package ShipIt::Step::CheckYAMLChangeLog;

use strict;
use warnings;
use Module::Changes;


our $VERSION = '0.02';


use base 'ShipIt::Step::CheckChangeLog';


sub check_file_for_version {
    my ($self, $file, $version) = @_;
    my $parser = Module::Changes->make_object_for_type('parser_yaml');
    my $changes = $parser->parse_from_file($file);
    for my $release ($changes->releases) {
        my $rel_version = $release->version_as_string;
        return 1 if $rel_version =~ /^v?\Q$version\E$/;
    }
    warn "No mention of version '$version' in changelog file '$file'\n";
    return 0;
}


1;


__END__

=head1 NAME

ShipIt::Step::CheckYAMLChangeLog - ShipIt step for YAML Changes files

=head1 SYNOPSIS

None.

=head1 DESCRIPTION

This is like the CheckChangeLog step from ShipIt, but it can handle YAML
Changes files as defined in L<Module::Changes>.

To use it, just list in your C<.shipit> file.

=head1 TAGS

If you talk about this module in blogs, on del.icio.us or anywhere else,
please use the C<shipitstepcheckyamlchangelog> tag.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-shipit-step-checkyamlchangelog@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.

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

