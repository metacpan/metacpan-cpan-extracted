package Pod::Weaver::Role::Section 4.020;
# ABSTRACT: a plugin that will get a section into a woven document

use Moose::Role;
with 'Pod::Weaver::Role::Plugin';

use namespace::autoclean;

#pod =head1 IMPLEMENTING
#pod
#pod This role is used by plugins that will append sections to the output document.
#pod They must provide a method, C<weave_section> which will be invoked like this:
#pod
#pod   $section_plugin->weave_section($output_document, \%input);
#pod
#pod They are expected to append their output to the output document, but they are
#pod free to behave differently if it's needed to do something really cool.
#pod
#pod =cut

requires 'weave_section';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Role::Section - a plugin that will get a section into a woven document

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

This role is used by plugins that will append sections to the output document.
They must provide a method, C<weave_section> which will be invoked like this:

  $section_plugin->weave_section($output_document, \%input);

They are expected to append their output to the output document, but they are
free to behave differently if it's needed to do something really cool.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
