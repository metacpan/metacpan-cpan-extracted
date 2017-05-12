use v5.10.0;
package Pod::Elemental::Transformer::Codebox;
# ABSTRACT: convert "=begin code" regions to SynHi boxes with no colorization
$Pod::Elemental::Transformer::Codebox::VERSION = '0.101000';
use Moose;
with 'Pod::Elemental::Transformer::SynHi';

# =head1 DESCRIPTION
#
# This transformer looks for regions like this:
#
#   =begin code
#
#     (map (stuff (lisp-has-lots-of '(,parens right))))
#
#   =end code
#
# ...and translates them into code blocks using
# L<Pod::Elemental::Transformer::SynHi>, but without actually considering the
# syntax of the included code.  It just gets the code listing box treatment.
#
# This form is also accepted, in a verbatim paragraph:
#
#   #!code
#   (map (stuff (lisp-has-lots-of '(,parens m-i-right))))
#
# In the above example, the shebang-like line will be stripped.
#
# =head1 SEE ALSO
#
# =for :list
# * L<Pod::Elemental::Transformer::SynHi>
#
# =cut

use HTML::Entities ();

has '+format_name' => (default => 'code');

sub build_html {
  my ($self, $str, $param) = @_;

  return HTML::Entities::encode_entities($str);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Transformer::Codebox - convert "=begin code" regions to SynHi boxes with no colorization

=head1 VERSION

version 0.101000

=head1 DESCRIPTION

This transformer looks for regions like this:

  =begin code

    (map (stuff (lisp-has-lots-of '(,parens right))))

  =end code

...and translates them into code blocks using
L<Pod::Elemental::Transformer::SynHi>, but without actually considering the
syntax of the included code.  It just gets the code listing box treatment.

This form is also accepted, in a verbatim paragraph:

  #!code
  (map (stuff (lisp-has-lots-of '(,parens m-i-right))))

In the above example, the shebang-like line will be stripped.

=head1 SEE ALSO

=over 4

=item *

L<Pod::Elemental::Transformer::SynHi>

=back

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
