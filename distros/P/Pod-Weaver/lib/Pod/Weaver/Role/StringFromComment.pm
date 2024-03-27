package Pod::Weaver::Role::StringFromComment 4.020;
# ABSTRACT: Extract a string from a specially formatted comment

use Moose::Role;

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use namespace::autoclean;

#pod =head1 OVERVIEW
#pod
#pod This role assists L<Pod::Weaver sections|Pod::Weaver::Role::Section> by
#pod allowing them to pull strings from the source comments formatted like:
#pod
#pod     # KEYNAME: Some string...
#pod
#pod This is probably the most familiar to people using lines like the following to
#pod allow the L<Name section|Pod::Weaver::Section::Name> to determine a module's
#pod abstract:
#pod
#pod     # ABSTRACT: Provides the HypnoToad with mind-control powers
#pod
#pod It will extract these strings by inspecting the C<ppi_document> which
#pod must be given.
#pod
#pod =head1 PRIVATE METHODS
#pod
#pod This role supplies only methods meant to be used internally by its consumer.
#pod
#pod =head2 _extract_comment_content($ppi_doc, $key)
#pod
#pod Given a key, try to find a comment matching C<# $key:> in the C<$ppi_document>
#pod and return everything but the prefix.
#pod
#pod e.g., given a document with a comment in it of the form:
#pod
#pod     # ABSTRACT: Yada yada...
#pod
#pod ...and this is called...
#pod
#pod     $self->_extract_comment_content($ppi, 'ABSTRACT')
#pod
#pod ...it returns to us:
#pod
#pod     Yada yada...
#pod
#pod =cut

sub _extract_comment_content {
  my ($self, $ppi_document, $key) = @_;

  my $regex = qr/^\s*#+\s*$key:\s*(.+)$/m;

  my $content;
  my $finder = sub {
    my $node = $_[1];
    return 0 unless $node->isa('PPI::Token::Comment');
    if ( $node->content =~ $regex ) {
      $content = $1;
      return 1;
    }
    return 0;
  };

  $ppi_document->find_first($finder);

  return $content;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Role::StringFromComment - Extract a string from a specially formatted comment

=head1 VERSION

version 4.020

=head1 OVERVIEW

This role assists L<Pod::Weaver sections|Pod::Weaver::Role::Section> by
allowing them to pull strings from the source comments formatted like:

    # KEYNAME: Some string...

This is probably the most familiar to people using lines like the following to
allow the L<Name section|Pod::Weaver::Section::Name> to determine a module's
abstract:

    # ABSTRACT: Provides the HypnoToad with mind-control powers

It will extract these strings by inspecting the C<ppi_document> which
must be given.

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

=head1 PRIVATE METHODS

This role supplies only methods meant to be used internally by its consumer.

=head2 _extract_comment_content($ppi_doc, $key)

Given a key, try to find a comment matching C<# $key:> in the C<$ppi_document>
and return everything but the prefix.

e.g., given a document with a comment in it of the form:

    # ABSTRACT: Yada yada...

...and this is called...

    $self->_extract_comment_content($ppi, 'ABSTRACT')

...it returns to us:

    Yada yada...

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
