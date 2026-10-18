package Perl::Critic::Policy::Variables::ProhibitExcessiveNames;

use 5.010001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw/:severities/;
use base 'Perl::Critic::Policy';

our $VERSION = '0.1.3';

Readonly::Scalar my $DESC  => q{Use concise names};
Readonly::Scalar my $EXPL  => undef;

sub applies_to           { return qw/PPI::Statement::Variable PPI::Statement::Sub/ }
sub default_severity     { return $SEVERITY_LOW      }
sub default_themes       { return qw/cosmetic/ }

sub supported_parameters {
	return (
		{
			name           => 'subs',
			description    => 'Report excessive subroutine names.',
			default_string => '1',
			behavior       => 'boolean',
		},
		{
			name           => 'vars',
			description    => 'Report excessive variable names.',
			default_string => '1',
			behavior       => 'boolean',
		},
		{
			name           => 'length',
			description    => 'Maximum identify length.',
			default_string => '15',
			behavior       => 'integer',
			integer_minimum=> 0,
		},
		{
			name           => 'words',
			description    => 'Maximum number of words.',
			default_string => '3',
			behavior       => 'integer',
			integer_minimum=> 0,
		},
		{
			name           => 'smallest',
			description    => 'Smallest word length in a multi-word.',
			default_string => '4',
			behavior       => 'integer',
			integer_minimum=> 0,
		},
		{
			name           => 'lpw',
			description    => 'Length-per-word maximum average.',
			default_string => '7',
			behavior       => 'integer',
			integer_minimum=> 0,
		},
		{
			name           => 'short',
			description    => 'Always allowed at-or-below this length.',
			default_string => '6',
			behavior       => 'integer',
			integer_minimum=> 0,
		},
	);
}

sub desigil {
	my ($name)=@_;
	$name=~s/^[\%\@\$\&\*]//;
	$name=~s/.*:://;
	return $name;
}

sub splitter {
	my ($name)=@_;
	$name=~s/^[\%\@\$\&\*]//;
	$name=~s/.*:://;
	$name=~s/^_+//;
	if($name=~/^[A-Z]+$/) { return $name }
	if($name=~/_/) { return split(/_+/,$name) }
	return split(/(?=[A-Z])/,$name)
}

sub happy {
	my ($name,$w,$L,$lpw,$small,$short)=@_;
	$name=desigil($name);
	my $NL=length($name);
	if($short&&($NL<=$short)) { return 1 }
	if($L&&($NL>$L)) { return 0 }
	my @S=splitter($name);
	if($w&&($#S>=$w)) { return 0 }
	if($#S) {
		if($lpw&&($NL>$lpw*(1+$#S))) { return 0 }
		if($small) { foreach my $word (grep {length($_)<$small} @S) { return 0 } }
	}
	return 1;
}

sub invalid {
	my ($self,$elem,$note)=@_;
	$note//='';
	if($note) { $note=" ($note)" }
	return $self->violation(sprintf("%s%s",$DESC,$note),$EXPL,$elem);
}

sub violates {
	my ($self,$elem,undef)=@_;
	my %violations;
	if($$self{_vars}&&$elem->isa('PPI::Statement::Variable')) {
		%violations=map {$_=>undef} grep {!happy($_,@$self{qw/_words _length _lpw _smallest _short/})} $elem->variables()
	}
	elsif($$self{_subs}&&$elem->isa('PPI::Statement::Sub')) {
		%violations=map {$_=>undef} grep {!happy($_,@$self{qw/_words _length _lpw _smallest _short/})} $elem->name();
	}
	if(%violations) { return $self->invalid($elem,join(',',sort keys(%violations))) }
	return;
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitExcessiveNames - Use concise variable and subroutine names.

=head1 DESCRIPTION

Modules adhering to the Single Responsibility Principle should ensure that external context does not poison internal logic and clarity.  Complex data should be represented structurally, not by using "universally unique names".

  $thing_num                                             # no
  $thing                                                 # yes

  ($thing_num, $thing_name, $thing_title)                # no
  %thing, $thing{num}, $thing{name}, $thing{title}       # yes
  $thing, $thing->num(), $thing->name(), $thing->title() # yes

  $whatsit->translate_thing_from_json($thing_json)       # no
  $whatsit->translate_motte_from_json($motte_json)       # no
  $whatsit->from_json(thing=>$doc)                       # yes
  $whatsit->from_json(motte=>$doc)                       # yes

=head2 Rules

=over

=item * No more than length fifteen, ever.

=item * No more than three words, ever.

=item * If a name uses more than one word, all words must have length greater than three.

(See L</CONFIGURATION>)

=back

=head2 Discussion

Lengthy, multiword names in code are indistinguishable from noise and, in general, a single line of code cannot reasonably represent a logical expression if each variable and function name is itself comprised of a large number of words.  The issue is compounded by code style rules that pressure toward shorter line lengths, where a single function call and its parameters may span multiple lines when large names are in use.

Consider the Unix spell-checking dictionary which contains 48.5k words between length four and seven (inclusive).  Taking the default configuration for this policy, there are more than 7.5 trillion combinations possible (42 bits, which exceeds Unix cksum as well as common non-cryptographic hash functions).  The claim is not that all such combinations will be meaningful, but that names of this length become I<meaningless> and, eventually, indistinguishable.

=head1 CONFIGURATION

The following control declarations that are considered violations.

=over

=item * C<length>:  The hard limit for maximum identifier length.  Default fifteen.

=item * C<words>:  The maximum number of words permitted.  Default three.

=item * C<smallest>:  The smallest permitted length for a single word in a multi-word identifier.  Default four.

=item * C<lpw>:  When non-zero, enforce a maximum length of C<lpw*N>, where C<N> is the number of words in the identifier.  Default seven, so that two-word identifiers still fall under the default C<length> limit.  Note that the computed length is the entire identifier, including leading underscores that signify "private" names.

=item * C<short>:  Names under this length are always allowed.  Default six.

=item * C<subs>:  Report excessive subroutine names.  Default 1.

=item * C<vars>:  Report excessive variable names.  Default 1.

=back

=head1 TODO

=head2 Approved short words

Some common prefix/suffixes should be configurable:  C<has> C<is> C<new> C<ok> C<to>

=head2 Abbreviations

In some cases, variables may contain sequences of uppercase letters that act as abbreviations:  loadFromPNG, CSVwrite.  While the underscore separation in such cases is clear (load_from_PNG, CSV_write), the camelcase variants may be indistinguishable (CSVwrite versus CSVWrite).  It may also be that all are "wrong" and should instead be:

  load(type=>'png',...)
  write(type=>'csv',...)

But that mostly just moves the cheese since internal helpers would still be called writeCSV and loadPNG.

A configuration to support tail-only abbreviations may be appropriate:  camelCaseThingAAA.

=cut
