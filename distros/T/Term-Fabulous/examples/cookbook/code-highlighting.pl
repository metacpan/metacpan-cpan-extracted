#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Clay::XS qw(sizing_grow);
use Term::Fabulous;
use Term::Fabulous::Document;
use Term::Fabulous::Widget::DocumentView;

# The styles of the kinds of token, and for each language a pattern
# that finds its tokens, one named group per kind.
my %STYLE_OF = (
	comment  => 'italic #7f848e',
	string   => '#98c379',
	variable => '#e06c75',
	keyword  => 'bold #c678dd',
	command  => 'bold #61afef',
	option   => '#d19a66',
	key      => '#e06c75',
);
my %TOKENS_OF = (
	perl => qr{
		  (?<comment>  \#.* )
		| (?<string>   "(?:[^"\\]|\\.)*" | '(?:[^'\\]|\\.)*' )
		| (?<variable> [\$\@%][\w:]+ )
		| (?<keyword>  \b(?:my|our|use|sub|return|if|unless|foreach|while|or|and|die)\b )
	}x,
	shell => qr{
		  (?<comment> \#.* )
		| (?<option>  (?<=\s) --?[\w-]+ )
		| (?<command> ^\w[\w-]* )
	}xm,
	ini => qr{
		  (?<comment> ^\s*\#.* )
		| (?<key>     ^\w+ (?=\s*=) )
	}xm,
);

# A highlighter gets the code of a block and its language, and returns
# spans [ start, end, style ] of character offsets into the code.
sub highlight ( $code, $language ) {
	my $tokens = $TOKENS_OF{ $language // '' } or return [];
	my @spans;
	while ( $code =~ /$tokens/g ) {
		my ($kind) = keys %+;
		push @spans, [ $-[0], $+[0], $STYLE_OF{$kind} ];
	}
	return \@spans;
}

# The code items name the language a highlighter gets. A parser takes
# the language from the source, such as the word after ``` in Markdown.
my $document = Term::Fabulous::Document->new;
$document->heading( 2, 'Highlighted code' );
$document->paragraph('Each code block names its language, and the highlighter colors its tokens. Left and Right scroll all code blocks sideways together.');
$document->code( <<'PERL' =~ s/\n\z//r, language => 'perl' );
#!/usr/bin/env perl
use v5.32;
use warnings;

my ($backup) = @ARGV or die "usage: $0 BACKUP-DIRECTORY\n";
say "snapback: new backup in $backup";    # a long comment that runs past the right edge of the view, to scroll to
PERL
$document->code( <<'SHELL' =~ s/\n\z//r, language => 'shell' );
snapback --dry-run ~/Documents /mnt/backup    # lists, copies nothing
SHELL
$document->code( <<'INI' =~ s/\n\z//r, language => 'ini' );
# ~/.snapback
target = /mnt/backup
keep   = 14
INI

my $view = Term::Fabulous::Widget::DocumentView->new(
	id          => 'code',
	document    => $document,
	highlighter => \&highlight,
	layout      => { sizing => { width => sizing_grow(), height => sizing_grow() }, padding => { left => 1, right => 1 } },
);

my $ui = Term::Fabulous->new( root => $view, width => 80, height => 24 );
$ui->interaction->set_focused_widget($view);
$ui->run;
