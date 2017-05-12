package SQL::Format;

use strict;
use warnings;
use 5.008_001;
our $VERSION = '0.16';

use Exporter 'import';
use Carp qw(croak carp);

our @EXPORT = qw(sqlf);

our $DELIMITER     = ', ';
our $NAME_SEP      = '.';
our $QUOTE_CHAR    = '`';
our $LIMIT_DIALECT = 'LimitOffset';

our $SELF = __PACKAGE__->new;

my $SPEC_TO_METHOD_MAP = {
    '%c' => '_columns',
    '%t' => '_table',
    '%w' => '_where',
    '%o' => '_options',
    '%j' => '_join',
    '%s' => '_set',
};

my $OP_ALIAS = {
    -IN              => 'IN',
    -NOT_IN          => 'NOT IN',
    -BETWEEN         => 'BETWEEN',
    -NOT_BETWEEN     => 'NOT BETWEEN',
    -LIKE            => 'LIKE',
    -NOT_LIKE        => 'NOT LIKE',
    -LIKE_BINARY     => 'LIKE BINARY',
    -NOT_LIKE_BINARY => 'NOT LIKE BINARY',
};

my $OP_TYPE_MAP = {
    in => {
        'IN'     => 1,
        'NOT IN' => 1,
    },
    between => {
        'BETWEEN'     => 1,
        'NOT BETWEEN' => 1,
    },
    like => {
        'LIKE'            => 1,
        'NOT LIKE'        => 1,
        'LIKE BINARY'     => 1,
        'NOT LIKE BINARY' => 1,
    },
};

my $SORT_OP_ALIAS = {
    -ASC  => 'ASC',
    -DESC => 'DESC',
};

my $SUPPORTED_INDEX_TYPE_MAP = {
    USE    => 1,
    FORCE  => 1,
    IGNORE => 1,
};

use constant {
    _LIMIT_OFFSET => 1,
    _LIMIT_XY     => 2,
    _LIMIT_YX     => 3,
};
my $LIMIT_DIALECT_MAP = {
    LimitOffset => _LIMIT_OFFSET, # PostgreSQL, SQLite, MySQL 5.0
    LimitXY     => _LIMIT_XY,     # MySQL
    LimitYX     => _LIMIT_YX,     # SQLite
};

sub sqlf {
    my $format = shift;

    my @bind;
    my @tokens = split m#(%[ctwosj])(?=\W|$)#, $format;
    for (my $i = 1; $i < @tokens; $i += 2) {
        my $spec = $tokens[$i];
        my $method = $SPEC_TO_METHOD_MAP->{$spec};
        croak "'$spec' does not supported format" unless $method;
        croak sprintf "missing arguments nummber of %i and '%s' format in sqlf",
            ($i + 1) / 2, $spec unless @_;

        $tokens[$i] = $SELF->$method(shift(@_), \@bind);
    }

    return join('',@tokens), @bind;
}

sub _columns {
    my ($self, $val, $bind) = @_;
    my $ret;

    if (!defined $val) {
        $ret = '*';
    }
    elsif (ref $val eq 'ARRAY') {
        if (@$val) {
            $ret = join $DELIMITER, map {
                my $ret;
                my $ref = ref $_;
                if ($ref eq 'HASH') {
                    my ($term, $col) = %$_;
                    $ret = _quote($term).' '._quote($col);
                }
                elsif ($ref eq 'ARRAY') {
                    my ($term, $col) = @$_;
                    my @params;
                    if (ref $term eq 'ARRAY') {
                        ($term, @params) = @$term;
                    }
                    elsif (ref $term eq 'REF' && ref $$term eq 'ARRAY') {
                        ($term, @params) = @{$$term};
                    }

                    $ret = (
                        ref $term eq 'SCALAR' ? $$term : _quote($term)
                    ).' '._quote($col);
                    push @$bind, @params;
                }
                elsif ($ref eq 'REF' && ref $$_ eq 'ARRAY') {
                    my ($term, $col, @params) = @{$$_};
                    $ret = (
                        ref $term eq 'SCALAR' ? $$term : _quote($term)
                    ).' '._quote($col);
                    push @$bind, @params;
                }
                else {
                    $ret = _quote($_)
                }
                $ret;
            } @$val;
        }
        else {
            $ret = '*';
        }
    }
    elsif (ref $val eq 'SCALAR') {
        $ret = $$val;
    }
    else {
        $ret = _quote($val);
    }

    return $ret;
}

sub _table {
    my ($self, $val, $bind) = @_;
    my $ret;

    if (ref $val eq 'ARRAY') {
        $ret = join $DELIMITER, map {
            my $v = $_;
            my $ret;
            if (ref $v eq 'HASH') {
                $ret = _complex_table_expr($v);
            }
            else {
                $ret = _quote($v);
            }
            $ret;
        } @$val;
    }
    elsif (ref $val eq 'HASH') {
        $ret = _complex_table_expr($val);
    }
    elsif (defined $val) {
        $ret = _quote($val);
    }
    else {
        # noop
    }

    return $ret;
}

