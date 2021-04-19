package Pod::Weaver::Role::Finalizer;
# ABSTRACT: something that goes back and finishes up after main weaving is over
$Pod::Weaver::Role::Finalizer::VERSION = '4.017';
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

version 4.017

=head1 IMPLEMENTING

The Finalizer role indicates that a plugin will be used to post-process the
output document hashref after section weaving is completed.  The plugin must
provide a C<finalize_document> method which will be called as follows:

  $finalizer_plugin->finalize_document($document, \%input);

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
