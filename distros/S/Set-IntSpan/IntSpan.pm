package Set::IntSpan;

use 5;
use if $Set::IntSpan::integer, qw(integer);
use strict;
use base qw(Exporter);
use Carp;

our $VERSION   = '1.19';
our @EXPORT_OK = qw(grep_set map_set grep_spans map_spans);

use overload
    '+'    => 'union'     ,
    '-'    => 'diff'      ,
    '*'    => 'intersect' ,
    '^'    => 'xor'       ,
    '~'    => 'complement',

    '+='   => 'U'	  ,
    '-='   => 'D'	  ,
    '*='   => 'I'	  ,
    '^='   => 'X'	  ,

    'eq'   => 'set_eq' 	  ,
    'ne'   => 'set_ne' 	  ,
    'lt'   => 'set_lt' 	  ,
    'le'   => 'set_le' 	  ,
    'gt'   => 'set_gt' 	  ,
    'ge'   => 'set_ge' 	  ,

    '<=>'  => 'spaceship' ,
    'cmp'  => 'spaceship' ,

    '""'   => 'run_list'  ,
    'bool' => sub { not shift->empty };

sub _reorder # restore the order of args that are reversed by operator overloads
{
    if ($_[2])
    {
	my $temp = $_[0];
	$_[0] = $_[1];
	$_[1] = $temp;
    }
}

sub set_eq
{
    my($a, $set_spec) = @_;
    my $b = $a->_real_set($set_spec);
    $a->equal($b)
}

sub set_le
{
    my($a, $set_spec, $reverse) = @_;
    my $b = $a->_real_set($set_spec);
    _reorder($a, $b, $reverse);
    $a->subset($b)
}

sub set_ge
{
    my($a, $set_spec, $reverse) = @_;
    my $b = $a->_real_set($set_spec);
    _reorder($a, $b, $reverse);
    $a->superset($b)
}

sub set_ne {             not &set_eq }
sub set_lt { &set_le and not &set_eq }
sub set_gt { &set_ge and not &set_eq }


sub set_cmp
{
    my($a, $b, $reverse) = @_;
    $b = $a->_real_set($b);

    _reorder($a, $b, $reverse);

    $a->equal($b) ? 0 : 1;
}


sub spaceship
{
    my($a, $b, $reverse) = @_;
    ref $a and $a = $a->size;
    ref $b and $b = $b->size;

    _reorder($a, $b, $reverse);

    $a ==  $b and return  0;
    $a <   0  and return  1;
    $b <   0  and return -1;
    $a <=> $b
}


$Set::IntSpan::Empty_String = '-';


sub new
{
    my($this, $set_spec, @set_specs) = @_;

    my $class = ref($this) || $this;
    my $set   = bless { }, $class;
    $set->{empty_string} = \$Set::IntSpan::Empty_String;
    $set->copy($set_spec);

    while (@set_specs)
    {
	$set = $set->union(shift @set_specs);
    }

    $set
}


sub valid
{
    my($this, $run_list) = @_;
    my $class = ref($this) || $this;
    my $set   = new $class;

    eval { $set->_copy_run_list($run_list) };
    $@ ? 0 : 1
}


sub copy
{
    my($set, $set_spec) = @_;

  SWITCH:
    {
	defined $set_spec            or  $set->_copy_empty   (         ), last;
	ref     $set_spec            or  $set->_copy_run_list($set_spec), last;
	ref     $set_spec eq 'ARRAY' and $set->_copy_array   ($set_spec), last;
				         $set->_copy_set     ($set_spec)      ;
    }

    $set
}


sub _copy_empty			# makes $set the empty set
{
    my $set = shift;

    $set->{negInf} = 0;
    $set->{posInf} = 0;
    $set->{edges } = [];
}


sub _copy_array			# copies an array into a set
{
    my($set, $array) = @_;

    my @spans    = 		      grep { ref     } @$array;
    my @elements = sort { $a <=> $b } grep { not ref } @$array;

    my @span;
    for my $e (@elements)
    {
	if (@span==0)
	{
	    push @span, $e;
	}
	elsif (@span==1 and $e==$span[0]+1)
	{
	    push @span, $e;
	}
	elsif (@span==1 and $e >$span[0]+1)
	{
	    push @spans, [ $span[0], $span[0] ];
	    @span = ($e);
	}
	elsif (@span==2 and $e==$span[1]+1)
	{
	    $span[1] = $e;
	}
	elsif (@span==2 and $e >$span[1]+1)
	{
	    push @spans, [ @span ];
	    @span = ($e);
	}
    }

    @span==1 and push @spans, [ $span[0], $span[0] ];
    @span==2 and push @spans, [ @span ];

    $set->_insert_spans(\@spans)
}

sub bySpan
{
    my($al, $au) = @$a;
    my($bl, $bu) = @$b;

       if (defined $al && defined $bl) { return $al <=> $bl; }
    elsif (defined $al               ) { return  1;          }
    elsif (               defined $bl) { return -1;          }
    elsif (defined $au               ) { return -1;          }
    elsif (               defined $bu) { return  1;          }
    else                               { return  0;          }
}

sub _insert_spans
{
    my($set, $spans) = @_;

    my @edges;
    $set->{negInf} = 0;
    $set->{posInf} = 0;
    $set->{edges } = \@edges;

    my @spans = sort bySpan @$spans;

    if (@spans and not defined $spans[0][0])
    {
	$set->{negInf} = 1;
	my $span = shift @spans;

	if (not defined $span->[1])
	{
	    $set->{posInf} = 1;
	    return $set;
	}

	push @edges, $span->[1];

	while (@spans and not defined $spans[0][0])
	{
	    my $span = shift @spans;
	    $edges[0] = $span->[1] if $edges[0] < $span->[1];
	}
    }

    for (@spans) { $_->[0]--; }

    if (@spans and not @edges)
    {
	my $span = shift @spans;

	if (defined $span->[1])
	{
	    push @edges, @$span;
	}
	else
	{
	    push @edges, $span->[0];
	    $set->{posInf} = 1;
	    return $set;
	}
    }

    while (@spans and defined $spans[0][1])
    {
	my $span = shift @spans;
	if ($edges[-1] < $span->[0])
	{
	    push @edges, @$span;
	}
	else
	{
	    $edges[-1] = $span->[1] if $edges[-1] < $span->[1];
	}
    }

    if (@spans)
    {
	$set->{posInf} = 1;
	my $span = shift @spans;

	if ($edges[-1] < $span->[0])
	{
	    push @edges, $span->[0];
	}
	else
	{
	    pop @edges;
	}
    }

    return $set
}


sub _copy_set			# copies one set to another
{
    my($dest, $src) = @_;

    $dest->{negInf} =     $src->{negInf};
    $dest->{posInf} =     $src->{posInf};
    $dest->{edges } = [ @{$src->{edges }} ];
}


