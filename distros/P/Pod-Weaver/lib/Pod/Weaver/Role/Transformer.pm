package Pod::Weaver::Role::Transformer 4.020;
# ABSTRACT: something that restructures a Pod5 document

use Moose::Role;
with 'Pod::Weaver::Role::Plugin';

use namespace::autoclean;

#pod =head1 IMPLEMENTING
#pod
#pod The Transformer role indicates that a plugin will be used to pre-process the input
#pod hashref's Pod document before weaving begins.  The plugin must provide a
#pod C<transform_document> method which will be called with the input Pod document.
#pod It is expected to modify the input in place.
#pod
#pod =cut

requires 'transform_document';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Role::Transformer - something that restructures a Pod5 document

=head1 VERSION

version 4.020

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 IMPLEMENTING

The Transformer role indicates that a plugin will be used to pre-process the input
hashref's Pod document before weaving begins.  The plugin must provide a
C<transform_document> method which will be called with the input Pod document.
It is expected to modify the input in place.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
