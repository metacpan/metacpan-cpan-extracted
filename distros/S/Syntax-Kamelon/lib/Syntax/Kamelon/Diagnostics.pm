package Syntax::Kamelon::Diagnostics;

our $VERSION = '0.15';

use strict;
use warnings;
use Carp qw(cluck);

use Syntax::Kamelon::Indexer;
use Syntax::Kamelon::XMLData;
use Term::ANSIColor;

my $keylength = 20;
my $formatdirection = 0;

my %styles = (
	title => color('white bold on_green'),
	key => color('yellow'),
	value => color('green'),
	error => color('yellow bold on_red'),
	header => color('white bold'),
	header1 => color('yellow bold'),
	message => color('blue'),
	normal => color('white'),
);

my %parses = (
	AnyChar => \&RuleDefault,
	DetectChar => \&RuleDefault,
	Detect2Chars => \&RuleDefault,
	DetectIdentifier => \&RuleDefault,
	DetectSpaces => \&RuleDefault,
	Float => \&RuleDefault,
	HlCChar => \&RuleDefault,
	HlCHex => \&RuleDefault,
	HlCOct => \&RuleDefault,
	HlCStringChar => \&RuleDefault,
	IncludeRules => \&RuleDefault,
	Int => \&RuleDefault,
	keyword => \&RuleKeyword,
	LineContinue => \&RuleDefault,
	RangeDetect => \&RuleDefault,
	RegExpr => \&RuleRegExpr,
	StringDetect => \&RuleDefault,
	WordDetect => \&RuleDefault,
);

my @contextkeys = qw(
	dynamic
	fallthrough
	fallthroughContext
	lineEmptyContext
	lineEndContext
	name
);

my @langkeys = qw(
	author
	casesensitive
	extensions
	hidden
	kateversion
	license
	mimetype
	name
	priority
	section
	style
	version
);

my @rulekeys = qw(
	attribute
	beginRegion
	char
	char1
	column
	context
	dynamic
	endRegion
	firstNonSpace
	includeAttrib
	insensitive
	lookAhead
	minimal
	String
);

my %tests = (
	attributes => \&CheckDuplicateAttributes,
	details => \&ListDetails,
	integrity => \&CheckIntegrity,
	listsizes => \&CheckListSizes,
);

my %operators = (
	'smaller' => sub { 
		my ($key, $match) = @_;
		return ($key < $match) 
	},
	'bigger' => sub { 
		my ($key, $match) = @_;
		return ($key > $match) 
	},
	'smaller or equal' => sub { 
		my ($key, $match) = @_;
		return ($key <= $match) 
	},
	'bigger or equal' => sub { 
		my ($key, $match) = @_;
		return ($key >= $match) 
	},
	'equal' => sub { 
		my ($key, $match) = @_;
		return ($key eq $match) 
	},
	'not equal' => sub { 
		my ($key, $match) = @_;
		return ($key ne $match) 
	},
	'regular expression' => sub { 
		my ($key, $match) = @_;
		return ($key =~ /$match/) 
	},
);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my %args = (@_);
	
	my $indexer = delete $args{'indexer'};
	#catch indexer options
	unless (defined $indexer) {
		my @iopts = qw(indexfile noindex xmlfolder);
		my %index = ();
		for (@iopts) {
			my $val = delete $args{$_};
			if (defined $val) {
				$index{$_} = $val;
			}
		}
		$indexer = Syntax::Kamelon::Indexer->new(%index);
	}
	
	my $self = bless {
		INDENT => 0,
		INDENTSTRING => '   ',
		CONTEXTFILTER => [],
		CURCONTEXT => '',
		CURRULE => '',
		CURSYNTAX => '',
		INDEXER => $indexer,
		OUT => [],
		RULEFILTER => [],
		SHOWDETAILS => 1,
		SHOWCONTEXT => 1,
		SHOWLISTS => 0,
		SHOWRULES => 1,
		SHOWATTRIBUTES => 0,
		SYNTAXFILTER => [],
	}, $class;
	$self->{OUTCALL} = sub { $self->PrintAnsi(@_) },

	return $self;
}

sub AttributeExists {
	my ($self, $attribute, $xml) = @_;
	if (exists $xml->Attributes->{$attribute}) {
		return 1
	} else {
		$self->PrintLine("Undefined attribute $attribute, will revert to 'normal'.", 'message')
	}
	return 0
}

sub AvailableContextKeys {
	my $self = shift;
	return \@contextkeys;
}

sub AvailableLanguageKeys {
	my $self = shift;
	return \@langkeys;
}