sub _copy_run_list		# parses a run list
{
    my($set, $runList) = @_;

    $set->_copy_empty;

    $runList =~ s/\s|_//g;
    return if $runList eq '-';	# empty set

    my($first, $last) = (1, 0);	# verifies order of infinite runs

    my @edges;
    for my $run (split(/,/ , $runList))
    {
    	croak "Set::IntSpan::_copy_run_list: Bad order 1: $runList\n" if $last;

      RUN:
    	{
	    $run =~ /^ (-?\d+) $/x and do
	    {
		push(@edges, $1-1, $1);
		last RUN;
	    };

	    $run =~ /^ (-?\d+) - (-?\d+) $/x and do
	    {
		croak "Set::IntSpan::_copy_run_list: Bad order 2: $runList\n"
		    if $1 > $2;
		push(@edges, $1-1, $2);
		last RUN;
	    };

	    $run =~ /^ \( - (-?\d+) $/x and do
	    {
		croak "Set::IntSpan::_copy_run_list: Bad order 3: $runList\n"
		    unless $first;
		$set->{negInf} = 1;
		push @edges, $1;
		last RUN;
	    };

	    $run =~ /^ (-?\d+) - \) $/x and do
	    {
		push @edges, $1-1;
		$set->{posInf} = 1;
		$last = 1;
		last RUN;
	    };

	    $run =~ /^ \( - \) $/x and do
	    {
		croak "Set::IntSpan::_copy_run_list: Bad order 4: $runList\n"
		    unless $first;
		$last = 1;
		$set->{negInf} = 1;
		$set->{posInf} = 1;
		last RUN;
	    };

	    croak "Set::IntSpan::_copy_run_list: Bad syntax: $runList\n";
	}

	$first = 0;
    }

    $set->{edges} = [ @edges ];

    $set->_cleanup or
	croak "Set::IntSpan::_copy_run_list: Bad order 5: $runList\n";
}


