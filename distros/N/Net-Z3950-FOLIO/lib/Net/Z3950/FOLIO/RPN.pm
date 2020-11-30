# The following code maps Z39.50 Type-1 queries to CQL by providing a
# toCQL() method on each query tree node type.

package Net::Z3950::RPN::Term;

sub _throw { return Net::Z3950::FOLIO::_throw(@_); }

sub toCQL {
    my $self = shift;
    my($session, $defaultSet) = @_;
    my $indexMap = $session->{cfg}->{indexMap};
    my($field, $relation);

    my $attrs = $self->{attributes};
    untie $attrs;

    # First we determine USE attribute
    foreach my $attr (@$attrs) {
	my $set = $attr->{attributeSet} || $defaultSet;
	if ($set ne Net::Z3950::FOLIO::ATTRSET_BIB1() &&
	    lc($set) ne 'bib-1') {
	    # Unknown attribute set (anything except BIB-1)
	    _throw(121, $set);
	}
	if ($attr->{attributeType} == 1) {
	    my $val = $attr->{attributeValue};
	    $field = _ap2index($indexMap, $val);
	    $relation = _ap2relation($indexMap, $val);
	}
    }

    if (!$field && $indexMap) {
	# No explicit access-point, fall back to default if specified
	$field = _ap2index($indexMap, 'default');
	$relation = _ap2relation($indexMap, 'default');
    }

    if ($field) {
	my @fields = split(/,/, $field);
	if (@fields > 1) {
	    return '(' . join(' or ', map { $self->_CQLTerm($_, $relation) } @fields) . ')';
	}
    }

    return $self->_CQLTerm($field, $relation);
}


sub _CQLTerm {
    my $self = shift;
    my($field, $relation) = @_;

    my($left_anchor, $right_anchor) = (0, 0);
    my($left_truncation, $right_truncation) = (0, 0);
    my $term = $self->{term};
    my $attrs = $self->{attributes};

    if (defined $field && $field =~ /(.*?)\/(.*)/) {
	$field = $1;
	$relation = "=/$2";
    }

    # Handle non-use attributes
    foreach my $attr (@$attrs) {
        my $type = $attr->{attributeType};
        my $value = $attr->{attributeValue};

        if ($type == 2) {
	    # Relation.  The following switch hard-codes information
	    # about the crrespondance between the BIB-1 attribute set
	    # and CQL context set.
	    if ($relation) {
		if ($value == 1) {
		    $relation = "<";
		} elsif ($value == 2) {
		    $relation = "<=";
		} elsif ($value == 3) {
		    $relation = "=";
		} elsif ($value == 4) {
		    $relation = ">=";
		} elsif ($value == 5) {
		    $relation = ">";
		} elsif ($value == 6) {
		    $relation = "<>";
		} elsif ($value == 100) {
		    $relation = "=/phonetic";
		} elsif ($value == 101) {
		    $relation = "=/stem";
		} elsif ($value == 102) {
		    $relation = "=/relevant";
		} else {
		    _throw(117, $value);
		}
	    }
        }

        elsif ($type == 3) { # Position
            if ($value == 1 || $value == 2) {
                $left_anchor = 1;
            } elsif ($value != 3) {
                _throw(119, $value);
            }
        }

        elsif ($type == 4) { # Structure -- we ignore it
        }

        elsif ($type == 5) { # Truncation
            if ($value == 1) {
                $right_truncation = 1;
            } elsif ($value == 2) {
                $left_truncation = 1;
            } elsif ($value == 3) {
                $right_truncation = 1;
                $left_truncation = 1;
            } elsif ($value == 101) {
		# Process # in search term
		$term =~ s/#/?/g;
            } elsif ($value == 104) {
		# Z39.58-style (CCL) truncation: #=single char, ?=multiple
		$term =~ s/\?\d?/*/g;
		$term =~ s/#/?/g;
            } elsif ($value != 100) {
                _throw(120, $value);
            }
        }

        elsif ($type == 6) { # Completeness
            if ($value == 2 || $value == 3) {
		$left_anchor = $right_anchor = 1;
	    } elsif ($value != 1) {
                _throw(122, $value);
            }
        }

        elsif ($type != 1) { # Unknown attribute type
            _throw(113, $type);
        }
    }

    $term = "*$term" if $left_truncation;
    $term = "$term*" if $right_truncation;
    $term = "^$term" if $left_anchor;
    $term = "$term^" if $right_anchor;

    $term = "\"$term\"" if $term =~ /[\s""\/=]/;

    if (defined $field && defined $relation) {
	$term = "$field $relation $term";
    } elsif (defined $field) {
	$term = "$field=$term";
    } elsif (defined $relation) {
	$term = "cql.serverChoice $relation $term";
    }

    return $term;
}


sub _ap2index {
    my($indexMap, $value) = @_;

    if (!defined $indexMap) {
	# This allows us to use string-valued attributes when no indexes are defined.
	return $value;
    }

    my $field = $indexMap->{$value};
    _throw(114, $value) if !defined $field;
    return $field->{cql} if ref $field;
    return $field;
}


sub _ap2relation {
    my($indexMap, $value) = @_;

    return undef if !defined $indexMap;
    my $field = $indexMap->{$value};
    return undef if !defined $field || !ref $field;
    return $field->{relation};
}


package Net::Z3950::RPN::RSID;
sub toCQL {
    my $self = shift;
    my($session, $defaultSet) = @_;

    my $zid = $self->{id};
    my $rs = $session->{resultsets}->{$zid};
    Net::Z3950::FOLIO::_throw(128, $zid) if !defined $rs; # "Illegal result set name"

    my $sid = $rs->{rsid};
    return qq[cql.resultSetId="$sid"]
}


package Net::Z3950::RPN::And;
sub toCQL {
    my $self = shift;
    my $left = $self->[0]->toCQL(@_);
    my $right = $self->[1]->toCQL(@_);
    return "($left and $right)";
}


package Net::Z3950::RPN::Or;
sub toCQL {
    my $self = shift;
    my $left = $self->[0]->toCQL(@_);
    my $right = $self->[1]->toCQL(@_);
    return "($left or $right)";
}


package Net::Z3950::RPN::AndNot;
sub toCQL {
    my $self = shift;
    my $left = $self->[0]->toCQL(@_);
    my $right = $self->[1]->toCQL(@_);
    return "($left not $right)";
}

1;
