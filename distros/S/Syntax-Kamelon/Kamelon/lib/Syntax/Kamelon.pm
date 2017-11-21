package Syntax::Kamelon;

use strict;
use warnings;
use Carp;

# use AutoLoader;

use Syntax::Kamelon::Builder;
use Syntax::Kamelon::Indexer;
use Module::Load::Conditional qw[can_load];
use Data::Dumper;

our $VERSION = '0.15';

# sub AUTOLOAD {
#     # This AUTOLOAD is used to 'autoload' constants from the constant()
#     # XS function.
#     my $constname;
#     our $AUTOLOAD;
#     ($constname = $AUTOLOAD) =~ s/.*:://;
#     croak "&Syntax::Kamelon::constant not defined" if $constname eq 'constant';
#     my ($error, $val) = constant($constname);
#     if ($error) { croak $error; }
#     {
# 		no strict 'refs';
# 	    *$AUTOLOAD = sub { $val };
#     }
#     goto &$AUTOLOAD;
# }

my @attributes = qw (
	Alert
	Annotation
	Attribute
	BaseN
	BuiltIn
	Char
	Comment
	CommentVar
	Constant
	ControlFlow
	DataType
	DecVal
	Documentation
	Error
	Extension
	Float
	Function
	Import
	Information
	Keyword
	Normal
	Operator
	Others
	Preprocessor
	RegionMarker
	SpecialChar
	SpecialString
	String
	Variable
	VerbatimString 
	Warning
);

# require XSLoader;
# XSLoader::load('Syntax::Kamelon', $VERSION);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my %args = (@_);
	
	#catch indexer options
	my @iopts = qw(indexfile noindex xmlfolder);
	my %indexer = ();
	for (@iopts) {
		my $val = delete $args{$_};
		if (defined $val) {
			$indexer{$_} = $val;
		}
	}

 	my $format = delete $args{formatter};
	my $cmnds = delete $args{commands};
	my $logcall = delete $args{logcall};
	my $syntax = delete $args{syntax};
	my $verbose = delete $args{verbose};

	if (%args) {
		for (keys %args) {
			warn "unrecognized option: $_"
		}
	}
	my $self = {}; #forego XS routines for now.
# 	my $self = Syntax::Kamelon->new_kam();
	bless ($self, $class);

	unless (defined $cmnds) { $cmnds = {} }

	#this one must be defined before we configure the formatter
	$self->{INDEXER} = Syntax::Kamelon::Indexer->new(%indexer);
	#configure the formatter
	unless (defined($format)) { $format = ['Base'] }
	$self->InitFormatter($format);

	unless (defined $logcall) { $logcall = sub { print STDERR shift, "\n" } }
	unless (defined($syntax)) { $syntax = '' };
   unless (defined($verbose)) { $verbose = 0 };

	$self->{CAPTURED} = [];
	$self->{COMMANDS} = [];
	$self->{CURRENTLINE} = '';
	$self->{HLPOOL} = {};
	$self->{LOGCALL} = $logcall;
	$self->{LINENUMBER} = 1;
	$self->{LINESEGMENT} = '';
	$self->{OUT} = [];
	$self->{POSTCREATE} = [];
	$self->{PULLED} = 0;
	$self->{SNIPPET} = '';
	$self->{SNIPPETATTRIBUTE} = $self->Formatter->FormatTable('Normal');
	$self->{STACK} = [];
	$self->{SYNTAX} = $syntax;
	$self->{USEATTRIBSTACK} = [];
	$self->{VERBOSE} = $verbose;
	$self->Reset;

	return $self;
}

sub AvailableAttributes {
	my $self = shift;
	return @attributes
}

sub AvailableSyntaxes {
	my $self = shift;
	return $self->{INDEXER}->AvailableSyntaxes;
}

sub Capture {
	my $self = shift;
	my $c = $self->{CAPTURED};
	push @$c, @_;
}

sub CapturedGet {
	my ($self, $num) = @_;
	$num --;
	my $stack = $self->{STACK};
	if (defined $stack->[0]->[2]->[$num]) {
		return $stack->[0]->[2]->[$num];
	}
	return '';
}

sub CapturedParse {
	my ($self, $string) = @_;
	my $s = '';
	while ($string ne '') {
		if ($string =~ s/^([^\%]*)\%(\d)//) {
			my $r = $self->CapturedGet($2);
			if ($r ne '') {
				$s = $s . $1 . $r
			} else {
				$s = $s . $1 . '%' . $2;
				$self->LogWarning("Capture $2 not found");
			}
		} else {
			$string =~ s/^(.)//;
			$s = "$s$1";
		}
	}
	return $s;
}

