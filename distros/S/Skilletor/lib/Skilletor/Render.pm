package Skilletor::Render;
# ABSTRACT: Build an item in memory – the reference's render.ts

use strict;
use warnings;

use Exporter qw( import );
use JSON::MaybeXS ();
use Path::Tiny qw( path );
use Scalar::Util qw( blessed );
use Skilletor::Error::Render;
use Skilletor::FSUtil qw( decode_utf8_lossy encode_text is_executable path_join path_normalize );
use Skilletor::JSON qw( js_sort_keys );
use Skilletor::JSString qw( js_ws_re );

our $VERSION = '0.008000';

our @EXPORT_OK = qw( build executables install_path renders_empty templates_of );

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

# The reference's Nunjucks environment: the loader confined to the source root, autoescape off
# (Markdown), throwOnUndefined on (a typo must not silently produce an empty skill). Text::Nunjucks
# is loaded with the first template, so an item without one never pays for it.
sub _env {
  my ( $source_dir ) = @_;
  require Text::Nunjucks::Environment;
  require Skilletor::Render::Loader;
  return Text::Nunjucks::Environment->new( Skilletor::Render::Loader->new( root => $source_dir ),
    { autoescape => !!0, throwOnUndefined => !!1 } );
}

# A value of the port's JSON model as the template sees it in the reference (Text::Nunjucks takes
# Perl 5.40's value kinds): a JSON null is Nunjucks' null, a JSON::MaybeXS boolean a core one, an
# object a Hash::Ordered in its property order.
sub _template_value {
  my ( $v ) = @_;
  return Text::Nunjucks::Runtime->None unless defined $v;
  return $v ? !!1 : !!0 if JSON::MaybeXS::is_bool($v);
  my $ref = ref $v;
  return [ map { _template_value($_) } @$v ] if $ref eq 'ARRAY';
  if ( $ref eq 'HASH' ) {
    my $h = Hash::Ordered->new;
    $h->set( $_ => _template_value( $v->{$_} ) ) for tied %$v ? keys %$v : js_sort_keys( keys %$v );
    return $h;
  }
  return $v;
}

# The render context (spec §5): every field but an undefined one (`project` in the user scope).
sub _template_context {
  my ( $context ) = @_;
  require Hash::Ordered;
  return { map { defined $context->{$_} ? ( $_ => _template_value( $context->{$_} ) ) : () } keys %$context };
}

sub _message {
  my ( $err ) = @_;
  my $message = blessed $err && $err->can('message')
    ? $err->message
    : ( "$err" =~ s/ at \S+ line \d+\.?\n?\z//r );
  # Text::Nunjucks repeats the root template around this parser error in an include; Nunjucks
  # reports that root once, then the included template. Keep the public RenderError byte-identical.
  $message =~ s/\A(\([^\n]+\))\n\s*Template render error: \1\n/$1\n/
    if $message =~ /\n\s*unexpected token: %}\z/;
  return $message;
}

