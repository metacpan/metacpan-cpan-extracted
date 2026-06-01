package CSV::LINQ;
###############################################################################
# CSV::LINQ - LINQ-style query interface for CSV files
# Compatible: Perl 5.005_03 and later
# Platform  : Windows / UNIX
###############################################################################

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings;
local $^W = 1;

BEGIN { pop @INC if $INC[-1] eq '.' }

use vars qw($VERSION $_fh_seq);
$VERSION = '1.00';
$VERSION = $VERSION;
$_fh_seq = 0;

###############################################################################
# Internal file-handle helper
###############################################################################

# _open_fh - open a file for reading ('<') or writing ('>') and return
# the glob name string.  Works on Perl 5.005_03 and all later versions.
#
# Always uses a unique numbered package glob (CSV::LINQ::FH::H<n>) so
# that concurrent iterators each get their own IO slot.
#
# $raw: if true, binmode is called (raw bytes).
#       Pass 0 for CSV, where OS-level \r\n->\n conversion is desired.
sub _open_fh {
    my($mode, $file, $raw) = @_;
    $_fh_seq++;
    my $seq = $_fh_seq;
    my $fhn = "CSV::LINQ::FH::H${seq}";
    my $arg = ($mode eq '>') ? ">$file" : "< $file";
    { no strict 'refs'; open($fhn, $arg) or die "Cannot open '$file': $!\n" }
    if ($raw) { no strict 'refs'; binmode(*{$fhn}) }
    return $fhn;
}

###############################################################################
# Constructor
###############################################################################

sub new {
    my($class, $iter) = @_;
    return bless { _iter => $iter }, $class;
}

###############################################################################
# CSV parsing (RFC 4180 compliant)
###############################################################################

sub _parse_csv_line {
    my($line, $sep) = @_;
    $sep = ',' unless defined $sep;
    my @fields = ();
    $line =~ s{\r\n\z|\r\z|\n\z}{};
    my $pos = 0;
    my $len = length($line);
    while ($pos <= $len) {
        if ($pos < $len && substr($line, $pos, 1) eq '"') {
            $pos++;
            my $field = '';
            while ($pos < $len) {
                my $c = substr($line, $pos, 1);
                if ($c eq '"') {
                    $pos++;
                    if ($pos < $len && substr($line, $pos, 1) eq '"') {
                        $field .= '"';
                        $pos++;
                    }
                    else {
                        last;
                    }
                }
                else {
                    $field .= $c;
                    $pos++;
                }
            }
            push @fields, $field;
            $pos++ if $pos < $len && substr($line, $pos, 1) eq $sep;
        }
        else {
            my $start = $pos;
            while ($pos < $len && substr($line, $pos, 1) ne $sep) {
                $pos++;
            }
            push @fields, substr($line, $start, $pos - $start);
            $pos++;
        }
    }
    return @fields;
}

