package Pod::Weaver::Role::Finalizer 4.020;
# ABSTRACT: something that goes back and finishes up after main weaving is over

use Moose::Role;
with 'Pod::Weaver::Role::Plugin';

use namespace::autoclean;

#pod =head1 IMPLEMENTING
#pod
#pod The Finalizer role indicates that a plugin will be used to post-process the
#pod output document hashref after section weaving is completed.  The plugin must
#pod provide a C<finalize_document> method which will be called as follows:
#pod
#pod   $finalizer_plugin->finalize_document($document, \%input);
#pod
#pod =cut

requires 'finalize_document';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Role::Finalizer - something that goes back and finishes up after main weaving is over

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

The Finalizer role indicates that a plugin will be used to post-process the
output document hashref after section weaving is completed.  The plugin must
provide a C<finalize_document> method which will be called as follows:

  $finalizer_plugin->finalize_document($document, \%input);

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
