package Pod::Literate;
use parent 'Pod::Simple';
our $VERSION='0.0.4';
use strict;
use warnings;

my $cache='--PODLITERATECACHE--';
my $tagL='#<';
my $tagR='>#';
my $reSection=qr/$tagL\h*(.+?)\h*$tagR/;

sub new {
	my ($class)=@_;
	my $self=$class->SUPER::new();
	if(exists($$self{$cache})) { die 'Basic Pod::Simple object unexpectedly contains the Pod::Literate cache key' }
	$$self{$cache}={
		ofn      =>[],    # the output filenames for the tangled application
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
	return qr/$tagL\h*\Q$name\E\h*$tagR/;
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
	if($s=~/^(\h+)/) {
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
	if($target eq ':literate') { die 'Non-data paragraphs are not currently supported via ":literate"' }
	if($target!~/^literate(?::command)?$/) { return }
	if(my $name=$self->target()) {
		$self->sectionAppend($name, $self->collected());
		$self->clearCollection()->initCollection();
		return;
	}
	if($element eq 'for') {
		if($target eq 'literate:command') { $$self{$cache}{mode}='command' }
		else { $$self{$cache}{mode}=$$attribute{'~really'} }
		if($$attribute{title}) { my $s=$$attribute{title}; $s=~s/^\+//; $self->targetSet($s) }
		$self->initCollection();
	}
}

sub _handle_element_end {
	my ($self,$element,$attribute)=@_;
	if($element eq 'for') {
		my ($mode,$collected)=@{$$self{$cache}}{qw/mode collector/};
		if(($mode eq 'command')&&($collected=~/^target=(.+)$/)) {
			push @{$$self{$cache}{ofn}},$1;
			$self->clearCollection();
		}
		elsif(($mode eq '=for')&&($collected=~/^target:(.+)$/)) {
			print STDERR "=for literate target: is deprecated; use =for literate:command\n";
			push @{$$self{$cache}{ofn}},$1;
			$self->clearCollection();
		}
		elsif(($mode eq '=for')&&($collected eq ".\n")) {
			$self->clearCollection();
		}
		elsif($mode eq '=for') {
			my $s=$collected; $s=~s/^\+//; $s=~s/\n$//s;
			$self->targetSet($s);
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
	foreach my $ofn (@{$$self{$cache}{ofn}}) {
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
		my $code=$$self{$cache}{section}{$import}; $code=~s/\n$//s;
		while($section=~/^(\h*)$re\h*$/m) {
			my $icode=indent($code,$1);
			$section=~s/^\h*$re\h*$/$icode/em;
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

Version 0.0.4

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

=item Spacing behaviors

Spacing behaviors of C<=begin> and C<=for> have been fixed/established in 0.0.4!

=item Section declaration versus addition

The warning/error behavior of C<literate Name> versus C<literate +Name> may change, be dependent on commandline flags, etc.

=item Unused sections

Unused sections may become failures, warnings, etc.

=item Weave

Weave options and overall behaviors are subject to change.

=back

=head1 FORMAT FEATURES

The module, C<Pod::Literate>, is implemented using the formatting features of L<perlpod>.  At this time, either C<=begin> or C<=for> may be used to declare I<named sections> of code.  They have different end-of-line behaviors.  Both declarations are visible when using the I<weave> command, but C<perlpod> will hide the C<=begin> sections if C<weave> is not used first.

=head2 begin and end

The begin and end command paragraphs are used to create named sections of code, and must appear in pairs:

	=begin literate Descriptive name

	...

	=end literate

When processing the start of these blocks, a title attribute is set with the "Descriptive name" which is used to identify the target section into which the text contents will be stored.  The C<begin/end> is best suited for code blocks, such as complete subroutines or functions, because the final blank line before the C<=end> I<will> be included in the code.  These sections will be hidden with plain C<perlpod>, but are visible when using C<weave>.

Notice, I<at this time>, that the classic additive syntax for a named section is supported, in particular

	=begin literate +Descriptive name

	...

	=end literate

but this is equivalent to the non-additive name.  In particular, if sections appear more than once, the contents are always concatenated.  (This is subject to change, additional warnings, etcetera).

=head2 for

The C<=for> command paragraph may also be used to create named sections of code, and must appear paired with and ending C<for> statement:


	=for literate Descriptive name

	...

	=for literate .

The stand-alone period is mandatory to signal the end of content collection.  The target section is still identified by the "Descriptive name".  The C<for/for> is best suited for referenced lines of code, one or multiple lines, because the final blank line before the ending C<=for> I<will not> be included in the code.  These sections will be visible with plain C<perlpod>, and are visible when using C<weave>.

The additive syntax also works for sections created with C<=for>.

=head2 Section names

Sections named in C<=begin> and C<=for> tags are limited only by L<perlpod> functionality.  Each name is I<referenced> in code by placing it within commented identifiers as:

	#< Descriptive name >#

Leading and trailing spaces are ignored, but otherwise only the sequence C<E<gt>#> would be illegal in a name.

=head2 Vertical Spacing

The behavior of single and concatenated begin and for blocks differs with regards to blank lines.  Blank lines appear


  when               after each reference    between concatenations
  using begin/end    yes                     yes
  using for/for      no                      no

Consider this example:

  =begin literate subs

    sub AAA {
      #< for lines >#
    }

  =end literate

  =begin literate subs

    sub BBB {
      #< for lines >#
    }

  =end literate

  =for literate for lines

    # comment 1

  =for literate .

  =for literate for lines

    # comment 2

  =for literate .

The result of C<tangle> will be:

  sub AAA {
    # comment 1
    # comment 2
  }
    (blank line here)
  sub BBB {
    # comment 1
    # comment 2
  }
    (blank line here)

For greater control, defined C<#E<lt> blank E<gt>#> and place it as needed.

=head2 Horizontal Spacing

References are included verbatim where they appear, so begin/end blocks are typically not appropriate in the middle of lines.  Consider

  =begin literate example

    if(#< begin inline >#) { #< for inline ># }

  =end literate

  =begin literate begin inline

    begin line

  =end literate

  =for literate for inline

    for line

  =for literate .

The result of C<tangle> will be:

  if(begin line
  ) { for line }

Note that C<#E<lt> for inline E<gt>##E<lt> for inline E<gt>#> will yield two references I<without> an inside newline, but multiple, concatenated declarations of C<=for literate> will still have a blank line between each.

This permits declarations such as

  =for literate header

    =head

  =for literate .

to be used in cases such as C<#E<lt>headerE<gt>#1  Title>.

=head1 OUTPUT

An output filename may be specified via

  =for literate:command target=Module.pm

Multiple targets may be specified by repeating the command, once for each output file.  Each target C<filename> must have a defined section C<=begin literate filename> or C<=for literate filename>.  Relative and full path specifications are permitted.

Note that the weave command still produces single-file output and does not split documentation into multiple files.

The old syntax will be deprecated:  C<=for literate target:Module.pm>

=head1 TODO

The following are being considered.  No particular priority order here.

=over

=item todo Weave command is required if the begin/for names are supposed to show up in the POD

The names are clear within the specification, but the generated POD doesn't contain the names.  Presumably the generated pod would show something like

  < Descriptive name > +=
  Content

Basic functionality is provided in C<weave>, but functionality is still being decided.

=item todo Support C<=for literate:command import=filename>

Documents may appear in sections, and one large POD can become difficult to manage.  With a specialized weave command, it would be sensible to support imports.

=item done Handle multiple output filenames

Multiple C<target=filename> calls can be made.

=item done First line indentation is removed, to match indentation at the point of reference

=item done First line indentation applies to every line in the reference

=item done Inline references

References within lines are expanded normally, with no terminal newline changes.

=item todo Inline declaration

Support for C<XE<lt>nameE<gt>code> to declare single lines of code within a paragraph.

=item todo Detect/reject invalid sequences like begin/for, begin/begin, for title/for title

=item done Investigate colon-prefixed C<=for :literate command> for the command strings.

These are now explicitly rejected.  These are meant to denote plain/POD paragraphs according to L<perlpodspec>, which will require additional parsers.  This syntax may be used to emit POD into the tangled result in the future.

=item todo Blank code lines

Blank lines after subroutines have improved with updates to C<=begin>, but there are still cases where it may be worthwhile to support additional filtering instructions during tangling, or when sections are loaded.

This may be entirely the responsibility of a later style tool, but it should be possible to get actual blank lines without having to put those blank lines around the reference.  Maybe some C<#nl> or equivalent, which would still look nicer than some lengthy C<# blank line #> type of comment.

Another approach would be, since this is Perl POD, to permit enabling spaces around balanced blocks that are denoted, such as C<sub>.

=item todo Cross reference

Lexicographic index of all section names etc.  (Page numbers seem irrelevant, is it just 1.2.3.4 style subsection numbering?).  Possibly leverage `makeindex`, if available.

=item todo Module pod

(This is possible/solved but not yet documented).  How to denote pod that belongs with the output module?

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
