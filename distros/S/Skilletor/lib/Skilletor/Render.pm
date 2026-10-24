package Skilletor::Render;
# ABSTRACT: Build an item in memory – the copy half of the reference's render.ts

use strict;
use warnings;

use Carp qw( croak );
use Exporter qw( import );
use Path::Tiny qw( path );
use Skilletor::FSUtil qw( encode_text is_executable path_join path_normalize );

our $VERSION = '0.001';

our @EXPORT_OK = qw( build executables install_path templates_of );

# The item's Nunjucks templates: its files ending in `.njk`.
sub templates_of {
  my ( $item ) = @_;
  return grep { /\.njk\z/ } @{ $item->{files} };
}

# posix.relative for two normalized relative paths.
sub _relative {
  my ( $from, $to ) = @_;
  my @f = grep { length && $_ ne '.' } split m{/}, path_normalize($from);
  my @t = grep { length && $_ ne '.' } split m{/}, path_normalize($to);
  while ( @f && @t && $f[0] eq $t[0] ) { shift @f; shift @t }
  return join '/', ( map {'..'} @f ), @t;
}

# Where a source file of the item installs: a skill's files under `skills/<name>/`, an agent's or
# rule's under `agents/` or `rules/`, wherever the item's `dir` sits in the source. Without a
# `dir` the item lives where it installs.
sub install_path {
  my ( $item, $file ) = @_;
  return $file unless defined $item->{dir};
  my $into = $item->{type} eq 'skill' ? 'skills/'.$item->{name} : $item->{type}.'s';
  return path_join( $into, _relative( $item->{dir}, $file ) );
}

# The item's files, copied byte for byte: [ [ install path, bytes ], ... ] in the item's order.
# The Perl port renders nothing: an item with a `.njk` file is the caller's to refuse.
sub build {
  my ( $item, $source_dir ) = @_;
  my @tpl = templates_of($item);
  croak 'build: '.$item->{type}.' '.$item->{name}.' has templates ('.join( ', ', @tpl ).'); the Perl port renders none' if @tpl;
  return [ map { [ install_path( $item, $_ ), path( encode_text( path_join( $source_dir, $_ ) ) )->slurp_raw ] } @{ $item->{files} } ];
}

# The install paths of the item's files whose source file has the owner's executable bit.
sub executables {
  my ( $item, $source_dir ) = @_;
  my %out;
  for my $file ( @{ $item->{files} } ) {
    my @st = stat encode_text( path_join( $source_dir, $file ) );
    die 'stat '.path_join( $source_dir, $file ).': '.$!."\n" unless @st;
    next unless is_executable( $st[2] );
    $out{ install_path( $item, $file =~ s/\.njk\z//r ) } = 1;
  }
  return \%out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Render - Build an item in memory – the copy half of the reference's render.ts

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::Render qw( build executables templates_of );

  my $output = build( $catalog_item, $source_dir );       # [ [ 'skills/foo/SKILL.md', $bytes ], ... ]
  my $exec   = executables( $catalog_item, $source_dir );  # { 'skills/foo/run.sh' => 1 }

=head1 DESCRIPTION

The reference's C<render.ts> without Nunjucks (spec §5): every file of an item
is copied byte for byte to its install path – a skill's files under
C<< skills/<name>/ >>, an agent's or rule's under C<agents/> or C<rules/>,
wherever the item lies in its source – and a skill's files keep their source's
executable bit (k99).

The Perl port renders no templates. L</build> refuses an item with a C<.njk>
file; L<Skilletor::Engine> never asks it to, and leaves such an item as it is
installed (see L<Skilletor::Engine/Templates>).

=head2 build

  build( $item, $source_dir );

The item's output as an ordered list of C<[ install path, bytes ]>; croaks for
a templated item.

=head2 executables

  executables( $item, $source_dir );

The install paths, as a hash set, of the files whose source has the owner's
executable bit.

=head2 install_path

  install_path( $item, 'plugins/x/skills/foo/SKILL.md' );   # skills/foo/SKILL.md

=head2 templates_of

The item's C<.njk> files, relative to its source tree.

=head1 SUPPORT

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
