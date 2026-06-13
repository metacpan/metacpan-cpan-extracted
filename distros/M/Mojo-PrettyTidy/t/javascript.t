use v5.40.0;
use common::sense;
use feature 'signatures';

use Test::More;
use lib 'lib';
use Mojo::PrettyTidy;

sub tidy_js ( $body, %args ) {
  my $input = "<script>\n$body\n</script>\n";
  return Mojo::PrettyTidy->new( %args )->tidy( $input );
}

sub compact_js ( $text ) {
  my $x = $text;
  $x =~ s{<script\b[^>]*>}{}gi;
  $x =~ s{</script>}{}gi;
  $x =~ s{<!--.*?-->}{}gs;
  $x =~ s{\s+}{ }g;
  $x =~ s{^\s+}{};
  $x =~ s{\s+\z}{};
  return $x;
}

subtest 'script tags are isolated and formatted blocks get a warning' => sub {
  my $out = tidy_js( 'const x=1;const y=2;' );

  like $out, qr/<script>\n/,   'script opener is on its own line';
  like $out, qr/\n<\/script>/, 'script closer is on its own line';
  like $out, qr/rerun with --javascript=off/,
      'changed JavaScript block gets warning';

  like $out, qr/const x\s*=\s*1;\s*const y\s*=\s*2;/s,
      'simple statements are split/formatted';
};
subtest 'line comments do not swallow following code' => sub {
  my $js = join "\n",
      "// wire Add form const f = document.getElementById('vmAddForm');
  f.querySelector('input[name=\"ih\"]').value = ih;m.style.display = 'block';",
      '';

  my $out = tidy_js( $js );

  like( $out,
        qr{// wire Add form\s*\n\s*const f},
        'comment is split before const statement', );

  ok( index( $out, "const f = document.getElementById('vmAddForm');" ) >= 0,
      'const statement survives', );

  ok( index( $out, q{f.querySelector('input[name="ih"]').value = ih;} ) >= 0,
      'querySelector assignment survives', );

  ok( index( $out, q{m.style.display = 'block';} ) >= 0,
      'display assignment survives', );

  like( $out,
        qr/value = ih;\s*\n\s*m\.style\.display/,
        'method-chain statements are split after semicolons', );

  unlike( $out,
          qr{// wire Add form const f},
          'comment/code glued form does not survive', );
};
subtest 'textContent ternary assignments split after assignment operator' =>
    sub {
  my $js = join "\n",
"document.getElementById('vmTitle').textContent = (j.name && j.name.trim()) ?
  j.name : '(no name)';",
"document.getElementById('vmMeta').textContent = (j.ih || ih) + (j.source_path
  ? '  |  ' + j.source_path : '');", '';

  my $out = tidy_js( $js );

  like( $out,
        qr/document\.getElementById\('vmTitle'\)\.textContent\s*=\s*\n\s*\(/,
        'title textContent assignment breaks after =', );

  ok( index( $out, "(j.name && j.name.trim()) ? j.name : '(no name)';" ) >= 0,
      'title ternary expression survives', );

  like( $out,
        qr/document\.getElementById\('vmMeta'\)\.textContent\s*=\s*\n\s*\(/,
        'meta textContent assignment breaks after =', );

  ok(
      index( $out,
             "(j.ih || ih) + (j.source_path ? '  |  ' + j.source_path : '');" )
          >= 0,
      'meta ternary expression survives', );
    };

subtest 'script tags with src are not treated as inline JavaScript bodies' =>
    sub {
  my $input = '<script src="/app.js"></script><div>after</div>';
  my $out   = Mojo::PrettyTidy->new->tidy( $input );

  like $out, qr!<script src="/app\.js">\s*</script>!s,
      'script src tag survives';
  unlike $out, qr/rerun with --javascript=off/,
      'external script tag does not get JavaScript reformat warning';
    };

done_testing;