sub CapturedParseC {
	my ($self, $string) = @_;
	if ($string =~ s/^(\d)//) {
		return $self->CapturedGet($1);
	}
	$self->LogWarning("Capture $string not found");
	return $string;
}

sub CapturedParseR {
	my ($self, $string) = @_;
	my $s = '';
	my @vn = (qw/a b c d e f g h/);
	my @out = ();
	my $num = 0;
	while ($string ne '') {
		if ($string =~ s/^([^\%]*)\%(\d)//) {
			my $r = $self->CapturedGet($2);
			if ($r ne '') {
				push @out, $r;
				$s = $s . $1 . "\$" . $vn[$num];
			} else {
				$s = $s . $1 . '%' . $2;
				$self->LogWarning("Capture $2 not found");
			}
			$num ++;
		} else {
			$string =~ s/^(.)//;
			$s = "$s$1";
		}
	}
	return ($s, @out);
}

sub ClearLexers {
	my $self = shift;
	$self->{HLPOOL} = {}
}

sub Column {
	my $self = shift;
	my $l = length($self->{LINESEGMENT});
	return $l
}

sub CommandExecute {
	my ($self, $cmnd, $parse) = @_;
	my $c = $self->{COMMANDS};
	if (exists $c->{$cmnd}) {
		my $ref = $c->{$cmnd};
		my $call; 
		my @o = ($parse);
		if ($ref =~/ARRAY/) { #it is a method with an owner
			$call = $ref->[0];
			unshift @o, $ref->[1];
		} else { #it is an anonymous sub
			$call = $ref;
		}
		return &$call(@o);
	}
	$self->LogWarning("Command $cmnd not found");
	return $parse;
}

sub CurrentLine {
	my $self = shift;
	return $self->{CURRENTLINE};
}

sub FirstNonSpace {
	my ($self, $string) = @_;
	my $line = $self->{LINESEGMENT};
	if ($line eq '') { return 1 }
	if (($line =~ /^\s*$/) and ($string =~ /^[^\s]/)) {
		return 1
	}
	return ''
}

sub Format {
	my $self = shift;
	return $self->{FORMATTER}->Format;
}

sub Formatter {
	my $self = shift;
	return $self->{FORMATTER}
}

sub GetIndexer {
	my $self = shift;
	return $self->{INDEXER}
}

sub GetLexer {
	my ($self, $syntax) = @_;
	my $pool = $self->{HLPOOL};
	my $id = $self->{INDEXER};
	my $i = $id->{INDEX};

	if (exists $pool->{$syntax}) { #syntax definition is already loaded
		return $pool->{$syntax}
	} elsif (exists $i->{$syntax}) { #create the syntax definition
		my $file = $id->{XMLFOLDER} . '/' . $i->{$syntax}->{'file'};
		my $hl = Syntax::Kamelon::Builder->new(
			engine => $self,
			xmlfile => $file,
		);
 		$pool->{$syntax} = $hl;

 		#if the newly created syntax definition depends on others, they are loaded here
 		my $p = $self->{POSTCREATE};
 		while (@$p) {
			my $s = shift @$p;
			unless (exists $pool->{$s}) {
				$self->GetLexer($s)
			}
		}
		return $hl
	} else {
		$self->LogWarning("Syntax definition for '$syntax' not found");
	}
}

sub IncludeRules {
	my ($self, $text, $callbacklist, $debuginfo, $inclattr) = @_;
	$self->UseAttribStackPush($inclattr);
	my $r = $self->ParseContext(\$text, $callbacklist, $debuginfo);
	$self->UseAttribStackPull;
	return $r;
}

sub IncludeSyntax {
	my ($self, $text, $syntax, $context) = @_;
	my $hl = $self->GetLexer($syntax);
	if ($context eq '') {
		$context = $hl->{basecontext};
	}
	my $callbacklist = $hl->{contexts}->{$context}->{callbacks};
	my $debuginfo = $hl->{contexts}->{$context}->{debug};
	return $self->ParseContext($text, $callbacklist, $debuginfo);
}

sub IncludeSyntaxIA {
	my ($self, $text, $syntax, $context, $attr) = @_;
	my $hl = $self->GetLexer($syntax);
	if ($context eq '') {
		$context = $hl->{basecontext};
	}
	$self->UseAttribStackPush($attr);
	my $callbacklist = $hl->{contexts}->{$context}->{callbacks};
	my $debuginfo = $hl->{contexts}->{$context}->{debug};
	my $r = $self->ParseContext($text, $callbacklist, $debuginfo);
	$self->UseAttribStackPull;
	return $r;
}