# check for overlapping runs
# delete duplicate edges
sub _cleanup
{
    my $set = shift;
    my $edges = $set->{edges};

    my $i=0;
    while ($i < $#$edges)
    {
	my $cmp = $$edges[$i] <=> $$edges[$i+1];
	{
	    $cmp == -1 and $i++                  , last;
	    $cmp ==  0 and splice(@$edges, $i, 2), last;
	    $cmp ==  1 and return 0;
	}
    }

    1
}


sub run_list
{
    my $set = shift;

    $set->empty and return ${$set->{empty_string}};

    my @edges = @{$set->{edges}};
    my @runs;

    $set->{negInf} and unshift @edges, '(';
    $set->{posInf} and push    @edges, ')';

    while(@edges)
    {
	my($lower, $upper) = splice @edges, 0, 2;

	if ($lower ne '(' and $upper ne ')' and $lower+1==$upper)
	{
	    push @runs, $upper;
	}
	else
	{
	    $lower ne '(' and $lower++;
	    push @runs, "$lower-$upper";
	}
    }

    join(',', @runs)
}

sub dump
{
    my $set = shift;
    ($set->{negInf} ? '(' : '') . join ',', @{$set->{edges}} . ($set->{posInf} ? ')' : '')
}

sub elements
{
    my $set = shift;

    ($set->{negInf} or $set->{posInf}) and
	croak "Set::IntSpan::elements: infinite set\n";

    my @elements;
    my @edges = @{$set->{edges}};
    while (@edges)
    {
	my($lower, $upper) = splice(@edges, 0, 2);
	push @elements, $lower+1 .. $upper;
    }

    wantarray ? @elements : \@elements
}

sub sets
{
    my $set   = shift;
    my @edges = @{$set->{edges}};

    unshift @edges, undef if $set->{negInf};
    push    @edges, undef if $set->{posInf};

    my @sets;
    while (@edges)
    {
	my($lower, $upper) = splice(@edges, 0, 2);

	$lower = defined $lower ? $lower+1 : '(';
	$upper = defined $upper ? $upper   : ')';

	push @sets, Set::IntSpan->new("$lower-$upper");
    }

    @sets
}


sub spans
{
    my $set   = shift;
    my @edges = @{$set->{edges}};

    unshift @edges, undef if $set->{negInf};
    push    @edges, undef if $set->{posInf};

    my @spans;
    while (@edges)
    {
	my($lower, $upper) = splice(@edges, 0, 2);
	$lower++
	    if defined $lower;
	push @spans, [$lower, $upper];
    }

    @spans
}


sub _real_set		# converts a set specification into a set
{
    my($set, $set_spec) = @_;

    (defined $set_spec and ref $set_spec and ref $set_spec ne 'ARRAY') ?
	$set_spec :
	$set->new($set_spec)
}

sub U
{
    my($a, $set_spec) = @_;
    my $s = $a->union($set_spec);
    $a->{negInf} = $s->{negInf};
    $a->{posInf} = $s->{posInf};
    $a->{edges } = $s->{edges };
    $a
}

sub union
{
    my($a, $set_spec) = @_;
    my $b = $a->_real_set($set_spec);
    my $s = $a->new;

    $s->{negInf} = $a->{negInf} || $b->{negInf};

    my $eA = $a->{edges};
    my $eB = $b->{edges};
    my $eS = $s->{edges};

    my $inA = $a->{negInf};
    my $inB = $b->{negInf};

    my $iA = 0;
    my $iB = 0;

    while ($iA<@$eA and $iB<@$eB)
    {
	my $xA = $$eA[$iA];
	my $xB = $$eB[$iB];

	if ($xA < $xB)
	{
	    $iA++;
	    $inA = ! $inA;
	    not $inB and push(@$eS, $xA);
	}
	elsif ($xB < $xA)
	{
	    $iB++;
	    $inB = ! $inB;
	    not $inA and push(@$eS, $xB);
	}
	else
	{
	    $iA++;
	    $iB++;
	    $inA = ! $inA;
	    $inB = ! $inB;
	    $inA == $inB and push(@$eS, $xA);
	}
    }

    $iA < @$eA and ! $inB and push(@$eS, @$eA[$iA..$#$eA]);
    $iB < @$eB and ! $inA and push(@$eS, @$eB[$iB..$#$eB]);

    $s->{posInf} = $a->{posInf} || $b->{posInf};
    $s
}


sub I
{
    my($a, $set_spec) = @_;
    my $s = $a->intersect($set_spec);
    $a->{negInf} = $s->{negInf};
    $a->{posInf} = $s->{posInf};
    $a->{edges } = $s->{edges };
    $a
}

sub intersect
{
    my($a, $set_spec) = @_;
    my $b = $a->_real_set($set_spec);
    my $s = $a->new;

    $s->{negInf} = $a->{negInf} && $b->{negInf};

    my $eA = $a->{edges};
    my $eB = $b->{edges};
    my $eS = $s->{edges};

    my $inA = $a->{negInf};
    my $inB = $b->{negInf};

    my $iA = 0;
    my $iB = 0;

    while ($iA<@$eA and $iB<@$eB)
    {
	my $xA = $$eA[$iA];
	my $xB = $$eB[$iB];

	if ($xA < $xB)
	{
	    $iA++;
	    $inA = ! $inA;
	    $inB and push(@$eS, $xA);
	}
	elsif ($xB < $xA)
	{
	    $iB++;
	    $inB = ! $inB;
	    $inA and push(@$eS, $xB);
	}
	else
	{
	    $iA++;
	    $iB++;
	    $inA = ! $inA;
	    $inB = ! $inB;
	    $inA == $inB and push(@$eS, $xA);
	}
    }

    $iA < @$eA and $inB and push(@$eS, @$eA[$iA..$#$eA]);
    $iB < @$eB and $inA and push(@$eS, @$eB[$iB..$#$eB]);

    $s->{posInf} = $a->{posInf} && $b->{posInf};
    $s
}


sub D
{
    my($a, $set_spec) = @_;
    my $s = $a->diff($set_spec);
    $a->{negInf} = $s->{negInf};
    $a->{posInf} = $s->{posInf};
    $a->{edges } = $s->{edges };
    $a
}

sub diff
{
    my($a, $set_spec, $reverse) = @_;
    my $b = $a->_real_set($set_spec);

    _reorder($a, $b, $reverse);

    my $s = $a->new;

    $s->{negInf} = $a->{negInf} && ! $b->{negInf};

    my $eA = $a->{edges};
    my $eB = $b->{edges};
    my $eS = $s->{edges};

    my $inA = $a->{negInf};
    my $inB = $b->{negInf};

    my $iA = 0;
    my $iB = 0;

    while ($iA<@$eA and $iB<@$eB)
    {
	my $xA = $$eA[$iA];
	my $xB = $$eB[$iB];

	if ($xA < $xB)
	{
	    $iA++;
	    $inA = ! $inA;
	    not $inB and push(@$eS, $xA);
	}
	elsif ($xB < $xA)
	{
	    $iB++;
	    $inB = ! $inB;
	    $inA and push(@$eS, $xB);
	}
	else
	{
	    $iA++;
	    $iB++;
	    $inA = ! $inA;
	    $inB = ! $inB;
	    $inA != $inB and push(@$eS, $xA);
	}
    }

    $iA < @$eA and not $inB and push(@$eS, @$eA[$iA..$#$eA]);
    $iB < @$eB and     $inA and push(@$eS, @$eB[$iB..$#$eB]);

    $s->{posInf} = $a->{posInf} && ! $b->{posInf};
    $s
}


sub X
{
    my($a, $set_spec) = @_;
    my $s = $a->xor($set_spec);
    $a->{negInf} = $s->{negInf};
    $a->{posInf} = $s->{posInf};
    $a->{edges } = $s->{edges };
    $a
}

sub xor
{
    my($a, $set_spec) = @_;
    my $b = $a->_real_set($set_spec);
    my $s = $a->new;

    $s->{negInf} = $a->{negInf} ^ $b->{negInf};

    my $eA = $a->{edges};
    my $eB = $b->{edges};
    my $eS = $s->{edges};

    my $iA = 0;
    my $iB = 0;

    while ($iA<@$eA and $iB<@$eB)
    {
	my $xA = $$eA[$iA];
	my $xB = $$eB[$iB];

	if ($xA < $xB)
	{
	    $iA++;
	    push(@$eS, $xA);
	}
	elsif ($xB < $xA)
	{
	    $iB++;
	    push(@$eS, $xB);
	}
	else
	{
	    $iA++;
	    $iB++;
	}
    }

    $iA < @$eA and push(@$eS, @$eA[$iA..$#$eA]);
    $iB < @$eB and push(@$eS, @$eB[$iB..$#$eB]);

    $s->{posInf} = $a->{posInf} ^ $b->{posInf};
    $s
}


sub complement
{
    my $set = shift;
    $set->new($set)->C
}

sub C
{
    my $set = shift;
    $set->{negInf} = ! $set->{negInf};
    $set->{posInf} = ! $set->{posInf};
    $set
}


sub superset
{
    my($a, $set_spec) = @_;
    my $b = $a->_real_set($set_spec);

    $b->diff($a)->empty
}


sub subset
{
    my($a, $b) = @_;

    $a->diff($b)->empty
}


sub equal
{
    my($a, $set_spec) = @_;
    my $b = $a->_real_set($set_spec);

    $a->{negInf} == $b->{negInf} or return 0;
    $a->{posInf} == $b->{posInf} or return 0;

    my $aEdge = $a->{edges};
    my $bEdge = $b->{edges};
    @$aEdge == @$bEdge or return 0;

    for (my $i=0; $i<@$aEdge; $i++)
    {
	$$aEdge[$i] == $$bEdge[$i] or return 0;
    }

    1
}


sub equivalent
{
    my($a, $set_spec) = @_;
    my $b = $a->_real_set($set_spec);

    $a->cardinality == $b->cardinality
}


sub cardinality
{
    my $set = shift;

    ($set->{negInf} or $set->{posInf}) and return -1;

    my $cardinality = 0;
    my @edges = @{$set->{edges}};
    while (@edges)
    {
	my $lower = shift @edges;
	my $upper = shift @edges;
	$cardinality += $upper - $lower;
    }

    $cardinality
}

*size = \&cardinality;


sub empty
{
    my $set = shift;

    not $set->{negInf} and not @{$set->{edges}} and not $set->{posInf}
}


sub finite
{
    my $set = shift;

    not $set->{negInf} and not $set->{posInf}
}


sub neg_inf { shift->{negInf} }
sub pos_inf { shift->{posInf} }


sub infinite
{
    my $set = shift;

    $set->{negInf} or $set->{posInf}
}


sub universal
{
    my $set = shift;

    $set->{negInf} and not @{$set->{edges}} and $set->{posInf}
}


sub member
{
    my($set, $n) = @_;

    my $i = _bsearch($set->{edges}, $n);

    $set->{negInf} xor $i & 1
}

use constant INSERT => 0;
use constant REMOVE => 1;

sub insert { _indel(@_, INSERT); }
sub remove { _indel(@_, REMOVE); }

sub _indel # INsertion/DELetion
{
    my($set, $n, $indel) = @_;
    defined $n or return;

    my $edge = $set->{edges};
    my $i    = _bsearch($edge, $n);

    return if $set->{negInf} xor $i & 1 xor $indel;

    my $lGap = $i==0      || $edge->[$i-1] < $n-1;
    my $rGap = $i==@$edge || $n            < $edge->[$i];

    if    (    $lGap and     $rGap) { splice @$edge, $i, 0, $n-1, $n }
    elsif (not $lGap and     $rGap) { $edge->[$i-1]++                }
    elsif (    $lGap and not $rGap) { $edge->[$i  ]--                }
    else                            { splice @$edge, $i-1, 2         }
}

# Returns the index of the first edge that satisifies target <= edge.
# Returns $#$edges+1 if target > the last edge.
# Returns 0 if edges is empty.
sub _bsearch
{
    my($edges, $target) = @_;

    @$edges or return 0;

    my $lower = 0;
    my $upper = $#$edges;

    while ($lower+1 < $upper)
    {
	my $mid = int(($lower + $upper) / 2);

	if ($target <= $edges->[$mid])
	{
	    $upper = $mid;
	}
	else
	{
	    $lower = $mid+1;
	}
    }

    $target <= $edges->[$lower] and return $lower;
    $target <= $edges->[$upper] and return $upper;
    $upper + 1
}

sub span_ord
{
    my($set, $n) = @_;

    my $i = _bsearch($set->{edges}, $n);
    ($set->{negInf} xor $i & 1) ? $i >> 1 : undef
}

sub min
{
    my $set = shift;

    $set->empty   and return undef;
    $set->neg_inf and return undef;
    $set->{edges}->[0]+1
}


sub max
{
    my $set = shift;

    $set->empty   and return undef;
    $set->pos_inf and return undef;
    $set->{edges}->[-1]
}

sub cover
{
    my $set    = shift;
    my $cover  = $set->new();
    my $edges  = $set->{edges};
    my $negInf = $set->{negInf};
    my $posInf = $set->{posInf};

    if ($negInf and $posInf)
    {
	$cover->{negInf}   = 1;
	$cover->{posInf}   = 1;
    }
    elsif ($negInf and not $posInf)
    {
	$cover->{negInf}   = 1;
	$cover->{edges}[0] = $set->{edges}[-1];
    }
    elsif (not $negInf and $posInf)
    {
	$cover->{edges}[0] = $set->{edges}[0];
	$cover->{posInf}   = 1;
    }
    elsif (@$edges)
    {
	$cover->{edges}[0] = $set->{edges}[ 0];
	$cover->{edges}[1] = $set->{edges}[-1];
    }

    $cover
}

*extent = \&cover;


sub holes
{
    my $set    = shift;
    my $holes  = $set->new($set);
    my $edges  = $holes->{edges};
    my $negInf = $holes->{negInf};
    my $posInf = $holes->{posInf};

    if ($negInf and $posInf)
    {
	$holes->{negInf}   = 0;
	$holes->{posInf}   = 0;
    }
    elsif ($negInf and not $posInf)
    {
	$holes->{negInf}   = 0;
	pop   @$edges;
    }
    elsif (not $negInf and $posInf)
    {
	shift @$edges;
	$holes->{posInf}   = 0;
    }
    elsif (@$edges)
    {
	shift @$edges;
	pop   @$edges;
    }

    $holes
}

sub inset
{
    my($set, $n) = @_;
    my $edges = $set->{edges};
    my @edges = @$edges;

    my $inset = $set->new();
    $inset->{negInf} = $set->{negInf};
    $inset->{posInf} = $set->{posInf};

    my @inset;
    my $nAbs = abs $n;

    if (@edges and ($inset->{negInf} xor $n < 0))
    {
	my $edge = shift @edges;
	push @inset, $edge - $nAbs;
    }

    while (@edges > 1)
    {
	my($lower, $upper) = splice(@edges, 0, 2);
	$lower += $nAbs;
	$upper -= $nAbs;

	push @inset, $lower, $upper
	    if $lower < $upper;
    }

    if (@edges)
    {
	my $edge = shift @edges;
	push @inset, $edge + $nAbs;
    }


    $inset->{edges} = \@inset;
    $inset
}

*trim = \&inset;

sub pad
{
    my($set, $n) = @_;
    $set->inset(-$n)
}


sub grep_set(&$)
{
    my($block, $set) = @_;

    return undef if $set->{negInf} or $set->{posInf};

    my @edges     = @{$set->{edges}};
    my @sub_edges = ();

    while (@edges)
    {
	my($lower, $upper) = splice(@edges, 0, 2);

	for (my $i=$lower+1; $i<=$upper; $i++)
	{
	    local $_ = $i;
	    &$block() or next;

	    if (@sub_edges and $sub_edges[-1] == $i-1)
	    {
		$sub_edges[-1] = $i;
	    }
	    else
	    {
		push @sub_edges, $i-1, $i;
	    }
	}
    }

    my $sub_set = $set->new;
    $sub_set->{edges} = \@sub_edges;
    $sub_set
}


sub map_set(&$)
{
    my($block, $set) = @_;

    return undef if $set->{negInf} or $set->{posInf};

    my $map_set = $set->new;

    my @edges = @{$set->{edges}};
    while (@edges)
    {
	my($lower, $upper) = splice(@edges, 0, 2);

	my $domain;
	for ($domain=$lower+1; $domain<=$upper; $domain++)
	{
	    local $_ = $domain;

	    my $range;
	    for $range (&$block())
	    {
		$map_set->insert($range);
	    }
	}
    }

    $map_set
}


sub grep_spans(&$)
{
    my($block, $set) = @_;

    my @edges     = @{$set->{edges}};
    my $sub_set   = $set->new;
    my @sub_edges = ();

    if ($set->{negInf} and $set->{posInf})
    {
	local $_ = [ undef, undef ];
	if (&$block())
	{
	    $sub_set->{negInf} = 1;
	    $sub_set->{posInf} = 1;
	}
    }
    elsif ($set->{negInf})
    {
	my $upper = shift @edges;
	local $_ = [ undef, $upper ];
	if (&$block())
	{
	    $sub_set->{negInf} = 1;
	    push @sub_edges, $upper;
	}
    }

    while (@edges > 1)
    {
	my($lower, $upper) = splice(@edges, 0, 2);
	local $_ = [ $lower+1, $upper ];
	&$block() and push @sub_edges, $lower, $upper;
    }

    if (@edges)
    {
	my $lower = shift @edges;
	local $_ = [ $lower+1, undef ];
	if (&$block())
	{
	    $sub_set->{posInf} = 1;
	    push @sub_edges, $lower;
	}
    }

    $sub_set->{edges} = \@sub_edges;
    $sub_set
}

sub map_spans(&$)
{
    my($block, $set) = @_;

    my @edges = @{$set->{edges}};
    my @spans;

    if ($set->{negInf} and $set->{posInf})
    {
	local $_ = [ undef, undef ];
	push @spans, &$block();
    }
    elsif ($set->{negInf})
    {
	my $upper = shift @edges;
	local $_ = [ undef, $upper ];
	push @spans, &$block();
    }

    while (@edges > 1)
    {
	my($lower, $upper) = splice(@edges, 0, 2);
	local $_ = [ $lower+1, $upper ];
	push @spans, &$block();
    }

    if (@edges)
    {
	my $lower = shift @edges;
	local $_ = [ $lower+1, undef ];
	push @spans, &$block();
    }

    $set->new->_insert_spans(\@spans)
}


sub first($)
{
    my $set   = shift;

    $set->{iterator} = $set->min;
    $set->{run}[0]   = 0;
    $set->{run}[1]   = $#{$set->{edges}} ? 1 : undef;

    $set->{iterator}
}


sub last($)
{
    my $set = shift;

    my $lastEdge     = $#{$set->{edges}};
    $set->{iterator} = $set->max;
    $set->{run}[0]   = $lastEdge ? $lastEdge-1 : undef;
    $set->{run}[1]   = $lastEdge;

    $set->{iterator}
}


sub start($$)
{
    my($set, $start) = @_;

    $set->{iterator} = undef;
    defined $start or return undef;

    my $inSet = $set->{negInf};
    my $edges = $set->{edges};

    for (my $i=0; $i<@$edges; $i++)
    {
	if ($inSet)
	{
	    if ($start <= $$edges[$i])
	    {
		$set->{iterator} = $start;
		$set->{run}[0] = $i ? $i-1 : undef;
		$set->{run}[1] = $i;
		return $start;
	    }
	    $inSet = 0;
	}
	else
	{
	    if ($start <= $$edges[$i])
	    {
		return undef;
	    }
	    $inSet = 1;
	}
    }

    if ($inSet)
    {
	$set->{iterator} = $start;
	$set->{run}[0]   = @$edges? $#$edges: undef;
	$set->{run}[1]   = undef;
    }

    $set->{iterator}
}


sub current($) { shift->{iterator} }


sub next($)
{
    my $set = shift;

    defined $set->{iterator} or return $set->first;

    my $run1 = $set->{run}[1];
    defined $run1 or return ++$set->{iterator};

    my $edges = $set->{edges};
    $set->{iterator} < $edges->[$run1] and return ++$set->{iterator};

    if    ($run1 < $#$edges-1)
    {
	my $run0         = $run1 + 1;
	$set->{run}      = [$run0, $run0+1];
	$set->{iterator} = $edges->[$run0]+1;
    }
    elsif ($run1 < $#$edges)
    {
	my $run0         = $run1 + 1;
	$set->{run}      = [$run0, undef];
	$set->{iterator} = $edges->[$run0]+1;
    }
    else
    {
	$set->{iterator} = undef;
    }

    $set->{iterator}
}


sub prev($)
{
    my $set = shift;

    defined $set->{iterator} or return $set->last;

    my $run0 = $set->{run}[0];
    defined $run0 or return --$set->{iterator};

    my $edges = $set->{edges};
    $set->{iterator} > $edges->[$run0]+1 and return --$set->{iterator};

    if    ($run0 > 1)
    {
	my $run1         = $run0 - 1;
	$set->{run}      = [$run1-1, $run1];
	$set->{iterator} = $edges->[$run1];
    }
    elsif ($run0 > 0)
    {
	my $run1         = $run0 - 1;
	$set->{run}      = [undef, $run1];
	$set->{iterator} = $edges->[$run1];
    }
    else
    {
	$set->{iterator} = undef;
    }

    $set->{iterator}
}

sub at
{
    my($set, $i) = @_;

    $i < 0 ? $set->_at_neg($i) : $set->_at_pos($i)
}

sub _at_pos
{
    my($set, $i) = @_;

    $set->neg_inf and
	croak "Set::IntSpan::at: negative infinite set\n";

    my @edges = @{$set->{edges}};

    while (@edges > 1)
    {
	my($lower, $upper) = splice(@edges, 0, 2);

	my $size = $upper - $lower;

	$i < $size and return $lower + 1 + $i;

	$i -= $size;
    }

    @edges ? $edges[0] + 1 + $i : undef
}

sub _at_neg
{
    my($set, $i) = @_;

    $set->pos_inf and
	croak "Set::IntSpan::at: positive infinite set\n";

    my @edges = @{$set->{edges}};
    $i++;

    while (@edges > 1)
    {
	my($lower, $upper) = splice(@edges, -2, 2);

	my $size = $upper - $lower;

	-$i < $size and return $upper + $i;

	$i += $size;
    }

    @edges ? $edges[0] + $i : undef
}

sub ord
{
    my($set, $n) = @_;

    $set->{negInf} and
	croak "Set::IntSpan::ord: negative infinite set\n";

    defined $n or return undef;

    my $i = 0;
    my @edges = @{$set->{edges}};

    while (@edges)
    {
	my($lower, $upper) = splice(@edges, 0, 2);

	$n <= $lower and return undef;

	if (defined $upper and $upper < $n)
	{
	    $i += $upper - $lower;
	    next;
	}

	return $i + $n - $lower - 1;
    }

    undef
}

sub slice
{
    my($set, $from, $to) = @_;

    $set->{slicing} = 1;
    my $slice = $set->_splice($from, $to - $from + 1);
    $set->{slicing} = 0;

    $slice
}

sub _splice
{
    my($set, $offset, $length) = @_;

    $offset < 0
	? $set->_splice_neg($offset, $length)
	: $set->_splice_pos($offset, $length)
}

sub _splice_pos
{
    my($set, $offset, $length) = @_;

    $set->neg_inf and
	croak "Set::IntSpan::slice: negative infinite set\n";

    my @edges = @{$set->{edges}};
    my $slice = new Set::IntSpan;

    while (@edges > 1)
    {
	my ($lower, $upper) = @edges[0,1];
	my $size = $upper - $lower;

	$offset < $size and last;

	splice(@edges, 0, 2);
	$offset -= $size;
    }

    @edges or
	return $slice;  # empty set

    $edges[0] += $offset;

    $slice->{edges} = $set->_splice_length(\@edges, $length);
    $slice
}

sub _splice_neg
{
    my($set, $offset, $length) = @_;

    $set->pos_inf and
	croak "Set::IntSpan::slice: positive infinite set\n";

    my @edges = @{$set->{edges}};
    my $slice = new Set::IntSpan;

    my @slice;
    $offset++;

    while (@edges > 1)
    {
	my ($lower, $upper) = @edges[-2,-1];
	my $size = $upper - $lower;

	-$offset < $size and last;

	unshift @slice, splice(@edges, -2, 2);
	$offset += $size;
    }

    if (@edges)
    {
	my $upper = pop @edges;
	unshift @slice, $upper+$offset-1, $upper;
    }
    elsif ($set->{slicing})
    {
	$length += $offset-1;
    }

    $slice->{edges} = $set->_splice_length(\@slice, $length);
    $slice
}

sub _splice_length
{
    my($set, $edges, $length) = @_;

    not defined $length   and return $edges;  # everything
    		$length<0 and return $set->_splice_length_neg($edges, -$length);
                $length>0 and return $set->_splice_length_pos($edges,  $length);

    []  # $length==0
}

sub _splice_length_pos
{
    my($set, $edges, $length) = @_;

    my @slice;

    while (@$edges > 1)
    {
	my ($lower, $upper) = @$edges[0,1];
	my $size = $upper - $lower;

	$length <= $size and last;

	push @slice, splice(@$edges, 0, 2);
	$length -= $size;
    }

    if (@$edges)
    {
	my $lower = shift @$edges;
	push @slice, $lower, $lower+$length;
    }

    \@slice
}

sub _splice_length_neg
{
    my($set, $edges, $length) = @_;

    $set->pos_inf and
	croak "Set::IntSpan::slice: positive infinite set\n";

    while (@$edges > 1)
    {
	my($lower, $upper) = @$edges[-2,-1];
	my $size = $upper - $lower;

	$length < $size and last;

	splice(@$edges, -2, 2);
	$length -= $size;
    }

    if (@$edges)
    {
	$edges->[-1] -= $length;
    }

    $edges
}

1

__END__

=head1 NAME

Set::IntSpan - Manages sets of integers


=head1 SYNOPSIS


  # BEGIN { $Set::IntSpan::integer = 1 }
  use Set::IntSpan qw(grep_set map_set grep_spans map_spans);

  # $Set::IntSpan::Empty_String = '-';   # or '';

  $set    = new   Set::IntSpan $set_spec;
  $set    = new   Set::IntSpan @set_specs;
  $valid  = valid Set::IntSpan $run_list;
  $set    = copy  $set $set_spec;

  $run_list = run_list $set;
  @elements = elements $set;
  @sets     = sets     $set;
  @spans    = spans    $set;

  $u_set = union      $set $set_spec;
  $i_set = intersect  $set $set_spec;
  $x_set = xor        $set $set_spec;
  $d_set = diff       $set $set_spec;
  $c_set = complement $set;

  $set->U($set_spec);   # Union
  $set->I($set_spec);   # Intersect
  $set->X($set_spec);   # Xor
  $set->D($set_spec);   # Diff
  $set->C;              # Complement

  equal      $set $set_spec
  equivalent $set $set_spec
  superset   $set $set_spec
  subset     $set $set_spec

  $n = cardinality $set;
  $n = size        $set;

  empty      $set
  finite     $set
  neg_inf    $set
  pos_inf    $set
  infinite   $set
  universal  $set

  member     $set $n;
  insert     $set $n;
  remove     $set $n;

  $min = min $set;
  $max = max $set;

  $holes   = holes $set;
  $cover   = cover $set;
  $inset   = inset $set $n;
  $smaller = trim  $set $n;
  $bigger  = pad   $set $n;

  $subset  = grep_set 	{ ... } $set;
  $mapset  = map_set  	{ ... } $set;

  $subset  = grep_spans { ... } $set;
  $mapset  = map_spans  { ... } $set;

  for ($element=$set->first; defined $element; $element=$set->next) { ... }
  for ($element=$set->last ; defined $element; $element=$set->prev) { ... }

  $element = $set->start($n);
  $element = $set->current;

  $n       = $set->at($i);
  $slice   = $set->slice($from, $to);
  $i       = $set->ord($n);
  $i       = $set->span_ord($n);

=head2 Operator overloads

  $u_set =  $set + $set_spec;   # union
  $i_set =  $set * $set_spec;	# intersect
  $x_set =  $set ^ $set_spec;	# xor
  $d_set =  $set - $set_spec;	# diff
  $c_set = ~$set;               # complement

  $set += $set_spec;            # union
  $set *= $set_spec;		# intersect
  $set ^= $set_spec;		# xor
  $set -= $set_spec;		# diff

  $set eq $set_spec		# equal
  $set ne $set_spec		# not equal
  $set le $set_spec		# subset
  $set lt $set_spec		# proper subset
  $set ge $set_spec		# superset
  $set gt $set_spec		# proper superset

  # compare sets by cardinality
  $set1 ==  $set2
  $set1 !=  $set2
  $set1 <=  $set2
  $set1 <   $set2
  $set1 >=  $set2
  $set1 >   $set2
  $set1 <=> $set2

  # compare cardinality of set to an integer
  $set1 ==  $n
  $set1 !=  $n
  $set1 <=  $n
  $set1 <   $n
  $set1 >=  $n
  $set1 >   $n
  $set1 <=> $n

  @sorted = sort @sets;         # sort sets by cardinality

  if ($set) { ... }             # true if $set is not empty

  print "$set\n";               # stringizes to the run list


=head1 EXPORTS

=head2 C<@EXPORT>

Nothing

=head2 C<@EXPORT_OK>

C<grep_set>, C<map_set>, C<grep_spans>, C<map_spans>


=head1 DESCRIPTION

C<Set::IntSpan> manages sets of integers.
It is optimized for sets that have long runs of consecutive integers.
These arise, for example, in .newsrc files, which maintain lists of articles:

  alt.foo: 1-21,28,31
  alt.bar: 1-14192,14194,14196-14221

A run of consecutive integers is also called a I<span>.

Sets are stored internally in a run-length coded form.
This provides for both compact storage and efficient computation.
In particular,
set operations can be performed directly on the encoded representation.

C<Set::IntSpan> is designed to manage finite sets.
However, it can also represent some simple infinite sets, such as { x | x>n }.
This allows operations involving complements to be carried out consistently,
without having to worry about the actual value of INT_MAX on your machine.


=head1 SPANS

A I<span> is a run of consecutive integers.
A span may be represented by an array reference,
in any of 5 forms:

=head2 Finite forms

    Span                Set
  [ $n,    $n    ]      { n }
  [ $a,    $b    ]      { x | a<=x && x<=b}

=head2 Infinite forms

    Span                Set
  [ undef, $b    ]      { x | x<=b }
  [ $a   , undef ]      { x | x>=a }
  [ undef, undef ]      The set of all integers


Some methods operate directly on spans.


=head1 SET SPECIFICATIONS

Many of the methods take a I<set specification>.
There are four kinds of set specifications.

=head2 Empty

If a set specification is omitted, then the empty set is assumed.
Thus,

  $set = new Set::IntSpan;

creates a new, empty set.  Similarly,

  copy $set;

removes all elements from $set.


=head2 Object reference

If an object reference is given, it is taken to be a C<Set::IntSpan> object.


=head2 Run list

If a string is given, it is taken to be a I<run list>.
A run list specifies a set using a syntax similar to that in newsrc files.

A run list is a comma-separated list of I<runs>.
Each run specifies a set of consecutive integers.
The set is the union of all the runs.

Runs may be written in any of 5 forms.

=head3 Finite forms

=over 8

=item n

{ n }

=item a-b

{ x | a<=x && x<=b }

=back

=head3 Infinite forms

=over 8

=item (-n

{ x | x<=n }

=item n-)

{ x | x>=n }

=item (-)

The set of all integers

=back

=head3 Empty forms

The empty set is consistently written as '' (the null string).
It is also denoted by the special form '-' (a single dash).

=head3 Restrictions

The runs in a run list must be disjoint,
and must be listed in increasing order.

Valid characters in a run list are 0-9, '(', ')', '-' and ','.
White space and underscore (_) are ignored.
Other characters are not allowed.

=head3 Examples

  Run list          Set
  "-"               { }
  "1"               { 1 }
  "1-2"             { 1, 2 }
  "-5--1"           { -5, -4, -3, -2, -1 }
  "(-)"             the integers
  "(--1"            the negative integers
  "1-3, 4, 18-21"   { 1, 2, 3, 4, 18, 19, 20, 21 }


=head2 Array reference

If an array reference is given,
then the elements of the array specify the elements of the set.
The array may contain

=over 4

=item *

integers

=item *

L<spans|/SPANS>

=back

The set is the union of all the integers and spans in the array.
The integers and spans need not be disjoint.
The integers and spans may be in any order.

=head3 Examples

  Array ref            		    Set
  [ ]                		    { }
  [ 1, 1 ]                          { 1 }
  [ 1, 3, 2 ]        		    { 1, 2, 3 }
  [ 1, [ 5, 8 ], 5, [ 7, 9 ], 2 ]   { 1, 2, 5, 6, 7, 8, 9 }
  [ undef, undef ]                  the integers
  [ undef, -1 ]                     the negative integers



=head1 ITERATORS

Each set has a single I<iterator>,
which is shared by all calls to
C<first>, C<last>, C<start>, C<next>, C<prev>, and C<current>.
At all times,
the iterator is either an element of the set,
or C<undef>.

C<first>, C<last>, and C<start> set the iterator;
C<next>, and C<prev> move it;
and C<current> returns it.
Calls to these methods may be freely intermixed.

Using C<next> and C<prev>,
a single loop can move both forwards and backwards through a set.
Using C<start>, a loop can iterate over portions of an infinite set.


=head1 METHODS


=head2 Creation

=over 4


=item I<$set> = C<new> C<Set::IntSpan> I<$set_spec>

=item I<$set> = C<new> C<Set::IntSpan> I<@set_specs>

Creates and returns a C<Set::IntSpan> object.

The initial contents of the set are given by I<$set_spec>,
or by the union of all the I<@set_specs>.


=item I<$ok> = C<valid> C<Set::IntSpan> I<$run_list>

Returns true if I<$run_list> is a valid run list.
Otherwise, returns false and leaves an error message in $@.


=item I<$set> = C<copy> I<$set> I<$set_spec>

Copies I<$set_spec> into I<$set>.
The previous contents of I<$set> are lost.
For convenience, C<copy> returns I<$set>.


=item I<$run_list> = C<run_list> I<$set>

Returns a run list that represents I<$set>.
The run list will not contain white space.
I<$set> is not affected.

By default, the empty set is formatted as '-';
a different string may be specified in C<$Set::IntSpan::Empty_String>.


=item I<@elements> = C<elements> I<$set>

Returns an array containing the elements of I<$set>.
The elements will be sorted in numerical order.
In scalar context, returns an array reference.
I<$set> is not affected.


=item I<@sets> = C<sets> I<$set>

Returns the runs in I<$set>,
as a list of C<Set::IntSpan> objects.
The sets in the list are in order.


=item I<@spans> = C<spans> I<$set>

Returns the runs in I<$set>,
as a list of the form

  ([$a1, $b1],
   [$a2, $b2],
   ...
   [$aN, $bN])

If a run contains only a single integer,
then the upper and lower bounds of the corresponding span will be equal.

If the set has no lower bound, then $a1 will be C<undef>.
Similarly,
if the set has no upper bound, then $bN will be C<undef>.

The runs in the list are in order.


=back


=head2 Set operations

For these operations,
a new C<Set::IntSpan> object is created and returned.
The operands are not affected.

=over 4

=item I<$u_set> = C<union> I<$set> I<$set_spec>

Returns the set of integers in either I<$set> or I<$set_spec>.


=item I<$i_set> = C<intersect> I<$set> I<$set_spec>

Returns the set of integers in both I<$set> and I<$set_spec>.


=item I<$x_set> = C<xor> I<$set> I<$set_spec>

Returns the set of integers in I<$set> or I<$set_spec>,
but not both.


=item I<$d_set> = C<diff> I<$set> I<$set_spec>

Returns the set of integers in I<$set> but not in I<$set_spec>.


=item I<$c_set> = C<complement> I<$set>

Returns the set of integers that are not in I<$set>.

=back



=head2 Mutators

By popular demand, C<Set::IntSpan> now has mutating forms of the binary set operations.
These methods alter the object on which they are called.

=over 4

=item I<$set>->C<U>(I<$set_spec>)

Makes I<$set> the union of I<$set> and I<$set_spec>.
Returns I<$set>.

=item I<$set>->C<I>(I<$set_spec>)

Makes I<$set> the intersection of I<$set> and I<$set_spec>.
Returns I<$set>.

=item I<$set>->C<X>(I<$set_spec>)

Makes I<$set> the symmetric difference of I<$set> and I<$set_spec>.
Returns I<$set>.

=item I<$set>->C<D>(I<$set_spec>)

Makes I<$set> the difference of I<$set> and I<$set_spec>.
Returns I<$set>.

=item I<$set>->C<C>

Converts I<$set> to its own complement.
Returns I<$set>.

=back


=head2 Comparison

=over 4


=item C<equal> I<$set> I<$set_spec>

Returns true iff I<$set> and I<$set_spec> contain the same elements.


=item C<equivalent> I<$set> I<$set_spec>

Returns true iff I<$set> and I<$set_spec> contain the same number of elements.
All infinite sets are equivalent.


=item C<superset> I<$set> I<$set_spec>

Returns true iff I<$set> is a superset of I<$set_spec>.


=item C<subset> I<$set> I<$set_spec>

Returns true iff I<$set> is a subset of I<$set_spec>.

=back


=head2 Cardinality

=over 4


=item I<$n> = C<cardinality> I<$set>

=item I<$n> = C<size> I<$set>

Returns the number of elements in I<$set>.
Returns -1 for infinite sets.
C<size> is provided as an alias for C<cardinality>.


=item C<empty> I<$set>

Returns true iff I<$set> is empty.


=item C<finite> I<$set>

Returns true iff I<$set> is finite.


=item C<neg_inf> I<$set>

Returns true iff I<$set> contains {x | x<n} for some n.


=item C<pos_inf> I<$set>

Returns true iff I<$set> contains {x | x>n} for some n.


=item C<infinite> I<$set>

Returns true iff I<$set> is infinite.


=item C<universal> I<$set>

Returns true iff I<$set> contains all integers.

=back


=head2 Membership

=over 4


=item C<member> I<$set> I<$n>

Returns true iff the integer I<$n> is a member of I<$set>.


=item C<insert> I<$set> I<$n>

Inserts the integer I<$n> into I<$set>.
Does nothing if I<$n> is already a member of I<$set>.


=item C<remove> I<$set> I<$n>

Removes the integer I<$n> from I<$set>.
Does nothing if I<$n> is not a member of I<$set>.

=back


=head2 Extrema

=over 4


=item C<min> I<$set>

Returns the smallest element of I<$set>,
or C<undef> if there is none.


=item C<max> I<$set>

Returns the largest element of I<$set>,
or C<undef> if there is none.

=back


=head2 Spans

=over 4

=item I<$holes> = C<holes> I<$set>

Returns a set containing all the holes in I<$set>,
that is, all the integers that are in-between spans of I<$set>.

C<holes> is always a finite set.


=item I<$cover> = C<cover> I<$set>

Returns a set consisting of a single span from I<$set>->C<min> to
I<$set>->C<max>. This is the same as

  union $set $set->holes


=item I<$inset> = C<inset> I<$set> I<$n>

=item I<$smaller> = C<trim> I<$set> I<$n>

=item I<$bigger> = C<pad> I<$set> I<$n>

C<inset> returns a set constructed by removing I<$n> integers from
each end of each span of I<$set>. If I<$n> is negative, then -I<$n>
integers are added to each end of each span.

In the first case, spans may vanish from the set;
in the second case, holes may vanish.

C<trim> is provided as a synonym for C<inset>.

C<pad> I<$set> I<$n> is the same as C<inset> I<$set> -I<$n>.


=back


=head2 Iterators

=over 4


=item I<$set>->C<first>

Sets the iterator for I<$set> to the smallest element of I<$set>.
If there is no smallest element,
sets the iterator to C<undef>.
Returns the iterator.


=item I<$set>->C<last>

Sets the iterator for I<$set> to the largest element of I<$set>.
If there is no largest element,
sets the iterator to C<undef>.
Returns the iterator.


=item I<$set>->C<start>(I<$n>)

Sets the iterator for I<$set> to I<$n>.
If I<$n> is not an element of I<$set>,
sets the iterator to C<undef>.
Returns the iterator.


=item I<$set>->C<next>

Sets the iterator for I<$set> to the next element of I<$set>.
If there is no next element,
sets the iterator to C<undef>.
Returns the iterator.

C<next> will return C<undef> only once;
the next call to C<next> will reset the iterator to
the smallest element of I<$set>.


=item I<$set>->C<prev>

Sets the iterator for I<$set> to the previous element of I<$set>.
If there is no previous element,
sets the iterator to C<undef>.
Returns the iterator.

C<prev> will return C<undef> only once;
the next call to C<prev> will reset the iterator to
the largest element of I<$set>.


=item I<$set>->C<current>

Returns the iterator for I<$set>.

=back


=head2 Indexing

The elements of a set are kept in numerical order.
These methods index into the set based on this ordering.

=over 4


=item I<$n> = I<$set>->C<at>($i)

Returns the I<$i>th element of I<$set>,
or C<undef> if there is no I<$i>th element.
Negative indices count backwards from the end of the set.

Dies if

=over 4

=item *

I<$i> is non-negative and I<$set> is C<neg_inf>

=item *

I<$i> is negative and I<$set> is C<pos_inf>

=back


=item I<$slice> = I<$set>->C<slice>(I<$from>, I<$to>)

Returns a C<Set::IntSpan> object containing the elements of I<$set>
at indices I<$from>..I<$to>.
Negative indices count backwards from the end of the set.

Dies if

=over 4

=item *

I<$from> is non-negative and I<$set> is C<neg_inf>

=item *

I<$from> is negative and I<$set> is C<pos_inf>

=back

=item I<$i> = I<$set>->C<ord>($n)

The inverse of C<at>.

Returns the index I<$i> of the integer I<$n> in I<$set>,
or C<undef> if I<$n> if not an element of I<$set>.

Dies if I<$set> is C<neg_inf>.

=item I<$i> = I<$set>->C<span_ord>($n)

Returns the index I<$i> of the span containing the integer I<$n>,
or C<undef> if I<$n> if not an element of I<$set>.

To recover the span containing I<$n>, write

  ($set->spans)[$i]

=back


=head1 OPERATOR OVERLOADS

For convenience, some operators are overloaded on C<Set::IntSpan> objects.

=head2 set operations

One operand must be a C<Set::IntSpan> object.
The other operand may be a C<Set::IntSpan> object or a set specification.

  $u_set =  $set + $set_spec;   # union
  $i_set =  $set * $set_spec;	# intersect
  $x_set =  $set ^ $set_spec;	# xor
  $d_set =  $set - $set_spec;	# diff
  $c_set = ~$set;               # complement

  $set += $set_spec;            # union
  $set *= $set_spec;		# intersect
  $set ^= $set_spec;		# xor
  $set -= $set_spec;		# diff

=head2 equality

The string comparison operations are overloaded to compare sets for equality and containment.
One operand must be a C<Set::IntSpan> object.
The other operand may be a C<Set::IntSpan> object or a set specification.

  $set eq $set_spec		# equal
  $set ne $set_spec		# not equal
  $set le $set_spec		# subset
  $set lt $set_spec		# proper subset
  $set ge $set_spec		# superset
  $set gt $set_spec		# proper superset

=head2 equivalence

The numerical comparison operations are overloaded to compare sets by cardinality.
One operand must be a C<Set::IntSpan> object.
The other operand may be a C<Set::IntSpan> object or an integer.

  $set1 ==  $set2
  $set1 !=  $set2
  $set1 <=  $set2
  $set1 <   $set2
  $set1 >=  $set2
  $set1 >   $set2
  $set1 <=> $set2
  $set1 cmp $set2

  $set1 ==  $n
  $set1 !=  $n
  $set1 <=  $n
  $set1 <   $n
  $set1 >=  $n
  $set1 >   $n
  $set1 <=> $n
  $set1 cmp $n

N.B. The C<cmp> operator is overloaded to compare sets by cardinality, not containment.
This is done so that

  sort @sets

will sort a list of sets by cardinality.

=head2 conversion

In boolean context, a C<Set::IntSpan> object evaluates to true if it is not empty.

A C<Set::IntSpan> object stringizes to its run list.


=head1 FUNCTIONS

=over 4

=item I<$sub_set> = C<grep_set> { ... } I<$set>

Evaluates the BLOCK for each integer in I<$set>
(locally setting C<$_> to each integer)
and returns a C<Set::IntSpan> object containing those integers
for which the BLOCK returns TRUE.

Returns C<undef> if I<$set> is infinite.

=item I<$map_set> = C<map_set> { ... } I<$set>

Evaluates the BLOCK for each integer in I<$set>
(locally setting C<$_> to each integer)
and returns a C<Set::IntSpan> object containing
all the integers returned as results of all those evaluations.

Evaluates the BLOCK in list context,
so each element of I<$set> may produce zero, one,
or more elements in the returned set.
The elements may be returned in any order,
and need not be disjoint.

Returns C<undef> if I<$set> is infinite.

=item I<$sub_set> = C<grep_spans> { ... } I<$set>

Evaluates the BLOCK for each span in I<$set>
and returns a C<Set::IntSpan> object containing those spans
for which the BLOCK returns TRUE.

Within BLOCK, C<$_> is locally set to an array ref of the form

  [ $lower, $upper ]

where I<$lower> and I<$upper> are the bounds of the span.
If the span contains only one integer, then I<$lower> and I<$upper> will be equal.
If the span is unbounded, then the corresponding element(s) of the array will be C<undef>.

=item I<$map_set> = C<map_spans> { ... } I<$set>

Evaluates the BLOCK for each span in I<$set>,
and returns a C<Set::IntSpan> object consisting of the union of
all the spans returned as results of all those evaluations.

Within BLOCK, C<$_> is locally set to an array ref of the form

  [ $lower, $upper ]

as described above for C<grep_spans>.
Each evaluation of BLOCK must return a list of L<spans|/SPANS>.
Each returned list may contain zero, one, or more spans.
Spans may be returned in any order, and need not be disjoint.
However, for each bounded span, the constraint

  $lower <= $upper

must hold.

=back


=head1 CLASS VARIABLES

=over 4

=item C<$Set::IntSpan::Empty_String>

C<$Set::IntSpan::Empty_String> contains the string that is returned when
C<run_list> is called on the empty set.
C<$Empty_String> is initially '-';
alternatively, it may be set to ''.
Other values should be avoided,
to ensure that C<run_list> always returns a valid run list.

C<run_list> accesses C<$Empty_String> through a reference
stored in I<$set>->{C<empty_string>}.
Subclasses that wish to override the value of C<$Empty_String> can
reassign this reference.

=item C<$Set::IntSpan::integer>

Up until version 1.16, C<Set::IntSpan> specified C<use integer>,
because they were sets of...you know...integers.
As of 2012, users are reporting newsgroups with article numbers above
0x7fffffff, which break C<Set::IntSpan> on 32-bit processors.

Version 1.17 removes C<use integer> by default.
This extends the usable range of C<Set::IntSpan> to the number of bits
in the mantissa of your floating point representation.
For IEEE 754 doubles, this is 53 bits, or around 9e15.

I benchmarked C<Set::IntSpan> on a Pentium 4,
and it looks like C<use integer> provides a 2% to 4% speedup,
depending on the application.

If you want C<use integer> back, either for performance,
or because you are somehow dependent on its semantics, write

  BEGIN { $Set::IntSpan::integer = 1 }
  use Set::IntSpan;

=back



=head1 DIAGNOSTICS

Any method (except C<valid>) will C<die> if it is passed an invalid run list.

=over 4

=item C<Set::IntSpan::_copy_run_list: Bad syntax:> I<$runList>

(F) I<$run_list> has bad syntax

=item C<Set::IntSpan::_copy_run_list: Bad order:> I<$runList>

(F) I<$run_list> has overlapping runs or runs that are out of order.

=item C<Set::IntSpan::elements: infinite set>

(F) An infinite set was passed to C<elements>.

=item C<Set::IntSpan::at: negative infinite set>

(F) C<at> was called with a non-negative index on a negative infinite set.

=item C<Set::IntSpan::at: positive infinite set>

(F) C<at> was called with a negative index on a positive infinite set.

=item C<Set::IntSpan::slice: negative infinite set>

(F) C<slice> was called with I<$from> non-negative on a negative infinite set.

=item C<Set::IntSpan::slice: positive infinite set>

(F) C<slice> was called with I<$from> negative on a positive infinite set.

=item C<Set::IntSpan::ord: negative infinite set>

(F) C<ord> was called on a negative infinite set.

=item Out of memory!

(X) C<elements> I<$set> can generate an "Out of memory!"
message on sufficiently large finite sets.

=back


=head1 NOTES

=head2 Traps

Beware of forms like

  union $set [1..5];

This passes an element of @set to union,
which is probably not what you want.
To force interpretation of $set and [1..5] as separate arguments,
use forms like

    union $set +[1..5];

or

    $set->union([1..5]);


=head2 grep_set and map_set

C<grep_set> and C<map_set> make it easy to construct
sets for which the internal representation used by C<Set::IntSpan>
is I<not> small. Consider:

  $billion = new Set::IntSpan '0-1_000_000_000';   # OK
  $odd     = grep_set { $_ & 1 } $billion;         # trouble
  $even    = map_set  { $_ * 2 } $billion;         # double trouble


=head2 Error handling

There are two common approaches to error handling:
exceptions and return codes.
There seems to be some religion on the topic,
so C<Set::IntSpan> provides support for both.

To catch exceptions, protect method calls with an eval:

    $run_list = <STDIN>;
    eval { $set = new Set::IntSpan $run_list };
    $@ and print "$@: try again\n";

To check return codes, use an appropriate method call to validate arguments:

    $run_list = <STDIN>;
    if (valid Set::IntSpan $run_list)
       { $set = new Set::IntSpan $run_list }
    else
       { print "$@ try again\n" }

Similarly, use C<finite> to protect calls to C<elements>:

    finite $set and @elements = elements $set;

Calling C<elements> on a large, finite set can generate an "Out of
memory!" message, which cannot (easily) be trapped.
Applications that must retain control after an error can use C<intersect> to
protect calls to C<elements>:

    @elements = elements { intersect $set "-1_000_000 - 1_000_000" };

or check the size of $set first:

    finite $set and cardinality $set < 2_000_000 and @elements = elements $set;


=head2 Limitations

Although C<Set::IntSpan> can represent some infinite sets,
it does I<not> perform infinite-precision arithmetic.
Therefore, finite elements are restricted to the range of integers on your machine.


=head2 Extensions

Users report that you can construct Set::IntSpan objects on anything that
behaves like an integer. For example:

    $x   = new Math::BigInt ...;
    $set = new Set::Intspan [ [ $x, $x+5 ] ];

I'm not documenting this as supported behavior,
because I don't have the resources to test it,
but I'll try not to break it.
If anyone finds problems with it, let me know.


=head2 Roots

The sets implemented here are based on a Macintosh data structure called
a I<region>. See Inside Macintosh for more information.

C<Set::IntSpan> was originally written to manage run lists for the L<C<News::Newsrc>> module.


=head1 AUTHOR

Steven McDougall <swmcd@world.std.com>


=head1 ACKNOWLEDGMENTS

=over 4

=item *

Malcolm Cook <mec@stowers-institute.org>

=item *

David Hawthorne <dsrthorne@hotmail.com>

=item *

Martin Krzywinski <martink@bcgsc.ca>

=item *

Marc Lehmann <schmorp@schmorp.de>

=item *

Andrew Olson <aolson@me.com>

=item *

Nicholas Redgrave <baron@bologrew.net>

=back


=head1 COPYRIGHT

Copyright (c) 1996-2013 by Steven McDougall. This module is free
software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