sub AvailableOperators {
	my $self = shift;
	my @list = sort keys %operators;
	return \@list;
}

sub AvailableRuleKeys {
	my $self = shift;
	return \@rulekeys;
}

sub AvailableSyntaxes {
	my $self = shift;
	my $i = $self->{INDEXER}->{INDEX};
	return sort keys %$i
}

sub CheckDuplicateAttributes {
	my ($self, $xml) = @_;
}

sub CheckContextAttribute {
	my ($self, $attribute, $xml) = @_;
	if (exists $xml->Attributes->{$attribute}) {
		return 1
	} else {
		$self->PrintLine("Undefined attribute, will revert to 'normal'.", 'message')
	}
	return 0
}

sub CheckListSizes {
	my ($self, $xml) = @_;
	my $l = $xml->Lists;
	foreach my $name (sort keys %$l) {
		my $list = $l->{$name};
		my $size = @$list;
		$self->PrintStyle("List $name: size $size\n");
	}
}

sub Clear {
	my $self = shift;
	$self->{OUT} = [];
}

sub ContextExists {
	my ($self, $context, $xml) = @_;
	if ($context =~ s/##(.*)//) {
		my $syntax = $1;
		my $xmld = $self->GetXMLObject($syntax);
		if (defined $xmld) {
			if ($context eq '') { 
				$context = $xmld->BaseContext;
			}
			unless (exists $xmld->ContextData->{$context}) {
				$self->PrintLine("Context $context in $syntax does not exist", 'message');
				return 0
			}
		}
	} elsif ($context =~ /^#pop/i) {
	} elsif ($context =~ /^#stay/i) {
	} else {
		unless (exists $xml->ContextData->{$context}) {
			$self->PrintLine("Context $context does not exist", 'message');
			return 0
		}
	}
	return 1
}

sub ContextFilter {
	my $self = shift;
	if (@_) { $self->{CONTEXTFILTER} = shift; }
	return $self->{CONTEXTFILTER};
}

sub CurContext {
	my $self = shift;
	if (@_) { $self->{CURCONTEXT} = shift; }
	return $self->{CURCONTEXT};
}

sub CurRule {
	my $self = shift;
	if (@_) { $self->{CURRULE} = shift; }
	return $self->{CURRULE};
}

sub CurSyntax {
	my $self = shift;
	if (@_) { $self->{CURSYNTAX} = shift; }
	return $self->{CURSYNTAX};
}

sub CurXML{
	my $self = shift;
	my $s = $self->CurSyntax;
	unless ($s eq '') {
		return $self->{INDEXER}->{INDEX}->{$s}
	}
}

sub Diagnoze {
	my ($self, $entry) = @_;
	$self->{CURSYNTAX} = $entry;
	my $xml = $self->GetXMLObject($entry);
	if ($self->FilterSyntax($xml->Language)) {
		my $txt = $self->{TXT};
		$self->PrintLine("Syntax: $entry", 'title');
		$self->PrintLine;
		if ($self->{SHOWDETAILS}) {
			$self->PrintLine("Details", 'header1');
			$self->PrintLine;
			$self->PrintHash($xml->Language);
			$self->PrintLine;
			my %h = (	
				BaseContext => $xml->BaseContext,
				WeakDeliminators => $xml->WeakDeliminator,
				AdditionalDeliminators => $xml->AdditionalDeliminator,
				KeywordsCase => $xml->KeywordsCase,
			);
			$self->PrintHash(\%h);
			$self->PrintLine;
		}
		if ($self->{SHOWLISTS}) {
			$self->PrintLine("Lists", 'header1');
			$self->IndentUp;
			my $lists = $xml->Lists;
			foreach my $l (sort keys %$lists) {
				my $list = $lists->{$l};
				my $size = @$list;
				$self->PrintLine($l, 'header', " Size $size", 'message');
				$self->PrintLine;
				$self->IndentUp;
				for (@$list) {
					$self->PrintLine($_, 'value');
				}
				$self->IndentDown;
			}
			$self->IndentDown;
		}
		$self->PrintLine("Contexts", 'header1');
		$self->PrintLine;
		$self->IndentUp;
		my $cd = $xml->ContextData;
		foreach my $k (sort keys %$cd) {
			$self->{CURCONTEXT} = $k;
			my $c = $cd->{$k};
			if ($self->FilterContext($c)) {
				$self->PrintLine("Name: $k", 'header');
				$self->IndentUp;
				if ($self->{SHOWCONTEXT}) {
					$self->PrintHash($c, qw / items /);
					$self->PrintLine;
					$self->CheckContextAttribute($c->{attribute}, $xml);
				}
				$self->PrintRelease;
				if ($self->{SHOWRULES}) {
					my $num = 1;
					my $i = $cd->{$k}->{items};
					for (@$i) {
						$self->{CURRULE} = $num;
						my $rule = $_;
						if ($self->FilterRule($rule)) {
							$self->PrintLine("Rule: $num", 'header');
							$self->PrintHash($rule);
							$self->CurRule($num);
							my $type = $rule->{type};
							my $call = $parses{$type};
							&$call($self, $rule, $xml);
							$self->PrintLine;
							$num++;
							$self->PrintRelease;
						}
					}
				}
				$self->IndentDown;
				$self->PrintLine;
			}
		}
		$self->IndentDown;
		$self->PrintLine;
		if ($self->{SHOWATTRIBUTES}) {
			$self->PrintLine("Attributes", 'title');
			$self->PrintLine;
			$self->IndentUp;
			$self->PrintHash($xml->Attributes);
			$self->IndentDown;
			$self->PrintRelease;
		}
	}
}

