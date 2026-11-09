package Pod::Literate;
use parent 'Pod::Simple';
our $VERSION='0.0.2';
use strict;
use warnings;
my $cache='--PODLITERATECACHE--';
my $tagL='#<';
my $tagR='>#';
my $reSection=qr/$tagL\s*(.+?)\s*$tagR/;
sub new {
	my ($class)=@_;
	my $self=$class->SUPER::new();
	if(exists($$self{$cache})) { die 'Basic Pod::Simple object unexpectedly contains the Pod::Literate cache key' }
	$$self{$cache}={
		ofn      =>{},    # the output filename for the tangled application
		section  =>{},    # the collection of named sections
		mode     =>'',    # scanning mode, to distinguish begin/for tags
		target   =>undef, # defined and destroyed while scanning
		collector=>undef, # defined and destroyed while scanning
		#
		dep      =>{},    # used during tangling to compute dependencies
	};
	return $self;
}
sub targetSet {
	my ($self,$name)=@_;
	$$self{$cache}{target}=$name;
	return $self;
}
sub target {
	my ($self)=@_;
	return $$self{$cache}{target};
}
sub sectionAppend {
	my ($self,$section,$text)=@_;
	$$self{$cache}{section}{$section}.=$text;
}
sub section {
	my ($self,$section)=@_;
	return $$self{$cache}{section}{$section};
}
sub sectionRegexp {
	my ($name)=@_;
	return qr/$tagL\s*\Q$name\E\s*$tagR/;
}
sub initCollection {
	my ($self,$text)=@_;
	$$self{$cache}{collector}=$text//'';
	return $self;
}
sub collected {
	my ($self)=@_;
	return unindent($$self{$cache}{collector});
}
sub clearCollection {
	my ($self)=@_;
	delete(@{$$self{$cache}}{qw/target collector/});
	return $self;
}
sub unindent {
	my ($s)=@_;
	if($s=~/^(\s+)/) {
		my $indent=$1;
		$s=~s/^\Q$indent\E//mg;
	}
	return $s;
}
sub indent {
	my ($code,$indent)=@_;
	if(!$indent) { return $code }
	$code=~s/^/$indent/emg;
	return $code;
}
sub _handle_element_start {
	my ($self,$element,$attribute)=@_;
	my $target=$$attribute{target}//'';
	if($target ne 'literate') { return }
	if(my $name=$self->target()) {
		$self->sectionAppend($name, $self->collected());
		$self->clearCollection()->initCollection();
		return;
	}
	if($element eq 'for') {
		$$self{$cache}{mode}=$$attribute{'~really'};
		if($$attribute{title}) { $self->targetSet($$attribute{title}=~s/^\+//r) }
		$self->initCollection();
	}
}

sub _handle_element_end {
	my ($self,$element,$attribute)=@_;
	if($element eq 'for') {
		my ($mode,$collected)=@{$$self{$cache}}{qw/mode collector/};
		$collected=~s/\n$//s;
		if(($mode eq '=for')&&($collected=~/^target:(.+)$/)) {
			$$self{$cache}{ofn}=$1;
			$self->clearCollection();
		}
		elsif(($mode eq '=for')&&($collected eq '.')) {
			$self->clearCollection();
		}
		elsif($mode eq '=for') {
			$self->targetSet($collected=~s/^\+//r);
			$self->initCollection();
		}
		elsif($self->target()) {
			$self->sectionAppend($self->target(), $self->collected());
			$self->clearCollection();
		}
	}
	elsif($element eq 'Document') {
		$self->tangle();
	}
}

sub _handle_text {
	my ($self,$text)=@_;
	if(defined($$self{$cache}{collector})) { $$self{$cache}{collector}.=$text."\n" }
}
sub tangle {
	my ($self)=@_;
	my (%tobuild,@todo); # prebuild to keep the loops separate
	$self->prepareSections();
	while(my ($ka,$refb)=each %{$$self{$cache}{dep}}) { $tobuild{$ka}={map {$_=>1} keys(%$refb)} }
	while(my @names=sort grep {!%{$tobuild{$_}}} keys(%tobuild)) {
		push @todo,@names;
		delete(@tobuild{@names});
		foreach my $name (values %tobuild) { delete(@$name{@names}) }
	}
	foreach my $name (@todo) { $self->tangleSection($name) }
	if(my $ofn=$$self{$cache}{ofn}) {
	if(my $oft=$self->section($ofn)) {
		open(my $fh,'>',$ofn) or die "open: $!";
		print $fh $oft;
		close($fh);
	} }
	return $self;
}
sub tangleSection {
	my ($self,$name)=@_;
	my $section=$$self{$cache}{section}{$name};
	foreach my $import (keys %{$$self{$cache}{dep}{$name}}) {
		my $re=sectionRegexp($import);
		my $code=$$self{$cache}{section}{$import}; $code=~s/\n+$//s;
		while($section=~/^(\s*)$re\s*$/m) {
			my $icode=indent($code,$1);
			$section=~s/^\s*$re\s*$/$icode/em;
		}
		$section=~s/$re/$code/ge;
	}
	$$self{$cache}{section}{$name}=$section;
}
sub codeSectionNames {
	my ($code)=@_;
	my %names;
	while($code=~m/$reSection/g) { $names{$1}=1 }
	return keys(%names);
}
sub prepareSections {
	my ($self)=@_;
	my ($changed,$sections,%dep,%missing,%cyclic)=(1);
	$sections=$$self{$cache}{section};
	while(my ($k,$code)=each %$sections) {
		foreach my $name (codeSectionNames($code)) {
			if(!defined($$sections{$name})) { $missing{$name}=1 }
			$dep{$k}{$name}=1;
		}
	}
	if(%missing) { die 'Name referenced but not defined:  '.join(q{; },sort keys %missing) }
	while($changed) { $changed=0;
		foreach my $ka (keys %dep) {
		foreach my $kb (keys %{$dep{$ka}}) {
			foreach my $kc (keys %{$dep{$kb}}) {
				my $d=$dep{$ka}{$kb}+$dep{$kb}{$kc};
				if(!defined($dep{$ka}{$kc})||($dep{$ka}{$kc}<$d)) {
					$dep{$ka}{$kc}=$d; $changed=1;
					if($ka eq $kc) { $cyclic{$ka}=1 }
				} }
		} }
	}
	if(%cyclic) { die 'Sections contain cyclic dependencies:  '.join(q{, },sort keys %cyclic) }
	$$self{$cache}{dep}=\%dep;
	return $self;
}
1;

__END__

=pod

=head1 NAME

Pod::Literate - Literate programming through POD, for general applications or specifications managed by AI/Copilot/Claude/ChatGPT

=head1 VERSION

Version 0.0.2

=head1 SYNOPSIS

  podweave.pl  Module.pod | pod2text
  podtangle.pl Module.pod
  perl -e 'use Module; ...'

=head1 DESCRIPTION

Literate programming naturally structures code based on its written specification.  Traditionally this permitted organization of very large applications in languages that initially focused on single-file development, which slowly extended to multiple files used as basic imports.  With the advance of projects spanning many directories and isolation into objects, and the propensity to author code with minimal comments and documentation, literate programming became an historical curiosity.

With AI/LLM tools focused on software development assistance, it is possible to leverage literate programming to build specifications for applications and interfaces.  Given the natural-language focus of this approach, LLMs benefit from and can better maintain consistency with specifications.  Code again becomes focused on small, isolated, well-tested goals that can be merged together to form larger systems.

These specifications can be processed in two ways.  A I<tangle> command permits coalescing all named sections into the final application.  A I<weave> operation generates the specification with all relevant visible elements.  In C<Pod::Literate>, the weave application is L<perlpod> itself and its associated formatters (L<pod2man> etc.).

=head2 Backwards Incompatibility

I<IMPORTANT>:  This is an early version.  Monitor the version change logs for additional information about forthcoming functional changes.

=over

=item Section declaration versus addition

The warning/error behavior of C<literate Name> versus C<literate +Name> may change, be dependent on commandline flags, etc.

=item Hidden sections

When I<weave> is provided, both of C<begin> and C<for> sections will become visible.  There may be some benefit to having hidden sections that still generate code.

=item Unused sections

Unused sections may become failures, warnings, etc.

=item Commands

Commands like C<literate target:name> might change.  Considering C<:literate> for these.

=item Weave

Weave options and overall behaviors are subject to change.

=back

=head1 FORMAT FEATURES

The module, C<Pod::Literate>, is implemented using the formatting features of L<perlpod>.  At this time, either C<=begin> or C<=for> may be used to declare I<named sections> of code.  They behave different within L<perlpod>, where the C<=begin> paragraphs will be hidden, but both declarations are visible with the current I<weave> command.

=head2 begin and end

The begin and end command paragraphs are used to create sections that are I<hidden> in perlpod (but still visible during a weave operation), and must appear in pairs:

	=begin literate Descriptive name

	...

	=end literate

When processing the start of these blocks, a title attribute is set with the "Descriptive name" which is used to identify the target section into which the text contents will be stored.

Notice, I<at this time>, that the classic additive syntax for a named section is supported, in particular

	=begin literate +Descriptive name

	...

	=end literate

but this is equivalent to the non-additive name.  In particular, if sections appear more than once, the contents are always concatenated.  (This is subject to change, additional warnings, etcetera).

=head2 for

The C<=for> command paragraph denotes sections that are I<not hidden> in L<perlpod>, nor during a weave operation.  The ending of a C<for> section uses a period:

	=for literate Descriptive name

	...

	=for literate .

At this time the period is mandatory and signals the end of content collection.

=head2 Section names

Sections named in C<=begin> and C<=for> tags are limited only by L<perlpod> functionality.  Each name is I<referenced> in code by placing it within commented identifiers as:

	#< Descriptive name >#

Leading and trailing spaces are ignored, but otherwise only the sequence C<E<gt>#> would be illegal in a name.

=head1 OUTPUT

At this time, a single output file is supported per specification:

  =for literate target:Module.pm

Relative and full path specifications are permitted.  (Expect this to support multiple file output in the future).

=head1 TODO

The following are being considered.  No particular priority order here.

=over

=item todo Weave command is required if the begin/for names are supposed to show up in the POD

The names are clear within the specification, but the generated POD doesn't contain the names.  Presumably the generated pod would show something like

  < Descriptive name > +=
  Content

Basic functionality is provided in C<weave>, but functionality is still being decided.

=item todo Support C<=for literate import:filename>

Documents may appear in sections, and one large POD can become difficult to manage.  With a specialized weave command, it would be sensible to support imports.

=item todo Handle multiple output filenames

The C<target:filename> can simmply set the output and all subsequent sections will be collected therein.  If another filename is encountered, the scanner will start putting sections there.  With an C<import> statement, the filenames would be fairly well scoped, and perhaps C<import> should explicitly scope any set filename.

=item done First line indentation is removed, to match indentation at the point of reference

=item done First line indentation applies to every line in the reference

=item todo Inline references

Most work has been focused on standalone references.  What is the behavior of C<{ named reference }> when the reference is a single line?  Multiline?

=item todo Inline declaration

Support for C<XE<lt>nameE<gt>code> to declare single lines of code within a paragraph.

=item todo Detect/reject invalid sequences like begin/for, begin/begin, for title/for title

=item todo Investigate colon-prefixed C<=for :literate command> for the command strings.

=item todo Blank code lines

Blank lines before/after subroutines, for example, are not straightforward to specify.  Inside C<=for> blocks, those would violate L<podchecker> which expects no whitespace-only lines.  It may be this is entirely the responsibility of a later style tool, but it should be possible to get actual blank lines without having to put those blank lines around the reference.  Maybe some C<#nl> or equivalent, which would still look nicer than some lengthy C<# blank line #> type of comment.

Another approach would be, since this is Perl POD, to permit enabling spaces around balanced blocks that are denoted, such as C<sub>.

=item todo Cross reference

Lexicographic index of all section names etc.  (Page numbers seem irrelevant, is it just 1.2.3.4 style subsection numbering?).  Possibly leverage `makeindex`, if available.

=item todo Module pod

How to denote pod that belongs with the output module?

=item todo Tests

Generally tests will appear in different sections, but it's possible to write a specification where the tests are associated with each section.  Unfortunately, for concatenated sections the tests might be more difficult to arrange prior to tangling.

=item todo Reference wildcards

Support C<#E<lt> Name.* E<gt>#> to select all matching names, alphabetical order

=back

=head1 SEE ALSO

* L<perlpod>

* L<Pod::Simple>

* L<Wikipedia|https://en.wikipedia.org/wiki/Literate_programming>

* L<Literate Programming FAQ|https://ctan.math.utah.edu/ctan/tex-archive/help/comp.programming.literate_FAQ>

=cut
