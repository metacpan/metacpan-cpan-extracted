package ShipIt::Step::Manifest;

use strict;
use warnings;
use Dist::Joseki;


our $VERSION = '0.01';


use base 'ShipIt::Step';


sub run {
    my ($self, $state) = @_;

    if ($state->dry_run) {
        warn "*** DRY RUN, not making manifest\n";
        return;
    }

    my $dist = Dist::Joseki->get_dist_type;
    $dist->ACTION_manifest;
}


1;


__END__

=head1 NAME

ShipIt::Step::Manifest - ShipIt step for recreating the MANIFEST

=head1 SYNOPSIS

None.

=head1 DESCRIPTION

This step recreates the MANIFEST by effectively running C<make manifest>, or
the equivalent in your build process.

I use this as I don't have superfluous files lying around in the distribution
directories, and have set the relevant C<svk ignore> properties.

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

