package Pod::CYOA::Transformer;
{
  $Pod::CYOA::Transformer::VERSION = '0.002';
}
use Moose;
with 'Pod::Elemental::Transformer';
# ABSTRACT: transform 'cyoa' regions


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

=head1 NAME

Pod::CYOA::Transformer - transform 'cyoa' regions

=head1 VERSION

version 0.002

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

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