sub InitFormatter {
   my ($self, $form) = @_;
   my @fopt = @$form;
   my $module = shift @fopt;
   $module = "Syntax::Kamelon::Format::$module";
	if (can_load(modules => {$module => 0})){
		$self->{FORMATTER} = $module->new($self, @fopt);
	} else {
		warn "unable to load formatter $module\n";
	}
}

sub IsDeliminator {
	my ($self, $char) = @_;
	my $deliminators = '\s|\~|\!|\%|\^|\&|\*|\+|\(|\)|-|=|\{|\}|\[|\]|:|;|<|>|,|\\|\||\.|\?|\/';
# 	my $deliminators = $self->deliminators;
	if ($char =~ /$deliminators/) { return 1 }
	return ''
}

sub LastcharBoundary {
	my $self = shift;
	my $l = $self->LastChar;
	return ($l =~ /\b/)
}

sub LastcharDeliminator {
	my $self = shift;
	if ($self->LineStart) { return 1 }
	return ($self->IsDeliminator($self->LastChar))
}

sub LastChar {
	my $self = shift;
	my $l = $self->{LINESEGMENT};
	if ($l eq '') { return "\n" } #last character was a newline
	return substr($l, length($l) - 1, 1);
}

sub LineNumber {
	my $self = shift;
	return $self->{LINENUMBER}
}

sub LineEndContext {
	my ($self, $shifter) = @_;
	$self->{PULLED} = 0;
	&$shifter;
	if ($self->{PULLED}) {
		my $top = $self->{STACK}->[0];
		my ($syn, $con) = @$top;
		my $shifter2 = $syn->{contexts}->{$con}->{endcontext};
		$self->LineEndContext($shifter2);
	}
}

sub LineStart {
	my $self = shift;
	return ($self->{LINESEGMENT} eq '')
}

sub LogCallGet {
	my $self = shift;
	return $self->{LOGCALL};
}

sub LogCallSet {
	my $self = shift;
	if (@_) { $self->{LOGCALL} = shift; }
}

sub LogWarning {
	my ($self, $warning) = @_;
	if ($self->{VERBOSE}) {
		my $top = $self->StackTop;
		if (defined $top) {
			my $lang = $top->[0]->{syntax};
			my $context = $top->[1];
			$warning = "Syntax: $lang, Context: $context, $warning\n";
		} else {
			$warning = "$warning\n  STACK IS EMPTY: PANIC\n"
		}
		my $call = $self->{LOGCALL};
		&$call($warning);
	}
}

sub Parse {
	my ($self, $text) = @_;
	$self->{SNIPPET} = '';
	my $form = $self->{FORMATTER};
	my $out = $self->{OUT};
	@$out = ();
	while ($text ne '') {
		if ($text =~ s/^([^\n]*\n)//) {
			$self->ParseLine($1);
			$self->SnippetForce;
			$form->Parse(@$out);
			@$out = ();
		} else {
			$self->ParseLine($text);
			$text = '';
			$self->SnippetForce;
			$form->Parse(@$out);
			@$out = ();
		}
	}
}

sub ParseLine {
	my ($self, $text) = @_;
	$self->{CURRENTLINE} = $text;
	while ($text ne '') {
		my $top = $self->{STACK}->[0];
		my ($hl, $context) = @$top;
		my $ctd = $hl->{contexts}->{$context};
		if ($text =~ s/^(\n)//) { #newline detected
			if ($self->LineStart) {
				my $m = $ctd->{emptycontext};
				&$m;
			}
			$self->SnippetForce;
			$self->LineEndContext($ctd->{endcontext});
# 			my $attr = $ctd->{attribute};
# 			$self->SnippetParse($1, $attr);
			$self->SnippetForce;
			$self->{LINESEGMENT} = '';
			$self->{LINENUMBER} = $self->{LINENUMBER} + 1;
		} else {
			my $callbacklist = $ctd->{callbacks};
			unless ($self->ParseContext(\$text, $callbacklist)) {
				my $f = $ctd->{fallthroughcontext};
				if (defined($f)) {
					&$f;
				} else {
					$text =~ s/^(.)//;
					my $attr = $self->{USEATTRIBSTACK}->[0];
					unless (defined $attr) {
						$attr = $ctd->{attribute};
					}
					$self->SnippetParse($1, $attr);
				}
			}
		}
	}
}

sub ParseContext {
	my ($self, $text, $callbacklist) = @_;
	my $r = 0;
	if ($self->StackTop->[1] ne 'aspsource') {
	}
	for (@$callbacklist) {
		my @i = @$_;
		my $call = shift @i;
		return 1 if &$call($self, $text, @i);
	}
	return '';
}

