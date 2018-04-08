use strict;
use Test::More;
use Test::Exception;
use Pandoc;

plan skip_all => 'pandoc executable required' unless pandoc;

my $latex = pandoc->convert('html' => 'latex', '<em>hällo</em>');
is $latex, '\emph{hällo}', 'html => latex';

my @options = (pandoc->version < 2.0)
    ? ('markdown' => 'html', '...', '--smart')
    : ('markdown+smart' => 'html', '...');
my $html = pandoc->convert(@options);
is $html, '<p>…</p>', 'markdown => html';
is $html, "<p>\xE2\x80\xA6</p>", 'convert returns bytes'; 

utf8::decode($html);
my $format = pandoc->version < 2.0 ? 'markdown' : 'markdown-smart';
my $markdown = pandoc->convert('html' => $format, $html);
like $markdown, qr{^\x{2026}}, 'convert returns Unicode to Unicode'; 

throws_ok { pandoc->convert('latex' => 'html', '', '--template' => '') }
    qr/template/, 'croak on error';

like pandoc->convert('latex' => 'html', '$\rightarrow$'), qr/→/, 'unicode';

done_testing;
