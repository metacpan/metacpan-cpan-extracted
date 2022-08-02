package Perl::Critic::Dancer2;
use Modern::Perl;
our $VERSION = '0.4100'; # VERSION
our $AUTHORITY = 'cpan:GEEKRUTH'; # AUTHORITY
# ABSTRACT: A collection of handy perlcritic modules for Dancer2
use Carp;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Dancer2 - A collection of handy perlcritic modules for Dancer2

=head1 VERSION

version 0.4100

=head1 SYNOPSIS

L<Perl::Critic> policies for use with L<Dancer2>.

=head1 DESCRIPTION

The included policies are:

=over

=item L<Perl::Critic::Policy::Dancer2::ProhibitDeprecatedKeywords>

Complains about usage of deprecated keywords [Default severity: 4] 

=item L<Perl::Critic::Policy::Dancer2::ProhibitUnrecommendedKeywords>

Complains about usage of unrecommended keywords [Default severity: 2]

=item L<Perl::Critic::Policy::Dancer2::ReturnNotNecessary>

Certain keywords immediately end execution of the route with an implicit
C<return>, so using C<return> before them is not necessary. [Default severity: 3]

=back

=head1 AFFILIATION

This module has no functionality, but instead contains documentation
for this distribution and acts as a means of pulling other modules
into a bundle.  All of the Policy modules contained herein will have
an B<AFFILIATION> section announcing their participation in this
grouping.

=head1 CONFIGURATION AND ENVIRONMENT

All policies included are in the C<dancer2> theme.  See the
L<Perl::Critic|Perl::Critic> documentation for how to make use of this.

=head1 ACKNOWLEDGEMENTS

Special thanks to L<Jason Crome|https://metacpan.org/author/CROMEDOME>, who
is always encouraging me to indulge and write tools like this one. And to
L<Sawyer X|https://metacpan.org/author/XSAWYERX>, who discussed the need for
such a module on a Dancer2 issue a loooooong time back, at
L<this GitHub issue|https://github.com/PerlDancer/Dancer2/issues/1263>.

=head1 SEE ALSO

=over 4

=item L<Perl::Critic>

=item L<Dancer2>

=back

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