sub ParseRaw {
	my ($self, $text) = @_;
	$self->{SNIPPET} = '';
	my $out = $self->{OUT};
	@$out = ();
# 	my $call = $modecalls{$self->{MODE}};
	while ($text ne '') {
		if ($text =~ s/^([^\n]+\n)//) {
# 			&$call($self, $1);
			$self->ParseLine($1);
		} else {
# 			&$call($self, $text);
			$self->ParseLine($text);
			$text = ''
		}
	}
	$self->SnippetForce;
	return @$out;
}

sub ParseResult {
	my ($self, $text, $string, $context, $attr) = @_;
	$$text = substr($$text, length($string));
	unless (defined($attr)) {
		my $t = $self->{STACK}->[0];
		my ($thl, $ctext) = @$t;
		$attr = $thl->{contexts}->{$ctext}->{attribute};
	}
	$self->SnippetParse($string, $attr);
	&$context;
	return 1
}

sub ParseResultChained {
	my ($self, $text, $string, $context, $attr) = @_;
	$$text = substr($$text, length($string));
	unless (defined($attr)) {
		my $t = $self->{STACK}->[0];
		my ($thl, $ctext) = @$t;
		$attr = $thl->{contexts}->{$ctext}->{attribute};
	}
	$self->SnippetParse($string, $attr);
	&$context;
	my $parser = pop @_;
	return &$parser($self, $text, $string, @_);
}

sub ParseResultCommand {
	my $self = shift;
	my $text = shift;
	my $match = shift;
	my $cmnd = pop @_;
	$match = $self->CommandExecute($cmnd, $match);
	my $parser = pop @_;
	return &$parser($self, $text, $match, @_);
}

sub ParseResultLookAhead {
	my ($self, $text, $string, $context, $attr) = @_;
	&$context;
	return 1
}

sub ParseResultChainedLookAhead {
	my ($self, $text, $string, $context, $attr) = @_;
	&$context;
	my $parser = pop @_;
	return &$parser($self, $text, $string, @_);
}

sub ParseResultOverStrike {
	my $self = shift;
	my $text = shift;
	my $match = shift;
	my $ovr = pop @_;
	my $parser = pop @_;
	return &$parser->ParseResult($self, $text, substr($ovr, 0, length($match)), @_);
}

sub ParseResultBeginRegion {
	my $self = shift;
	my $region = pop @_;
	$self->{FORMATTER}->FoldBegin($region);
	my $parser = pop @_;
	return &$parser($self, @_);
}

sub ParseResultEndRegion {
	my $self = shift;
	my $region = pop @_;
	$self->{FORMATTER}->FoldEnd($region);
	my $parser = pop @_;
	return &$parser($self, @_);
}

sub ParseResultReplace {
	my $self = shift;
	my $text = shift;
	my $match = shift;
	my $replace = pop @_;
	my $parser = pop @_;
	return &$parser($self, $text, $replace, @_);
}

sub Reset {
	my $self = shift;
	my $lang = $self->Syntax;
	$self->{OUT} = [];
	$self->{SNIPPET} = '';
	$self->{LINESEGMENT} = '';
	my $linenumber = $self->Formatter->LineOffset;
	unless (defined $linenumber) { $linenumber = 1 }
	$self->{LINENUMBER} = $linenumber;
	$self->{FORMATTER}->Reset;
	if ($lang eq '') {
		$self->{STACK} = [];
	} else {
		my $hl = $self->GetLexer($lang);
		unless (defined $hl) {
			if ($self->Debug) {
				croak "Lexer for syntax '$lang' could not be created.";
			}
			$self->{STACK} = [];
			return
		}
		my $basecontext = $hl->{basecontext};
		$self->{STACK} = [
			[$hl, $basecontext]
		];
	}
}

sub SnippetForce {
	my $self = shift;
	my $parse = $self->{SNIPPET};
	if ($parse ne '') {
		my $out = $self->{OUT};
# 		push(@$out, [$parse, $self->{SNIPPETATTRIBUTE}, undef, undef]);
		push(@$out, $parse, $self->{SNIPPETATTRIBUTE});
		$self->{SNIPPET} = '';
	}
}

sub SnippetParse {
	my ($self, $snip, $attr) = @_;
	my $parse = $self->{SNIPPET};
	my $out = $self->{OUT};
	if ($attr ne $self->{SNIPPETATTRIBUTE}) {
		if ($parse ne '') {
			push(@$out, $parse, $self->{SNIPPETATTRIBUTE});
			$parse = '';
		}
		$self->{SNIPPETATTRIBUTE} = $attr;
	}
	$self->{SNIPPET} = $parse . $snip;
	$self->{LINESEGMENT} =  $self->{LINESEGMENT}  . $snip;
}

