package Perl::Critic::Policy::ValuesAndExpressions::RequireSlices;

use 5.010001;
use strict;
use warnings;
use Readonly;
use Scalar::Util qw/refaddr/;

use Perl::Critic::Utils qw/:severities/; # :classification
use base 'Perl::Critic::Policy';

our $VERSION = '0.1.0';

Readonly::Scalar my $DESC  => q{Write chains of array/hash access as slices};
Readonly::Scalar my $EXPL  => undef;

#-----------------------------------------------------------------------------

sub supported_parameters {
	return (
		{
			name           => 'minimum',
			description    => 'Subscript repetition needed to raise a violation (only 2 is supported).',
			default_string => '2',
			behavior       => 'integer',
			integer_minimum => 1,
		},
	);
}

sub applies_to           { return qw/PPI::Structure::Subscript/ }
sub default_severity     { return $SEVERITY_LOW }
sub default_themes       { return qw/cosmetic/ }

#-----------------------------------------------------------------------------

sub invalid {
	my ($self,$elem,$note)=@_;
	$note//='';
	if($note) { $note=" ($note)" }
	return $self->violation(sprintf("%s%s",$DESC,$note),$EXPL,$elem);
}

sub parseStatement {
	my ($statement)=@_;
	my $skiptocomma=0;
	my %boot=(violates=>0,path=>'',node=>undef);
	my @res=({%boot});
	foreach my $node ($statement->children()) {
		if($skiptocomma) {
			if($node->isa('PPI::Token::Operator') && ($node->content()=~/\s*,\s*/)) { push @res,{%boot}; $skiptocomma=0 }
			next;
		}
		if($node->isa('PPI::Token::Symbol')) { $res[-1]{path}=$node->content() }
		elsif($node->isa('PPI::Structure::Subscript')) {
			if($res[-1]{node}) { $res[-1]{path}.=','.$res[-1]{node}->content() }
			else {
				my $type=$node->start()->content();
				$res[-1]{path}.=$type;
				if   ($type eq '[') { $res[-1]{path}=~s/^[\@\$]+/@/ } # ]
				elsif($type eq '{') { $res[-1]{path}=~s/^[\@\$]+/%/ } # }
			}
			$res[-1]{node}=$node;
		}
		elsif($node->isa('PPI::Token::Operator') && ($node->content()=~/\s*,\s*/))  { push @res,{%boot} }
		elsif($node->isa('PPI::Token::Operator') && ($node->content()=~/\s*->\s*/)) { 1 }
		elsif($node->isa('PPI::Token::Operator')) { %{$res[-1]}=%boot; $skiptocomma=1 }
		elsif($node->isa('PPI::Structure::List')) { 1 }
		elsif($node->isa('PPI::Token::Word'))     { %{$res[-1]}=%boot; $skiptocomma=1 }
		else                                      { $res[-1]={%boot} }
	}
	return @res;
}

sub countViolations {
	my ($M,$P)=@_;
	my $idx=$#$P-$M+1;
	while($idx>=0) {
		my $violates=0;
		if($$P[$idx]{node}) {
			$violates=1;
			foreach my $off (1..($M-1)) {
				if(!$$P[$off+$idx]{node} || ($$P[$idx]{path} ne $$P[$off+$idx]{path})) {
					$violates=0 } } }
		if($violates) {
			$$P[$idx]{violates}=1;
			foreach my $off (1..($M-1)) { $$P[$off+$idx]{violates}=0 }
		}
		$idx--;
	}
	return;
}

