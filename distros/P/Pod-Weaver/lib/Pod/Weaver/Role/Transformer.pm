package Pod::Weaver::Role::Transformer;
# ABSTRACT: something that restructures a Pod5 document
$Pod::Weaver::Role::Transformer::VERSION = '4.017';
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

version 4.017

=head1 IMPLEMENTING

The Transformer role indicates that a plugin will be used to pre-process the input
hashref's Pod document before weaving begins.  The plugin must provide a
C<transform_document> method which will be called with the input Pod document.
It is expected to modify the input in place.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
