package Pod::Elemental::Element::Pod5::Verbatim;
# ABSTRACT: a Pod verbatim paragraph
$Pod::Elemental::Element::Pod5::Verbatim::VERSION = '0.103005';
use Moose;
extends 'Pod::Elemental::Element::Generic::Text';
with    'Pod::Elemental::Autoblank';
with    'Pod::Elemental::Autochomp';

# BEGIN Autochomp Replacement
use Pod::Elemental::Types qw(ChompedString);
has '+content' => (coerce => 1, isa => ChompedString);
# END   Autochomp Replacement

#pod =head1 OVERVIEW
#pod
#pod Pod5::Verbatim elements represent "verbatim" paragraphs of text.  These are
#pod ordinary, flat paragraphs of text that were indented in the source Pod to
#pod indicate that they should be represented verbatim in formatted output.  The
#pod following paragraph is a verbatim paragraph:
#pod
#pod   This is a verbatim
#pod       paragraph
#pod          right here.
#pod
#pod =cut

use namespace::autoclean;

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Element::Pod5::Verbatim - a Pod verbatim paragraph

=head1 VERSION

version 0.103005

=head1 OVERVIEW

Pod5::Verbatim elements represent "verbatim" paragraphs of text.  These are
ordinary, flat paragraphs of text that were indented in the source Pod to
indicate that they should be represented verbatim in formatted output.  The
following paragraph is a verbatim paragraph:

  This is a verbatim
      paragraph
         right here.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