sub Filter {
	my ($self, $filter, $hash) = @_;
	unless (@$filter) { return 2 };
	for (@$filter) {
		my ($key, $operator, $value, $cont) = @$_;
		unless (exists $hash->{$key}) { return 0 }
		my $token = $hash->{$key};
		my $call = $operators{$operator};
		if (&$call($token, $value)) {
			if (($cont eq 'or') or ($cont eq '')) {
				return 1
			} 
		} else {
			if (($cont eq 'and') or ($cont eq '')) {
				return 0
			}
		}
	}
}

sub FilterContext {
	my ($self, $hash) = @_;
	my $filter = $self->{CONTEXTFILTER};
	return $self->Filter($filter, $hash)
}

sub FilterRule {
	my ($self, $hash) = @_;
	my $filter = $self->{RULEFILTER};
	return $self->Filter($filter, $hash)
}

sub FilterSyntax {
	my ($self, $hash) = @_;
	my $filter = $self->{SYNTAXFILTER};
	return $self->Filter($filter, $hash)
}

sub FormatStringLength {
	my ($self, $str, $length) = @_;
	unless (defined $length) { $length = $keylength }
	if ($formatdirection) {
		while (length($str) < $length) {
			$str = "$str ";
		}
	} else {
		while (length($str) < $length) {
			$str = " $str";
		}
	}
	return $str;
}

sub GetIndexer {
	my $self = shift;
	return $self->{INDEXER}
}

sub GetXMLObject {
	my ($self, $syntax) = @_;
	my $p = $self->{XMLPOOL};
	my $id = $self->{INDEXER};
	my $i = $id->{INDEX};
	if (exists $p->{$syntax}) {
		return $p->{$syntax}
	} elsif (exists $i->{$syntax}) {
		my $file = $id->{XMLFOLDER} . '/' . $i->{$syntax}->{'file'};
		my $hl = Syntax::Kamelon::XMLData->new(
			xmlfile => $file,
		);
 		$self->{XMLPOOL}->{$syntax} = $hl;
		return $hl
	} else {
		warn "XML file for $syntax is not indexed. Please load manually\n";
	}
	return undef;
}

sub IndentDown {
	my $self = shift;
	my $i = $self->{INDENT};
	if ($i > 0) {
		$self->{INDENT} = $i - 1;
	} else {
		warn "indentation already 0";
	}
}

sub IndentUp {
	my $self = shift;
	my $i = $self->{INDENT};
	$self->{INDENT} = $i + 1;
}

sub IndentString {
	my $self = shift;
	if (@_) { $self->{INDENTSTRING} = shift; }
	my $i = $self->{INDENT};
	my $s = $self->{INDENTSTRING};
	my $o = "";
	if ($i) {
		for (1 .. $i) { $o = $o . $s }
	}
	return $o;
}


sub OutCall {
	my $self = shift;
	if (@_) { $self->{OUTCALL} = shift; }
	return $self->{OUTCALL};
}

sub PrintAnsi {
	my ($self, $txt, $style) = @_;
	unless (defined($style)) { $style = 'normal' }
	unless (exists $styles{$style}) {
		warn "invalid style, $style";
		$style = 'normal',
	}
	print $styles{$style}, $txt, color('reset');
}

sub PrintClear {
	my $self = shift;
	$self->{OUT} = [];
}