# The item's output: [ [ install path, bytes ], ... ] in the item's order. `X.njk` is rendered and
# installed as `X`, encoded as UTF-8; every other file is copied byte for byte, so a skill that
# uses `{{ }}` itself stays intact.
sub build {
  my ( $item, $source_dir, $context ) = @_;
  my ( $env, $vars, $template_context, @out );
  for my $file ( @{ $item->{files} } ) {
    unless ( $file =~ /\.njk\z/ ) {
      push @out, [ install_path( $item, $file ), path( encode_text( path_join( $source_dir, $file ) ) )->slurp_raw ];
      next;
    }
    $env  //= _env($source_dir);
    $template_context //= ref $context eq 'CODE' ? $context->() : $context;
    $vars //= _template_context($template_context);
    my $rendered;
    unless ( eval { $rendered = $env->render( $file, $vars ); 1 } ) {
      my $err = $@;
      die $err if blessed $err && $err->isa('Skilletor::Error::Render');
      Skilletor::Error::Render->throw( $file.': '._message($err) );
    }
    push @out, [ install_path( $item, $file =~ s/\.njk\z//r ), encode_text($rendered) ];
  }
  return \@out;
}

# The install paths of the item's files whose source file has the owner's executable bit: a
# template passes its bit to what it renders.
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

# A leading YAML frontmatter block (after optional whitespace), closed by `---`: the reference's
# FRONTMATTER, with JavaScript's \s.
my $WS = js_ws_re();
my $FRONTMATTER = qr/\A$WS*---[ \t]*\r?\n(?:.*?\r?\n)?---[ \t]*(?:\r?\n|\z)/s;

# Does the item's main file render to nothing but whitespace once a leading frontmatter block is
# removed (spec §5)? Then the item does not apply here. A non-template main file is never empty.
sub renders_empty {
  my ( $item, $output ) = @_;
  my $src = $item->{type} eq 'skill'
    ? path_join( $item->{dir} // 'skills/'.$item->{name}, 'SKILL.md' )
    : path_join( $item->{dir} // $item->{type}.'s', $item->{name}.'.md' );
  my %files = map { ( $_ => 1 ) } @{ $item->{files} };
  return 0 if !$files{ $src.'.njk' } || $files{$src};
  my $want = install_path( $item, $src );
  my ($bytes) = map { $_->[1] } grep { $_->[0] eq $want } @$output;
  return 0 unless defined $bytes;
  ( my $text = decode_utf8_lossy($bytes) ) =~ s/$FRONTMATTER//;
  return $text =~ /\A$WS*\z/ ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Render - Build an item in memory – the reference's render.ts

=head1 VERSION

version 0.008000

=head1 SYNOPSIS

  use Skilletor::Render qw( build executables renders_empty templates_of );

  my $output = build( $catalog_item, $source_dir, $context );   # [ [ 'skills/foo/SKILL.md', $bytes ], ... ]
  my $exec   = executables( $catalog_item, $source_dir );        # { 'skills/foo/run.sh' => 1 }
  my $skip   = renders_empty( $catalog_item, $output );          # the item does not apply here

=head1 DESCRIPTION

The reference's C<render.ts> (spec §5): an item is built in memory. A file
C<X.njk> is rendered by Nunjucks – L<Text::Nunjucks>, the Perl port of
Nunjucks 3.2.4 the reference uses – and installed as C<X>; every other file is
copied byte for byte, so a skill that writes C<{{ }}> itself stays intact.
Each file goes to its install path – a skill's under C<< skills/<name>/ >>, an
agent's or rule's under C<agents/> or C<rules/>, wherever the item lies in its
source – and a skill's files keep their source's executable bit (k99), a
template passing its bit to what it renders.

A template renders as the reference's does: autoescape off, an undefined
variable an error, includes, imports and macros looked up relative to the
source root and confined to it (L<Skilletor::Render::Loader>), the source read
and the output written as UTF-8. A template that fails throws a
L<Skilletor::Error::Render> with the reference's message, C<< <file>: <the
Nunjucks message> >>.

=head2 build

  build( $item, $source_dir, $context );
  build( $item, $source_dir, sub { $context } );

The item's output as an ordered list of C<[ install path, bytes ]>. The
context remains the reference's C<RenderContext>, values as L<Skilletor::JSON>
reads them:
C<< { vars, project?, scope, harness, target => { dir }, host => { name, os },
user => { name, home }, item => { name, type, source } } >>. A JSON C<null> in
it is the template's C<null>, a missing field its C<undefined>; objects keep
their property order.

Alternatively, C<$context> may be a zero-argument C<CODE> reference. It is
evaluated at the first C<.njk> file only, including a companion template, and
its returned hash is cached for the build. An item with no C<.njk> files copies
without evaluating it. A supplier exception propagates directly; a template
rendering failure throws L<Skilletor::Error::Render>.

=head2 executables

  executables( $item, $source_dir );

The install paths, as a hash set, of the files whose source has the owner's
executable bit.

=head2 renders_empty

  renders_empty( $item, $output );

True when the item's main file (C<SKILL.md>, C<< <name>.md >>) is a template
whose output is whitespace only once a leading frontmatter block is removed:
the item does not apply in this scope (C<renders-empty>). False for a main
file that is no template.

=head2 install_path

  install_path( $item, 'plugins/x/skills/foo/SKILL.md' );   # skills/foo/SKILL.md

=head2 templates_of

The item's C<.njk> files, relative to its source tree.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/skilletor/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
