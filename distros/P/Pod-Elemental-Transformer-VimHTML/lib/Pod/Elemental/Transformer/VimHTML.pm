package Pod::Elemental::Transformer::VimHTML;
{
  $Pod::Elemental::Transformer::VimHTML::VERSION = '0.093582';
}
use Moose;
with 'Pod::Elemental::Transformer::SynHi';
# ABSTRACT: convert "=begin vim" regions to colorized XHTML with Vim


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

=head1 NAME

Pod::Elemental::Transformer::VimHTML - convert "=begin vim" regions to colorized XHTML with Vim

=head1 VERSION

version 0.093582

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

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