sub StackPush {
	my $self = shift;
	my $stack = $self->{STACK};
	unshift(@$stack, [@_, $self->{CAPTURED}]);
	$self->{CAPTURED} = [];
}

sub StackPull {
	my $self = shift;
	my $stack = $self->{STACK};
	if (@$stack > 1) {
		$self->{PULLED} = 1;
		return shift @$stack;
	} else {
		$self->LogWarning("Cannot #pop context, already at basecontext")
	}
}

sub StackTop {
	my $self = shift;
	return $self->{STACK}->[0];
}

sub StateCompare {
	my ($self, $state) = @_;
	my $h = [ $self->stateGet ];
	return (Dumper($h) eq Dumper($state));
}

sub StateGet {
	my $self = shift;
	my $s = $self->{STACK};
	return @$s;
}

sub StateSet {
	my $self = shift;
	my $s = $self->{STACK};
	@$s = (@_);
}

sub SuggestSyntax {
	my ($self, $file) = @_;
	my $hsh = $self->{INDEXER}->Extensions;
	foreach my $key (keys %$hsh) {
		my $reg = $key;
		$reg =~ s/\./\\./g;
		$reg =~ s/\+/\\+/g;
		$reg =~ s/\*/.*/g;
		$reg = "$reg\$";
		if ($file =~ /$reg/) {
			return $hsh->{$key}->[0]
		}
	}
	return undef;
}

sub Syntax {
	my $self = shift;
	if (@_) {
		$self->{SYNTAX} = shift;
		$self->Reset;
	}
	return $self->{SYNTAX};
}

sub testAnyChar {
	my $self = shift;
	my $text = shift;
	my $string = shift;
	my $test = substr($$text, 0, 1);
	if (index($string, $test) > -1) {
		my $parser = pop @_;
		&$parser($self, $text, $test, @_);
		return 1
	}
	return ''
}

sub testAnyCharI {
	my $self = shift;
	my $text = shift;
	my $string = shift;
	my $test = substr($$text, 0, 1);
	my $bck = $test;
	$test = lc($test);
	if (index($string, $test) > -1) {
		my $parser = pop @_;
		&$parser($self, $text, $bck, @_);
		return 1
	}
	return ''
}

sub testCommonColumn {
	my $self = shift;
	my $text = shift;
	my $column = shift;
	if ($column ne $self->Column) {
		return '';
	}
	my $next = shift;
	return &$next($self, $text, @_)
}

sub testCommonFirstNonSpace {
	my $self = shift;
	my $text = shift;
	unless ($self->FirstNonSpace($$text)) {
		return 0
	}
	my $next = shift;
	return &$next($self, $text, @_)
}

sub testCommonLastCharBB {
	my $self = shift;
	my $lastchar = $self->LastChar;
	unless ($lastchar =~ /\w/) { return '' }
	my $text = shift;
	my $next = shift;
	return &$next($self, $text, @_)
}

sub testCommonLastCharBb {
	my $self = shift;
	my $lastchar = $self->LastChar;
	if ($lastchar =~ /\w/) { return '' }
	my $text = shift;
	my $next = shift;
	return &$next($self, $text, @_)
}

sub testCommonLineStart {
	my $self = shift;
	my $text = shift;
	unless ($self->{LINESEGMENT} eq '') {
		return ''
	}
	my $next = shift;
	return &$next($self, $text, @_)
}

sub testDetectChar {
	my $self = shift;
	my $text = shift;
	my $char = shift; 
	my $test = substr($$text, 0, 1);
	if ($char eq $test) {
		my $parser = pop @_;
		&$parser($self, $text, $test, @_);
		return 1
	}
	return ''
}

sub testDetectCharD {
	my $self = shift;
	my $text = shift;
	my $char = shift;
	$char = $self->CapturedParseC($char);
	my $test = substr($$text, 0, 1);
	if ($char eq $test) {
		my $parser = pop @_;
		&$parser($self, $text, $test, @_);
		return 1
	}
	return ''
}

sub testDetectCharDI {
	my $self = shift;
	my $text = shift;
	my $char = shift; 
	$char = $self->CapturedParseC($char);
	my $test = substr($$text, 0, 1);
	if (lc($char) eq lc($test)) {
		my $parser = pop @_;
		&$parser($self, $text, $test, @_);
		return 1
	}
	return ''

}

sub testDetectCharI {
	my $self = shift;
	my $text = shift;
	my $char = shift; 
	my $test = substr($$text, 0, 1);
	if (lc($char) eq lc($test)) {
		my $parser = pop @_;
		&$parser($self, $text, $test, @_);
		return 1
	}
	return ''
}

