package Tangram::Relational::PolySelectTemplate;

use strict;
use Tangram::Schema;

sub new
  {
	my $class = shift;
	bless [ @_ ], $class;
  }

use Set::Object qw(set);

use vars qw($paren);
$paren = qr{\( (?: (?> [^()]+ )    # Non-parens without backtracking
	    |   (??{ $paren })  # Group with matching parens
	   )* \)}x;


sub instantiate {

    my ($self, $remote, $xcols, $xfrom, $xwhere, %o) = @_;
    my ($expand, $cols, $from, $where) = @$self;

    $xcols ||= [];
    $xfrom ||= [];

    my @xwhere;

    if (@$xwhere) {
	$xwhere[0] = join ' AND ', @$xwhere;
	$xwhere[0] =~ s[%][%%]g;
    }

    my @tables = $remote->table_ids() if $remote;

    # expand table aliases early
    my $i = 0;
    my @cols = map { sprintf $_, map { $tables[$expand->[$i++]] } m{(%d)}g } @$cols;
    my @from = map { sprintf $_, map { $tables[$expand->[$i++]] } m{(%d)}g } @$from;
    my @where = map { sprintf $_, map { $tables[$expand->[$i++]] } m{(%d)}g } @$where;

    my $selected;
    if ( my $group = $o{group} ) {
	# grouping, (make sure that all columns are aggregate)

	# make sure all grouped columns are selected
	$selected = Set::Object->new(@cols, @$xcols);

	push @$xcols, (grep { $selected->insert($_) }
		       map { ref $_ ? $_->expr : $_ } @$group);
    }

    if (my $order = $o{order}) {
	# ordering, make sure that all ordered columns are selected
	$selected ||= Set::Object->new(@cols, @$xcols);

	push @$xcols, (grep {  $selected->insert($_) }
		       map { ref $_ ? $_->expr : $_ } @$order);
    }

    my $select = sprintf("SELECT%s\n%s\n",
			 ($o{distinct} ? " DISTINCT" : ""),
			 (join(",\n", map {"    $_"} @cols, @$xcols)));

    # add outer join clauses
    if ( my $owhere = $o{owhere} or $o{any_outer} ) {

	#kill 2, $$ if $Tangram::Global;
	my $ofrom = $o{ofrom};

	# ugh.  we need to add a new clause for every join, and in
	# order of joinedness.  Which means that we have to go and
	# break up some joins.

	# this is highly ugly, but at least it makes something that
	# was impossible, possible.  This requires a thorough
	# re-engineering to fix, as I see it.

	$owhere = Set::Object->new(map {
	    my @x;
	    while ( s{^\(((?:[^(]+|$paren)*)\s+and\s((?:[^(]+|$paren)*)\)$}{$1}is
		    or s{^((?:[^(]+|$paren)*)\s+and\s((?:[^(]+|$paren)*)$}{$1}is
		  ) {
		#print STDERR "got: $2\n";
		push @x, $2;
	    }
	    #print STDERR "left: $_\n";
	    @x, $_
	} @{$o{owhere}}, ($o{any_outer} ? (@where, @xwhere) : ()));
	#print STDERR "new owhere: ".join("/",$owhere->members)."\n";
	#print STDERR "ofrom: @$ofrom\n";
	$ofrom = Set::Object->new(@{$o{ofrom}});
	#print STDERR "new ofrom: ".join("/",$ofrom->members)."\n";

	(my $tmp_sel = $select) =~ s{.*^FROM}{}ms;

	# ook ook
	my $seen_from = Set::Object->new( map { m{\b(tl?\d+)\b}sg }
					  (@from, @$xfrom) );

	my (@ofrom, @ojoin, %owhen);
	my %hovering_dogs_bottom;

	# this loop is heinous
	while ( $ofrom->size ) {
	FROM:
	    my $ofrom_size = $ofrom->size;
	    my @from_todo = $ofrom->members;

	    while ( my $from = shift @from_todo ) {
		my ($tnum) = ($from =~ m{\b(tl?\d+)\b})
		    or die "What? `$from; doesn't m/tl?\\d+/ ?";
		my @tmpjoin;

		#print STDERR "Checking (outer): $from\n";
		my @queue = $owhere->members;
	    JOIN:
		while ( my $join  = shift @queue ) {
		    my @tables = ($join =~ m{\b(tl?\d+)\b}g);

		    if (@tables == 1) {
			#kill 2,$$;
			push @{$hovering_dogs_bottom{$tables[0]}||=[]},
			    $join;
			$owhere->delete($join);
			next;
		    }

		    next unless ( grep { $_ eq $tnum } @tables );
		    #print STDERR "Checking: $join for @tables (seen_from = $seen_from)\n";
		    if ( my @bad = grep { !$seen_from->has($_)
					     and $_ ne $tnum 
				      } @tables ) {
			next JOIN;
		    } else {
			my (@others) = (grep { $_ ne $tnum } @tables);
			#kill 2, $$ if @others == 0;
			(@others == 1)
			    or die("Can't handle more than two-table "
				   ."outer join clauses");

			# when you reach table $others[0],
			# look at @ofrom and @ojoin index N
			$owhen{$others[0]} = scalar @ofrom;
			#print STDERR "ADDED JOIN FROM $others[0] to $tnum ($from?): $join\n";

			# hooray!  SQL will accept it in this order!
			$seen_from->insert($tnum);
			#print STDERR "SEEN ADDED: $tnum\n";
			$ofrom-= Set::Object->new($from);
			#print STDERR "OFROM REMOVED: $from\n";
			$owhere-= Set::Object->new($join);

			# we're joining in $from, so add all clauses
			# that have nothing but seen tables and from
			@queue = $owhere->members;
			@from_todo = $ofrom->members;

			push(@tmpjoin, $join);
		    }
		}
		if ( @tmpjoin ) {
		    push @ofrom, $from;
		    push @ojoin, \@tmpjoin;
		}
	    }
	    die "failed to join tables: ".join(", ", $ofrom->members)
		."\nquery: >-\n$select\nowhere:\n".join(", ", $owhere->members)
		    ."supplied from:\n"
			.join(", ", @from, @$xfrom)
		if $ofrom->size;
	}

	if ( $o{any_outer} ) {
	    my $old_where = set(@where, @xwhere) * $owhere;
	    $owhere -= $old_where;
	    (@where, @xwhere) = $old_where->members;
	}

	die "failed to include conditions: ".join(", ", $owhere->members)
	    if $owhere->size;

	my @tables = (@from, @$xfrom);

	my $i;
	for my $table ( @tables ) {
	    my ($tnum) = ($table =~ m/\b(tl?\d+)\b/)
		or die "table without an alias";

	    while ( defined(my $idx = delete $owhen{$tnum}) ) {
		my $from = $ofrom[$idx];
		my $join = $ojoin[$idx];
		$ofrom[$idx] = undef;
		my $other_table;
		if ( $from =~ m{\s(tl?\d+)$}
		     and exists $hovering_dogs_bottom{$1}
		   ) {
		    push @$join, @{ $hovering_dogs_bottom{$1} };
		}

		# if we're doing an ID join, this one shouldn't be
		# outer.
		#kill 2, $$;
		my ($id_col) = ($self->[1][0] =~ m{\.(.*)});
		my $isnt_outer = ( grep /t\d+.$id_col = t\d+\.$id_col/,
				   @$join )
		    if $id_col;
		my $frag = (sprintf
			    ("\n\t".($isnt_outer?"INNER ":"LEFT ")
			     ."JOIN\n%s\n\tON\n%s",
			     join(",\n", map { "\t    $_" } $from),
			     join("\tAND\n", map { "\t    $_" } @$join),
			    ));
		# if it's not an outer join, it also needs to be
		# grouped with the correct table.
		if ( $isnt_outer ) {
		    if ( $table =~ m{^\s+\(\S+\s+$tnum$}m ) {
			die "TODO";
		    } else {
			$table =~ s{^(\s+)(\S+\s+$tnum)$}{$1($2\n${\(do {
                            my $indent = $1;
                            $frag =~ s{\A\s*}{    }s;
                            $frag =~ s{^}{$indent}mg;
                            $frag;
                        })})}m;
		    }
		} else {
		    $table .= $frag;
		}
		($tnum) = grep { $_ ne $tnum } ($from =~ m/\b(tl?\d+)\b/g);
	    }
	    $i++;
	}
	if ( my @missed = grep { defined } @ofrom ) {
	    die "Couldn't figure out where to stick @missed";
	}
	$select .= sprintf ("FROM\n%s\n",
			    (join(",\n", map {"    $_"} @tables))
			   );
    } else {
	$select .= sprintf ("FROM\n%s\n",
			    (join(",\n", map {"    $_"} @from, @$xfrom))
			   );
    }

    my $max_len = 0;

    #push @xwhere, @{$o{lwhere}} if $o{lwhere};

    foreach (@where, @xwhere) {

	if ( $Tangram::TRACE and $Tangram::DEBUG_LEVEL <= 1) {
	    # In trace mode, split up queries that have an AND clause
	    # but no parantheses.  be sure not to put parantheses in
	    # hardcoded queries, inside quotes etc.
	    while (my ($left, $right) =
		   m/^((?:[^(]+|$paren)*)\s+and\s((?:[^(]+|$paren)*)$/i) {
		$_ = $left;
		push @xwhere, $right;
	    }
	}
	($max_len = length $_) if (length $_ > $max_len);
    }
    # don't go insane with the spaces!
    $max_len = 20 if $max_len > 20;

    $select .= sprintf("WHERE\n%s\n",
		       join("    AND\n", map {
			   sprintf("    %-${max_len}s", $_)
		       } @where, @xwhere)
		      )
	if @where || @$xwhere;

    if ( my $group = $o{group} ) {
	$select .= ("GROUP BY\n".
		    join ",\n", map { "    ".$_->expr } @$group)."\n";
    }

    if (my $order = $o{order}) {

	my $desc = $o{desc};
	if ( ! ref $desc ) {
	    $desc = [ ($desc) x @$order ];
	}
	my $i = 0;
	$select .= "ORDER BY\n".
	    join(",\n", (map { ("    ".$_->expr.
				($desc->[$i++] ? " DESC" : "")) }
			 @$order))."\n";
    }

    if (defined $o{limit}) {
	if (ref $o{limit}) {
	    $select .= "LIMIT\n    ".join(",",@{ $o{limit} })."\n";
	} else {
	    $select .= "LIMIT\n    $o{limit}\n";
	}
    }

    if ( defined $o{postfilter} ) {
	$select = "SELECT\n    *\nFROM\n(\n$select\n)\n"
	    .sprintf("WHERE\n%s\n",
		     join("    AND\n", map {
			 sprintf("    %-${max_len}s", $_)
		     } @{$o{postfilter}}
			 )
		    );
    }

    $select;
    #sprintf $select, map { $tables[$_] } @$expand;
}

sub extract {

    my ($self, $row) = @_;
    my $id = shift @$row;
    my $class_id = shift @$row;

    my $slice = $self->[-1]{$class_id}
	or do {
	    #kill 2, $$;
	    Carp::croak("unexpected class id '$class_id' (OK: "
			.(join(",",keys %{$self->[-1]})).")");
	};

    my $state = [ @$row[ @$slice ] ];

    splice @$row, 0, @{ $self->[1] } - 2;

    return ($id, $class_id, $state);
}

1;
