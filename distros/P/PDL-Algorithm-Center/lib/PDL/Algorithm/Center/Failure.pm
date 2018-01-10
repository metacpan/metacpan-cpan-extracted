package PDL::Algorithm::Center::Failure;

use strict;
use warnings;

our $VERSION = '0.06';

use custom::failures();

use Package::Stash;

use Exporter 'import';

our @EXPORT_OK;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

BEGIN {

    my @failures = qw<
      parameter
      iteration::limit_reached
      iteration::empty
    >;

    custom::failures->import( __PACKAGE__, @failures );

    my $stash = Package::Stash->new( __PACKAGE__ );

    for my $failure ( @failures ) {

        ( my $name = $failure ) =~ s/::/_/g;

        $name = "${name}_failure";

        $stash->add_symbol( "&$name", sub () { __PACKAGE__ . "::$failure" } );

        push @EXPORT_OK, $name;
    }

}

1;

__END__

=pod

=head1 NAME

PDL::Algorithm::Center::Failure

=head1 VERSION

version 0.06

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=PDL-Algorithm-Center>
or by email to
L<bug-PDL-Algorithm-Center@rt.cpan.org|mailto:bug-PDL-Algorithm-Center@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SOURCE

The development version is on github at L<https://github.com/djerius/pdl-algorithm-center>
and may be cloned from L<git://github.com/djerius/pdl-algorithm-center.git>

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<PDL::Algorithm::Center|PDL::Algorithm::Center>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
