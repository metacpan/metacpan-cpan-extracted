package Syntax::Kamelon::XMLData;

use 5.006;
use strict;
use warnings;
use XML::TokeParser;
use Data::Dumper;

our $VERSION = '0.15';

my $regchars = "\\^.\$|()[]{}*+?~!%^&/";

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my %args = (@_);

	my $file = delete $args{'xmlfile'};
	my $self = {
		ATTRIBUTES => {},
		BASECONTEXT => '',
		CONTEXTDATA => {},
		ADDDELIMINATORS => '',
		WEAKDELIMINATORS => '',
		FILENAME => $file,
		KEYWORDSCASE => 'undef',
		LANGUAGE => {},
		LISTS => {},
	};
	bless ($self, $class);
	if (defined($file)) {
		$self->XMLLoad($file);
	}
	return $self;
}


sub Attributes {
	my $self = shift;
	if (@_) { $self->{ATTRIBUTES} = shift; };
	return $self->{ATTRIBUTES};
}

sub BaseContext {
	my $self = shift;
	if (@_) { $self->{BASECONTEXT} = shift }
	return $self->{BASECONTEXT}
}

sub Booleanize {
	my ($self, $d) = @_;
	if (lc($d) eq 'true') { $d = 1 };
	if (lc($d) eq 'false') { $d = 0 };
	if (($d ne 0) and ($d ne 1)) { return undef };
	return $d;
}

sub Clear {
	my $self = shift;
	$self->{BASECONTEXT} = '';
	$self->{CONTEXTDATA} = {};
	$self->{ADDDELIMINATORS} = '';
	$self->{WEAKDELIMINATORS} = '';
	$self->{FILENAME} = '';
	$self->{ITEMDATA} = {};
	$self->{KEYWORDSCASE} = 1;
	$self->{LANGUAGE} = {};
	$self->{LISTS} = {};
}

sub ContextData {
	my $self = shift;
	if (@_) { $self->{CONTEXTDATA} = shift; };
	return $self->{CONTEXTDATA};
}

sub AdditionalDeliminator {
	my $self = shift;
	if (@_) { $self->{ADDDELIMINATORS} = shift }
	return $self->{ADDDELIMINATORS}
}

sub WeakDeliminator {
	my $self = shift;
	if (@_) { $self->{WEAKDELIMINATORS} = shift }
	return $self->{WEAKDELIMINATORS}
}

sub FileName {
	my $self = shift;
	if (@_) { $self->{FILENAME} = shift }
	return $self->{FILENAME}
}

sub GetItems {
	my ($self, $parser) = @_;
	my @list = ();
	while (my $token = $parser->get_token) {
		if ($token->[0] eq 'S') {
			my $t = $token->[2];
			$t->{'type'} = $token->[1];
			my @items = $self->GetItems($parser);
			if (@items) {
				$t->{'items'} = \@items
			}
			push @list, $t;
		} elsif ($token->[0] eq 'E') {
			return @list;
		}
	}
}

sub KeywordsCase {
	my $self = shift;
	if (@_) { $self->{KEYWORDSCASE} = shift }
	return $self->{KEYWORDSCASE}
}


sub Language {
	my $self = shift;
	if (@_) { $self->{LANGUAGE} = shift }
	return $self->{LANGUAGE}
}

sub Lists {
	my $self = shift;
	if (@_) { $self->{LISTS} = shift }
	return $self->{LISTS}
}

sub Setup {}

sub Syntax {
	my $self = shift;
	return $self->{LANGUAGE}->{name};
}

sub XMLGetAttribute {
	my ($self, $token, $parser) = @_;
	my $style = $token->[2]->{'defStyleNum'};
	unless (defined($style)) { 
		warn "undefined style";
		$style = '';
	};
	$style =~ s/^ds//;
	$self->Attributes->{$token->[2]->{'name'}} =  $style;
}

sub XMLGetContext {
	my ($self, $token, $parser) = @_;
	my $ctx = delete $token->[2]->{'name'};
	unless (defined($ctx)) { $ctx ='noname' };
	my $ar = $token->[2];
	my %args = %$ar;
	if ($self->BaseContext eq '') {
		$self->BaseContext($ctx);
	}
	my @items = $self->GetItems($parser);
	if (@items) { $args{'items'} = \@items };
	$self->XMLSetContext($ctx,\%args);
}

sub XMLGetKeywordSettings {
	my ($self, $token, $parser) = @_;
	my $case = delete $token->[2]->{'casesensitive'};
	if (defined($case)) {
		$case = $self->Booleanize($case);
		unless (defined $case) { $case = 1 }
		$self->KeywordsCase($case);
	}
	my $wdelim = delete $token->[2]->{'weakDeliminator'};
	if (defined($wdelim)) {
		$self->WeakDeliminator($wdelim)
	}
	my $adelim = delete $token->[2]->{'additionalDeliminator'};
	if (defined($adelim)) {
		$self->AdditionalDeliminator($wdelim)
	}
}

sub XMLGetLanguage {
	my ($self, $token, $parser) = @_;
	my $args = $token->[2];
	$self->Language($args);
}

sub XMLGetList {
	my ($self, $token, $parser) = @_;
	my $name = $token->[2]->{'name'};
	my @list = ();
	my $inlist = 1;
	while ($inlist) {
		my $ltok = $parser->get_token;
		if ($ltok->[0] eq 'T') {
			my $tx = $ltok->[1];
			$tx =~ s/^\s+//;
			$tx =~ s/\s+$//;
			push @list, $tx;
		} elsif ($ltok->[0] eq 'E') {
			if ($ltok->[1] eq 'list') {
				$self->Lists->{$name} = [ @list ];
				$inlist = 0;
			}
		}
	}
}

my %xmlmethods = (
	context => 'XMLGetContext',
	itemData => 'XMLGetAttribute',
	keywords => 'XMLGetKeywordSettings',
	language => 'XMLGetLanguage',
	list => 'XMLGetList',
);

sub XMLLoad {
	my ($self, $file) = @_;
	unless (open KATE, "<$file") { 
		warn "cannot open $file";
		return
	};
	$self->Clear;
	my $parser = new XML::TokeParser(\*KATE, Noempty => 1);
	while (my $token = $parser->get_token) {
		if ($token->[0] eq 'S') {
			my $tag = $token->[1];
			if (my $method = $xmlmethods{$tag}) {
				my $call = $self->can($method);
				&$call($self, $token, $parser);
			}
		}
	}
	close KATE;
	$self->FileName($file);
}

sub XMLSetContext {
	my ($self, $context, $data) = @_;
	my $path = $self->Syntax . "::$context";
	$data->{path} = $path;
	my $i = $data->{items};
	my $num = 1;
	foreach my $item (@$i) {
		$item->{path} = $path . "::$num";
		$num ++;
	}
	$self->ContextData->{$context} = $data;
}

1;
