use strict;
use Test::More;
use Test::Exception;
use Pandoc;

plan skip_all => 'pandoc executable required' unless pandoc;

my $latex = pandoc->convert('html' => 'latex', '<em>hällo</em>');
is $latex, '\emph{hällo}', 'html => latex';

my $html = pandoc->convert('markdown' => 'html', '...', '--smart');
is $html, '<p>…</p>', 'markdown => html';
is $html, "<p>\xE2\x80\xA6</p>", 'convert returns bytes'; 

utf8::decode($html);
my $markdown = pandoc->convert('html' => 'markdown', $html);
like $markdown, qr{^\x{2026}}, 'convert returns Unicode to Unicode'; 

throws_ok { pandoc->convert('latex' => 'html', '', '--template' => '') }
    qr/^pandoc: /, 'croak on error';

like pandoc->convert('latex' => 'html', '$\rightarrow$'), qr/→/, 'unicode';

done_testing;