my $cachekey;
sub stmtViolates {
	my ($self,$elem,$statement)=@_;
	my $nodes;
	if($cachekey) {
		my ($cache,$recent)=@{$$self{$cachekey}}{qw/cache recent/};
		my $skey=join(',',map {$_//'U'} @{$statement->location()});
		if($$cache{$skey}&&($$cache{$skey}[0]<$#$recent)) {
			push @$recent,$skey;
			splice(@$recent,$$cache{$skey}[0],1);
			$$cache{$skey}[0]=$#$recent;
		}
		elsif(!$$cache{$skey}) {
			push @$recent,$skey;
			my @parsed=parseStatement($statement);
			countViolations($$self{_minimum},\@parsed);
			$$cache{$skey}=[$#$recent,\@parsed];
			while($#$recent>63) {
				my $rkey=shift(@$recent);
				delete($$cache{$rkey});
			}
		}
		# else the cache key is defined and the most recent, do nothing
		$nodes=$$cache{$skey}[1];
	}
	else { # no caching support
		my @parsed=parseStatement($statement);
		countViolations($$self{_minimum},\@parsed);
		$nodes=\@parsed;
	}
	foreach my $node (@$nodes) {
		if($$node{violates} && (refaddr($$node{node})==refaddr($elem))) { return $self->invalid($elem) }
	}
	return;
}

# Create a statement cache inside the policy instance.  While unlikely, this permits
# parallel scans launched by perlcritic, and prevents bleed across scanned documents.
sub initialize_if_enabled {
	my ($self,$config)=@_;
	my $name='__REQUIRESLICES__';
	my $suffix=int(rand(1e9));
	my $retry=3;
	while($retry&&exists($$self{"$name$suffix"})) { $suffix=int(rand(1e9)); $retry-- }
	if(exists($$self{"$name$suffix"})) { warn 'RequireSlices unable to build statement cache' }
	else {
		$cachekey="$name$suffix";
		$$self{$cachekey}={cache=>{},recent=>[]};
	}
	return 1;
}

# Reset the cache between documents
sub prepare_to_scan_document {
	my ($self,$doc)=@_;
	if($cachekey) { $$self{$cachekey}={cache=>{},recent=>[]} }
	return 1;
}

sub violates {
	my ($self,$elem,undef)=@_;
	if(!$elem->isa('PPI::Structure::Subscript')) { return }
	my $parent=$elem->parent();
	if(ref($parent) eq 'PPI::Statement')             { return $self->stmtViolates($elem,$parent) }
	if(ref($parent) eq 'PPI::Statement::Expression') { return $self->stmtViolates($elem,$parent) }
	return;
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::References::RequireSlices - Use array and hash slices for multiple lookups

=head1 DESCRIPTION

Value slices of arrays and hashes, and key-value slices of hashes, permit selecting multiple indexes/keys/values in a single call.  This reduces redundancy of code and permits runtime optimization.

  $array[1], $array[3]                 # no
  @array[1,3]                          # yes

  $hash{one}, $hash{two}               # no
  @hash{qw/one two/}                   # yes

  $hash{$one}, $hash{$two}             # no
  @hash{$one, $two}                    # yes

  $hash{one}, $hash{two}, $hash{three} # no
  @hash{qw/one two three/}             # yes

  $hash{one}{two}, $hash{two}{one}     # yes
  $hash{one}{one}, $hash{one}{two}     # no
  @{$hash{one}}{qw/one two/}           # yes

=head1 CONFIGURATION

By default, two lookups of the same object in a sequence is considered a violation.  In living code, it may be easier to manage rewriting to slices when hitting three lookups.  This can be controlled with the C<minimum> option:

  [ValuesAndExpressions::RequireSlices]
  minimum = 3

This setting represents the number of I<symbol uses> and not the number of elements being selected.  In particular, there is no detection of the count of keys inside existing slices:

  @hash{qw/one two/}, $hash{three}  # okay with minimum=3

=head1 NOTES

A violation occurs for array subscripts and hash key 'subscripts' at any level.  Violations are attached only to the I<first occurrence> in the list.  A list may still have multiple violations, however, such as with:

  $hash{one}, $hash{two}, 5, $hash{three}, $hash{four} # no
  @hash{qw/one two/}, 5, @hash{qw/three four/}         # yes

=head2 Written code optimization

Slices are useful when more than one subscript is needed, but the actual code savings is dependent on:
C<V> the length of the variable name;
C<N> the number of keys referenced;
C<K> the total length of the C<N> keynames;

If a hash is used in a literal value-slicing situation:

  $hash{one}, $hash{two} takes (N+N*V+2(N-1)+2N+K)
  @hash{qw/one two/}     takes (1+V+2+4+K+(N-1))

The first is (sigils, variable name redundancy, comma-spaces, curlies, keys).  The second is (sigil, variable name, curlies, qw, keys, and the spaces between).  Totals are K+4N+NV-2 vs K+N+V+6, so the rewrite reduces space when C<V+8E<lt>N(V+4)>.

Hash used with variable value-slicing:

  $hash{$one}, $hash{$two} takes (N+N*V+2(N-1)+2N+K)
  @hash{$one,$two}         takes (1+V+2+K+2(N-1))

Totals are K+4N+NV-2 vs K+2N+V+1, so the rewrite reduces space when C<V+3E<lt>N(V+3)>.

Hash used with literals quoted separately:

  $hash{one}, $hash{two} takes (N+N*V+2(N-1)+2N+K)
  @hash{'one', 'two'}    takes (1+V+2+2N+K+2(N-1))

Totals are K+4N+NV-2 vs K+4N+V+1, so the rewrite reduces space when C<V+3E<lt>N(V+1)>.

Hash reference with literal postfix dereferencing:

  $href->{one}, $href->{two} takes (5N+NV+2(N-1)+K)
  @$href{qw/one two/}        takes (2+V+2+4+K+(N-1))

Rewrite reduces space when C<V+9E<lt>N(V+6)>

Hash reference with literal postfix dereferencing, and postfix slicing:

  $href->{one}, $href->{two} takes (5N+NV+2(N-1)+K)
  $href->@{qw/one two/}      takes (4+V+2+4+K+(N-1))

Rewrite reduces space when C<V+11E<lt>N(V+6)>

For C<VE<gt>0>, the right-hand sides increase with C<N>, and the LHS are fixed.  For C<NE<gt>=2>, C<N(V+k)E<gt>=2V+2k=V+(2k+V)E<gt>=V+(2k+1)>.  All of the above inequalities hold, except the separately-quoted case which may be equal in some cases.

=head1 BUGS

Key-value slicing is not currently supported.

Perl version is not considered.

Messaging could be a bit more specific.

=head1 SEE ALSO

L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitSingleArgArraySlice>

=cut
