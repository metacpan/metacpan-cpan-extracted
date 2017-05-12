package ShipIt::Step::DistClean;

use strict;
use warnings;
use Dist::Joseki;


our $VERSION = '0.01';


use base 'ShipIt::Step';


sub run {
    my ($self, $state) = @_;

    if ($state->dry_run) {
        warn "*** DRY RUN, not cleaning distribution\n";
        return;
    }

    my $dist = Dist::Joseki->get_dist_type;
    $dist->ACTION_distclean;
}


1;


__END__

=head1 NAME

ShipIt::Step::DistClean - ShipIt step for cleaning the distribution

=head1 SYNOPSIS

None.

=head1 DESCRIPTION

This step effectively runs C<make distclean>, or the equivalent in your build
process.

I use it as the last step in the C<.shipit> file.

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

