use v5.12.0;
package Pod::Elemental::Transformer::Codebox 0.101001;
# ABSTRACT: convert "=begin code" regions to SynHi boxes with no colorization

use Moose;
with 'Pod::Elemental::Transformer::SynHi';

#pod =head1 DESCRIPTION
#pod
#pod This transformer looks for regions like this:
#pod
#pod   =begin code
#pod
#pod     (map (stuff (lisp-has-lots-of '(,parens right))))
#pod
#pod   =end code
#pod
#pod ...and translates them into code blocks using
#pod L<Pod::Elemental::Transformer::SynHi>, but without actually considering the
#pod syntax of the included code.  It just gets the code listing box treatment.
#pod
#pod This form is also accepted, in a verbatim paragraph:
#pod
#pod   #!code
#pod   (map (stuff (lisp-has-lots-of '(,parens m-i-right))))
#pod
#pod In the above example, the shebang-like line will be stripped.
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod * L<Pod::Elemental::Transformer::SynHi>
#pod
#pod =cut

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

version 0.101001

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

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 SEE ALSO

=over 4

=item *

L<Pod::Elemental::Transformer::SynHi>

=back

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
