package Perl::Critic::Policy::Generic::External;

use strict;
use warnings;

use Perl::Critic::Utils qw/:severities/;
use base 'Perl::Critic::Policy';

our $VERSION = '0.1.4';

sub supported_parameters {
	return (
		{
			name           => 'filetsv',
			description    => 'File of violations (TSV).',
			default_string => '',
			behavior       => 'string',
		},
	);
}

sub applies_to           { return qw/PPI::Token/ }
sub default_severity     { return $SEVERITY_LOW }
sub default_themes       { return qw// }

# Create a randomly-named cache inside the policy instance.
my $cachekey;
sub initialize_if_enabled {
	my ($self,$config)=@_;
	my %opt=(
		tsv=>$config->get('filetsv'),
	);
	if(!grep {!!$_} values(%opt)) { return 0 }
	my $name='__GENERICEXTERNAL';
	my $suffix=int(rand(1e9));
	my $retry=3;
	while($retry&&exists($$self{"$name$suffix"})) { $suffix=int(rand(1e9)); $retry-- }
	if(exists($$self{"$name$suffix"})) { warn 'Generic::External unable to build cache' }
	else { $cachekey="$name$suffix" }
	return 1;
}

sub cache {
	my ($self)=@_;
	return %{$$self{$cachekey}//{}};
}

sub retrieveFiles {
	my ($self,$docfn)=@_;
	$docfn=~s/^\.\///;
	if($$self{_filetsv}) {
		if($$self{files}&&!$$self{files}{$docfn}) { return }
		my @violations;
		open(my $fh,'<',$$self{_filetsv});
		while(<$fh>) { chomp;
			if   (/^# Description for (\w+::\w+):\s*(.*)$/) { $$self{$cachekey}{desc}{$1}=$2 }
			elsif(/^# Explanation for (\w+::\w+):\s*(.*)$/) { $$self{$cachekey}{expl}{$1}=$2 }
			elsif(/.+\t.+\t.+\t.+\t.+/) {
				my ($srcfn,@data)=split(/\t/,$_);
				if($#data>=3) {
					$data[2]=~s/[^A-Za-z0-9_]//g;
					$data[3]=~s/[^A-Za-z0-9_]//g;
					if   ($data[2]=~/^[^A-Za-z]/) { print STDERR "Invalid category:  $data[2]\n" }
					elsif($data[3]=~/^[^A-Za-z]/) { print STDERR "Invalid category:  $data[3]\n" }
					else {
						# just prototyping, TODO use regexp or something else
						if($srcfn eq $docfn) { push @violations,\@data }
						$$self{$cachekey}{files}{$srcfn}=1;
					}
				}
			}
		}
		close($fh);
		@{$$self{$cachekey}{violations}}=sort {
			($$a[0] cmp $$b[0])
			|| ($$a[1]<=>$$b[1])
			|| ($$a[2]<=>$$b[2])
			} @violations;
	}
	return;
}

sub prepare_to_scan_document {
	my ($self,$doc)=@_;
	if(!$cachekey) { return 1 }
	$self->retrieveFiles($doc->filename());
	return 1;
}

sub _withPolicy {
	my ($self,$cat,$pol)=@_;
	if(!$cat) { return $self }
	$pol||='External';
	my $policy="Perl::Critic::Policy::${cat}::$pol";
	my $path=($policy=~s/::/\//gr);
	if(!$INC{$path}) {
		my $eval="package $policy".q|{
			our @ISA='Perl::Critic::Policy';
			sub dispatch { my ($self,@arg)=@_; return $self->violation(@arg) }
		};|;
		# print STDERR "Building $policy\n";
		eval($eval);
		if($@) { die "Failed to create dynamic $policy" }
		$INC{$path}='/dev/null';
	}
	return $policy->new();
}

sub invalid {
	my ($self,$elem,undef,undef,$cat,$pol,$note)=@_;
	$note//='';
	if($note) { $note=" ($note)" }
	my $policy=$self->_withPolicy($cat,$pol);
	$policy->dispatch($$self{$cachekey}{desc}{"${cat}::$pol"}//$pol,$$self{$cachekey}{expl}{"${cat}::$pol"}//'',$elem);
}

# Assume that $line,$col inputs are ordered.
# If a $this shows up past ($line,$col), the violation was missed and should emit.
sub _within {
	my ($line,$col,$this)=@_;
	my $next=$this->next_token();
	my ($rb,$cb)=(@{$next->location()})[0,1];
	if($rb<$line) { return }
	my ($ra,$ca)=(@{$this->location()})[0,1];
	if(($rb>$ra)&&($cb==1)) { $cb=0 }
	if($ra>$line) { return 1 }
	elsif($ra==$line) {
		if($rb>$line)               { return 1 }
		if($col<$ca)                { return 1 }
		if(($ca<=$col)&&($col<$cb)) { return 1 }
		return;
	}
	elsif($rb>$line) { return 1 } # ra<line
	elsif($col<$cb)  { return 1 } # ra<line, rb=line
	else { return }
}

sub violates {
	my ($self,$elem,$doc)=@_;
	if(!$cachekey) { return }
	# print '  loc:',join(':',map{$_//'u'} @{$elem->location()}),"\n";
	my $V=$$self{$cachekey}{violations};
	while(@$V&&_within($$V[0][0],$$V[0][1],$elem)) { return $self->invalid($elem,@{shift @$V}) }
	return;
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::Generic::External - Dynamically ingest violations from external files, Copilot, ChatGPT, Claude

=head1 DESCRIPTION

L<Perl::Critic> is already used by organizations to analyze and track code improvement needs.  External tooling that performs static analysis of code can be integrated into the same workflows by producing data that is directly available when L<Perl::Critic> analyzes each file.

=head2 Example

Suppose an external scanner identifies the following concerns and categorizes them as:

  # Description for BuiltinFunctions::UseSay:  Use 'say' instead of print \n.
  # Explanation for BuiltinFunctions::UseSay:  ... so using 'say' is more common.
  a.pl   3   0   BuiltinFunctions   UseSay
  a.pl   3   6   BuiltinFunctions   UseSprintf

When Generic::External is configured to use that source file, it yields:

  perlcritic --verbose '%m in %f %l:%c (%p)\n' a.pl

  Use 'say' instead of print \n in a.pl 3:1 (BuiltinFunctions::UseSay)
  UseSprintf in a.pl 3:6 (BuiltinFunctions::UseSprintf)

=head1 CONFIGURATION

=head2 filetsv

A tab-separated file can be used to identify files with violations:

  [Generic::External]
  filetsv = filename.tsv

The general format of the file should be I<tab> separated columns:

  source line column Category Policy

The violations can appear in any order.  Note that the file may be scanned I<multiple times> during perlcritic execution.

Descriptions and Explanations may be included in the file:

  # Description for Category::Policy:  Here is some description.
  # Explanation for Category::Policy:  Here is some explanation.

Each is limited to a single line and the category and policy must exactly match the I<resulting> violation package name.

=head1 VIOLATIONS

=head2 Category and Policy

Each violation must include a Category and Policy, which will associate with a violation for Perl::Critic::Policy::Category::Policy.  Names must match C</[A-Za-z][A-Za-z0-9_]*/> as with regular Perl package names.  Names are first stripped of all extra characters so "Some Category" will become "SomeCategory".

=head2 Filenames

At this time, filenames must match exactly.  Any file that perlcritic scans of the form C<./source.ext> will check external references only for C<source.ext>.

=head2 Violation location

Violations will generally emit based on the line and column as:

* Exactly at the matching token if it exists within the document.

* With this token if the next token would be past the violation.

If a violation has a column number of zero, it will emit with the first token on that line.

=head1 TODO

The following appear in no particular priority order.

=head2 filetsv

Subject to change... Currently the file is scanned when each source file is checked by perlcritic.  To reduce unnecessary reads, the full file list is loaded on first read; any document being scanned by Perl::Critic will be skipped if the filename didn't appear in the file.  Otherwise the file will be fully read for matching lines.  This approach is primarily to avoid the memory overhead of fully loading the file in the first pass, since large repositories may have 10--100MB of violations per 1000 files.  Options include loading it and not caring, always rereading, or setting some configurable limit at which rereading is enabled.

=head2 Input

Add support for:  filejson, cli.

After the performance/memory question has been answered for filetsv, it may be reasonable to support wildcard directories/names as input.

=head2 Policy skipping

It may be reasonable to skip any external policies that are already loaded/defined by the Perl::Critic profile.  Presumably those represent overlaps and should not be emitted twice.

=head1 BUGS

None known.

=cut