sub PrintHash {
	my $self = shift;
	my $h = shift;
	my %exclude = ();
	for (@_) {
		$exclude{$_} = 1;
	}
	my $length = $keylength;
	foreach my $k (sort keys %$h) {
		unless (exists $exclude{$k}) {
			my $l = length $k;
			if ($l > $length) { $length = $l }
		}
	}
	foreach my $k (sort keys %$h) {
		unless (exists $exclude{$k}) {
			my $l = $k;
			$l = $self->FormatStringLength($l, $length);
			$self->PrintStyle("$l: ", 'key');
			my $i = $self->{INDENT};
			$self->{INDENT} = 0;
			$self->PrintStyle($h->{$k} . "\n", 'value');
			$self->{INDENT} = $i;
		}
	}
}

sub PrintLine {
	my $self = shift;
	my @o = ("\n", 'normal');
	unless (@_) { $self->PrintStyle(@o) }
	while (@_) {
		my $txt = shift;
		my $style = shift;
		$self->PrintStyle($txt, $style);
		$self->PrintStyle(@o);
	}
}

sub PrintRelease {
	my $self = shift;
	my $o = $self->{OUT};
	my $call = $self->{OUTCALL};
	while (@$o) {
		my $txt = shift @$o;
		my $style = shift @$o;
		&$call($txt, $style);
	}
	
}

sub PrintStyle {
	my $self = shift;
	my $o = $self->{OUT};
	while (@_) {
		my $txt = shift;
		my $style = shift;
		push @$o, $self->IndentString . $txt, $style;
# 		&$call($self->IndentString . $txt, $style);
	}
}

sub RuleAnyChar {
}

sub RuleDefault {
	my ($self, $rule, $xml) = @_;
	my $result = 1;
	if (exists $rule->{context}) {
		unless ($self->ContextExists($rule->{context}, $xml)) {
			$result = 0
		}
	}
	if (exists $rule->{attribute}) {
		unless ($self->AttributeExists($rule->{attribute}, $xml)) {
			$result = 0
		}
	}
	return $result
}

sub RuleDetectChar {
	my ($self, $rule, $xml) = @_;
	my $result = 1;
	unless ($self->RuleDefault) {
		$result = 0;
	}
	return $result
}

sub RuleDetect2Chars {
	my ($self, $rule, $xml) = @_;
	my $result = 1;
	unless ($self->RuleDefault) {
		$result = 0;
	}
	return $result
}

sub RuleFilter {
	my $self = shift;
	if (@_) { $self->{RULEFILTER} = shift; }
	return $self->{RULEFILTER};
}

sub RuleIncludeRules {
}

sub RuleInt {
}

sub RuleKeyword {
	my ($self, $rule, $xml) = @_;
	my $result = 1;
	unless ($self->RuleDefault) {
		$result = 0;
	}
	my $name = $rule->{String};
	my $lists = $xml->{LISTS};
	unless (exists $lists->{$name}) {
		$self->PrintLine("List $name does not exist. Rule will be ignored", 'message');
		$result = 0;
	}
	return $result
}

sub RuleLineContinue {
}

sub RuleRangeDetect {
	my ($self, $rule, $xml) = @_;
	my $result = 1;
	unless ($self->RuleDefault) {
		$result = 0;
	}
	return $result
}

sub RuleRegExpr {
	my ($self, $rule, $xml) = @_;
# 	print "testing RuleRegExpr\n";
	my $result = 1;
	unless ($self->RuleDefault) {
		$result = 0;
	}
	my $reg = $rule->{String};
	eval { qr/$reg/ };
	if ($@) {
		my $msg = $@;
		$msg =~ s/\sat\s\/[^\n]+\n//;
		$self->PrintLine("$msg Rule will be ignored", 'message');
		$result = 0;
	}
	return $result
}

sub RuleStringDetect {
}

sub RuleWordDetect {
}

sub ShowAttributes {
	my $self = shift;
	if (@_) { $self->{SHOWATTRIBUTES} = shift; }
	return $self->{SHOWATTRIBUTES};
}

sub ShowContext {
	my $self = shift;
	if (@_) { $self->{SHOWCONTEXT} = shift; }
	return $self->{SHOWCONTEXT};
}

sub ShowDetails {
	my $self = shift;
	if (@_) { $self->{SHOWDETAILS} = shift; }
	return $self->{SHOWDETAILS};
}

sub ShowLists {
	my $self = shift;
	if (@_) { $self->{SHOWLISTS} = shift; }
	return $self->{SHOWLISTS};
}

sub ShowRules {
	my $self = shift;
	if (@_) { $self->{SHOWRULES} = shift; }
	return $self->{SHOWRULES};
}

sub SyntaxFilter {
	my $self = shift;
	if (@_) { $self->{SYNTAXFILTER} = shift; }
	return $self->{SYNTAXFILTER};
}



1;

__END__