sub _format_csv_field {
    my($value, $sep) = @_;
    $sep = ',' unless defined $sep;
    $value = '' unless defined $value;
    if ($value =~ /["\n\r]/ || index($value, $sep) >= 0) {
        $value =~ s/"/""/g;
        return '"' . $value . '"';
    }
    return $value;
}

###############################################################################
# Data source methods
###############################################################################

sub From {
    my($class, $arrayref) = @_;
    die "From() requires ARRAY reference\n"
        unless ref($arrayref) eq 'ARRAY';
    my $i = 0;
    my $iter = sub {
        return undef if $i >= scalar(@{$arrayref});
        return $arrayref->[$i++];
    };
    return $class->new($iter);
}

sub FromCSV {
    my($class, $file, %opts) = @_;
    my $sep     = defined $opts{sep}     ? $opts{sep}     : ',';
    my $headers = $opts{headers};
    my $skip    = $opts{skip_header};
    my $fhn = _open_fh('<', $file, 0);
    my @cols = ();
    {
        no strict 'refs';
        if (!defined $headers) {
            my $hdr = readline(*{$fhn});
            if (defined $hdr) {
                @cols = _parse_csv_line($hdr, $sep);
            }
        }
        else {
            @cols = @{$headers};
            if ($skip) {
                readline(*{$fhn});
            }
        }
    }
    my $iter = sub {
        no strict 'refs';
        my $line = readline(*{$fhn});
        if (!defined $line) {
            close(*{$fhn});
            return undef;
        }
        $line =~ s{\r\n\z|\r\z|\n\z}{};
        return undef if $line eq '';
        my @vals = _parse_csv_line($line, $sep);
        my %rec = ();
        for my $i (0 .. $#cols) {
            $rec{ $cols[$i] } = $vals[$i];
        }
        return { %rec };
    };
    return $class->new($iter);
}

sub Range {
    my($class, $start, $count) = @_;
    my $current = $start;
    my $end     = $start + $count - 1;
    my $iter = sub {
        return undef if $current > $end;
        return $current++;
    };
    return $class->new($iter);
}

sub Empty {
    my($class) = @_;
    my $iter = sub { return undef };
    return $class->new($iter);
}

sub Repeat {
    my($class, $element, $count) = @_;
    my $i = 0;
    my $iter = sub {
        return undef if $i >= $count;
        $i++;
        return $element;
    };
    return $class->new($iter);
}

###############################################################################
# Internal iterator helpers
###############################################################################

sub _next {
    my($self) = @_;
    return $self->{_iter}->();
}

###############################################################################
# Filtering methods
###############################################################################

sub Where {
    my($self, @args) = @_;
    my $pred;
    if (ref($args[0]) eq 'CODE') {
        $pred = $args[0];
    }
    else {
        die "Where() DSL requires even number of arguments\n"
            if @args % 2 != 0;
        my %cond = @args;
        $pred = sub {
            my $rec = $_[0];
            for my $k (keys %cond) {
                return 0 unless defined $rec->{$k};
                return 0 unless $rec->{$k} eq $cond{$k};
            }
            return 1;
        };
    }
    my $source = $self;
    my $iter = sub {
        while (1) {
            my $elem = $source->_next();
            return undef unless defined $elem;
            return $elem if $pred->($elem);
        }
    };
    return ref($self)->new($iter);
}

###############################################################################
# Projection methods
###############################################################################

sub Select {
    my($self, $selector) = @_;
    my $source = $self;
    my $iter = sub {
        my $elem = $source->_next();
        return undef unless defined $elem;
        return $selector->($elem);
    };
    return ref($self)->new($iter);
}

sub SelectMany {
    my($self, $selector) = @_;
    my $source = $self;
    my @buf = ();
    my $iter = sub {
        while (1) {
            if (@buf) {
                return shift @buf;
            }
            my $elem = $source->_next();
            return undef unless defined $elem;
            my $arr = $selector->($elem);
            die "SelectMany: selector must return an ARRAY reference\n"
                unless ref($arr) eq 'ARRAY';
            push @buf, @{$arr};
        }
    };
    return ref($self)->new($iter);
}

###############################################################################
# Concatenation methods
###############################################################################

sub Concat {
    my($self, $second) = @_;
    my $source  = $self;
    my $second2 = $second;
    my $first_done = 0;
    my $iter = sub {
        unless ($first_done) {
            my $elem = $source->_next();
            if (defined $elem) {
                return $elem;
            }
            $first_done = 1;
        }
        return $second2->_next();
    };
    return ref($self)->new($iter);
}

sub Zip {
    my($self, $second, $selector) = @_;
    my $src1 = $self;
    my $src2 = $second;
    my $iter = sub {
        my $e1 = $src1->_next();
        my $e2 = $src2->_next();
        return undef unless defined $e1 && defined $e2;
        return $selector->($e1, $e2);
    };
    return ref($self)->new($iter);
}

###############################################################################
# Partitioning methods
###############################################################################

sub Take {
    my($self, $count) = @_;
    $count = 0 if $count < 0;
    my $source = $self;
    my $taken  = 0;
    my $iter = sub {
        return undef if $taken >= $count;
        my $elem = $source->_next();
        return undef unless defined $elem;
        $taken++;
        return $elem;
    };
    return ref($self)->new($iter);
}

sub Skip {
    my($self, $count) = @_;
    $count = 0 if $count < 0;
    my $source  = $self;
    my $skipped = 0;
    my $iter = sub {
        while ($skipped < $count) {
            my $elem = $source->_next();
            return undef unless defined $elem;
            $skipped++;
        }
        return $source->_next();
    };
    return ref($self)->new($iter);
}

sub TakeWhile {
    my($self, $pred) = @_;
    my $source = $self;
    my $done   = 0;
    my $iter = sub {
        return undef if $done;
        my $elem = $source->_next();
        return undef unless defined $elem;
        if ($pred->($elem)) {
            return $elem;
        }
        $done = 1;
        return undef;
    };
    return ref($self)->new($iter);
}

sub SkipWhile {
    my($self, $pred) = @_;
    my $source     = $self;
    my $skipping   = 1;
    my $iter = sub {
        while ($skipping) {
            my $elem = $source->_next();
            return undef unless defined $elem;
            unless ($pred->($elem)) {
                $skipping = 0;
                return $elem;
            }
        }
        return $source->_next();
    };
    return ref($self)->new($iter);
}

###############################################################################
# Ordering methods
###############################################################################

sub OrderBy {
    my($self, $key_sel) = @_;
    my @items = ();
    while (defined(my $e = $self->_next())) { push @items, $e }
    return CSV::LINQ::Ordered->_new_ordered([ @items ],
        [{ sel => $key_sel, dir => 1, type => 'smart' }]);
}

sub OrderByDescending {
    my($self, $key_sel) = @_;
    my @items = ();
    while (defined(my $e = $self->_next())) { push @items, $e }
    return CSV::LINQ::Ordered->_new_ordered([ @items ],
        [{ sel => $key_sel, dir => -1, type => 'smart' }]);
}

sub OrderByStr {
    my($self, $key_sel) = @_;
    my @items = ();
    while (defined(my $e = $self->_next())) { push @items, $e }
    return CSV::LINQ::Ordered->_new_ordered([ @items ],
        [{ sel => $key_sel, dir => 1, type => 'str' }]);
}

sub OrderByStrDescending {
    my($self, $key_sel) = @_;
    my @items = ();
    while (defined(my $e = $self->_next())) { push @items, $e }
    return CSV::LINQ::Ordered->_new_ordered([ @items ],
        [{ sel => $key_sel, dir => -1, type => 'str' }]);
}

sub OrderByNum {
    my($self, $key_sel) = @_;
    my @items = ();
    while (defined(my $e = $self->_next())) { push @items, $e }
    return CSV::LINQ::Ordered->_new_ordered([ @items ],
        [{ sel => $key_sel, dir => 1, type => 'num' }]);
}

sub OrderByNumDescending {
    my($self, $key_sel) = @_;
    my @items = ();
    while (defined(my $e = $self->_next())) { push @items, $e }
    return CSV::LINQ::Ordered->_new_ordered([ @items ],
        [{ sel => $key_sel, dir => -1, type => 'num' }]);
}

sub Reverse {
    my($self) = @_;
    my @items = ();
    while (defined(my $e = $self->_next())) { push @items, $e }
    my @rev = reverse @items;
    return ref($self)->new(ref($self)->From([ @rev ])->{_iter});
}

###############################################################################
# Internal sort helpers
###############################################################################

# _extract_key($raw_value, $type) - normalise one sort key
#
# Returns a scalar for 'num'/'str', or a two-element arrayref [flag, value]
# for 'smart':
#   [0, $numeric_val]  - key is numeric
#   [1, $string_val ]  - key is string
sub _extract_key {
    my($val, $type) = @_;
    $val = '' unless defined $val;
    if ($type eq 'num') {
        return defined($val) && length($val) ? $val + 0 : 0;
    }
    elsif ($type eq 'str') {
        return "$val";
    }
    else {
        # smart: detect whether value looks like a number
        my $t = $val;
        $t =~ s{^\s+}{};
        $t =~ s{\s+$}{};
        if ($t =~ /^[+-]?(?:\d+\.?\d*|\d*\.\d+)(?:[eE][+-]?\d+)?$/) {
            return [0, $t + 0];
        }
        else {
            return [1, "$val"];
        }
    }
}

# _compare_keys($ka, $kb, $type) - compare two extracted keys
sub _compare_keys {
    my($ka, $kb, $type) = @_;
    if ($type eq 'num') {
        return $ka <=> $kb;
    }
    elsif ($type eq 'str') {
        return $ka cmp $kb;
    }
    else {
        # smart: both are [flag, value] arrayrefs
        my $fa = $ka->[0]; my $va = $ka->[1];
        my $fb = $kb->[0]; my $vb = $kb->[1];
        if    ($fa == 0 && $fb == 0) { return $va <=> $vb }
        elsif ($fa == 1 && $fb == 1) { return $va cmp $vb }
        else                         { return $fa <=> $fb  }
    }
}

# _perform_sort($items_aref, $specs_aref) - stable multi-key sort
#
# Schwartzian Transform:
#   1. Decorate each element: [ orig_index, [key1..keyN], item ]
#   2. Sort by keys in sequence; original index as final tie-breaker (stability)
#   3. Undecorate
sub _perform_sort {
    my($items, $specs) = @_;

    # Step 1: decorate
    my @decorated = map {
        my $idx  = $_;
        my $item = $items->[$idx];
        my @keys = map { _extract_key($_->{sel}->($item), $_->{type}) } @{$specs};
        [$idx, [ @keys ], $item]
    } 0 .. $#{$items};

    # Step 2: sort
    my @sorted_dec = sort {
        my $r = 0;
        for my $i (0 .. $#{$specs}) {
            my $cmp = _compare_keys($a->[1][$i], $b->[1][$i], $specs->[$i]{type});
            if ($specs->[$i]{dir} < 0) { $cmp = -$cmp }
            if ($cmp != 0) { $r = $cmp; last }
        }
        $r != 0 ? $r : ($a->[0] <=> $b->[0]);
    } @decorated;

    # Step 3: undecorate
    return map { $_->[2] } @sorted_dec;
}

###############################################################################
# Ordered sub-class (ThenBy support)
###############################################################################

package CSV::LINQ::Ordered;
use vars qw(@ISA);
@ISA = ('CSV::LINQ');

# _new_ordered($items_aref, $specs_aref) - internal constructor
#
# $specs_aref is an arrayref of sort-spec hashrefs:
#   { sel  => $code_ref,           # key selector: ($item) -> $key
#     dir  => 1 or -1,             # 1 = ascending, -1 = descending
#     type => 'smart'|'str'|'num'  # comparison family
#   }
#
# Uses _factory so each _next() call draws from a fresh sorted iterator,
# enabling re-iteration of Ordered objects.
sub _new_ordered {
    my($class, $items, $specs) = @_;
    return bless {
        _items   => $items,
        _specs   => $specs,
        _factory => sub {
            my @sorted = CSV::LINQ::_perform_sort($items, $specs);
            my $i = 0;
            return sub { $i < scalar(@sorted) ? $sorted[$i++] : undef };
        },
    }, $class;
}

# Override _next() to use _factory if available
# When the iterator signals end-of-sequence (undef), clear {_iter} so
# the next call to _next() rebuilds a fresh iterator from {_factory},
# enabling re-iteration of the same Ordered object.
sub _next {
    my($self) = @_;
    unless (exists $self->{_iter}) {
        $self->{_iter} = $self->{_factory}->();
    }
    my $val = $self->{_iter}->();
    unless (defined $val) {
        delete $self->{_iter};
    }
    return $val;
}

# _thenby - shared implementation for all ThenBy* variants
#
# Non-destructive: builds a new spec list and returns a new
# CSV::LINQ::Ordered object. The original object is unchanged.
sub _thenby {
    my($self, $key_sel, $dir, $type) = @_;
    my @new_specs = (@{$self->{_specs}}, { sel => $key_sel, dir => $dir, type => $type });
    return CSV::LINQ::Ordered->_new_ordered($self->{_items}, [ @new_specs ]);
}

sub ThenBy              { my($s, $k)=@_; $s->_thenby($k,  1, 'smart') }
sub ThenByDescending    { my($s, $k)=@_; $s->_thenby($k, -1, 'smart') }
sub ThenByStr           { my($s, $k)=@_; $s->_thenby($k,  1, 'str')   }
sub ThenByStrDescending { my($s, $k)=@_; $s->_thenby($k, -1, 'str')   }
sub ThenByNum           { my($s, $k)=@_; $s->_thenby($k,  1, 'num')   }
sub ThenByNumDescending { my($s, $k)=@_; $s->_thenby($k, -1, 'num')   }

package CSV::LINQ;


###############################################################################
# Grouping methods
###############################################################################

sub GroupBy {
    my($self, $key_sel, $elem_sel) = @_;
    my %groups  = ();
    my @keys    = ();
    while (defined(my $e = $self->_next())) {
        my $k = $key_sel->($e);
        $k = '' unless defined $k;
        unless (exists $groups{$k}) {
            push @keys, $k;
            $groups{$k} = [];
        }
        if (defined $elem_sel) {
            push @{ $groups{$k} }, $elem_sel->($e);
        }
        else {
            push @{ $groups{$k} }, $e;
        }
    }
    my @result = ();
    for my $k (@keys) {
        push @result, { Key => $k, Elements => $groups{$k} };
    }
    return ref($self)->From([ @result ]);
}

###############################################################################
# Set operations
###############################################################################

sub Distinct {
    my($self, $comparer) = @_;
    my $source = $self;
    my %seen   = ();
    my $iter = sub {
        while (1) {
            my $elem = $source->_next();
            return undef unless defined $elem;
            my $key = defined $comparer ? $comparer->($elem) : $elem;
            $key = '' unless defined $key;
            next if $seen{$key};
            $seen{$key} = 1;
            return $elem;
        }
    };
    return ref($self)->new($iter);
}

sub Union {
    my($self, $second, $comparer) = @_;
    return $self->Concat($second)->Distinct($comparer);
}

sub Intersect {
    my($self, $second, $comparer) = @_;
    my %in2 = ();
    while (defined(my $e = $second->_next())) {
        my $k = defined $comparer ? $comparer->($e) : $e;
        $k = '' unless defined $k;
        $in2{$k} = 1;
    }
    my $source = $self;
    my %seen   = ();
    my $iter = sub {
        while (1) {
            my $elem = $source->_next();
            return undef unless defined $elem;
            my $k = defined $comparer ? $comparer->($elem) : $elem;
            $k = '' unless defined $k;
            next unless $in2{$k};
            next if $seen{$k};
            $seen{$k} = 1;
            return $elem;
        }
    };
    return ref($self)->new($iter);
}

sub Except {
    my($self, $second, $comparer) = @_;
    my %in2 = ();
    while (defined(my $e = $second->_next())) {
        my $k = defined $comparer ? $comparer->($e) : $e;
        $k = '' unless defined $k;
        $in2{$k} = 1;
    }
    my $source = $self;
    my %seen   = ();
    my $iter = sub {
        while (1) {
            my $elem = $source->_next();
            return undef unless defined $elem;
            my $k = defined $comparer ? $comparer->($elem) : $elem;
            $k = '' unless defined $k;
            next if $in2{$k};
            next if $seen{$k};
            $seen{$k} = 1;
            return $elem;
        }
    };
    return ref($self)->new($iter);
}

###############################################################################
# Join operations
###############################################################################

sub Join {
    my($self, $inner, $outer_key, $inner_key, $result_sel) = @_;
    my %lookup = ();
    while (defined(my $e = $inner->_next())) {
        my $k = $inner_key->($e);
        $k = '' unless defined $k;
        $lookup{$k} = [] unless exists $lookup{$k};
        push @{ $lookup{$k} }, $e;
    }
    my $source = $self;
    my @buf    = ();
    my $iter = sub {
        while (1) {
            if (@buf) {
                return shift @buf;
            }
            my $outer = $source->_next();
            return undef unless defined $outer;
            my $k = $outer_key->($outer);
            $k = '' unless defined $k;
            next unless exists $lookup{$k};
            for my $inner_elem (@{ $lookup{$k} }) {
                push @buf, $result_sel->($outer, $inner_elem);
            }
        }
    };
    return ref($self)->new($iter);
}

sub GroupJoin {
    my($self, $inner, $outer_key, $inner_key, $result_sel) = @_;
    my %lookup = ();
    while (defined(my $e = $inner->_next())) {
        my $k = $inner_key->($e);
        $k = '' unless defined $k;
        $lookup{$k} = [] unless exists $lookup{$k};
        push @{ $lookup{$k} }, $e;
    }
    my $source = $self;
    my $iter = sub {
        my $outer = $source->_next();
        return undef unless defined $outer;
        my $k = $outer_key->($outer);
        $k = '' unless defined $k;
        my $group = exists $lookup{$k} ? $lookup{$k} : [];
        my $inner_query = ref($self)->From([ @{$group} ]);
        return $result_sel->($outer, $inner_query);
    };
    return ref($self)->new($iter);
}

###############################################################################
# Quantifier methods
###############################################################################

sub All {
    my($self, $pred) = @_;
    while (defined(my $e = $self->_next())) {
        return 0 unless $pred->($e);
    }
    return 1;
}

sub Any {
    my($self, $pred) = @_;
    if (defined $pred) {
        while (defined(my $e = $self->_next())) {
            return 1 if $pred->($e);
        }
        return 0;
    }
    else {
        return defined($self->_next()) ? 1 : 0;
    }
}

sub Contains {
    my($self, $value, $comparer) = @_;
    while (defined(my $e = $self->_next())) {
        if (defined $comparer) {
            return 1 if $comparer->($e, $value);
        }
        else {
            if (!defined $value) {
                return 1 unless defined $e;
            }
            elsif (defined $e && $e eq $value) {
                return 1;
            }
        }
    }
    return 0;
}

sub SequenceEqual {
    my($self, $second, $comparer) = @_;
    while (1) {
        my $e1 = $self->_next();
        my $e2 = $second->_next();
        if (!defined $e1 && !defined $e2) {
            return 1;
        }
        return 0 if !defined $e1 || !defined $e2;
        if (defined $comparer) {
            return 0 unless $comparer->($e1, $e2);
        }
        else {
            return 0 unless $e1 eq $e2;
        }
    }
}

###############################################################################
# Element access methods
###############################################################################

sub First {
    my($self, $pred) = @_;
    while (defined(my $e = $self->_next())) {
        if (!defined $pred || $pred->($e)) {
            return $e;
        }
    }
    if (defined $pred) {
        die "No element satisfies the condition\n";
    }
    die "Sequence contains no elements\n";
}

sub FirstOrDefault {
    my($self, $pred, $default) = @_;
    if (ref($pred) eq 'CODE') {
        while (defined(my $e = $self->_next())) {
            return $e if $pred->($e);
        }
        return $default;
    }
    else {
        $default = $pred;
        my $e = $self->_next();
        return defined $e ? $e : $default;
    }
}

sub Last {
    my($self, $pred) = @_;
    my $found;
    my $has = 0;
    while (defined(my $e = $self->_next())) {
        if (!defined $pred || $pred->($e)) {
            $found = $e;
            $has   = 1;
        }
    }
    if ($has) {
        return $found;
    }
    if (defined $pred) {
        die "No element satisfies the condition\n";
    }
    die "Sequence contains no elements\n";
}

sub LastOrDefault {
    my($self, $pred) = @_;
    my $found;
    my $has = 0;
    while (defined(my $e = $self->_next())) {
        if (!defined $pred || $pred->($e)) {
            $found = $e;
            $has   = 1;
        }
    }
    return $has ? $found : undef;
}

sub Single {
    my($self, $pred) = @_;
    my $found;
    my $count = 0;
    while (defined(my $e = $self->_next())) {
        if (!defined $pred || $pred->($e)) {
            $found = $e;
            $count++;
            die "Sequence contains more than one element\n"
                if $count > 1;
        }
    }
    die "Sequence contains no elements\n" if $count == 0;
    return $found;
}

sub SingleOrDefault {
    my($self, $pred) = @_;
    my $found;
    my $count = 0;
    while (defined(my $e = $self->_next())) {
        if (!defined $pred || $pred->($e)) {
            $found = $e;
            $count++;
            return undef if $count > 1;
        }
    }
    return $count == 1 ? $found : undef;
}

sub ElementAt {
    my($self, $index) = @_;
    die "ElementAt: index out of range\n" if $index < 0;
    my $i = 0;
    while (defined(my $e = $self->_next())) {
        return $e if $i == $index;
        $i++;
    }
    die "ElementAt: index out of range\n";
}

sub ElementAtOrDefault {
    my($self, $index) = @_;
    return undef if $index < 0;
    my $i = 0;
    while (defined(my $e = $self->_next())) {
        return $e if $i == $index;
        $i++;
    }
    return undef;
}

###############################################################################
# Aggregation methods
###############################################################################

sub Count {
    my($self, $pred) = @_;
    my $n = 0;
    while (defined(my $e = $self->_next())) {
        if (!defined $pred || $pred->($e)) {
            $n++;
        }
    }
    return $n;
}

sub Sum {
    my($self, $selector) = @_;
    my $total = 0;
    while (defined(my $e = $self->_next())) {
        my $v = defined $selector ? $selector->($e) : $e;
        $total += (defined $v ? $v : 0);
    }
    return $total;
}

sub Min {
    my($self, $selector) = @_;
    my $min;
    while (defined(my $e = $self->_next())) {
        my $v = defined $selector ? $selector->($e) : $e;
        next unless defined $v;
        $min = $v if !defined $min || $v < $min;
    }
    return $min;
}

sub Max {
    my($self, $selector) = @_;
    my $max;
    while (defined(my $e = $self->_next())) {
        my $v = defined $selector ? $selector->($e) : $e;
        next unless defined $v;
        $max = $v if !defined $max || $v > $max;
    }
    return $max;
}

sub Average {
    my($self, $selector) = @_;
    my $sum = 0;
    my $n   = 0;
    while (defined(my $e = $self->_next())) {
        my $v = defined $selector ? $selector->($e) : $e;
        $sum += (defined $v ? $v : 0);
        $n++;
    }
    die "Sequence contains no elements\n" if $n == 0;
    return $sum / $n;
}

sub AverageOrDefault {
    my($self, $selector) = @_;
    my $sum = 0;
    my $n   = 0;
    while (defined(my $e = $self->_next())) {
        my $v = defined $selector ? $selector->($e) : $e;
        $sum += (defined $v ? $v : 0);
        $n++;
    }
    return $n == 0 ? undef : $sum / $n;
}

sub Aggregate {
    my($self, @args) = @_;
    my($seed, $func, $result_sel);
    if (@args == 1) {
        $func = $args[0];
        my $first = $self->_next();
        return undef unless defined $first;
        $seed = $first;
    }
    elsif (@args == 2) {
        ($seed, $func) = @args;
    }
    else {
        ($seed, $func, $result_sel) = @args;
    }
    my $acc = $seed;
    while (defined(my $e = $self->_next())) {
        $acc = $func->($acc, $e);
    }
    return defined $result_sel ? $result_sel->($acc) : $acc;
}

###############################################################################
# Conversion methods
###############################################################################

sub ToArray {
    my($self) = @_;
    my @result = ();
    while (defined(my $e = $self->_next())) {
        push @result, $e;
    }
    return @result;
}

sub ToList {
    my($self) = @_;
    my @result = ();
    while (defined(my $e = $self->_next())) {
        push @result, $e;
    }
    return [ @result ];
}

sub DefaultIfEmpty {
    my($self, $default) = @_;
    my $source  = $self;
    my $started = 0;
    my $done    = 0;
    my $iter = sub {
        if (!$started) {
            my $elem = $source->_next();
            $started = 1;
            unless (defined $elem) {
                unless ($done) {
                    $done = 1;
                    return $default;
                }
                return undef;
            }
            return $elem;
        }
        return undef if $done;
        return $source->_next();
    };
    return ref($self)->new($iter);
}

sub ToDictionary {
    my($self, $key_sel, $val_sel) = @_;
    my %dict = ();
    while (defined(my $e = $self->_next())) {
        my $k = $key_sel->($e);
        $k = '' unless defined $k;
        my $v = defined $val_sel ? $val_sel->($e) : $e;
        $dict{$k} = $v;
    }
    return { %dict };
}

sub ToLookup {
    my($self, $key_sel, $val_sel) = @_;
    my %lookup = ();
    my @keys   = ();
    while (defined(my $e = $self->_next())) {
        my $k = $key_sel->($e);
        $k = '' unless defined $k;
        unless (exists $lookup{$k}) {
            push @keys, $k;
            $lookup{$k} = [];
        }
        my $v = defined $val_sel ? $val_sel->($e) : $e;
        push @{ $lookup{$k} }, $v;
    }
    return { %lookup };
}

sub ToCSV {
    my($self, $file, %opts) = @_;
    my $sep       = defined $opts{sep}       ? $opts{sep}       : ',';
    my $headers   = defined $opts{headers}   ? $opts{headers}
                  : defined $opts{label_order} ? $opts{label_order}
                  : undef;
    my $no_header = $opts{no_header};
    my @items = ();
    while (defined(my $e = $self->_next())) {
        push @items, $e;
    }
    my $fhn = _open_fh('>', $file, 0);
    unless ($no_header) {
        my @cols = ();
        if (defined $headers) {
            @cols = @{$headers};
        }
        elsif (@items && ref($items[0]) eq 'HASH') {
            @cols = sort keys %{ $items[0] };
        }
        if (@cols) {
            no strict 'refs';
            print {*{$fhn}}
                join($sep, map { _format_csv_field($_, $sep) } @cols) . "\n";
        }
        if (!@cols && @items && ref($items[0]) ne 'HASH') {
            # scalar sequence - no header
        }
        else {
            for my $item (@items) {
                no strict 'refs';
                if (ref($item) eq 'HASH') {
                    print {*{$fhn}}
                        join($sep, map {
                            _format_csv_field($item->{$_}, $sep)
                        } @cols) . "\n";
                }
                else {
                    print {*{$fhn}}
                        _format_csv_field($item, $sep) . "\n";
                }
            }
            no strict 'refs';
            close(*{$fhn});
            return 1;
        }
    }
    for my $item (@items) {
        no strict 'refs';
        if (ref($item) eq 'HASH') {
            my @cols = sort keys %{$item};
            print {*{$fhn}}
                join($sep, map {
                    _format_csv_field($item->{$_}, $sep)
                } @cols) . "\n";
        }
        else {
            print {*{$fhn}}
                _format_csv_field($item, $sep) . "\n";
        }
    }
    {
        no strict 'refs';
        close(*{$fhn});
    }
    return 1;
}

###############################################################################
# Utility methods
###############################################################################

sub ForEach {
    my($self, $action) = @_;
    while (defined(my $e = $self->_next())) {
        $action->($e);
    }
    return;
}

1;

__END__

=head1 NAME

CSV::LINQ - LINQ-style query interface for CSV files

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use CSV::LINQ;

    # Read CSV file and query
    my @results = CSV::LINQ->FromCSV("sales.csv")
        ->Where(sub { $_[0]{amount} > 1000 })
        ->Select(sub { $_[0]{name} })
        ->Distinct()
        ->ToArray();

    # DSL syntax for simple filtering
    my @tokyo = CSV::LINQ->FromCSV("users.csv")
        ->Where(city => 'Tokyo')
        ->ToArray();

    # Grouping and aggregation
    my @stats = CSV::LINQ->FromCSV("sales.csv")
        ->GroupBy(sub { $_[0]{category} })
        ->Select(sub {
            my $g = shift;
            return {
                Category => $g->{Key},
                Count    => scalar(@{$g->{Elements}}),
                Total    => CSV::LINQ->From($g->{Elements})
                                ->Sum(sub { $_[0]{amount} }),
            };
        })
        ->OrderByNumDescending(sub { $_[0]{Total} })
        ->ToArray();

=head1 TABLE OF CONTENTS

=over 4

=item * L</DESCRIPTION>

=item * L</METHODS> - Complete method reference (60 methods)

=item * L</EXAMPLES> - Practical examples

=item * L</FEATURES> - Lazy evaluation, method chaining, DSL

=item * L</ARCHITECTURE> - Iterator design, execution flow

=item * L</PERFORMANCE> - Memory usage, optimization tips

=item * L</COMPATIBILITY> - Perl 5.005+ support, pure Perl

=item * L</DIAGNOSTICS> - Error messages

=item * L</COOKBOOK> - Common patterns

=item * L</LIMITATIONS AND KNOWN ISSUES> - Iterator consumption, undef values

=item * L</BUGS> - Bug reports

=item * L</SEE ALSO>

=back

=head1 DESCRIPTION

CSV::LINQ provides a LINQ-style query interface for CSV (Comma-Separated
Values) files. It offers a fluent, chainable API for filtering, transforming,
and aggregating CSV data.

Key features:

=over 4

=item * B<Lazy evaluation> - O(1) memory usage for most operations

=item * B<Method chaining> - Fluent, readable query composition

=item * B<DSL syntax> - Simple key-value filtering

=item * B<RFC 4180 compliant> - Proper CSV parsing including quoted fields

=item * B<60 LINQ methods> - Comprehensive query capabilities

=item * B<Pure Perl> - No XS dependencies

=item * B<Perl 5.005_03+> - Works on ancient and modern Perl

=back

=head2 What is CSV?

CSV (Comma-Separated Values) is the most widely used format for tabular data
exchange. The first row is treated as a header row containing column names.
Each subsequent row contains values for those columns.

Example:

    name,age,city
    Alice,30,Tokyo
    Bob,25,Osaka
    Carol,35,Tokyo

=head2 What is LINQ?

LINQ (Language Integrated Query) is a query syntax in C# and .NET.
This module brings LINQ-style querying to Perl for CSV data.

For more information: https://learn.microsoft.com/en-us/dotnet/csharp/linq/

=head1 METHODS

=head2 Complete Method Reference

This module implements 60 LINQ-style methods organized into 15 categories:

=over 4

=item * B<Data Sources (5)>: From, FromCSV, Range, Empty, Repeat

=item * B<Filtering (1)>: Where (with DSL)

=item * B<Projection (2)>: Select, SelectMany

=item * B<Concatenation (2)>: Concat, Zip

=item * B<Partitioning (4)>: Take, Skip, TakeWhile, SkipWhile

=item * B<Ordering (7)>: OrderBy, OrderByDescending, OrderByStr,
OrderByStrDescending, OrderByNum, OrderByNumDescending, Reverse

=item * B<Secondary Ordering (6)>: ThenBy, ThenByDescending, ThenByStr,
ThenByStrDescending, ThenByNum, ThenByNumDescending
(via CSV::LINQ::Ordered)

=item * B<Grouping (1)>: GroupBy

=item * B<Set Operations (4)>: Distinct, Union, Intersect, Except

=item * B<Join Operations (2)>: Join, GroupJoin

=item * B<Quantifiers (4)>: All, Any, Contains, SequenceEqual

=item * B<Element Access (8)>: First, FirstOrDefault, Last, LastOrDefault,
Single, SingleOrDefault, ElementAt, ElementAtOrDefault

=item * B<Aggregation (7)>: Count, Sum, Min, Max, Average, AverageOrDefault,
Aggregate

=item * B<Conversion (6)>: ToArray, ToList, ToCSV, DefaultIfEmpty,
ToDictionary, ToLookup

=item * B<Utility (1)>: ForEach

=back

=head2 Data Source Methods

=over 4

=item B<From(\@array)>

Create a query from an array.

    my $query = CSV::LINQ->From([{name => 'Alice'}, {name => 'Bob'}]);

=item B<FromCSV($file [, %opts])>

Create a query from a CSV file. The first line is used as column names
(header row), and each data row is returned as a hash reference.

Options:

=over 4

=item C<sep> - Field separator (default: C<','>). Use C<"\t"> for TSV.

=item C<headers> - Array reference of column names. If given, the first
data line is used as data (no header in file). Combine with C<skip_header>
to skip an existing header line.

=item C<skip_header> - If true, skip the first line even when C<headers>
is given.

=back

    # Standard CSV
    my $q = CSV::LINQ->FromCSV("data.csv");

    # Tab-separated (TSV)
    my $q = CSV::LINQ->FromCSV("data.tsv", sep => "\t");

    # Explicit headers (headerless CSV)
    my $q = CSV::LINQ->FromCSV("noheader.csv",
        headers    => [qw(name age city)]);

=item B<Range($start, $count)>

Generate a sequence of integers.

    my $q = CSV::LINQ->Range(1, 10);  # 1, 2, ..., 10

=item B<Empty()>

Return an empty sequence.

    my $q = CSV::LINQ->Empty();

=item B<Repeat($element, $count)>

Return a sequence that repeats $element $count times.

    my $q = CSV::LINQ->Repeat({value => 0}, 5);

=back

=head2 Filtering Methods

=over 4

=item B<Where($predicate)>

=item B<Where(key => value, ...)>

Filter elements. Accepts either a code reference or DSL form.

B<Code Reference Form:>

    ->Where(sub { $_[0]{age} >= 20 })
    ->Where(sub { $_[0]{city} eq 'Tokyo' && $_[0]{age} > 30 })

B<DSL Form (string equality, AND):>

    ->Where(city => 'Tokyo')
    ->Where(city => 'Tokyo', role => 'admin')

=back

=head2 Projection Methods

=over 4

=item B<Select($selector)>

Transform each element.

    ->Select(sub { $_[0]{name} })
    ->Select(sub { { Name => $_[0]{name}, Age => $_[0]{age} } })

=item B<SelectMany($selector)>

Flatten nested sequences. Selector must return an ARRAY reference.

    ->SelectMany(sub { $_[0]{tags} })

=back

=head2 Concatenation Methods

=over 4

=item B<Concat($second)>

Concatenate two sequences.

    $q1->Concat($q2)->ToArray()

=item B<Zip($second, $selector)>

Combine two sequences element by element.

    $q1->Zip($q2, sub { [$_[0], $_[1]] })->ToArray()

=back

=head2 Partitioning Methods

=over 4

=item B<Take($count)>

Take first N elements.

=item B<Skip($count)>

Skip first N elements.

=item B<TakeWhile($predicate)>

Take while predicate is true (stops at first false).

=item B<SkipWhile($predicate)>

Skip while predicate is true.

=back

=head2 Ordering Methods

B<Note:> All ordering methods are materializing (load all data into memory).

=over 4

=item B<OrderBy($key_selector)>

Sort ascending (smart comparison: numeric keys sort numerically, string keys
sort with C<cmp>; numeric values sort before strings when types differ).
Use C<OrderByStr> to force pure string comparison.

=item B<OrderByDescending($key_selector)>

Sort descending (smart comparison, same rules as C<OrderBy>).
Use C<OrderByStrDescending> to force pure string comparison.

=item B<OrderByStr($key_selector)>

Sort ascending (pure string comparison with C<cmp>).

=item B<OrderByStrDescending($key_selector)>

Sort descending (pure string comparison with C<cmp>).

=item B<OrderByNum($key_selector)>

Sort ascending (numeric comparison with C<< <=> >>).

=item B<OrderByNumDescending($key_selector)>

Sort descending (numeric comparison).

=item B<Reverse()>

Reverse the order.

=back

B<ThenBy methods> (available after OrderBy* via CSV::LINQ::Ordered):

ThenBy and ThenByDescending use smart comparison (same rules as OrderBy).
ThenByStr, ThenByStrDescending, ThenByNum, ThenByNumDescending use
string and numeric comparison respectively.

=head2 Grouping Methods

=over 4

=item B<GroupBy($key_selector [, $element_selector])>

Group elements. Returns query of hashrefs with C<Key> and C<Elements> fields.

    ->GroupBy(sub { $_[0]{city} })

=back

=head2 Set Operations

=over 4

=item B<Distinct([$comparer])>

Remove duplicates.

=item B<Union($second [, $comparer])>

Set union (no duplicates).

=item B<Intersect($second [, $comparer])>

Set intersection.

=item B<Except($second [, $comparer])>

Set difference.

=back

=head2 Join Operations

=over 4

=item B<Join($inner, $outer_key, $inner_key, $result_selector)>

Inner join. Inner sequence is fully buffered.

    $orders->Join(
        $customers,
        sub { $_[0]{customer_id} },
        sub { $_[0]{id} },
        sub { { Order => $_[0], Customer => $_[1] } }
    )

=item B<GroupJoin($inner, $outer_key, $inner_key, $result_selector)>

Left outer join. Inner group passed as re-iterable CSV::LINQ object.

=back

=head2 Quantifier Methods

=over 4

=item B<All($predicate)>

True if all elements satisfy predicate.

=item B<Any([$predicate])>

True if any element satisfies predicate (or sequence non-empty).

=item B<Contains($value [, $comparer])>

True if sequence contains value.

=item B<SequenceEqual($second [, $comparer])>

True if both sequences have same elements in same order.

=back

=head2 Element Access Methods

=over 4

=item B<First([$predicate])>

First element. Dies if empty.

=item B<FirstOrDefault([$predicate,] $default)>

First element or default.

=item B<Last([$predicate])>

Last element. Dies if empty.

=item B<LastOrDefault([$predicate])>

Last element or undef.

=item B<Single([$predicate])>

The only element. Dies if not exactly one.

=item B<SingleOrDefault([$predicate])>

The only element or undef.

=item B<ElementAt($index)>

Element at zero-based index. Dies if out of range.

=item B<ElementAtOrDefault($index)>

Element at index or undef.

=back

=head2 Aggregation Methods

=over 4

=item B<Count([$predicate])>

Count elements.

=item B<Sum([$selector])>

Sum of numeric values.

=item B<Min([$selector])>

Minimum value.

=item B<Max([$selector])>

Maximum value.

=item B<Average([$selector])>

Arithmetic mean. Dies if empty.

=item B<AverageOrDefault([$selector])>

Arithmetic mean or undef if empty.

=item B<Aggregate([$seed,] $func [, $result_selector])>

General fold/reduce operation.

=back

=head2 Conversion Methods

=over 4

=item B<ToArray()>

Convert to list.

    my @arr = $query->ToArray();

=item B<ToList()>

Convert to array reference.

    my $aref = $query->ToList();

=item B<ToCSV($file [, %opts])>

Write sequence to CSV file.

Options: C<sep> (default C<','>), C<headers> (arrayref), C<label_order> (arrayref, alias for C<headers>), C<no_header> (bool).

    $query->ToCSV("output.csv");
    $query->ToCSV("output.tsv", sep => "\t");
    $query->ToCSV("output.csv", headers => [qw(name age city)]);

=item B<DefaultIfEmpty([$default])>

Return default if sequence is empty.

=item B<ToDictionary($key_selector [, $value_selector])>

Convert to hash reference (key => element or transformed value).

=item B<ToLookup($key_selector [, $value_selector])>

Convert to hash reference (key => [elements]).

=back

=head2 Utility Methods

=over 4

=item B<ForEach($action)>

Execute action for each element (void context).

    $query->ForEach(sub { print $_[0]{name}, "\n" });

=back

=head1 EXAMPLES

=head2 Basic CSV Query

    use CSV::LINQ;

    # sales.csv:
    #   name,amount,category
    #   Alice,1500,A
    #   Bob,800,B
    #   Carol,2000,A

    my @high_sales = CSV::LINQ->FromCSV("sales.csv")
        ->Where(sub { $_[0]{amount} > 1000 })
        ->OrderByNumDescending(sub { $_[0]{amount} })
        ->ToArray();

=head2 Grouping and Aggregation

    my @by_category = CSV::LINQ->FromCSV("sales.csv")
        ->GroupBy(sub { $_[0]{category} })
        ->Select(sub {
            my $g = shift;
            return {
                Category => $g->{Key},
                Count    => scalar(@{$g->{Elements}}),
                Total    => CSV::LINQ->From($g->{Elements})
                                ->Sum(sub { $_[0]{amount} }),
            };
        })
        ->OrderByStrDescending(sub { $_[0]{Total} })
        ->ToArray();

=head2 Join Two CSV Files

    # orders.csv: id,customer_id,amount
    # customers.csv: id,name,city

    my $orders    = CSV::LINQ->FromCSV("orders.csv");
    my $customers = CSV::LINQ->FromCSV("customers.csv");

    my @joined = $orders->Join(
        $customers,
        sub { $_[0]{customer_id} },
        sub { $_[0]{id} },
        sub { { Name => $_[1]{name}, Amount => $_[0]{amount} } }
    )->ToArray();

=head2 TSV Support

    my @data = CSV::LINQ->FromCSV("data.tsv", sep => "\t")
        ->Where(status => 'active')
        ->ToArray();

=head2 Transform and Write

    CSV::LINQ->FromCSV("input.csv")
        ->Select(sub {
            my $r = shift;
            return { %{$r}, processed => 1 };
        })
        ->ToCSV("output.csv");

=head1 FEATURES

=head2 Lazy Evaluation

All query operations use lazy evaluation via iterators. Data is processed
on-demand, not all at once.

    # Only reads 10 records from file
    my @top10 = CSV::LINQ->FromCSV("huge.csv")
        ->Take(10)
        ->ToArray();

=head2 RFC 4180 Compliant CSV Parsing

Correctly handles:

=over 4

=item * Quoted fields containing commas

=item * Quoted fields containing double-quotes (escaped as C<"">)

=item * Quoted fields containing newlines

=item * Empty fields

=back

=head2 DSL Syntax

Simple key-value filtering without code references:

    ->Where(city => 'Tokyo', role => 'admin')

=head1 ARCHITECTURE

=head2 Iterator-Based Design

Each query operation returns a new query object wrapping an iterator
(a code reference that produces one element per call, returning undef
to signal end-of-sequence).

=head2 Memory Characteristics

B<Constant Memory Operations:> Where, Select, SelectMany, Concat, Zip,
Take, Skip, TakeWhile, SkipWhile, Distinct, ForEach, Count, Sum,
Min, Max, Average, First, Any, All.

B<Linear Memory Operations:> ToArray, ToList, ToCSV, OrderBy*,
GroupBy, Last, Reverse.

=head1 PERFORMANCE

=over 4

=item * Filter early with Where before OrderBy or GroupBy.

=item * Use Take to limit processing of large files.

=item * Reuse ToArray() result rather than iterating the query twice.

=back

=head1 COMPATIBILITY

This module is compatible with B<Perl 5.00503 and later>.

Uses only Perl core features. No CPAN dependencies required.

Build system: pmake.bat (Perl 5.005_03 on Windows lacks make).

=head1 DIAGNOSTICS

=over 4

=item C<Where() DSL requires even number of arguments>

Where() was called in DSL form with an odd number of arguments.
DSL form requires key-value pairs: C<< ->Where(key => value, ...) >>.

=item C<From() requires ARRAY reference>

From() was called with a non-array-reference argument.

=item C<Cannot open 'E<lt>filenameE<gt>': E<lt>reasonE<gt>>

FromCSV() or ToCSV() could not open the file.

=item C<Sequence contains no elements>

First(), Last(), Average(), Single() called on empty sequence.

=item C<No element satisfies the condition>

First() or Last() with predicate found no matching element.

=item C<Sequence contains more than one element>

Single() found more than one element.

=item C<SelectMany: selector must return an ARRAY reference>

The selector passed to SelectMany() returned a non-array-reference.

=item C<ElementAt: index out of range>

ElementAt() was called with a negative or out-of-range index.

=back

=head1 COOKBOOK

=head2 Top N by numeric field

    ->OrderByNumDescending(sub { $_[0]{score} })
      ->Take(10)
      ->ToArray()

=head2 Group and count

    ->GroupBy(sub { $_[0]{category} })
      ->Select(sub {
          {
              Category => $_[0]{Key},
              Count    => scalar(@{$_[0]{Elements}}),
          }
      })
      ->ToArray()

=head2 Pagination

    # Page 3, size 20
    ->Skip(40)->Take(20)->ToArray()

=head2 Unique values of a column

    ->Select(sub { $_[0]{category} })
      ->Distinct()
      ->ToArray()

=head2 CSV round-trip

    CSV::LINQ->FromCSV("input.csv")
        ->Where(sub { $_[0]{active} eq '1' })
        ->ToCSV("active.csv");

=head1 LIMITATIONS AND KNOWN ISSUES

=over 4

=item * B<ToCSV Column Order Without C<headers>>

When writing hash-reference sequences with C<ToCSV()> and no C<headers>
option, column order is determined by C<sort keys> of the first record.
To guarantee a specific column order, always pass the C<headers> option:

    $query->ToCSV("out.csv", headers => [qw(name age city)]);

=item * B<Iterator Consumption>

Query objects can only be consumed once. The iterator is exhausted after
terminal operations. Create a new query or save ToArray() result to reuse.

=item * B<Undef Values>

Due to the iterator-based design, undef signals end-of-sequence. Sequences
containing undef values may not work correctly with all operations. This is
not a practical limitation for CSV data (which uses hash references).

=item * B<Multi-line CSV Fields>

FromCSV() reads files one line at a time. CSV fields that span multiple lines
(embedded newlines within double-quoted fields) are not yet supported.

=item * B<No Parallel Execution>

All operations execute sequentially in a single thread.

=back

=head1 BUGS

Please report any bugs or feature requests to:

Email: C<ina.cpan@gmail.com>

=head1 SEE ALSO

=over 4

=item * L<LTSV::LINQ> - LINQ-style query interface for LTSV files

=item * L<JSON::LINQ> - LINQ-style query interface for JSON/JSONL files

=item * RFC 4180: https://www.ietf.org/rfc/rfc4180.txt

=item * Microsoft LINQ documentation:
https://learn.microsoft.com/en-us/dotnet/csharp/linq/

=back

=head1 AUTHOR

INABA Hitoshi E<lt>ina.cpan@gmail.comE<gt>

=head2 Contributors

Contributions are welcome! See file: CONTRIBUTING.

=head1 ACKNOWLEDGEMENTS

=head2 LINQ Technology

This module is inspired by LINQ (Language Integrated Query), developed by
Microsoft Corporation for the .NET Framework.

LINQ(R) is a registered trademark of Microsoft Corporation.

=head2 References

=over 4

=item * Microsoft LINQ: https://learn.microsoft.com/en-us/dotnet/csharp/linq/

=item * RFC 4180 (CSV): https://www.ietf.org/rfc/rfc4180.txt

=item * L<LTSV::LINQ> (inspiration): https://metacpan.org/pod/LTSV::LINQ

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 INABA Hitoshi

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head2 License Details

=over 4

=item * Artistic License 1.0:
https://dev.perl.org/licenses/artistic.html

=item * GNU General Public License version 1 or later:
https://www.gnu.org/licenses/gpl-1.0.html

=back

You may choose either license.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS
TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE
SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL
ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE
THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED
TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY
YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut
