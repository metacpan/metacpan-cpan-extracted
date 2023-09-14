package Pod::CYOA::Transformer 0.004;
use Moose;
with 'Pod::Elemental::Transformer';
# ABSTRACT: transform 'cyoa' regions

#pod =head1 OVERVIEW
#pod
#pod Pod::CYOA::Transformer is a L<Pod::Elemental::Transformer> implementation.  It
#pod looks for a region with the format name C<cyoa> and transforms it into a
#pod C<=item>-list surrounded by C<html> regions.
#pod
#pod A C<cyoa> region is written with pairs of C<?>-separated values representing
#pod page links and descriptions.  For example:
#pod
#pod   =for :cyoa
#pod   ? pie-eating  ? eat a pie
#pod   ? start       ? start over
#pod   ? visit-lefty ? buy an "O"
#pod
#pod ...will become something like:
#pod
#pod   =for html
#pod   <div class='cyoa'>
#pod
#pod   =over 4
#pod
#pod   =item * If you'd like to L<eat a pie|@pie-eating>
#pod
#pod   =item * If you'd like to L<start over|@start>
#pod
#pod   =item * If you'd like to L<buy an "O"|@visit-lefty>
#pod
#pod   =back
#pod
#pod   =for html
#pod   </div>
#pod
#pod The C<@>-prefix on the link targets is expected to be handled by
#pod L<Pod::CYOA::XHTML>.
#pod
#pod =cut

use Pod::Elemental::Types qw(FormatName);

has format_name => (
  is  => 'ro',
  isa => FormatName,
  default => 'cyoa',
);

sub transform_node {
  my ($self, $node) = @_;

  for my $i (reverse(0 .. $#{ $node->children })) {
    my $para = $node->children->[ $i ];
    next unless $self->__is_xformable($para);

    my @replacements = $self->_expand_cyoa( $para );
    splice @{ $node->children }, $i, 1, @replacements;
  }
}

sub __is_xformable {
  my ($self, $para) = @_;

  return unless $para->isa('Pod::Elemental::Element::Pod5::Region')
         and $para->format_name eq $self->format_name;

  confess("CYOA regions must be non-pod (=begin " . $self->format_name . ")")
    if $para->is_pod;
  
  return 1;
}

sub _expand_cyoa {
  my ($self, $para) = @_;

  my ($data, @wtf) = @{ $para->children };
  confess "more than one child of a non-Pod region!" if @wtf;

  my @replacements;

  push @replacements, Pod::Elemental::Element::Pod5::Region->new({
    is_pod      => 0,
    format_name => 'html',
    content     => '',
    children    => [
      Pod::Elemental::Element::Pod5::Data->new({
        content => "<div class='cyoa'>",
      }),
    ],
  });

  push @replacements, Pod::Elemental::Element::Pod5::Command->new({
    command => 'over',
    content => 4,
  });

  my @lines = split /\n/, $data->as_pod_string;
  for my $line (@lines) {
    my ($link, $desc) = $line =~ /\A\?\s*([-a-z0-9]+)\s*\?\s*(.+)\z/;
    confess "do not understand CYOA line: $line" unless $link and $desc;

    push @replacements, Pod::Elemental::Element::Pod5::Command->new({
      command => 'item',
      content => '*',
    });

    push @replacements, Pod::Elemental::Element::Pod5::Ordinary->new({
      content => "If you'd like to L<$desc|\@$link>",
    });
  }

  push @replacements, Pod::Elemental::Element::Pod5::Command->new({
    command => 'back',
    content => '',
  });

  push @replacements, Pod::Elemental::Element::Pod5::Region->new({
    is_pod      => 0,
    format_name => 'html',
    content     => '',
    children    => [
      Pod::Elemental::Element::Pod5::Data->new({
        content => "</div>",
      }),
    ],
  });

  return @replacements;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::CYOA::Transformer - transform 'cyoa' regions

=head1 VERSION

version 0.004

=head1 OVERVIEW

Pod::CYOA::Transformer is a L<Pod::Elemental::Transformer> implementation.  It
looks for a region with the format name C<cyoa> and transforms it into a
C<=item>-list surrounded by C<html> regions.

A C<cyoa> region is written with pairs of C<?>-separated values representing
page links and descriptions.  For example:

  =for :cyoa
  ? pie-eating  ? eat a pie
  ? start       ? start over
  ? visit-lefty ? buy an "O"

...will become something like:

  =for html
  <div class='cyoa'>

  =over 4

  =item * If you'd like to L<eat a pie|@pie-eating>

  =item * If you'd like to L<start over|@start>

  =item * If you'd like to L<buy an "O"|@visit-lefty>

  =back

  =for html
  </div>

The C<@>-prefix on the link targets is expected to be handled by
L<Pod::CYOA::XHTML>.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
