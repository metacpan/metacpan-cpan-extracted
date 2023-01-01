use 5.012;
package Pod::Elemental::Transformer::PPIHTML 0.093582;
use Moose;
with 'Pod::Elemental::Transformer::SynHi';
# ABSTRACT: convert "=begin perl" and shebang-marked blocks to XHTML

use utf8;
use PPI;
use PPI::HTML;

#pod =head1 DESCRIPTION
#pod
#pod This transformer, based on L<Pod::Elemental::Transformer::SynHi>, looks for
#pod regions like this:
#pod
#pod   =begin perl
#pod
#pod     my $x = 1_00_000 ** $::xyzzy;
#pod
#pod   =end perl
#pod
#pod ...into syntax-highlighted HTML that I can't really usefully represent here.
#pod It uses L<PPI::HTML>, so you can read more about the kind of HTML it will
#pod produce, there.
#pod
#pod This form is also accepted, in a verbatim paragraph:
#pod
#pod   #!perl
#pod   my $x = 1_00_000 ** $::xyzzy;
#pod
#pod In the above example, the shebang-like line will be stripped.
#pod
#pod The C<format_name> attribute may be supplied during the construction of the
#pod transformer to look for a region other than C<perl>.
#pod
#pod =cut

has '+format_name' => (default => 'perl');

sub build_html {
  my ($self, $perl, $param) = @_;

  my $ppi_doc = PPI::Document->new(\$perl);
  my $ppihtml = PPI::HTML->new;
  my $html    = $ppihtml->html( $ppi_doc );

  $param->{'stupid-hyphen'} and s/-/−/g for $html;

  $html =~ s/<br>\n?/\n/g;

  return $html;
}

sub parse_synhi_param {
  my ($self, $str) = @_;

  my @keys = split /\s+/, $str;
  return {} unless @keys;

  confess "couldn't parse PPIHTML region parameter"
    if @keys > 1 or $keys[0] ne 'stupid-hyphen';

  return { 'stupid-hyphen' => 1 };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Transformer::PPIHTML - convert "=begin perl" and shebang-marked blocks to XHTML

=head1 VERSION

version 0.093582

=head1 DESCRIPTION

This transformer, based on L<Pod::Elemental::Transformer::SynHi>, looks for
regions like this:

  =begin perl

    my $x = 1_00_000 ** $::xyzzy;

  =end perl

...into syntax-highlighted HTML that I can't really usefully represent here.
It uses L<PPI::HTML>, so you can read more about the kind of HTML it will
produce, there.

This form is also accepted, in a verbatim paragraph:

  #!perl
  my $x = 1_00_000 ** $::xyzzy;

In the above example, the shebang-like line will be stripped.

The C<format_name> attribute may be supplied during the construction of the
transformer to look for a region other than C<perl>.

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
