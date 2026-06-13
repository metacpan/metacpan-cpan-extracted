use v5.40.0;
use common::sense;
use feature 'signatures';

use Test::More;
use lib 'lib';
use Mojo::PrettyTidy;

subtest 'perl formatting is enabled by default' => sub {
  my $input = <<'EP';
% if($ok){
<div>yes</div>
% }
EP

  my $out = Mojo::PrettyTidy->new->tidy( $input );

  like( $out,
        qr/^% if \( \$ok \) \{/m,
        'default run formats EP control line through perltidy', );

  unlike( $out,
          qr/^% if\(\$ok\)\{/m,
          'original tight EP control line is not preserved by default', );
};

subtest 'perl => 0 preserves EP code regions' => sub {
  my $input = <<'EP';
% if($ok){
<div>yes</div>
% }
EP

  my $out = Mojo::PrettyTidy->new( perl => 0 )->tidy( $input );

  like( $out,
        qr/^% if\(\$ok\)\{/m,
        'perl disabled preserves original EP control line', );

  unlike( $out,
          qr/^% if \( \$ok \) \{/m,
          'perl disabled does not apply perltidy spacing to EP control line', );

  like( $out, qr/<div>\s*yes\s*<\/div>/s,
        'non-Perl template content still survives', );
};

subtest 'perl toggle does not disable non-Perl formatting passes' => sub {
  my $input = <<'EP';
<a href="https://mojolicious.org" id="mojobar-brand" class="navbar-brand"><picture><img src="/logo.png" srcset="/logo-2x.png 2x"></picture></a>
EP

  my $out = Mojo::PrettyTidy->new( perl => 0 )->tidy( $input );

  like(
    $out,
qr/<a href="https:\/\/mojolicious\.org"\n\s+id="mojobar-brand"\n\s+class="navbar-brand">/,
    'attribute formatting still runs when perl formatting is disabled', );

  like(
    $out,
qr/<picture>\n\s+<img src="\/logo\.png"\n\s+srcset="\/logo-2x\.png 2x">\n\s+<\/picture>/,
    'HTML structural formatting still runs when perl formatting is disabled', );
};

done_testing;