sub _where {
    my ($self, $val, $bind, $logic) = @_;

    if (ref $val eq 'ARRAY') {
        my @ret;
        for my $v (@$val) {
            push @ret, $self->_where($v, $bind);
        }
        $logic ||= 'OR';
        return @ret == 1 ? $ret[0] : join " $logic ", map { "($_)" } @ret;
    }

    return unless ref $val eq 'HASH';
    my $ret = join ' AND ', map {
        my $org_key  = $_;
        my $no_paren = 0;
        my ($k, $v) = (_quote($org_key), $val->{$org_key});
        if (uc $org_key eq '-OR') {
            $k = $self->_where($v, $bind);
        }
        elsif (uc $org_key eq '-AND') {
            $k = $self->_where($v, $bind, 'AND');
        }
        elsif (ref $v eq 'ARRAY') {
            if (
                   ref $v->[0]
                or (($v->[0]||'') eq '-and')
                or (($v->[0]||'') eq '-or')
            ) {
                # [-and => qw/foo bar baz/]
                # [-and => { '>' => 10 }, { '<' => 20 } ]
                # [-or  => qw/foo bar baz/]
                # [-or  => { '>' => 10 }, { '<' => 20 } ]
                # [{ '>' => 10 }, { '<' => 20 } ]
                my $logic = 'OR';
                my @values = @$v;
                if ($v->[0] && $v->[0] eq '-and') {
                    $logic = 'AND';
                    @values = @values[1..$#values];
                }
                elsif ($v->[0] && $v->[0] eq '-or') {
                    @values = @values[1..$#values];
                }
                my @statements;
                for my $arg (@values) {
                    my ($_stmt, @_bind) = sqlf('%w', { $org_key => $arg });
                    push @statements, $_stmt;
                    push @$bind, @_bind;
                }
                $k = join " $logic ", @statements;
            }
            elsif (@$v == 0) {
                # []
                $k = '0=1';
            }
            else {
                # [qw/1 2 3/]
                $k .= ' IN ('.join($DELIMITER, ('?')x@$v).')';
                push @$bind, @$v;
            }
        }
        elsif (ref $v eq 'HASH') {
            my $no_paren = scalar keys %$v > 1 ? 0 : 1;
            $k = join ' AND ', map {
                my $k = $k;
                my ($op, $v) = (uc($_), $v->{$_});
                $op = $OP_ALIAS->{$op} || $op;
                if ($OP_TYPE_MAP->{in}{$op}) {
                    my $ref = ref $v;
                    if ($ref eq 'ARRAY') {
                        unless (@$v) {
                            # { IN => [] }
                            $k = $op eq 'IN' ? '0=1' : '1=1';
                        }
                        else {
                            # { IN => [qw/1 2 3/] }
                            $k .= " $op (".join($DELIMITER, ('?')x@$v).')';
                            push @$bind, @$v;
                        }
                    }
                    elsif ($ref eq 'REF') {
                        # { IN => \['SELECT foo FROM bar WHERE hoge = ?', 'fuga']
                        $k .= " $op (${$v}->[0])";
                        push @$bind, @{$$v}[1..$#$$v];
                    }
                    elsif ($ref eq 'SCALAR') {
                        # { IN => \'SELECT foo FROM bar' }
                        $k .= " $op ($$v)";
                    }
                    elsif (defined $v) {
                        # { IN => 'foo' }
                        $k .= $op eq 'IN' ? ' = ?' : ' <> ?';
                        push @$bind, $v;
                    }
                    else {
                        # { IN => undef }
                        $k .= $op eq 'IN' ? ' IS NULL' : ' IS NOT NULL';
                    }
                }
                elsif ($OP_TYPE_MAP->{between}{$op}) {
                    my $ref = ref $v;
                    if ($ref eq 'ARRAY') {
                        # { BETWEEN => ['foo', 'bar'] }
                        # { BETWEEN => [\'lower(x)', \['upper(?)', 'y']] }
                        my ($va, $vb) = @$v;
                        my @stmt;
                        for my $value ($va, $vb) {
                            if (ref $value eq 'SCALAR') {
                                push @stmt, $$value;
                            }
                            elsif (ref $value eq 'REF') {
                                push @stmt, ${$value}->[0];
                                push @$bind, @{$$value}[1..$#$$value];
                            }
                            else {
                                push @stmt, '?';
                                push @$bind, $value;
                            }
                        }
                        $k .= " $op ".join ' AND ', @stmt;
                    }
                    elsif ($ref eq 'REF') {
                        # { BETWEEN => \["? AND ?", 1, 2] }
                        $k .= " $op ${$v}->[0]";
                        push @$bind, @{$$v}[1..$#$$v];
                    }
                    elsif ($ref eq 'SCALAR') {
                        # { BETWEEN => \'lower(x) AND upper(y)' }
                        $k .= " $op $$v";
                    }
                    else {
                        # { BETWEEN => $scalar }
                        # noop
                    }
                }
                elsif ($OP_TYPE_MAP->{like}{$op}) {
                    my $ref = ref $v;
                    my $escape_char;
                    if ($ref eq 'HASH') {
                        ($escape_char, $v) = %$v;
                        $ref = ref $v;
                    }
                    if ($ref eq 'ARRAY') {
                        # { LIKE => ['%foo', 'bar%'] }
                        # { LIKE => [\'"%foo"', \'"bar%"'] }
                        my @stmt;
                        for my $value (@$v) {
                            if (ref $value eq 'SCALAR') {
                                push @stmt, $$value;
                            }
                            else {
                                push @stmt, '?';
                                push @$bind, $value;
                            }
                            if ($escape_char) {
                                $stmt[-1] .= ' ESCAPE ?';
                                push @$bind, $escape_char;
                            }
                        }
                        $k = join ' OR ', map { "$k $op $_" } @stmt;
                    }
                    elsif ($ref eq 'SCALAR') {
                        # { LIKE => \'"foo%"' }
                        $k .= " $op $$v";
                        if ($escape_char) {
                            $k .= ' ESCAPE ?';
                            push @$bind, $escape_char;
                        }
                    }
                    else {
                        $k .= " $op ?";
                        push @$bind, $v;
                        if ($escape_char) {
                            $k .= ' ESCAPE ?';
                            push @$bind, $escape_char;
                        }
                    }
                }
                elsif (ref $v eq 'SCALAR') {
                    # { '>' => \'foo' }
                    $k .= " $op $$v";
                }
                elsif (ref $v eq 'ARRAY') {
                    if ($op eq '=') {
                        unless (@$v) {
                            $k = '0=1';
                        }
                        else {
                            $k .= " IN (".join($DELIMITER, ('?')x@$v).')';
                            push @$bind, @$v;
                        }
                    }
                    elsif ($op eq '!=') {
                        unless (@$v) {
                            $k = '1=1';
                        }
                        else {
                            $k .= " NOT IN (".join($DELIMITER, ('?')x@$v).')';
                            push @$bind, @$v;
                        }
                    }
                    else {
                        # { '>' => [qw/1 2 3/] }
                        $k .= join ' OR ', map { "$op ?" } @$v;
                        push @$bind, @$v;
                    }
                }
                elsif (ref $v eq 'REF' && ref $$v eq 'ARRAY') {
                    # { '>' => \['UNIX_TIMESTAMP(?)', '2012-12-12 00:00:00'] }
                    $k .= " $op ${$v}->[0]";
                    push @$bind, @{$$v}[1..$#$$v];
                }
                else {
                    # { '>' => 'foo' }
                    $k .= " $op ?";
                    push @$bind, $v;
                }
                $no_paren ? $k : "($k)";
            } sort keys %$v;
        }
        elsif (ref $v eq 'REF' && ref $$v eq 'ARRAY') {
            $k .= " IN ($$v->[0])";
            push @$bind, @{$$v}[1..$#$$v];
        }
        elsif (ref $v eq 'SCALAR') {
            # \'foo'
            $k .= " $$v";
        }
        elsif (!defined $v) {
            # undef
            $k .= ' IS NULL';
        }
        else {
            # 'foo'
            $k .= ' = ?';
            push @$bind, $v;
        }
        $no_paren ? $k : "($k)";
    } sort keys %$val;

    return $ret;
}

sub _options {
    my ($self, $val, $bind) = @_;

    my @exprs;
    if (exists $val->{group_by}) {
        my $ret = _sort_expr($val->{group_by});
        push @exprs, 'GROUP BY '.$ret;
    }
    if (exists $val->{having}) {
        my ($ret, @new_bind) = sqlf('%w', $val->{having});
        push @exprs, 'HAVING '.$ret;
        push @$bind, @new_bind;
    }
    if (exists $val->{order_by}) {
        my $ret = _sort_expr($val->{order_by});
        push @exprs, 'ORDER BY '.$ret;
    }
    if (defined $val->{limit}) {
        croak "limit must be numeric specified ($val->{limit})" if $val->{limit} =~ /\D/;
        my $ret = 'LIMIT ';
        if ($val->{offset}) { # defined and > 0
            croak "offset must be numeric specified ($val->{offset})" if $val->{offset} =~ /\D/;
            my $limit_dialect = $LIMIT_DIALECT_MAP->{$LIMIT_DIALECT} || 0;
            if ($limit_dialect == _LIMIT_OFFSET) {
                $ret .= "$val->{limit} OFFSET $val->{offset}";
            }
            elsif ($limit_dialect == _LIMIT_XY) {
                $ret .= "$val->{offset}, $val->{limit}";
            }
            elsif ($limit_dialect == _LIMIT_YX) {
                $ret .= "$val->{limit}, $val->{offset}";
            }
            else {
                warn "Unkown LIMIT_DIALECT `$LIMIT_DIALECT`";
                $ret .= $val->{limit};
            }
        }
        else {
            $ret .= $val->{limit};
        }
        push @exprs, $ret;
    }

    return join ' ', @exprs;
}

sub _join {
    my ($self, $val, $bind) = @_;

    my @statements;
    $val = [$val] unless ref $val eq 'ARRAY';
    for my $param (@$val) {
        croak '%j mast be HASH ref specified' unless ref $param eq 'HASH';
        croak 'table and condition options must be specified at %j'
            unless $param->{table} && $param->{condition};

        my $ret = sprintf '%s JOIN ', uc($param->{type} || 'INNER');
        $ret .= $self->_table($param->{table}, $bind);

        if (ref $param->{condition} eq 'ARRAY') {
            $ret .= ' USING ('.(
                join $DELIMITER, map { _quote($_) } @{$param->{condition}}
            ).')';
        }
        elsif (ref $param->{condition} eq 'HASH') {
            my $cond = $param->{condition};
            my $no_paren = keys %$cond > 1 ? 0 : 1;
            $ret .= ' ON '.(join ' AND ', map {
                my ($k, $v) = ($_, $cond->{$_});
                my $ret;
                if (uc $k eq '-WHERE') {
                    $ret = $self->_where($v, $bind);
                }
                elsif (ref $v eq 'HASH') {
                    my $no_paren = keys %$v > 1 ? 0 : 1;
                    $ret = join ' AND ', map {
                        my $op = $_;
                        my $ret;
                        if (ref $v->{$op} eq 'REF' && ref ${$v->{$op}} eq 'ARRAY') {
                            my $v = ${$v->{$op}};
                            $ret = _quote($k)." $op ".$v->[0];
                            push @$bind, @{$v}[1..$#$v];
                        }
                        else {
                            $ret = _quote($k)." $op "._quote($v->{$_});
                        }
                        $no_paren ? $ret : "($ret)";
                    } sort keys %$v;
                }
                elsif (ref $v eq 'REF' && ref $$v eq 'ARRAY') {
                    my $v = $$v;
                    $ret = _quote($k).' = '._quote($v->[0]);
                    push @$bind, @{$v}[1..$#$v];
                }
                else {
                    $ret = _quote($k).' = '._quote($v);
                }
                $no_paren ? $ret : "($ret)";
            } sort keys %$cond);
        }
        else {
            $ret .= ' ON '.$param->{condition};
        }
        push @statements, $ret;
    }

    return join ' ', @statements;
}

sub _quote {
    my $stuff = shift;
    return $$stuff if ref $stuff eq 'SCALAR';
    return $stuff unless $QUOTE_CHAR && $NAME_SEP;
    return $stuff if $stuff eq '*';
    return $stuff if substr($stuff, 0, 1) eq $QUOTE_CHAR; # skip if maybe quoted
    return $stuff if $stuff =~ /\(/; # skip if maybe used function
    return join $NAME_SEP, map {
        "$QUOTE_CHAR$_$QUOTE_CHAR"
    } split /\Q$NAME_SEP\E/, $stuff;
}

sub _complex_table_expr {
    my $stuff = shift;
    my $ret = join $DELIMITER, map {
        my ($k, $v) = ($_, $stuff->{$_});
        my $ret = _quote($k);
        if (ref $v eq 'HASH') {
            $ret .= ' '._quote($v->{alias}) if $v->{alias};
            if (exists $v->{index} && ref $v->{index}) {
                my $type = uc($v->{index}{type} || 'USE');
                croak "unkown index type: $type"
                    unless $SUPPORTED_INDEX_TYPE_MAP->{$type};
                croak "keys field must be specified in index option"
                    unless defined $v->{index}{keys};
                my $keys = $v->{index}{keys};
                $keys = [ $keys ] unless ref $keys eq 'ARRAY';
                $ret .= " $type INDEX (".join($DELIMITER,
                    map { _quote($_) } @$keys
                ).")";
            }
        }
        else {
            $ret .= ' '._quote($v);
        }
        $ret;
    } sort keys %$stuff;

    return $ret;
}

sub _sort_expr {
    my $stuff = shift;
    my $ret = '';
    if (!defined $stuff) {
        # undef
        $ret .= 'NULL';
    }
    elsif (ref $stuff eq 'HASH') {
        # { colA => 'DESC' }
        # { -asc => 'colB' }
        $ret .= join $DELIMITER, map {
            if (my $sort_op = $SORT_OP_ALIAS->{uc $_}) {
                _quote($stuff->{$_}).' '.$sort_op,
            }
            else {
                _quote($_).' '.$stuff->{$_}
            }
        } sort keys %$stuff;
    }
    elsif (ref $stuff eq 'ARRAY') {
        # ['column1', { column2 => 'DESC', -asc => 'column3' }]
        my @parts;
        for my $part (@$stuff) {
            if (ref $part eq 'HASH') {
                push @parts, join $DELIMITER, map {
                    if (my $sort_op = $SORT_OP_ALIAS->{uc $_}) {
                        _quote($part->{$_}).' '.$sort_op,
                    }
                    else {
                        _quote($_).' '.$part->{$_}
                    }
                } sort keys %$part;
            }
            else {
                push @parts, _quote($part);
            }
        }
        $ret .= join $DELIMITER, @parts;
    }
    else {
        # 'column'
        $ret .= _quote($stuff);
    }
    return $ret;
}

sub _set {
    my ($self, $val, $bind) = @_;

    my @set = ref $val eq 'HASH' ? map { $_ => $val->{$_} } sort keys %$val : @$val;
    my @columns;
    for (my $i = 0; $i < @set; $i += 2) {
        my ($col, $val) = ($set[$i], $set[$i+1]);
        my $quoted_col = _quote($col);
        if (ref $val eq 'SCALAR') {
            # foo => { bar => \'NOW()' }
            push @columns, "$quoted_col = $$val";
        }
        elsif (ref $val eq 'REF' && ref $$val eq 'ARRAY') {
            # foo => { bar => \['UNIX_TIMESTAMP(?)', '2011-11-11 11:11:11'] }
            my ($stmt, @sub_bind) = @{$$val};
            push @columns, "$quoted_col = $stmt";
            push @$bind, @sub_bind;
        }
        else {
            # foo => { bar => 'baz' }
            push @columns, "$quoted_col = ?";
            push @$bind, $val;
        }
    }

    my $ret = join $self->{delimiter}, @columns;
}

sub new {
    my ($class, %args) = @_;

    if (exists $args{driver} && defined $args{driver}) {
        my $driver = lc $args{driver};
        unless (defined $args{quote_char}) {
            $args{quote_char} = $driver eq 'mysql' ? '`' : '"';
        }
        unless (defined $args{limit_dialect}) {
            $args{limit_dialect} =
                $driver eq 'mysql'  ? 'LimitXY' : 'LimitOffset';
        }
    }

    bless {
        delimiter     => $DELIMITER,
        name_sep      => $NAME_SEP,
        quote_char    => $QUOTE_CHAR,
        limit_dialect => $LIMIT_DIALECT,
        %args,
    }, $class;
}

sub format {
    my $self = shift;
    local $SELF          = $self;
    local $DELIMITER     = $self->{delimiter};
    local $NAME_SEP      = $self->{name_sep};
    local $QUOTE_CHAR    = $self->{quote_char};
    local $LIMIT_DIALECT = $self->{limit_dialect};
    sqlf(@_);
}

sub select {
    my ($self, $table, $cols, $where, $opts) = @_;
    croak 'Usage: $sqlf->select($table [, \@cols, \%where, \%opts])' unless defined $table;

    local $SELF          = $self;
    local $DELIMITER     = $self->{delimiter};
    local $NAME_SEP      = $self->{name_sep};
    local $QUOTE_CHAR    = $self->{quote_char};
    local $LIMIT_DIALECT = $self->{limit_dialect};

    my $prefix = delete $opts->{prefix} || 'SELECT';
    my $suffix = delete $opts->{suffix};
    my $format = "$prefix %c FROM %t";
    my @args   = ($cols, $table);

    if (my $join = delete $opts->{join}) {
        $format .= ' %j';
        push @args, $join;
    }
    if ($where && (ref $where eq 'HASH' && keys %$where) || (ref $where eq 'ARRAY' && @$where)) {
        $format .= ' WHERE %w';
        push @args, $where;
    }
    if (keys %$opts) {
        $format .= ' %o';
        push @args, $opts;
    }
    if ($suffix) {
        $format .= " $suffix";
    }

    sqlf($format, @args);
}

sub insert {
    my ($self, $table, $values, $opts) = @_;
    croak 'Usage: $sqlf->insert($table \%values|\@values [, \%opts])' unless defined $table && ref $values;

    local $SELF          = $self;
    local $DELIMITER     = $self->{delimiter};
    local $NAME_SEP      = $self->{name_sep};
    local $QUOTE_CHAR    = $self->{quote_char};
    local $LIMIT_DIALECT = $self->{limit_dialect};

    my $prefix       = $opts->{prefix} || 'INSERT INTO';
    my $quoted_table = _quote($table);

    my @values = ref $values eq 'HASH' ? %$values : @$values;
    my (@columns, @bind_cols, @bind_params);
    for (my $i = 0; $i < @values; $i += 2) {
        my ($col, $val) = ($values[$i], $values[$i+1]);
        push @columns, _quote($col);
        if (ref $val eq 'SCALAR') {
            # foo => { bar => \'NOW()' }
            push @bind_cols, $$val;
        }
        elsif (ref $val eq 'REF' && ref $$val eq 'ARRAY') {
            # foo => { bar => \['UNIX_TIMESTAMP(?)', '2011-11-11 11:11:11'] }
            my ($stmt, @sub_bind) = @{$$val};
            push @bind_cols, $stmt;
            push @bind_params, @sub_bind;
        }
        else {
            # foo => { bar => 'baz' }
            push @bind_cols, '?';
            push @bind_params, $val;
        }
    }

    my $stmt = "$prefix $quoted_table "
             . '('.join(', ', @columns).') '
             . 'VALUES ('.join($self->{delimiter}, @bind_cols).')';

    return $stmt, @bind_params;
}

sub update {
    my ($self, $table, $set, $where, $opts) = @_;
    croak 'Usage: $sqlf->update($table \%set|\@set [, \%where, \%opts])' unless defined $table && ref $set;

    local $SELF          = $self;
    local $DELIMITER     = $self->{delimiter};
    local $NAME_SEP      = $self->{name_sep};
    local $QUOTE_CHAR    = $self->{quote_char};
    local $LIMIT_DIALECT = $self->{limit_dialect};

    my $prefix       = delete $opts->{prefix} || 'UPDATE';
    my $quoted_table = _quote($table);

    my $set_clause = $self->_set($set, \my @bind_params);
    my $format = "$prefix $quoted_table SET ".$set_clause;

    my @args;
    if ($where && (ref $where eq 'HASH' && keys %$where) || (ref $where eq 'ARRAY' && @$where)) {
        $format .= ' WHERE %w';
        push @args, $where;
    }
    if (keys %$opts) {
        $format .= ' %o';
        push @args, $opts;
    }

    my ($stmt, @bind) = sqlf($format, @args);

    return $stmt, (@bind_params, @bind);
}

sub delete {
    my ($self, $table, $where, $opts) = @_;
    croak 'Usage: $sqlf->delete($table [, \%where, \%opts])' unless defined $table;

    local $SELF          = $self;
    local $DELIMITER     = $self->{delimiter};
    local $NAME_SEP      = $self->{name_sep};
    local $QUOTE_CHAR    = $self->{quote_char};
    local $LIMIT_DIALECT = $self->{limit_dialect};

    my $prefix       = delete $opts->{prefix} || 'DELETE';
    my $quoted_table = _quote($table);
    my $format       = "$prefix FROM $quoted_table";

    my @args;
    if ($where && (ref $where eq 'HASH' && keys %$where) || (ref $where eq 'ARRAY' && @$where)) {
        $format .= ' WHERE %w';
        push @args, $where;
    }
    if (keys %$opts) {
        $format .= ' %o';
        push @args, $opts;
    }

    sqlf($format, @args);
}

sub insert_multi {
    my ($self, $table, $cols, $values, $opts) = @_;
    croak 'Usage: $sqlf->insert_multi($table, \@cols, [ \@values1, \@values2, ... ] [, \%opts])'
        unless ref $cols eq 'ARRAY' && ref $values eq 'ARRAY';

    local $SELF          = $self;
    local $DELIMITER     = $self->{delimiter};
    local $NAME_SEP      = $self->{name_sep};
    local $QUOTE_CHAR    = $self->{quote_char};
    local $LIMIT_DIALECT = $self->{limit_dialect};

    my $prefix       = $opts->{prefix} || 'INSERT INTO';
    my $quoted_table = _quote($table);

    my $columns_num = @$cols;
    my @bind_params;
    my @values_stmt;
    for my $value (@$values) {
        my @bind_cols;
        for (my $i = 0; $i < $columns_num; $i++) {
            my $val = $value->[$i];
            if (ref $val eq 'SCALAR') {
                # \'NOW()'
                push @bind_cols, $$val;
            }
            elsif (ref $val eq 'REF' && ref $$val eq 'ARRAY') {
                # \['UNIX_TIMESTAMP(?)', '2011-11-11 11:11:11']
                my ($expr, @sub_bind) = @{$$val};
                push @bind_cols, $expr;
                push @bind_params, @sub_bind;
            }
            else {
                # 'baz'
                push @bind_cols, '?';
                push @bind_params, $val;
            }
        }
        push @values_stmt, '('.join($self->{delimiter}, @bind_cols).')';
    }

    my $stmt = "$prefix $quoted_table "
        . '('.join($self->{delimiter}, map { _quote($_) } @$cols).') '
        . 'VALUES '.join($self->{delimiter}, @values_stmt);

    if ($opts->{update}) {
        my $update_stmt = $self->_set($opts->{update}, \@bind_params);
        $stmt .= " ON DUPLICATE KEY UPDATE $update_stmt";
    }

    return $stmt, @bind_params;
}

sub insert_multi_from_hash {
    my ($self, $table, $values, $opts) = @_;
    croak 'Usage: $sqlf->insert_multi_from_hash($table, [ { colA => $valA, colB => $valB }, { ... } ] [, \%opts])'
        unless ref $values eq 'ARRAY' && ref $values->[0] eq 'HASH';

    my $cols = [ keys %{$values->[0]} ];
    my $new_values = [];
    for my $value (@$values) {
        push @$new_values, [ @$value{@$cols} ];
    }

    $self->insert_multi($table, $cols, $new_values, $opts);
}

sub insert_on_duplicate {
    my ($self, $table, $values, $update_values, $opts) = @_;
    croak 'Usage: $sqlf->insert_on_duplicate($table, \%values|\@values, \%update_values|\@update_values [, \%opts])'
        unless ref $values && ref $update_values;

    my ($stmt, @bind) = $self->insert($table, $values, $opts);
    my $set_clause = $self->_set($update_values, \@bind);

    $stmt .= " ON DUPLICATE KEY UPDATE $set_clause";

    return $stmt, @bind;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

SQL::Format - Yet another yet another SQL builder

=head1 SYNOPSIS

  use SQL::Format;

  my ($stmt, @bind) = sqlf 'SELECT %c FROM %t WHERE %w' => (
      [qw/bar baz/], # %c
      'foo',         # %t
      {
          hoge => 'fuga',
          piyo => [qw/100 200 300/],
      },             # %w
  );
  # $stmt: SELECT `bar`, `baz` FROM `foo` WHERE (`hoge` = ?) AND (`piyo` IN (?, ?, ?))
  # @bind: ('fuga', 100, 200, 300);

  ($stmt, @bind) = sqlf 'SELECT %c FROM %t WHERE %w %o' => (
      '*',                # %c
      'foo',              # %t
      { hoge => 'fuga' }, # w
      {
          order_by => { bar => 'DESC' },
          limit    => 100,
          offset   => 10,
      },                  # %o
  );
  # $stmt: SELECT * FROM `foo` WHERE (`hoge` = ?) ORDER BY `bar` DESC LIMIT 100 OFFSET 10
  # @bind: (`fuga`)

  ($stmt, @bind) = sqlf 'UPDATE %t SET %s' => (
      foo => { bar => 'baz', 'hoge => 'fuga' },
  );
  # $stmt: UPDATE `foo` SET `bar` = ?, `hoge` = ?
  # @bind: ('baz', 'fuga')

  my $sqlf = SQL::Format->new(
      quote_char    => '',        # do not quote
      limit_dialect => 'LimitXY', # mysql style limit-offset
  );
  ($stmt, @bind) = $sqlf->select(foo => [qw/bar baz/], {
      hoge => 'fuga',
  }, {
      order_by => 'bar',
      limit    => 100,
      offset   => 10,
  });
  # $stmt: SELECT bar, baz FROM foo WHERE (hoge = ?) ORDER BY bar LIMIT 10, 100
  # @bind: ('fuga')

  ($stmt, @bind) = $sqlf->insert(foo => { bar => 'baz', hoge => 'fuga' });
  # $stmt: INSERT INTO foo (bar, hoge) VALUES (?, ?)
  # @bind: ('baz', 'fuga')

  ($stmt, @bind) = $sqlf->update(foo => { bar => 'xxx' }, { hoge => 'fuga' });
  # $stmt: UPDATE foo SET bar = ? WHERE hoge = ?
  # @bind: ('xxx', 'fuga')

  ($stmt, @bind) = $sqlf->delete(foo => { hoge => 'fuga' });
  # $stmt: DELETE FROM foo WHERE (hoge = ?)
  # @bind: ('fuga')

=head1 DESCRIPTION

SQL::Format is a easy to SQL query building library.

B<< THIS MODULE IS ALPHA LEVEL INTERFACE!! >>

=head1 FUNCTIONS

=head2 sqlf($format, @args)

Generate SQL from formatted output conversion.

  my ($stmt, @bind) = sqlf 'SELECT %c FROM %t WHERE %w' => (
      [qw/bar baz/],   # %c
      'foo',           # %t
      {
          hoge => 'fuga',
          piyo => [100, 200, 300],
      },               # %w
  );
  # $stmt: SELECT `foo` FROM `bar`, `baz WHERE (`hoge` = ?) AND (`piyo` IN (?, ?, ?))
  # @bind: ('fuga', 100, 200, 300)

Currently implemented formatters are:

=over

=item %t

This format is a table name.

  ($stmt, @bind) = sqlf '%t', 'table_name';        # $stmt => `table_name`
  ($stmt, @bind) = sqlf '%t', [qw/tableA tableB/]; # $stmt => `tableA`, `tableB`
  ($stmt, @bind) = sqlf '%t', { tableA => 't1' };  # $stmt => `tableA` `t1`
  ($stmt, @bind) = sqlf '%t', {
      tableA => {
          index => { type => 'force', keys => [qw/key1 key2/] },
          alias => 't1',
  }; # $stmt: `tableA` `t1` FORCE INDEX (`key1`, `key2`)

=item %c

This format is a column name.

  ($stmt, @bind) = sqlf '%c', 'column_name';       # $stmt => `column_name`
  ($stmt, @bind) = sqlf '%c', [qw/colA colB/];     # $stmt => `colA`, `colB`
  ($stmt, @bind) = sqlf '%c', '*';                 # $stmt => *
  ($stmt, @bind) = sqlf '%c', [\'COUNT(*)', colC]; # $stmt => COUNT(*), `colC`

=item %w

This format is a where clause.

  ($stmt, @bind) = sqlf '%w', { foo => 'bar' };
  # $stmt: (`foo` = ?)
  # @bind: ("bar")

  ($stmt, @bind) = sqlf '%w', {
      foo => 'bar',
      baz => [qw/100 200 300/],
  };
  # $stmt: (`baz` IN (?, ?, ?) AND (`foo` = ?)
  # @bind: (100, 200, 300, 'bar')

=item %o

This format is a options. Currently specified are:

=over

=item limit

This option makes C<< LIMIT $n >> clause.

  ($stmt, @bind) = sqlf '%o', { limit => 100 }; # $stmt => LIMIT 100

=item offset

This option makes C<< OFFSET $n >> clause. You must be specified both limit option.

  ($stmt, @bind) = sqlf '%o', { limit => 100, offset => 20 }; # $stmt => LIMIT 100 OFFSET 20

You can change limit dialects from C<< $SQL::Format::LIMIT_DIALECT >>.

=item order_by

This option makes C<< ORDER BY >> clause.

  ($stmt, @bind) = sqlf '%o', { order_by => 'foo' };                       # $stmt => ORDER BY `foo`
  ($stmt, @bind) = sqlf '%o', { order_by => { foo => 'DESC' } };           # $stmt => ORDER BY `foo` DESC
  ($stmt, @bind) = sqlf '%o', { order_by => ['foo', { -asc => 'bar' } ] }; # $stmt => ORDER BY `foo`, `bar` ASC

=item group_by

This option makes C<< GROUP BY >> clause. Argument value some as C<< order_by >> option.

  ($stmt, @bind) = sqlf '%o', { group_by => { foo => 'DESC' } }; # $stmt => GROUP BY `foo` DESC

=item having

This option makes C<< HAVING >> clause. Argument value some as C<< where >> clause.

  ($stmt, @bind) = sqlf '%o', { having => { foo => 'bar' } };
  # $stmt: HAVING (`foo` = ?)
  # @bind: ('bar')

=back

=item %j

This format is join clause.

  ($stmt, @bind) = sqlf '%j', { table => 'bar', condition => 'foo.id = bar.id' };
  # $stmt: INNER JOIN `bar` ON (foo.id = bar.id)

  ($stmt, @bind) = sqlf '%j', {
      type      => 'left',
      table     => { bar => 'b' },
      condition => {
          'f.id'         => 'b.id',
          'f.updated_at' => \['UNIX_TIMESTAMP()', '2012-12-12']
          'f.created_at' => { '>' => 'b.created_at' },
      },
  };
  # $stmt: LEFT JOIN `bar` `b` ON (`f`.`id` = `b.id`)

=item %s

This format is set clause.

  ($stmt, @bind) = sqlf '%s', { bar => 'baz' };
  # $stmt: `bar` = ?
  # @bind: ('baz')

  ($stmt, @bind) = sqlf '%s', { bar => 'baz', 'hoge' => \'UNIX_TIMESTAMP()' };
  # $stmt: `bar` = ?, `hoge` = UNIX_TIMESTAMP()
  # @bind: ('baz')

  ($stmt, @bind) = sqlf '%s', {
      bar  => 'baz',
      hoge => \['CONCAT(?, ?)', 'ya', 'ppo'],
  };
  # $stmt: `bar` = ?, `hoge` = CONCAT(?, ?)
  # @bind: ('baz', 'ya', 'ppo')

=back

For more examples, see also L<< SQL::Format::Spec >>.

You can change the behavior by changing the global variable.

=over

=item $SQL::Format::QUOTE_CHAR : Str

This is a quote character for table or column name.

Default value is C<< "`" >>.

=item $SQL::Format::NAME_SEP : Str

This is a separate character for table or column name.

Default value is C<< "." >>.

=item $SQL::Format::DELIMITER Str

This is a delimiter for between columns.

Default value is C<< ", " >>.

=item $SQL::Format::LIMIT_DIALECT : Str

This is a types for dialects of limit-offset.

You can choose are:

  LimitOffset  # LIMIT 100 OFFSET 20  (SQLite / PostgreSQL / MySQL)
  LimitXY      # LIMIT 20, 100        (MySQL / SQLite)
  LimitYX      # LIMIT 100, 20        (other)

Default value is C<< LimitOffset" >>.

=back

=head1 METHODS

=head2 new([%options])

Create a new instance of C<< SQL::Format >>.

  my $sqlf = SQL::Format->new(
      quote_char    => '',
      limit_dialect => 'LimitXY',
  );

C<< %options >> specify are:

=over

=item quote_char : Str

Default value is C<< $SQL::Format::QUOTE_CHAR >>.

=item name_sep : Str

This is a separate character for table or column name.

Default value is C<< $SQL::Format::NAME_SEP >>.

=item delimiter: Str

This is a delimiter for between columns.

Default value is C<< $SQL::Format::DELIMITER >>.

=item limit_dialect : Str

This is a types for dialects of limit-offset.

Default value is C<< $SQL::Format::LIMIT_DIALECT >>.

=back

=head2 format($format, \%args)

This method same as C<< sqlf >> function.

  my ($stmt, @bind) = $self->format('SELECT %c FROM %t WHERE %w',
      [qw/bar baz/],
      'foo',
      { hoge => 'fuga' },
  );
  # $stmt: SELECT `bar`, `baz` FROM ` foo` WHERE (`hoge` = ?)
  # @bind: ('fuga')

=head2 select($table|\@table, $column|\@columns [, \%where, \%opts ])

This method returns SQL string and bind parameters for C<< SELECT >> statement.

  my ($stmt, @bind) = $sqlf->select(foo => [qw/bar baz/], {
      hoge => 'fuga',
      piyo => [100, 200, 300],
  });
  # $stmt: SELECT `foo` FROM `bar`, `baz` WHERE (`hoge` = ?) AND (`piyo` IN (?, ?, ?))
  # @bind: ('fuga', 100, 200, 300)

Argument details are:

=over

=item $table | \@table

Same as C<< %t >> format.

=item $column | \@columns

Same as C<< %c >> format.

=item \%where

Same as C<< %w >> format.

=item \%opts

=over

=item $opts->{prefix}

This is prefix for SELECT statement.

  my ($stmt, @bind) = $sqlf->select(foo => '*', { bar => 'baz' }, { prefix => 'SELECT SQL_CALC_FOUND_ROWS' });
  # $stmt: SELECT SQL_CALC_FOUND_ROWS * FROM `foo` WHERE (`bar` = ?)
  # @bind: ('baz')

Default value is C<< SELECT >>.

=item $opts->{suffix}

Additional value for after the SELECT statement.

  my ($stmt, @bind) = $sqlf->select(foo => '*', { bar => 'baz' }, { suffix => 'FOR UPDATE' });
  # $stmt: SELECT * FROM `foo` WHERE (bar = ?) FOR UPDATE
  # @bind: ('baz')

Default value is C<< '' >>

=item $opts->{limit}

=item $opts->{offset}

=item $opts->{order_by}

=item $opts->{group_by}

=item $opts->{having}

=item $opts->{join}

See also C<< %o >> format.

=back

=back

=head2 insert($table, \%values|\@values [, \%opts ])

This method returns SQL string and bind parameters for C<< INSERT >> statement.

  my ($stmt, @bind) = $sqlf->insert(foo => { bar => 'baz', hoge => 'fuga' });
  # $stmt: INSERT INTO `foo` (`bar`, `hoge`) VALUES (?, ?)
  # @bind: ('baz', 'fuga')

  my ($stmt, @bind) = $sqlf->insert(foo => [
      hoge => \'NOW()',
      fuga => \['UNIX_TIMESTAMP()', '2012-12-12 12:12:12'],
  ]);
  # $stmt: INSERT INTO `foo` (`hoge`, `fuga`) VALUES (NOW(), UNIX_TIMESTAMP(?))
  # @bind: ('2012-12-12 12:12:12')

Argument details are:

=over

=item $table

This is a table name for target of INSERT.

=item \%values | \@values

This is a VALUES clause INSERT statement.

Currently supported types are:

  # \%values case
  { foo => 'bar' }
  { foo => \'NOW()' }
  { foo => \['UNIX_TIMESTAMP()', '2012-12-12 12:12:12'] }

  # \@values case
  [ foo => 'bar' ]
  [ foo => \'NOW()' ]
  [ foo => \['UNIX_TIMESTAMP()', '2012-12-12 12:12:12'] ]

=item \%opts

=over

=item $opts->{prefix}

This is a prefix for INSERT statement.

  my ($stmt, @bind) = $sqlf->insert(foo => { bar => baz }, { prefix => 'INSERT IGNORE' });
  # $stmt: INSERT IGNORE INTO `foo` (`bar`) VALUES (?)
  # @bind: ('baz')

Default value is C<< INSERT >>.

=back

=back

=head2 update($table, \%set|\@set [, \%where, \%opts ])

This method returns SQL string and bind parameters for C<< UPDATE >> statement.

  my ($stmt, @bind) = $sqlf->update(foo => { bar => 'baz' }, { hoge => 'fuga' });
  # $stmt: UPDATE `foo` SET `bar` = ? WHERE (`hoge` = ?)
  # @bind: ('baz', 'fuga')

Argument details are:

=over

=item $table

This is a table name for target of UPDATE.

=item \%set | \@set

This is a SET clause for INSERT statement.

Currently supported types are:

  # \%values case
  { foo => 'bar' }
  { foo => \'NOW()' }
  { foo => \['UNIX_TIMESTAMP()', '2012-12-12 12:12:12'] }

  # \@values case
  [ foo => 'bar' ]
  [ foo => \'NOW()' ]
  [ foo => \['UNIX_TIMESTAMP()', '2012-12-12 12:12:12'] ]

=item \%where

Same as C<< %w >> format.

=item \%opts

=over

=item $opts->{prefix}

This is a prefix for UPDATE statement.

  my ($stmt, @bind) = $sqlf->update(
      'foo'                                # table
      { bar    => 'baz' },                 # sets
      { hoge   => 'fuga' },                # where
      { prefix => 'UPDATE LOW_PRIORITY' }, # opts
  );
  # $stmt: UPDATE LOW_PRIORITY `foo` SET `bar` = ? WHERE (`hoge` = ?)
  # @bind: ('baz', 'fuga')

Default value is C<< UPDATE >>.

=item $opts->{order_by}

=item $opts->{limit}

See also C<< %o >> format.

=back

=back

=head2 delete($table [, \%where, \%opts ])

This method returns SQL string and bind parameters for C<< DELETE >> statement.

  my ($stmt, @bind) = $sqlf->delete(foo => { bar => 'baz' });
  # $stmt: DELETE FROM `foo` WHERE (`bar = ?)
  # @bind: ('baz')

Argument details are:

=over

=item $table

This is a table name for target of DELETE.

=item \%where

Same as C<< %w >> format.

=item \%opts

=over

=item $opts->{prefix}

This is a prefix for DELETE statement.

  my ($stmt, @bind) = $sqlf->delete(foo => { bar => 'baz' }, { prefix => 'DELETE LOW_PRIORITY' });
  # $stmt: DELETE LOW_PRIORITY FROM `foo` WHERE (`bar` = ?)
  # @bind: ('baz')

Default value is C<< DELETE >>.

=item $opts->{order_by}

=item $opts->{limit}

See also C<< %o >> format.

=back

=back

=head2 insert_multi($table, \@cols, \@values [, \%opts])

This method returns SQL string and bind parameters for bulk insert.

  my ($stmt, @bind) = $self->insert_multi(
      foo => [qw/bar baz/],
      [
          [qw/hoge fuga/],
          [qw/fizz buzz/],
      ],
  );
  # $stmt: INSERT INTO `foo` (`bar`, `baz`) VALUES (?, ?), (?, ?)
  # @bind: (qw/hoge fuga fizz buzz/)

Argument details are:

=over

=item $table

This is a table name for target of INSERT.

=item \@cols

This is a columns for target of INSERT.

=item \@values

This is a values parameters. Must be ARRAY within ARRAY.

  my ($stmt, @bind) = $sqlf->insert_multi(
      foo => [qw/bar baz/], [
          [qw/foo bar/],
          [\'NOW()', \['UNIX_TIMESTAMP(?)', '2012-12-12 12:12:12'] ],
      ],
  );
  # $stmt: INSERT INTO `foo` (`bar`, `baz`) VALUES (?, ?), (NOW(), UNIX_TIMESTAMP(?))
  # @bind: (qw/foo bar/, '2012-12-12 12:12:12')

=item \%opts

=over

=item $opts->{prefix}

This is a prefix for INSERT statement.

  my ($stmt, @bind) = $sqlf->insert_multi(..., { prefix => 'INSERT IGNORE INTO' });
  # $stmt: INSERT IGNORE INTO ...

Default value is C<< INSERT INTO >>.

=item $opts->{update}

Some as C<< %s >> format.

If this value specified then add C<< ON DUPLICATE KEY UPDATE >> statement.

  my ($stmt, @bind) = $sqlf->insert_multi(
      foo => [qw/bar baz/],
      [
          [qw/hoge fuga/],
          [qw/fizz buzz/],
      ],
      { update => { bar => 'piyo' } },
  );
  # $stmt: INSERT INTO `foo` (`bar`, `baz`) VALUES (?, ?), (?, ?) ON DUPLICATE KEY UPDATE `bar` = ?
  # @bind: (qw/hoge fuga fizz buzz piyo/)

=back

=back

=head2 insert_multi_from_hash($table, \@values [, \%opts])

This method is a wrapper for C<< insert_multi() >>.

Argument dialects are:

=over

=item $table

Same as C<< insert_multi() >>

=item \@values

This is a values parameters. Must be HASH within ARRAY.

  my ($stmt, @bind) = $sqlf->insert_multi_from_hash(foo => [
      { bar => 'hoge', baz => 'fuga' },
      { bar => 'fizz', baz => 'buzz' },
  ]);
  # $stmt: INSERT INTO `foo` (`bar`, `baz`) VALUES (?, ?), (?, ?)
  # @bind: (qw/hoge fuga fizz buzz/)

=item \%opts

Same as C<< insert_multi() >>

=back

=head2 insert_on_duplicate($table, \%values|\@values, \%update_values|\@update_values [, \%opts])

This method generate "INSERT INTO ... ON DUPLICATE KEY UPDATE" query for MySQL.

  my ($stmt, @bind) = $sqlf->insert_on_duplicate(
      foo => {
          bar => 'hoge',
          baz => 'fuga',
      }, {
          bar => \'VALUES(bar)',
          baz => 'piyo',
      },
  );
  # $stmt: INSERT INTO `foo` (`bar`, `baz`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `bar` = VALUES(bar), baz = 'piyo'
  # @bind: (qw/hoge fuga piyo/)

Argument details are:

=over

=item $table

This is a table name for target of INSERT.

=item \%values|\@values

This is a values parameters.

=item \%update_values|\@update_values

This is a ON DUPLICATE KEY UPDATE parameters.

=item \%opts

=over

=item $opts->{prefix}

This is a prefix for INSERT statement.

  my ($stmt, @bind) = $sqlf->insert_on_duplicate(..., { prefix => 'INSERT IGNORE INTO' });
  # $stmt: INSERT IGNORE INTO ...

=back

=back

=head1 AUTHOR

xaicron E<lt>xaicron {at} cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2012 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<< SQL::Format::Spec >>

L<< SQL::Maker >>

L<< SQL::Abstract >>

=cut
