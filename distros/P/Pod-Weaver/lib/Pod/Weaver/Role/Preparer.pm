package Pod::Weaver::Role::Preparer 4.018;
# ABSTRACT: something that mucks about with the input before weaving begins

use Moose::Role;
with 'Pod::Weaver::Role::Plugin';

use namespace::autoclean;

#pod =head1 IMPLEMENTING
#pod
#pod The Preparer role indicates that a plugin will be used to pre-process the input
#pod hashref before weaving begins.  The plugin must provide a C<prepare_input>
#pod method which will be called with the input hashref.  It is expected to modify
#pod the input in place.
#pod
#pod =cut

requires 'prepare_input';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Role::Preparer - something that mucks about with the input before weaving begins

=head1 VERSION

version 4.018

=head1 PERL VERSION SUPPORT

This module has the same support period as perl itself:  it supports the two
most recent versions of perl.  (That is, if the most recently released version
is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 IMPLEMENTING

The Preparer role indicates that a plugin will be used to pre-process the input
hashref before weaving begins.  The plugin must provide a C<prepare_input>
method which will be called with the input hashref.  It is expected to modify
the input in place.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
