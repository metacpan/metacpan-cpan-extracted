package Pod::Weaver::Role::Dialect 4.019;
# ABSTRACT: something that translates Pod subdialects to standard Pod5

use Moose::Role;
with 'Pod::Weaver::Role::Plugin';

use namespace::autoclean;

#pod =head1 IMPLEMENTING
#pod
#pod The Dialect role indicates that a plugin will be used to pre-process the input
#pod Pod document before weaving begins.  The plugin must provide a
#pod C<translate_dialect> method which will be called with the input hashref's
#pod C<pod_document> entry.  It is expected to modify the document in place.
#pod
#pod =cut

requires 'translate_dialect';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Role::Dialect - something that translates Pod subdialects to standard Pod5

=head1 VERSION

version 4.019

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 IMPLEMENTING

The Dialect role indicates that a plugin will be used to pre-process the input
Pod document before weaving begins.  The plugin must provide a
C<translate_dialect> method which will be called with the input hashref's
C<pod_document> entry.  It is expected to modify the document in place.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