sub testDetect2Chars {
	my $self = shift;
	my $text = shift;
	my $char = shift; 
	my $char1 = shift;
	my $string = $char . $char1;
	my $test = substr($$text, 0, 2);
	if ($string eq $test) {
		my $parser = pop @_;
		&$parser($self, $text, $test, @_);
		return 1
	}
	return ''
}

sub testDetect2CharsD {
	my $self = shift;
	my $text = shift;
	my $char = shift; 
	my $char1 = shift;
	$char = $self->CapturedParseC($char);
	$char1 = $self->CapturedParseC($char1);
	my $string = $char . $char1;
	my $test = substr($$text, 0, 2);
	if ($string eq $test) {
		my $parser = pop @_;
		&$parser($self, $text, $test, @_);
		return 1
	}
	return ''
}

sub testDetect2CharsDI {
	my $self = shift;
	my $text = shift;
	my $char = shift; 
	my $char1 = shift;
	$char = $self->CapturedParseC($char);
	$char1 = $self->CapturedParseC($char1);
	my $string = $char . $char1;
	my $test = substr($$text, 0, 2);
	if (lc($string) eq lc($test)) {
		my $parser = pop @_;
		&$parser($self, $text, $test, @_);
		return 1
	}
	return ''

}

sub testDetect2CharsI {
	my $self = shift;
	my $text = shift;
	my $char = shift; 
	my $char1 = shift;
	my $string = $char . $char1;
	my $test = substr($$text, 0, 2);
	if (lc($string) eq lc($test)) {
		my $parser = pop @_;
		&$parser($self, $text, $test, @_);
		return 1
	}
	return ''

}
sub testDetectIdentifier {
	my $self = shift;
	my $text = shift;
	unless ($self->LastcharDeliminator) { return '' }
	if ($$text =~ /^([a-z][a-z0-9_]*)/i) {
		my $parser = pop @_;
		&$parser($self, $text, $1, @_);
		return 1
	}
	return ''
}

sub testDetectSpaces {
	my $self = shift;
	my $text = shift;
	if ($$text =~ /^([\040|\t]+)/) {
		my $parser = pop @_;
		&$parser($self, $text, $1, @_);
		return 1
	}
	return ''
}

sub testFloat {
	my $self = shift;
	my $text = shift;
	if ($self->LastcharDeliminator) {
		if ($$text =~ /^((?=\.?\d)\d*(?:\.\d*)?(?:[Ee][+-]?\d+)?)/) {
			my $parser = pop @_;
			&$parser($self, $text, $1, @_);
			return 1
		}
	}
	return ''
}

sub testHlCChar {
	my $self = shift;
	my $text = shift;
	if ($$text =~ /^('.')/) {
		my $parser = pop @_;
		&$parser($self, $text, $1, @_);
		return 1
	}
	return ''
}

sub testHlCHex {
	my $self = shift;
	my $text = shift;
	if ($self->LastcharDeliminator) {
		if ($$text =~ /^(0x[0-9a-fA-F]+)/) {
			my $parser = pop @_;
			&$parser($self, $text, $1, @_);
			return 1
		}
	}
	return ''
}

sub testHlCOct {
	my $self = shift;
	my $text = shift;
	if ($self->LastcharDeliminator) {
		if ($$text =~ /^(0[0-7]+)/) {
			my $parser = pop @_;
			&$parser($self, $text, $1, @_);
			return 1;
		}
	}
	return ''
}

