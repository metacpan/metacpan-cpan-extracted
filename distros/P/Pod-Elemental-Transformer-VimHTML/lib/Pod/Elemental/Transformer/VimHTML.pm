package Pod::Elemental::Transformer::VimHTML 0.093583;
use Moose;
with 'Pod::Elemental::Transformer::SynHi';
# ABSTRACT: convert "=begin vim" regions to colorized XHTML with Vim

#pod =head1 DESCRIPTION
#pod
#pod This transformer, based on L<Pod::Elemental::Transformer::SynHi>, looks for
#pod regions like this:
#pod
#pod   =begin vim lisp
#pod
#pod     (map (stuff (lisp-has-lots-of '(,parens right))))
#pod
#pod   =end vim
#pod
#pod ...into syntax-highlighted HTML that I can't really usefully represent here.
#pod It uses L<Text::VimColor>, so you can read more about the kind of HTML it will
#pod produce, there.  The parameter after "=begin vim" is used as the filetype.
#pod
#pod This form is also accepted, in a verbatim paragraph:
#pod
#pod   #!vim lisp
#pod   (map (stuff (lisp-has-lots-of '(,parens right))))
#pod
#pod In the above example, the shebang-like line will be stripped.  The filetype
#pod parameter is I<mandatory>.
#pod
#pod The C<format_name> attribute may be supplied during the construction of the
#pod transformer to look for a region other than C<vim>.
#pod
#pod =cut

use Encode ();
use Text::VimColor;

has '+format_name' => (default => 'vim');

sub build_html {
  my ($self, $str, $param) = @_;

  my $octets = Encode::encode('utf-8', $str, Encode::FB_CROAK);

  my $vim = Text::VimColor->new(
    string   => $octets,
    filetype => $param->{filetype},

    vim_options => [
      qw( -RXZ -i NONE -u NONE -N -n ), "+set nomodeline", '+set fenc=utf-8',
    ],
  );

  my $html_bytes = $vim->html;
  my $html = Encode::decode('utf-8', $html_bytes);

  return $html;
}

sub parse_synhi_param {
  my ($self, $str) = @_;

  my @opts = split /\s+/, $str;

  confess "no filetype provided for VimHTML region" unless @opts;

  confess "illegal VimHTML region parameter: $str"
    unless @opts == 1 and $opts[0] !~ /:/;

  return { filetype => $opts[0] };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Transformer::VimHTML - convert "=begin vim" regions to colorized XHTML with Vim

=head1 VERSION

version 0.093583

=head1 DESCRIPTION

This transformer, based on L<Pod::Elemental::Transformer::SynHi>, looks for
regions like this:

  =begin vim lisp

    (map (stuff (lisp-has-lots-of '(,parens right))))

  =end vim

...into syntax-highlighted HTML that I can't really usefully represent here.
It uses L<Text::VimColor>, so you can read more about the kind of HTML it will
produce, there.  The parameter after "=begin vim" is used as the filetype.

This form is also accepted, in a verbatim paragraph:

  #!vim lisp
  (map (stuff (lisp-has-lots-of '(,parens right))))

In the above example, the shebang-like line will be stripped.  The filetype
parameter is I<mandatory>.

The C<format_name> attribute may be supplied during the construction of the
transformer to look for a region other than C<vim>.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
