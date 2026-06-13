use v5.40.0;
use common::sense;
use feature 'signatures';

use Test::More;
use lib 'lib';
use Mojo::PrettyTidy;

sub tidy_with ( $input, %args ) {
  return Mojo::PrettyTidy->new( %args )->tidy( $input );
}

subtest 'columns packs long style attributes' => sub {
  my $input = <<'HTML';
<div style=" position:absolute; top:6%; left:50%; transform:translateX(-50%); width:min(1100px, 92vw); max-height:88vh; overflow:auto; background:#151515; color:#eee; border:1px solid #333; border-radius:12px; box-shadow:0 18px 60px rgba(0,0,0,.6); padding:14px; font-family: system-ui, -apple-system, sans-serif;"></div>
HTML

  my $out = tidy_with( $input, columns => 80 );

  like( $out,
        qr/style="position:absolute;.*\n\s+\S/s,
        'style attribute is split across lines when over columns', );

  like( $out, qr/top:6%;/, 'style declarations are preserved', );

  like( $out,
        qr/font-family: system-ui, -apple-system, sans-serif;"/,
        'final style declaration and quote are preserved', );

  unlike( $out, qr/style="\s/,
          'leading whitespace inside style value is normalized', );
};

subtest 'no columns leaves long style value inline after attrib formatting' =>
    sub {
  my $input = <<'HTML';
<div style="position:absolute; top:6%; left:50%; transform:translateX(-50%); width:min(1100px, 92vw); max-height:88vh; overflow:auto; background:#151515; color:#eee; border:1px solid #333; border-radius:12px; box-shadow:0 18px 60px rgba(0,0,0,.6); padding:14px; font-family: system-ui, -apple-system, sans-serif;"></div>
HTML

  my $out = tidy_with( $input, columns => 0 );

  like(
    $out,
qr/style="position:absolute; top:6%; left:50%; transform:translateX\(-50%\); width:min\(1100px, 92vw\);/s,
    'style value remains inline when columns are disabled', );

  unlike( $out,
          qr/style="position:absolute;\n/,
          'style value is not column-packed when columns are disabled', );
    };

subtest 'svg path d attribute is not column-wrapped' => sub {
  my $input = <<'HTML';
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 480 512"><path fill="currentColor" d="M433 179.11c0-97.2-63.71-125.7-63.71-125.7c-62.52-28.7-228.56-28.4-290.48 0c0 0-63.72 28.5-63.72 125.7c0 115.7-6.6 259.4 105.63 289.1c40.51 10.7 75.32 13 103.33 11.4c50.81-2.8 79.32-18.1 79.32-18.1l-1.7-36.9s-36.31 11.4-77.12 10.1c-40.41-1.4-83-4.4-89.63-54a102.54 102.54 0 0 1-.9-13.9c85.63 20.9 158.65 9.1 178.75 6.7c56.12-6.7 105-41.3 111.23-72.9c9.8-49.8 9-121.5 9-121.5z"/></svg>
HTML

  my $out = tidy_with( $input, columns => 80 );

  like( $out,
        qr/d="M433 179\.11c0-97\.2-63\.71-125\.7/s,
        'path d attribute is preserved', );

  unlike( $out,
          qr/d="M433 179\.11c0-97\.2-\n/,
          'path d attribute is not wrapped by columns', );
};

subtest 'quoted html-ish attribute payload is preserved' => sub {
  my $input = <<'HTML';
<tr data-bs-toggle="tooltip" data-bs-placement="left" data-bs-html="true" data-bs-title="<b>Regex:</b><code><%= $regex %></code>"><td><span>Regex</span></td></tr>
HTML

  my $out = tidy_with( $input, columns => 80 );

  like( $out,
        qr/data-bs-title="<b>Regex:<\/b><code><%= \$regex %><\/code>"/,
        'html-ish quoted attribute value is preserved', );

  unlike( $out,
          qr/data-bs-title="<b>Regex:<\/b>\s*\n\s*<code>/,
          'html-ish quoted attribute value is not split internally', );
};

done_testing;