sub testHlCStringChar {
	my $self = shift;
	my $text = shift;
	if ($$text =~ /^(\\[a|b|e|f|n|r|t|v|'|"|\?])/) {
		my $parser = pop @_;
		&$parser($self, $text, $1, @_);
		return 1
	}
	if ($$text =~ /^(\\x[0-9a-fA-F][0-9a-fA-F]?)/) {
		my $parser = pop @_;
		&$parser($self, $text, $1, @_);
		return 1
	}
	if ($$text =~ /^(\\[0-7][0-7]?[0-7]?)/) {
		my $parser = pop @_;
		&$parser($self, $text, $1, @_);
		return 1
	}
	return ''
}

sub testInt {
	my $self = shift;
	my $text = shift;
	if ($self->LastcharDeliminator) {
		if ($$text =~ /^([+-]?\d+)/) {
			my $parser = pop @_;
			&$parser($self, $text, $1, @_);
			return 1
		}
	}
	return ''
}

sub testKeyword {
	my $self = shift;
	unless ($self->LastcharDeliminator) { return '' }
	my $text = shift;
	my $list = shift;
	my $delim = shift;
# 	my $deliminators = $self->StackTop->[0]->{deliminators};
# 	if ($$text =~ /^([^$deliminators]+)/) {
	if ($$text =~ /^([^$delim]+)/) {
# 	if ($$text =~ /^([^\b]+)/) {
		my $match = $1;
		if (exists $list->{$match}) {
			my $parser = pop @_;
			&$parser($self, $text, $match, @_);
			return 1
		}
	}
	return ''
}

sub testKeywordI {
	my $self = shift;
	unless ($self->LastcharDeliminator) { return '' }
	my $text = shift;
	my $list = shift;
	my $delim = shift;
# 	my $deliminators = $self->StackTop->[0]->{deliminators};
# 	if ($$text =~ /^([^$deliminators]+)/) {
	if ($$text =~ /^([^$delim]+)/) {
# 	if ($$text =~ /^([^\b]+)/) {
		my $match = $1;
		my $test = lc($match);
		if (exists $list->{$test}) {
			my $parser = pop @_;
			&$parser($self, $text, $match, @_);
			return 1
		}
	}
	return ''
}

sub testLineContinue {
	my $self = shift;
	my $text = shift;
	my $char = shift;
	if ($$text =~ /^($char)\n/) {
		my $parser = pop @_;
		&$parser($self, $text, $1, @_);
		return 1
	}
	return ''
}

sub testRangeDetect {
	my $self = shift;
	my $text = shift;
	my $char = shift;
	my $char1 = shift;
	if ($$text =~ /^($char[^$char1]+$char1)/) {
		my $parser = pop @_;
		&$parser($self, $text, $1, @_);
		return 1
	}
}

sub testRangeDetectI {
	my $self = shift;
	my $text = shift;
	my $char = shift;
	my $char1 = shift;
	if ($$text =~ /^($char[^$char1]+$char1)/i) {
		my $parser = pop @_;
		&$parser($self, $text, $1, @_);
		return 1
	}
}

sub testRegExpr {
	my $self = shift;
	my $text = shift;
	my $reg = shift;
	if ($$text =~ /$reg/) {
		my $match = $1;
		chomp $match; #Sometimes a trailing newline is matched.
		if ($match eq '') { return '' } #Sometimes a reg gives a positive result of zero length
		if ($#- > 1) {
			no strict 'refs';
			my @cap = map {$$_} 2 .. $#-;
			$self->Capture(@cap);
# 			$self->{STACK}->[0]->[2] = \@cap;
		}
		my $parser = pop @_;
		&$parser($self, $text, $match, @_);
		return 1
	}
	return ''
}

sub testRegExprD {
	my $self = shift;
	my $text = shift;
	my $reg = shift;
	
	my ($a, $b, $c, $d, $e, $f, $g, $h);
	($reg, $a, $b, $c, $d, $e, $f, $g, $h) = $self->CapturedParseR($reg);
	$reg = "^($reg)";
	# emergency measurements to avoid exception (szabgab)
	eval "\$reg = qr/$reg/;";
	if ($@) {
		warn $@;
		return '';
	}
	if ($$text =~ /$reg/) {
		my $match = $1;
		chomp $match; #Sometimes a trailing newline is matched.
		if ($match eq '') { return '' } #Sometimes a reg gives a positive result of zero length
		if ($#- > 1) {
			no strict 'refs';
			my @cap = map {$$_} 2 .. $#-;
			$self->Capture(@cap);
# 			$self->{STACK}->[0]->[2] = \@cap;
		}
		my $parser = pop @_;
		&$parser($self, $text, $match, @_);
		return 1
	}
	return ''
}

sub testRegExprDI {
	my $self = shift;
	my $text = shift;
	my $reg = shift;
	
	my ($a, $b, $c, $d, $e, $f, $g, $h);
	($reg, $a, $b, $c, $d, $e, $f, $g, $h) = $self->CapturedParseR($reg);
	$reg = "^($reg)";
	# emergency measurements to avoid exception (szabgab)
	eval "\$reg = qr/$reg/i;";
	if ($@) {
		warn $@;
		return '';
	}
	if ($$text =~ /$reg/i) {
		my $match = $1;
		chomp $match; #Sometimes a trailing newline is matched.
		if ($match eq '') { return '' } #Sometimes a reg gives a positive result of zero length
		if ($#- > 1) {
			no strict 'refs';
			my @cap = map {$$_} 2 .. $#-;
			$self->Capture(@cap);
# 			$self->{STACK}->[0]->[2] = \@cap;
		}
		my $parser = pop @_;
		&$parser($self, $text, $match, @_);
		return 1
	}
	return ''
}

sub testRegExprI {
	my $self = shift;
	my $text = shift;
	my $reg = shift;
	if ($$text =~ /$reg/i) {
		my $match = $1;
		chomp $match; #Sometimes a trailing newline is matched.
		if ($match eq '') { return '' } #Sometimes a reg gives a positive result of zero length
		if ($#- > 1) {
			no strict 'refs';
			my @cap = map {$$_} 2 .. $#-;
			$self->Capture(@cap);
# 			$self->{STACK}->[0]->[2] = \@cap;
		}
		my $parser = pop @_;
		&$parser($self, $text, $match, @_);
		return 1
	}
	return ''
}

sub testStringDetect {
	my $self = shift;
	my $text = shift;
	my $string = shift;
	my $test = substr($$text, 0, length($string));
	if ($string eq $test) {
		my $parser = pop @_;
		&$parser($self, $text, $test, @_);
		return 1
	}
	return ''
}

sub testStringDetectD {
	my $self = shift;
	my $text = shift;
	my $string = shift;
	$string = $self->CapturedParse($string);
	my $test = substr($$text, 0, length($string));
	if ($string eq $test) {
		my $parser = pop @_;
		&$parser($self, $text, $test, @_);
		return 1
	}
	return ''

}

sub testStringDetectDI {
	my $self = shift;
	my $text = shift;
	my $string = shift;
	$string = $self->CapturedParse($string);
	my $test = substr($$text, 0, length($string));
	if (lc($string) eq lc($test)) {
		my $parser = pop @_;
		&$parser($self, $text, $test, @_);
		return 1
	}
	return ''

}

sub testStringDetectI {
	my $self = shift;
	my $text = shift;
	my $string = shift;
	my $test = substr($$text, 0, length($string));
	if (lc($string) eq lc($test)) {
		my $parser = pop @_;
		&$parser($self, $text, $test, @_);
		return 1
	}
	return ''
}

sub testWordDetect {
	my $self = shift;
	my $text = shift;
	my $string = shift;
	if (length($string) + 1 > length($$text)) { return '' }
	unless ($self->LastcharDeliminator) { return '' }
	my $testc = substr($$text, length($string), 1);
	unless ($self->IsDeliminator($testc)) { return '' }
	my $test = substr($$text, 0, length($string));
	if ($string eq $test) {
		my $parser = pop @_;
		&$parser($self, $text, $test, @_);
		return 1
	}
	return ''
}

sub testWordDetectD {
	my $self = shift;
	my $text = shift;
	my $string = shift;
	if (length($string) + 1 > length($$text)) { return '' }
	$string = $self->CapturedParse($string);
	unless ($self->LastcharDeliminator) { return '' }
	my $testc = substr($$text, length($string), 1);
	unless ($self->IsDeliminator($testc)) { return '' }
	my $test = substr($$text, 0, length($string));
	if ($string eq $test) {
		my $parser = pop @_;
		&$parser($self, $text, $test, @_);
		return 1
	}
	return ''
}

sub testWordDetectDI {
	my $self = shift;
	my $text = shift;
	my $string = shift;
	if (length($string) + 1 > length($$text)) { return '' }
	$string = lc($self->CapturedParse($string));
	unless ($self->LastcharDeliminator) { return '' }
	my $testc = substr($$text, length($string), 1);
	unless ($self->IsDeliminator($testc)) { return '' }
	my $test = substr($$text, 0, length($string));
	if (lc($string) eq lc($test)) {
		my $parser = pop @_;
		&$parser($self, $text, $test, @_);
		return 1
	}
	return ''
}

sub testWordDetectI {
	my $self = shift;
	my $text = shift;
	my $string = shift;
	if (length($string) + 1 > length($$text)) { return '' }
	unless ($self->LastcharDeliminator) { return '' }
	my $testc = substr($$text, length($string), 1);
	unless ($self->IsDeliminator($testc)) { return '' }
	my $test = substr($$text, 0, length($string));
	if (lc($string) eq lc($test)) {
		my $parser = pop @_;
		&$parser($self, $text, $test, @_);
		return 1
	}
	return ''
}

sub UseAttribStackPush {
	my ($self, $item) = @_;
	my $stack = $self->{USEATTRIBSTACK};
	unshift(@$stack, $item);
}

sub UseAttribStackPull {
	my ($self, $val) = @_;
	my $stack = $self->{USEATTRIBSTACK};
	return shift(@$stack);
}

sub UseAttribStackTop {
	my $self = shift;
	return $self->{USEATTRIBSTACK}->[0];
}

1;
__END__
