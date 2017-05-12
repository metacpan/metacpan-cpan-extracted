=encoding utf8

=head1 NAME

SQL::Steno - Short hand for SQL and compact output

=head1 SYNOPSIS

Type some short-hand, see the corresponding SQL and its output:

 steno> TABLE1;somecolumn > 2    -- ; after tables means where
 select * from TABLE1 where somecolumn > 2;
 prepare: 0.000s   execute: 0.073s   rows: 14
   id|column1                                    |column2
     |                                           |    |column3
     |                                           |    | |somecolumn
 ----|-------------------------------------------|----|-|-|
   27|foo                                        |    |a|7|
   49|bar                                        |abcd|a|3|
   81|baz\nbazinga\nbazurka                      |jk  |b|9|
 1984|bla bla bla bla bla bla bla bla bla bla bla|xyz |c|5|
 ...
 steno> /abc|foo/#TBL1;.socol > 2    -- /regexp/ grep, #tableabbrev, .columnabbrev
 select * from TABLE1 where somecolumn > 2;
 prepare: 0.000s   execute: 0.039s   rows: 14
 id|column1
   |   |column2
   |   |    |[column3=a]
   |   |    |somecolumn
 --|---|----|-|
 27|foo|    |7|
 49|bar|abcd|3|
 steno> .c1,.c2,.some;#TE1#:ob2d3    -- ; before tables means from, 2nd # alias, :macro
 select column1,column2,somecolumn from TABLE1 TE1 order by 2 desc, 3;
 ...
 steno> n(), yr(), cw(,1,2,3)    -- functionabbrev before (, can have initial default arg
 select count(*), year(now()), concat_ws(',',1,2,3);
 ...
 steno> .col1,.clm2,.sn;#TBL1:jTBL2 u(id);mydate :b :m+3d and :d-w    -- :jTABLEABBREV and :+/- family
 select column1,column2,somecolumn from TABLE1 join TABLE2 using(id) where mydate
 between date_format(now(),"%Y-%m-01")+interval 3 day and curdate()-interval 1 week;
 ...

=head1 DESCRIPTION

You're the command-line type, but are tired of typing C<select * from TABLE
where CONDITION>, always forgetting the final C<;>?  Output always seems far
too wide and at least mysql cli messes up the format when it includes
newlines?

This module consists of the function C<convert> which implements a
configurable ultra-compact language that maps to SQL.  Then there is C<run>
which performs normal SQL queries but has various tricks for narrowing the
output.  It can also grep on whole rows, rather than having to list all fields
that you expect to match.  They get combined by the function C<shell> which
converts and runs in an endless loop.

This is work in progress, only recently isolated from a monolithic script.
Language elements and API may change as the need arises, e.g. C<:macro> used
to be C<@macro>, till the day I wanted to use an SQL-variable and noticed the
collision.  In this early stage, you are more than welcome to propose
ammendments, especially if they make the language more powerful and/or more
consistent.  Defaults are for MariaDB/MySQL, though the mechanism also works
with other DBs.

=cut

use v5.14;

package SQL::Steno v0.3.2;

use utf8;
use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);

binmode $_, ':utf8' for *STDIN, *STDOUT, *STDERR;

our $dbh;
our $perl_re = qr/(\{(?:(?>[^{}]+)|(?-1))*\})/;
our( %Table_Columns, $table_re );
sub init {
    die "\$dbh is undef\n" unless $dbh;
    local @{$dbh}{qw(PrintWarn PrintError RaiseError)} = (0, 0, 0); # \todo is this right? views can barf because more restrictive.
    for my $table ( @{$dbh->table_info->fetchall_arrayref} ) {
	$Table_Columns{uc $table->[2]} = [];
	splice @$table, 3, -1, '%';
	my $info = $dbh->column_info( @$table ) or next;
	for my $column ( @{$info->fetchall_arrayref} ) {
	    push @{$Table_Columns{$table->[2]}}, uc $column->[3];
	}
    }
    undef $table_re;		# (re)create below
}
our $init_from_query = <<\SQL;
	select ucase(TABLE_NAME), ucase(COLUMN_NAME)
	from information_schema.COLUMNS
	where TABLE_SCHEMA = schema()
SQL
sub init_from_query {
    die "\$dbh is undef\n" unless $dbh;
    local @{$dbh}{qw(PrintWarn PrintError RaiseError)} = (0, 0, 0); # \todo is this right?
    my $sth = $dbh->prepare( $init_from_query );
    $sth->execute;
    $sth->bind_columns( \my( $table, $column ));
    push @{$Table_Columns{$table}}, $column while $sth->fetch;
    undef $table_re;		# (re)create below
}



my %render =
    (csv => \&render_csv,
     table => \&render_table,
     yaml => \&render_yaml,
     yml => \&render_yaml);
my( $render, %opt );

sub set_render($@) {
    ($render, %opt) = ();
    for( @_ ) {
	if( defined $render ) {	# all further args are opts
	    tr/ \t//d;
	    undef $opt{$_};	# make it exist
	} else {
	    $render = substr $_, 1;
	}
    }
    $render = $render{$render};
    '';				# For use as a query
}



our( %Queries_help, %Queries );
sub Query {
    $Queries_help{$_[0]} = $_[1];
    $Queries{$_[0]} = $_[2];
    undef;
}
Query ".$_", "   output '&.$_() this' or next query as \U$_", \&set_render
    for keys %render;

Query 'c'.substr( $_, 0, 1 ), "$_   show create (&- or similar for full display)",
    '&{ $render ||= \&render__create; "" }=show create '.$_.' $1'
    for qw(table function procedure view);

Query @$_
    for
    ['-' => "   output next query as YAML",
      '&.yaml'],


    [ps => '   show processlist (without Sleep)',
      '{(${_}[7] // "") ne "Sleep"}=show processlist'],

    [psf => '   show full processlist (without Sleep)',
      '{(${_}[7] // "") ne "Sleep"}=show full processlist'],


    [t => 'unquotedtablename[,unquotedcolumnpattern]   show fields',
      'COLUMN_NAME,COLUMN_TYPE,IS_NULLABLE NUL,COLUMN_KEY `KEY`,COLUMN_COMMENT;information_schema.`COLUMNS`;TABLE_SCHEMA=schema() and TABLE_NAME=$\1:ob ORDINAL_POSITION'],
#      'COLUMN_NAME,COLUMN_TYPE,IS_NULLABLE NUL,COLUMN_KEY `KEY`,COLUMN_COMMENT;information_schema.`COLUMNS`;TABLE_SCHEMA=schema() and TABLE_NAME=$\1$?>? and COLUMN_NAME like$\>??:ob ORDINAL_POSITION'],


    [s => 'var;value   set @var = value',
      'set @$1=$2'],

    [ss => "var;value   set \@var = 'value'",
      'set @$1=$\2'],

    [sd => 'var;value   set @var = cast("value" as date)',
      'set @$1=cast($\2 as date)'],

    [sdt => 'var;value   set @var = cast("value" as datetime)',
      'set @$1=cast($\2 as datetime)'],

    [st => 'var;value   set @var = cast("value" as time)',
      'set @$1=cast($\2 as time)'],

    [sy => '            set @a, @z   yesterday is between @a and @z  (see :baz)',
      #'set @a=date(now())-interval 1 day, @z=date(now())-interval 1 second',
     'select @a:=date(now()-interval 1 day)`@a`, @z:=date(now())-interval 1 second`@z`'];



our( %Quotes_help,  %Quotes );
sub Quote {
    $Quotes_help{$_[0]} = $_[1];
    $Quotes{$_[0]} = $_[2];
    undef;
}
Quote @$_
    for
    ['a' => 'and: unquoted joined with &&',
      '!%&&'],

    ['o' => 'or: unquoted joined with ||',
      '!%||'];


our $weekstart = 1;		# Monday is the first day of the week as per ISO 8601.
my $timespec_re = qr/[yqmwdhMs]?/;
our %Join_clause;
our %Macros =
   (
    b => ' between',
    baz => ' between @a and @z',
    d => ' distinct',
    h => ' having',
    j => ' join',
    l => ' like',
    lj => ' left join',
    n => ' is null',
    nb => ' not between',
    nc => ' sql_no_cache',
    nl => ' not like',
    nn => ' is not null',
    nr => ' not rlike',
    od => ' on duplicate key update',
    odku => ' on duplicate key update',
    r => ' rlike',
    u => ' union select',
    ua => ' union all select',
    wr => ' with rollup',
    '' => sub {
	my $join = 'for all #TBL matching TABLE';
	my $int = 'see :+  :-  :y-m  :q+0  :d+2h';
	my $gob = 'for 0 or more digits, optionally followed by a or d';
	return ([jTBL => $join], ['jTBL#' => $join], [ljTBL => $join], [1 => 'for all numbers'],
		[gb147 => $gob], [ob2d5a9 => $gob],
		['+' => <<INT], ['-' => $int], ['d+2h' => $int], ['y-m' => $int], ['q+0' => $int])
:B+/-NO this B(ase) +/- N(umber, 0 for none, default 1 if O given) O(ffset)
	 optional B, O is y(ear), q(uarter), m(onth), w(eek), d(ay), h(our), M(inute), s(econd)
INT
	    unless @_;		# help
	for( $_[0] ) {
	    return " limit $_" if /^\d+$/;
	    if( s/^([og])b(?=(?:\d[ad]?)*$)/ $1 eq 'g' ? ' group by ' : ' order by ' /e ) {
		s/(?<! )(?=\d)/, /g;
		s/a/ asc/g; s/(?<!r)d/ desc/g;
		return $_;
	    }
	    if( s/^(l?)j/#/ ) {	# (l)jtbl: j or lj with any #tbl
		my $left = $1 ? ' left' : '';
		&convert_table_column;
		/^(\w+)/;
		return "$left join $_" . ($Join_clause{$1} || $Join_clause{''} || '');
	    }
	    return $_ if
		s(^($timespec_re)([+-])(\d*)($timespec_re)$) {
		    ({ y => ' date_format(now(),"%Y-01-01")',
		       q => ' date_format(now()-interval mod(month(now())+11,3) month,"%Y-%m-01")',
		       m => ' date_format(now(),"%Y-%m-01")',
		       w => ' curdate()-interval weekday(now())' . ($weekstart ? ' day' : '+1 day'),
		       d => ' curdate()',
		       h => ' date_format(now(),"%F %H:00")',
		       M => ' date_format(now(),"%F %H:%M")',
		       s => ' now()' }->{$1} || '') .
		    ($3 ne '0' &&
		     " $2interval" .
		     ($3 ? " $3" : $4 ? ' 1' : '') .
		     ({ y => ' year',
			q => ' quarter',
			m => ' month',
			w => ' week',
			d => ' day',
			h => ' hour',
			M => ' minute',
			s => ' second' }->{$4} || ''))
		}eo;
	}
    });

# \todo default arg n() -> n(*) time*(now())
our %Functions =
   (
    c => 'concat',
    cw => 'concat_ws',
    coa => 'coalesce',
    gc => 'group_concat',
    i => 'in',			# not really fn, but ( follows
    in => 'ifnull',
    l => 'char_length',
    lc => 'lcase',
    m => 'min',
    M => 'max',
    n => 'count',
    ni => 'not in',		# -"-
    s => 'substring',
    u => 'using',		# -"-
    uc => 'ucase'
   );

# functions where the 1st argument can be now()
my @nowFunctions = qw(
    adddate addtime convert_tz date date_add date_format date_sub datediff day
    dayname dayofmonth dayofweek dayofyear hour last_day minute month
    monthname quarter second subdate subtime time time_format time_to_sec
    timediff timestamp to_days to_seconds week weekday weekofyear year
    yearweek
);
our @Functions = sort @nowFunctions, qw(
    abs acos aes_decrypt aes_encrypt ascii asin atan avg benchmark bin bit_and
    bit_count bit_length bit_or bit_xor cast ceiling char_length char
    character_length charset coalesce coercibility collation compress
    concat_ws concat connection_id conv cos cot count crc32 curdate
    current_date current_time current_timestamp current_user curtime database
    decode default degrees des_decrypt des_encrypt elt encode encrypt exp
    export_set field find_in_set floor format found_rows from_days
    from_unixtime get_format get_lock greatest group_concat hex if ifnull
    inet_aton inet_ntoa insert instr interval is_free_lock is_used_lock isnull
    last_insert_id lcase least left length ln load_file localtime
    localtimestamp locate log10 log2 log lower lpad ltrim make_set makedate
    maketime master_pos_wait max md5 microsecond mid min mod name_const now
    nullif oct octet_length old_password ord password period_add period_diff
    pi position power quote radians rand release_lock repeat replace reverse
    right round row_count rpad rtrim schema sec_to_time session_user sha1 sign
    sin sleep soundex space sqrt stddev stddev_pop stddev_samp str_to_date
    strcmp substring_index substring sum sysdate system_user tan timestampadd
    timestampdiff trim truncate ucase uncompress uncompressed_length unhex
    unix_timestamp upper user utc_date utc_time utc_timestamp uuid values
    var_pop var_samp variance
);

our %DefaultArguments = (
    count => '*',
    concat_ws => "','"
);
$DefaultArguments{$_} = 'now()' for @nowFunctions;


our %Tables;
our %Columns;

sub regexp($$) {
    my( $str, $type ) = @_;
    if( $type < 2 ) {
	return if $str !~ /_/; # Otherwise same as find sprintf cases
	return ($type ? '' : '^') . join '.*?_', split /_/, $str; # 0 & 1
    }
    my $expr = join '.*?', split //, $str; # 2, 3 & 4
    if( $type < 4 ) {
	substr $expr, 0, 0, '^'; # 2 & 3
	$expr .= '$' if $type == 2; # 2
    }
    $expr;
}

my $error;
my @simple = qw(^%s$ ^%s_ ^%s _%s$ _%s %s$ %s_ %s);
sub find($$$\%;\@) {
    my( $str, $prefix, $suffix, $hash, $list ) = @_;
    my $ret = $hash->{$str};
    return $ret if $ret;

    $ret = $hash->{''};
    $ret = &$ret( $str ) if $ret;
    return $ret if $ret;

    if( $list ) {
	for my $type ( 0..@simple+4 ) { # Try to find a more and more fuzzy match.
	    my $expr = $type < @simple ?
		sprintf $simple[$type], $str :
		regexp $str, $type - @simple;
	    next unless defined $expr;
	    my @res = grep /$expr/i, @$list;
	    if( @res ) {
		return $res[0] if @res == 1;
		warn "$prefix$str$suffix matches @res\n";
		$error = 1;
		return '';
	    }
	}
    }
    # no special syntax for fields or functions, so don't fail on real one
    return $str if ord $prefix == ord '.' or ord $suffix == ord '(';

    warn "$prefix$str$suffix doesn't match\n";
    $error = 1;
}

my %rq = ('[', ']',
	  '{', '}');
my $quote_re = qr(\\([^\W\d_]*)([-,:;./ #?ω^\\\@!'"`[\]{}]*)(?:%(.+?))?); # $1: name, $2: spec, $3: join
sub quote($$$$) {
    local $_ = $_[1];
    my( $named, undef, $join, @args ) = @_;
    while( $named ) {
	my $quotes = $Quotes{$named};
	if( !defined $quotes or "\\$quotes" !~ /^$quote_re$/o ) {
	    warn $quotes ? "\\$named is bad '$quotes' in \%Quotes\n" : "\\$named not found in \%Quotes\n";
	    $error = 1;
	    return '';
	}
	$named = $1;
	substr $_, 0, 0, $2;
	$join //= $3;
    }
    $join //= ',';
    my $list = ref $args[0];
    @args = @{$args[0]} if $list;
    return join $join, @args unless defined;
    /(['"`[{])/;
    my( $lq ) = /(['"`[{])/;
    $lq ||= "'";
    my $rq = $rq{$lq} || $lq;
    my( $noquote, $number, $boolean, $null, $space, $var ) =
	(tr/!//, tr/#//, tr/?//, tr/ω^//, tr/\\//, tr/@//);
    my $split = tr/-// ? '-' : ''; # avoid range by putting - 1st
    $split .= tr/ // ? '\s' : '';  # space means any whitespace
    $split .= join '', /([,:;.\/])/g;
    $split ||= ',' unless $list;
    $split &&= $space ? qr/[$split]/ : qr/\s*[$split]\s*/;
    join $join, map {
	if( $noquote || $boolean && /^(?:true|false)$/i || $null && /^null$/i || $var && /^\@\w+$/ ) {
	    $_;
	} elsif( $number && /^[-+]?(?:0b[01]+|0x[\da-f]+|(?=\.?\d)\d*\.?\d*(?:e[-+]?\d+)?)$/i ) {
	    $_;
	} else {
	    s/$rq/$rq$rq/g;
	    "$lq$_$rq";
	}
    } map {
	unless( $space ) {
	    s/\A\s*//;
	    s/\s*\Z//;
	}
	$split ? split $split, $_, -1 : $_;
    } @args;
}

sub convert_Query($$) {
    my $name = $_[0];
    my $res = find $name, '&', '', %Queries;
    my $ref = ref $res;
    my @arg;
    for( $ref ? $_[1] : "$res\cA$_[1]" ) {
	&convert_table_column;
	($res, $_) = split "\cA" unless $ref;
	@arg = split ';';
    }
    return &$res( $name, @arg ) // '' if $ref;

    my( @var, %seen, @rest );
    $res =~ s(\$$quote_re?(?:(\d+\b)|([*>_]))) { # $4: numbered arg, $5: special arg
	if( $4 && $4 > @arg ) {
	    '';
	} else {
	    push @var, [$1, $2, $3, $5 ? (undef, $5) : $4-1];
	    undef $seen{$4-1} if $4;	# make it exist
	    "\cV$#var\cZ";
	}
    }eg;
    if( @arg > keys %seen ) {
	@rest = @arg;
	undef $rest[$_] for keys %seen;
	@rest = grep defined(), @rest;
    }
    $res =~ s(\cV(\d+)\cZ) {
	my @res = @{$var[$1]};
	quote $res[0], $res[1], $res[2],
	    $res[4] ? ($res[4] eq '*' ? \@arg :
		       $res[4] eq '>' ? \@rest :
		       $_) :
	    $res[3] < 0 ? $name : $arg[$res[3]];
    }eg;
    $res;
}

my @keys_Table_Columns;
sub convert_table_column {
    @keys_Table_Columns = keys %Table_Columns unless @keys_Table_Columns;
    s&(?<!\\)#(\w+)(?:#(\w*))?&find( $1, '#', '', %Tables, @keys_Table_Columns ) . ($2 ? " $2" : defined $2 ? " $1" : '')&eg unless $error;

    unless( $table_re ) {
	$table_re = join '|', keys %Table_Columns;
	$table_re = $table_re ? qr/\b(?:$table_re)\b/ : qr/\s\b\s/;
    }
    unless( $error ) {
	my %column;
	for( grep /$table_re/io, split /\W+/ ) {
	    undef $column{$_} for @{$Table_Columns{$_}};
	}
	my @column = keys %column;
	s/(^|.&|[-+\s(,;|])?(?<!\\)\.([a-z]\w*)(?:\.(\w*))?/(defined $1 ? $1 : '.') . (find $2, '.', '', %Columns, @column) . ($3 ? " $3" : defined $3 ? " $2" : '')/egi;
    }
}


=head2 convert

This function takes a short-hand query in C<$_> and transforms it to SQL.  See
L</shell> for more run time oriented features.

=head3 C<:\I<namespec>(I<strings>)> E<nbsp> or E<nbsp> C<:\I<namespec>%I<join>(I<strings>)>

This is a special macro that transforms odd lists to SQL syntax.  It takes a
list of unquoted strings and quotes each one of them in various ways.  The
syntax is inspired by the Shell single character quote and Perl's C<\(...)>
syntax.  The I<namespec> is a combination of an optional I<name> (set up with the
Perl function C<Quote>), followed by an optional I<spec> that extends the named
spec.  The I<strings> can get split on a variety of one or even simultaneously
various characters, which you can give in any order in the I<spec>:

=over

=item C<\> (backslash)

This one isn't a character to split on, but rather prevents trimming the
whitespace of both ends of the resulting strings.

=item C<,> (comma), the default

You only need to specify it, if you want to split on commas, as well as other
characters, at the same time.  Where the C<\> (backslash) syntax is also used,
when given a list, there is no default splitting of list members:
L<C<:\{I<Perl
code>}>|/Perl-code-or-:-namespec-Perl-code-or-:-namespec-join-Perl-code> and
L<canned query's|/query-arg-...-or-query-arg-...-following-text> C<$\*> &
C<$\E<gt>>.  In that case you must specify it, if needed, e.g. C<$\,*>.

=item C<E<nbsp>> (space)

This one stands for any single whitespace.  Since strings are normally
trimmed, it's the equivalent of what the Shell does.  But, if you combine it
with C<\>, which prevents trimming, you will get an empty string between each
of multiple whitespaces.

=item C<-> (minus)

=item C<:> (colon)

=item C<;> (semicolon)

=item C<.> (period)

=item C</> (slash)

=back

The I<spec> can also contain several of these characters to prevent certain
strings from being quoted:

=over

=item C<#> (hash)

All numbers, including signed, floats, binary and hexadecimal stay literal.
If you use C<-> as a separator, there can be no negative numbers.

=item C<?> (question mark)

The boolean values C<true> and C<false> stay literal.

=item C<ω> (omega) E<nbsp> or E<nbsp> C<^> (caret)

The value C<null> stays literal.  Note that C<ω> is also a word character,
that would be part of a name at the beginning of I<namespec>.  It is only the
C<null>-symbol following some non-word character, e.g. C<,> (comma).

=item C<@> (at sign)

Variables C<@name> stay literal.

=item C<!> (exclamation mark)

Everything, presumed valid sql syntax, stays literal.

=back

And you can give at most one I<spec> for the quotes to use:

=over

=item C<'> (quote), the default

=item C<"> (double quote)

=item C<`> (backquote)

=item C<[]> (brackets)

=item C<{}> (braces)

In the latter two cases, the closing quotes are optional, for decoration only,
or if code completion adds them.

=back

The results are joined by comma, unless I<join> is given.  E.g. C<:\(a,b,
c,NULL,true,-1.2)> gives C<'a','b','c','NULL','true','-1.2'>, while
C<:\:"/\#?0(a:b/ c:NULL:true/-1.2)> gives C<"a","b"," c",NULL,true,-1.2> and
C<:\ !%&&(a b E<nbsp>c)> gives C<a&&b&&c>.



=head3 C<:I<macro>>

These are mostly simple text-replacements stored in C<%Macros>.  Unlike
L<C<:\>|/namespec-strings-or-:-namespec-join-strings> these do not take arguments.
There are also some dynamic macros.  Those starting with C<:j> (join) or
C<:lj> (left join) may continue into a L<table spec|/tbl-or-tbl-or-tbl-alias>
without the leading C<#>.  E.g. C<:ljtbl#t> might expand to C<left join table
t>.

Those starting with C<:gb> (group by) or C<:ob> (order by) may be followed by
result columns numbers from 1-9, each optionally followed by a or d for asc or
desc.  E.g. C<:ob2d3> gives C<order by 2 desc, 3>.

=head3 C<:+I<interval>> E<nbsp> or E<nbsp> C<:I<time>+I<interval>> E<nbsp> or E<nbsp> C<:-I<interval>> E<nbsp> or E<nbsp> C<:I<time>-I<interval>>

These are time calculation macros, where an optional leading letter indicates
a base time, and an optional trailing letter with an optional count means the
offset.  The letters are:

=over

=item y

(this) year(start).  E.g. C<:y+2m> is march this year.

=item q

(this) quarter(start).  E.g. C<:q+0> is this quarter, C<:q+q> is next quarter.

=item m

(this) month(start).  E.g. C<:-3m> is whatever precedes, minus 3 months.

=item w

(this) week(start).  E.g. C<:w+3d> is this week thursday (or wednesday if you
set C<$weekstart> to not follow ISO 8601 and the bible).

=item d

(this) day(start).  E.g. C<:d-w> is midnight one week ago.

=item h

(this) hour(start).  E.g. C<:h+30M> is half past current hour.

=item M

(this) minute(start).  E.g. C<:+10M> is whatever precedes, plus 10min.

=item s

(this) second.  E.g. C<:s-2h> is exactly 2h ago.

=back


=head3 C<:{I<Perl code>}> E<nbsp> or E<nbsp> C<:\I<namespec>{I<Perl code>}> E<nbsp> or E<nbsp> C<:\I<namespec>%I<join>{I<Perl code>}>

This gets replaced by what it returns in list context.  Undefined elements get
rendered as C<NULL> and they all get joined by I<join> or else C<,> (comma).
They can become quoted like
L<C<:\>|/namespec-strings-or-:-namespec-join-strings>.  Since the result is
already a list, the elements don't get split by default.  If you want that,
you must specify it as in C<:\,{I<Perl code>}>.


=head3 C<#I<tbl>> E<nbsp> or E<nbsp> C<#I<tbl>#> E<nbsp> or E<nbsp> C<#I<tbl>#I<alias>>

Here I<tbl> is a key of C<%Tables> or any abbreviation of known tables in
C<@Tables>.  If followed by C<#>, the abbreviation is used as an alias, unless
an I<alias> directly follows, in which case that is used.


=head3 C<.I<col>> E<nbsp> or E<nbsp> C<.I<col>.> E<nbsp> or E<nbsp> C<.I<col>.I<alias>>

Here I<col> is a key of C<%Columns> or any abbreviation of columns of any table
recognized in the query.  If followed by C<.>, the abbreviation is used as an
alias, unless an I<alias> directly follows, in which case that is used.  It tries
to be clever about whether the 1st C<.> needs to be preserved, i.e. following
a table name.

=head3 C<I<func>(> E<nbsp> or E<nbsp> C<I<func>\I<namespec>(I<strings>)> E<nbsp>
or E<nbsp> C<I<func>\I<namespec>%I<join>(I<strings>)>

Here I<func> is a key of C<%Functions> or any
abbreviation of known functions in C<@Functions>, which includes words
typically followed by an opening parenthesis, such as C<u(> for C<using(>.
C<i(> becomes C<in(>, whereas C<in(> becomes C<ifnull(>.

If the 2nd or 3rd form is used, the I<strings> inside of the parentheses are treated
just like C<L<:\I<namespec>(I<strings>)|/namespec-strings-or-:-namespec-join-strings>>,
but in this case preserving the parentheses.

If the 1st argument of a function is empty and the abbrev or function is found
in C<%DefaultArguments> the value becomes the 1st argument.
E.g. C<cw(,'a','b','c')> or C<cw(,:\(a,b,c))> both become
C<concat_ws(',','a','b','c')>.

=head3 Abbreviated Keyword

Finally it picks on the structure of the statement: These keywords can be
abbreviated: C<se(lect)>, C<ins(ert)>, C<upd(ate)> or C<del(ete)>.  If none of
these or C<set> is present, C<select> is assumed as default (more keywords
need to be recognized in the future).

For C<select>, semicolons are alternately replaced by C<from> (the 1st being
optional if it starts with a table name) and C<where>.  If no result columns
are given, they default to C<*>, see L</SYNOPSIS>.  For C<update>, semicolons
are frst replaced by C<set> and then C<where>.

=cut

sub convert {
    my @strings;		# extract strings to prevent following replacements inside.
    until( $error ) {
	# Handle :\...{perl}
	next if
	    s(:$quote_re?$perl_re){
		my @ret = map $_ // 'NULL', eval substr $4, 1, -1; # strip {}
		$error = 1, warn $@ if $@;
		quote $1, $2, $3, \@ret;
	    }ego

	# Handle function\...(str1, str2, str3) and :\...(str1, str2, str3)
	or
	    s<(?:\b(\w+)|:)$quote_re\((.+?)\)> {
		($1 ? "$1(" : '') .
		quote( $2, $3, $4, $5 ) .
		($1 ? ')' : '')
	    }ge;

	# extract quoted strings
	while( /\G.*?(['"`[{])/gc ) {
	    my $rq = $rq{$1}||$1;
	    my $pos = pos;
	    while( /\G.*?([$rq\\])/gc ) {
		if( $1 eq '\\' ) {
		    ++pos;		# skip next
		} elsif( ! /\G$rq/gc ) { # skip doubled quote
		    push @strings,
			substr $_, $pos - 1, 1 - $pos + pos, # get string
			"\cS".@strings."\cZ"; # and replace with counter
		    last;
		}
	    }
	}

	# \todo (?(?<=\w)\b)
	next if
	    s&:($timespec_re[+-]\d*$timespec_re(?(?<=\w)\b)|l?j\w+(?:#(\w*))|\w+)&find $1, ':', '', %Macros&ego;
	last;
    }

    my $was_column = /^\./ or	# Avoid next assumption when 1st column name is also a table name.
	s&^(?=#)&;&;		# Assume empty fieldlist before table name
    &convert_table_column;
    s&^(?=$table_re)&;& unless $was_column; # Assume empty fieldlist before table name

    s&\b(\w+)\((?=\s*([,)])?)&my $fn = find $1, '', '(', %Functions, @Functions; ($fn || $1).'('.($2 and $DefaultArguments{$1} || $DefaultArguments{$fn} or '')&eg unless $error;
    #s&\b(\w+)(?=\()&find $1, '', '(', %Functions, @Functions or $1&eg unless $error;

    return if $error;
    s/\A\s*;/*;/;
    s/;\s*\Z//;
    if( s/^upd(?:a(?:t(?:e)?)?)?\b/update/i ) {
	s/(?<!\\);(?:\s*set\s*)?/ set / && s/(?<!\\);(?:\s*where\s*)?/ where /;
    } else {
	s/(?<!\\);(?:\s*where\s*)?/ where / while s/(?<!\\);(?:\s*from\s*)?/ from /;
	s/^ins(?:e(?:r(?:t)?)?)?\b/insert/i ||
	    s/^del(?:e(?:t(?:e)?)?)?\b/delete/i ||
	    s/^(?!se(?:lec)?t)/select /i;
    }

    s/ $//mg;
    s/ {2,}/ /g;
    s/\cS(\d+)\cZ/$strings[$1]/g; # put back the strings

    1;
}


# escape map for special replacement characters
my %esc = map { $_ eq 'v' ? "\013" : eval( qq!"\\$_"! ), "\\$_" } qw'0 a b e f n r t v \ "';

# With an argument of total number of rows, init output counting and return undef if it is to be skipped (not stdout).
# Without an argument, do the counting and return undef if no more rows wanted.
{
    my( $total, $cnt, $i );
    sub count(;$) {
	if( @_ ) {
	    $total = $_[0];
	    $cnt = 0;
	    $i = 100;
	    return select eq 'main::STDOUT' ? 1 : undef;
	}
	++$cnt;
	if( --$i <= 0 && $cnt < $total ) {
	    printf STDERR "How many more, * for all, or q to quit? (%d of %d) [default: 100] ",
		$cnt, $total;
	    $i = <>;
	    if( defined $i ) {
		$i =~ tr/qQxX \t\n\r/0000/d;
		$i = (0 == length $i) ? 100 :
		    $i eq '*' ? ~0 :
			$i == 0 ? return :
			    $i;
	    } else {
		print "\n";
		return;
	    }
	}
	1;
    }
}

sub render_csv($;$$) {
    my( $sth, $filter ) = @_;
    my( $semi, $tab ) =
	(exists $_[2]{semi},
	 exists $_[2]{tab})
	if $_[2];
    my $name = $sth->{NAME};
    my @row = @$name;
    while() {
	for( @row ) {
	    if( defined ) {
		$_ = qq!"$_"! if
		    /\A\Z/ or
		    s/"/""/g or
		    $semi ? tr/;\n// : $tab ? tr/\t\n// : tr/,\n// or
		    /\A=/;
	    } else {
		$_ = '';
	    }
	    utf8::decode $_;
	}
	print join( $semi ? ';' : $tab ? "\t" : ',', @row ) . "\n";

      FETCH:
	@row = $sth->fetchrow_array
	    or last;
	$filter->( $name, @row ) or goto FETCH if $filter;
    }
}

our $NULL = 'ω';
utf8::decode $NULL;
my( $r1, $r2, $r3, $r5 ) = ('[01]\d', '[0-2]\d', '[0-3]\d', '[0-5]\d');
sub render_table($;$$) {
    my( $sth, $filter ) = @_;
    my( $null, $crlf, $date, $time ) =
	exists $_[2]{all} ?
	('NULL', 1, 1, 1) :
	(exists $_[2]{NULL} ? 'NULL' : exists $_[2]{null} ? 'null' : 0,
	 exists $_[2]{crlf},
	 exists $_[2]{date},
	 exists $_[2]{time})
	if $_[2];
    $null ||= $NULL;
    my @name = @{$sth->{NAME}};
    my @len = (0) x @name;
    my( @txt, @res, @comp );
    while( my @res1 = $sth->fetchrow_array ) {
	$filter->( \@name, @res1 ) or next if $filter;
	for my $i ( 0..$#res1 ) {
	    if( !defined $res1[$i] ) {
		$res1[$i] = $null;
	    } elsif( $res1[$i] !~ /^\d+(?:\.\d+)?$/ ) {
		$txt[$i] = 1;
		$res1[$i] =~ s/\r\n/\\R/g unless $crlf;
		$res1[$i] =~ s/([\t\n\r])/$esc{$1}/g;
		no warnings 'uninitialized';
		unless( $date ) {
		    if( $res1[$i] =~ s/^(\d{4}-)($r1)-0[01]([T ]$r2:$r5(?::$r5(?:[.,]\d{3})?)?(?:Z|[+-]$r2:$r5)?)?$/$1/o ) {
			$res1[$i] .= "$2-" if $2 > 1;
			$res1[$i] .= $3 if $3;
		    }
		}
		unless( $time ) {
		    if( $res1[$i] =~ s/^(\d{4}-(?:$r1-(?:$r3)?)?[T ])?($r2):($r5)(?::($r5)(?:([.,])(\d{3}))?)?(Z|[+-]$r2:$r5)?$/$1/o ) {
			$res1[$i] = $1 || '';
			if( $2 == 23 && $3 == 59 && ($4 // 59) == 59 && ($6 // 999) == 999 ) {
			    $res1[$i] .= "24:";
			} elsif( $6 > 0 ) {
			    $res1[$i] .= "$2:$3:$4$5$6";
			} elsif( $4 > 0 ) {
			    $res1[$i] .= "$2:$3:$4";
			} elsif( $3 > 0 ) {
			    $res1[$i] .= "$2:$3";
			} else {
			    $res1[$i] .= "$2:";
			}
			($res1[$i] .= $7) =~ s/:00$/:/
			    if $7;
		    }
		}
		utf8::decode $res1[$i];
	    }
	    $txt[$i] = 0 if @txt < $i;
	    my $len = length $res1[$i];
	    $len[$i] = $len if $len[$i] < $len;
	}
	if( @comp ) {
	    for my $i ( 0..$#comp ) {
		undef $comp[$i] if defined $comp[$i] && $comp[$i] ne $res1[$i];
	    }
	} else {
	    @comp = @res1;
	}
	push @res, \@res1;
    }
    if( @res ) {
	@comp = () if @res == 1;
	my $fmt = '';
	for( my $i = 0; $i < @name; ++$i ) {
	    $name[$i] =~ s/\r\n/\\R/g;
	    $name[$i] =~ s/([\t\n\r])/$esc{$1}/g;
	    if( defined $comp[$i] ) {
		my $more;
		while( defined $comp[$i] ) {
		    printf $fmt, @name[0..$i-1] unless $more;
		    $more = 1;
		    printf "[%s=%s]", $name[$i], $comp[$i];
		    @name[0..$i] = ('') x ($i+1);
		    for my $row ( \@comp, \@name, \@len, \@txt, @res ) {
			splice @$row, $i, 1;
		    }
		}
		print "\n";
		--$i, next;
	    }
	    if( $len[$i] < length $name[$i] ) {
		printf "$fmt%s\n", @name[0..$i];
		@name[0..$i] = ('') x ($i+1);
	    }
	    $fmt .= '%' . ($txt[$i] ? -$len[$i] : $len[$i]) . 's|';
	}
	$fmt .= "\n";
	printf $fmt, @name if $name[-1];
	printf $fmt, map '-'x$_, @len;
	my $count = count @res;		# init
	for my $row ( @res ) {
	    printf $fmt, @$row;
	    defined count or last if defined $count;
	}
    }
}

my $yaml_re = join '', sort keys %esc;
$yaml_re =~ s!\\!\\\\!;
my $tabsize = $ENV{TABSIZE} || 8;
sub render_yaml($;$$) {
    my( $sth, $filter ) = @_;
    my @label;			       # Fill on 0th round with same transformation as data (but \n inline)
    my $count = count $DBI::rows || 1; # init \todo don't know how many unfiltered
    my @row = @{$sth->{NAME}};
    while() {
	local $_;
	my $i = 0;
	for( @row ) {
	    if( !defined ) {
		$_ = '~';
	    } elsif( /^(?:y(?:es)?|no?|true|false|o(?:n|ff)|-?\.inf|\.nan)$/s ) { # can only be string in Perl or DB
		$_ = "'$_'";
	    } elsif( tr/][{},?:`'"|<>&*!%#@=~\0-\010\013-\037\177-\237-// or @label ? 0 : tr/\n// ) {
		s/([$yaml_re])/$esc{$1}/go;
		s/([\0-\010\013-\037\177-\237])/sprintf "\\x%02x", ord $1/ge;
		$_ = qq!"$_"!;
	    } elsif( tr/\n// ) {
		my $nl = chomp;
		s/^/    /mg;
		substr $_, 0, 0, $nl ? "|2\n" : "|2-\n";
	    }
	    print "$label[$i++]$_\n" if @label;
	}
	if( @label ) {
	    defined count or last if defined $count;
	} else {
	    my $maxlen = 0;
	    for( @row ) {
		substr $_, 0, 0, $maxlen ? '  ' : '- '; # 1st field if no maxlen yet
		my $length = 0;
		$length += $1 ? $tabsize - $length % $tabsize : length $2
		    while /\G(?:(\t)|([^\t]+))/gc;
		$_ .= ": $length";
		$maxlen = $length if $maxlen < $length;
	    }
	    s/(\d+)\Z/' ' x ($maxlen - $1)/e
		for @label = @row;
	}
      FETCH:
	@row = $sth->fetchrow_array
	    or last;
	$filter->( $sth->{NAME}, @row ) or goto FETCH if $filter;
    }
}

sub render__create($;$$) {
    my @row = $_[0]->fetchrow_array
	or return;
    my $col = $_[0]{NAME}[0] =~ /Function|Procedure/i ? 2 : 1;
    if( @row > $col ) {
	$col = $row[$col];
	$col =~ s/,/,\n/g if $_[0]{NAME}[0] =~ /View/i;
	say $col;
    }
}



my $lasttime = time;
sub run($;$\%) {
    my( $sql, $filter, $opt ) = @_;
    my $t0 = [gettimeofday];
    if( $DBI::err || $t0->[0] - $lasttime > 3600 and !$dbh->ping ) {
	printf STDOUT "Inactive for %ds, ping failed after %.03fs, your session variables are lost.\n",
	    $t0->[0] - $lasttime, tv_interval $t0;
	#$dbh->disconnect;
	$dbh = $dbh->clone;	# reconnect
	$t0 = [gettimeofday];
    }
    $lasttime = $t0->[0];
    if( my $sth = UNIVERSAL::isa( $sql, 'DBI::st' ) ? $sql : $dbh->prepare( $sql )) {
	my $t1 = [gettimeofday];
	$sth->execute;
	printf STDOUT "prepare: %.03fs   execute: %.03fs   rows: %d\n",
	    tv_interval( $t0, $t1 ), tv_interval( $t1 ), $DBI::rows;
	if( $sth->{Active} ) {
	    if( $render ) {
		&$render( $sth, $filter, $opt );
	    } else {
		render_table $sth, $filter, $opt;
	    }
	}
    }
}


=head2 shell

This function reads, converts and (if C<$dbh> is set) runs in an end-less loop
(i.e. till end of file or C<^D>).  Reading is a single line affair, unless you
request otherwise.  This can happen either, as in Unix Shell, by using
continuation lines as long as you put a backslash at the end of your lines.
Or there is a special case, if the 1st line starts with C<\\>, then everything
up to C<\\> at the end of one of the next lines, constitutes one entry.

In addition to converting, it offers a few extra features, performed in this
order (i.e. C<&I<xyz>> can return C</I<regexp>/=I<literal sql>> etc.):

=head3 C<&{I<Perl code>} I<following text>>

Run I<Perl code>.  It sees the optional I<following text> in C<$_> and may
modify it.  If it returns C<undef>, this statement is skipped.  If it returns
a DBI statement handle, run that instead of this statement.  Else replace with
what it returns.

Reprocess result as a shell entry (i.e. it may return another C<&I<query>>).

=head3 C<&I<query arg>; ...> E<nbsp> or E<nbsp> C<&I<query>( I<arg>; ... ) I<following text>>

These allow canned entries and are more complex than macros, in that they take
arguments and replacement can depend on the argument.

Reprocess result as a shell entry (i.e. it may return another C<&I<query>>).

You can define your own canned queries with:

C<    &{ Query I<name> =E<gt> 'I<doc>', 'I<query>' }>

Here C<query> becomes the replacement string for C<&name>.  It may contain
arguments a bit like the Shell: C<$0> (I<name>), C<$*> (all arguments), C<$1,
$2, ..., $10, ...> (individual arguments) and C<$E<gt>> (all arguments not
adressed individually).  They can become quoted like
L<C<:\>|/namespec-strings-or-:-namespec-join-strings> as
C<$\I<namespec>I<arg>> or C<$\I<namespec>%I<join>I<arg>>.  Here I<arg> is
C<*>, C<E<gt>> or a number directly tacked on to I<spec> or I<join>.  E.g.:
C<$\-"1> splits the 1st (semi-colon separated from the 2nd) argument itself on
C<-> (minus), quotes the pieces with C<"> (double quote) and joins them with
C<,> (comma).  The two list variables C<$\*> & C<$\E<gt>> don't get split
individually unless explicitly specified, e.g. C<$\,*>.  Putting the quotes
inside the argument like this, eliminates them, if no argument is given.

=head3 C</I<regexp>/ I<statement>> E<nbsp> or E<nbsp> C</I<regexp>/i I<statement>> E<nbsp> or E<nbsp> C<!/I<regexp>/ I<statement>> E<nbsp> or E<nbsp> C<!/I<regexp>/i I<statement>>

This will treat the I<statement> normally, but will join each output row into
a C<~> (tilde) separated string for matching.  NULL fields are rendered as
that string.  E.g. to return only rows starting with a number 1-5, followed by
a NULL field, you could write: C</^[1-5]~NULL~/>.

With a suffix C<i>, matching becomes case insensitive.  This is why the mostly
optional space before I<statement> is shown above.  Without an C<i>, but if
the statement starts with the word C<i> (e.g. your first column name), you
must separate it with a space.  With an C<i>, if the statement starts with an
alphanumeric caracter, you must separate it with a space.

Only matching rows are considered unless there is a preceding C<!>
(exclamation mark), in which case only non-matching rows are considered.

You can provide your own formatting of the row by setting C<$regexp_fail> to a
Perl sub that returns a Perl expression as a string.  That expression takes
the row in C<@_> and shall be true if the row fails to match.

Caveat: the whole result set of the I<statement> gets generated and
transferred to the client.  This is definitely much more expensive than doing
the equivalent filtering in the where clause.  But it is not a big deal for
tens or maybe hundreds of thousands or rows, probably still faster than
writing the corresponding SQL.  And Perl's regexps are so much more powerful.

=head3 C<{I<Perl code>}I<statement>>

Call I<Perl code> for every output row returned by the I<statement> with the
array of column names as zeroth argument and the values after that (i.e.
numbered from 1 like in SQL).  It may modify individual values.  If it returns
false, the row is skipped.

You may combine S<C</I<regexp>/{I<Perl code>}>> in any order and as many of them as
you want.

The same caveat as for regexps applies here.  But again Perl is far more
powerful than any SQL functions.

=head3 C<=I<literal sql>>

A preceding C<=> prevents conversion, useful for hitherto untreated keywords
or where the conversion doesn't play well with your intention.

=head3 C<?>

Help prefix.  Alone it will give an overview.  You can follow up with any of
the special syntaxes, with or without an abbreviation.  E.g. C<?(> will show
all function abbreviations, whereas C<?I<abbrev>(> will show only those functions
matching I<abbrev> or C<?#I<abbrev>> only those tables matching I<abbrev>.

=head3 C<??I<statement>>

Will convert and show, but not perform I<statement>.  If C<$dbh> is not set, this
is the default behaviour.

=head3 C<!I<System Shell code>>

Run I<System Shell code>.

=head3 C<E<gt>I<filename>> E<nbsp> or E<nbsp> C<E<gt>E<gt>I<filename>>

Redirect or append next statement's output to I<filename>.  For known
suffixes and options, see the L<next section|/Output Formats>.

=head3 C<|I<System Shell code>>

Pipe next statement's output through I<System Shell code>.

=head2 Output Formats

The output format for the next SQL statement that is run, is chosen from the
suffix of a redirection or a special suffix query.  In both cases
comma-separated options may be passed:

=over

=item >I<filename>.I<suffix>

=item >I<filename>.I<suffix>( I<opt>; ... )

=item >>I<filename>.I<suffix>

=item >>I<filename>.I<suffix>( I<opt>; ... )

=item &.I<suffix opt>; ...

=item &.I<suffix>( I<opt>; ... ) following text

=back

The known suffixes and their respective options are:

=over

=item C<.csv>

This writes Comma Separated Values with one subtle trick: NULL and empty
strings are distinguished by quoting the latter.  Some tools like Perl's file
DB L<DBD::CSV> or rather its underlying L<Text::CSV_XS> can pick that up.  CSV
can take one of these options:

=over

=item semi

Use a semicolon as a separator.  This is a common format in environments where
the comma is the decimal separator.  However if you want decimal commas, you must
provide such formatting yourself.

=item tab

Use tabulators as column separators.  Apart from that you get the full CSV
formatting, so this is not the primitive F<.tsv> format some tools may have.

=back


=item C<.table>

This is the default table format.  But you need to name it, if you want to set
options.

=over

=item all

This is a shorthand for outputting everything in the long form, equivalent to
C<( NULL, crlf, date )>.

=item crlf

Do not shorten C<\r\n> to C<\R>.

=item date

Output ISO dates fully instead of shortening 0000-00-00 to 0000- and
yyyy-01-01 to yyyy- or yyyy-mm-01 to yyyy-mm-.

=item time

Output times fully instead of shortening 23:59(:59) to 24: and hh:00(:00) to
hh: or hh:mm(:00) to hh:mm.

=item NULL

=item null

Output this keyword instead of the shorter C<ω> from DB theory (or whatever
you assigned to C<$NULL>).

=back


=item C<.yaml>

=item C<.yml>

Format output as YAML.  This format has no options.  Because its every value
on a new line format can be more readable, there is a shorthand query C<&->
for it.

=back

=cut

our $prompt = 'steno> ';
our $contprompt = '...>  ';
our $echo;
# Called for every leading re, 1st arg is the optional '!', 2nd arg '/re/' or '/re/i'.  Expression shall be true for non-matching lines.
our $regexp_fail = sub($$) { 'join( "~", map ref() ? () : $_ // q!NULL!, @_ )' . ($_[0] ? '=~' : '!~') . $_[1] };
sub shell() {
    print STDERR $prompt;
    my $fh;
    while( <> ) {
	undef $error;
	goto NEXT unless /\S/;
	if( s/^\s*\\\\\s*// ) {
	    s/\s*\Z/\n/s;
	    local $/ = "\\\\\n";	# leading \n gets chopped below
	    $_ .= <>;
	    chomp;
	} else {
	    while( s/(?<!\\)((?:\\\\)*)\\(?=\n\Z)/$1/ ) {	# join continuation lines
		print STDERR $contprompt;
		$_ .= <>;
	    }
	    s/\A\s+//;
	}
	s/\s+\Z//;
	say if $echo;
	until( $error ) {
	    if( s!^&$perl_re!! ) {
		my $perl = eval $1;
		local $| = 1;	# flush to avoid stderr prompt overtaking last output line.
		warn $@ if $@;
		if( UNIVERSAL::isa $perl, 'DBI::st' ) {
		    $_ = $perl;
		    goto RUN;
		} elsif( defined $perl ) {
		    substr $_, 0, 0, $perl;
		} else {
		    goto NEXT;
		}
	    } else {
		last unless
		    s!^&(\.?\w+|-)(\(((?:(?>[^()]+)|(?2))*)\))!convert_Query $1, $3!e
		    or s!^&(\.?\w+|-) *(.*)!convert_Query $1, $2!e;
	    }
	}

	my $filter = '';
	while( s/^\s*$perl_re// || s%^\s*(!?)(/.+?/(?:i\b)?)\s*%% ) {
	    if( defined $2 ) {
		$filter .= 'return if ' . $regexp_fail->( $1, $2 ) .  ";\n";
	    } else {
		$filter .= "return unless eval $1;\n";
	    }
	}
	if( $filter ) {
	    $filter = eval "sub {\n$filter 1; }";
	    warn $@ if $@;
	}
	goto RUN if s/^\s*=//;	# run literally

	my $skip = 0;
	if( /^\s*\?\s*(?:([?&#.:\\])(\w*)|(\w*)\()?/ ) { # help
	    if( $1 && $1 eq '?' ) {
		s/^\s*\?\s*\?//;
		$skip = 1;
	    } else {
		help( $1, $2, $3 );
		goto NEXT;
	    }
	}
	if( s/^\s*!// ) {
	    system $_;
	    if( $? == -1 ) {
		print STDERR "failed to execute: $!\n";
	    } elsif( my $exit = $? & 0b111_1111 ) {
		printf STDERR "child died with signal %d, with%s coredump\n",
		    $exit, ($? & 0b1000_0000) ? '' : 'out';
	    } else {
		printf STDERR "child exited with value %d\n", $? >> 8;
	    }
	    goto NEXT;
	}
	s/^\s*()//;			# dummy because $1 survives loop iterations :-o
	if( /\A(>{1,2})\s*(.+?(\.\w+)?)(?:\((.*)\))?\s*\Z/ ) {	# redirect output
	    set_render $3, $4 ? split ';', $4 : () if $3;
	    open $fh, "$1:utf8", (glob $2)[0];
	    select $fh;
	    goto NEXT;
	} elsif( /\A\|(.+)\Z/ ) {	# pipe output
	    open $fh, '|-:utf8', $1;
	    select $fh;
	    goto NEXT;
	}

	undef $error;

	goto NEXT unless $_ && &convert;

	print STDOUT "$_;\n";
	goto NEXT if $skip;

      RUN:
	run $_, $filter, %opt if $dbh;
	($render, %opt) = ();
	if( $fh ) {
	    close;
	    select STDOUT;
	    undef $fh;
	}
      NEXT:
	print STDERR $prompt;
    }
    print STDERR "\n";
}



sub helphashalt(\%@) {
    my $hash = shift;
    if( @_ ) {
	my $ret = $hash->{''};
	print "for *ptr, *cr, *cp, ...:\n";
	printf "%-5s %s\n", $_, &$ret( $_ )
	    for @_;
	print "\n";
    }
    $_ eq '' or printf "%-5s %s\n", $_, $hash->{$_}
	for sort keys %$hash;
}
sub helphash($$$\%;\@) {
    #my( $str, $prefix, $suffix, $hash, $list ) = @_;
    if( $_[0] ) {
	undef $error;
	$error or printf "%-7s %s\n", "$_[1]$_[0]$_[2]", $_ if $_ = &find;
    } else {
	my %hash = %{$_[3]};
	if( my $sub = delete $hash{''} ) {
	    my @list = $sub->();
	    for my $elt ( @list ) {
		$hash{$elt->[0]} = $sub->( my $name = $elt->[0] ) . '    ' . $elt->[1];
	    }
	}
	chomp %hash;
	printf "%-7s %s\n", "$_[1]$_$_[2]", $hash{$_}
	    for sort { lc( $a ) cmp lc( $b ) or  $a cmp $b } keys %hash;
	return unless $_[4];
	my $i = 0;
	my @list = sort { lc( $a ) cmp lc( $b ) or  $a cmp $b } @{$_[4]};
	while( @list ) {
	    if( ($i += length $list[0]) < 80 ) {
		print ' ', shift @list;
	    } else {
		$i = 0;
		print "\n";
	    }
	}
	print "\n" if $i;
    }
}

sub help {
    if( defined $_[2] ) {
	helphash $_[2], '', '(', %Functions, @Functions;
    } elsif( !$_[0] ) {
	print <<\HELP;
All entries are single line unless \\wrapped at 1st bol and last eol\\ or continued.\
Queries have the form: {{!}/regexp/{i}}{=}query
The query has lots of short-hands expanded, unless it is prefixed by the optional =.
The fields joined with '~' are grepped if regexp is given, case-insensitively if i is given.

??query		Only shows massaged query.
!perl-code	Runs perl-code.
>file		Next query's output to file.  In csv or yaml format if filename has that suffix.

Query has the form {select|update|insert|delete}{fieldlist};tablelist{;clause} or set ...
'select' is prepended if none of these initial keywords.
fieldlist defaults to '*', also if Query starts with '#'.
';' is alternately replaced by 'from' and 'where'.

Abbreviations, more help with ?&{abbrev}, ?:{abbrev}, ?\{abbrev}, ?#{abbrev}, ?.{abbrev}, ?{abbrev}(
&{Perl code}...		# only at bol, if it returns undef then skip, else prepend to ...
&query $1;$2;...	# only at bol
&query($1;$2;...)...	# only at bol, only replace upto )
:macro
:\quote(arg,...)	# split, quote & join (?\ alone needs trailing space, because \ at end continues)
:{Perl code}		# dynamic macro
#table #table#t
.column	.column.c	# for any table recognized in statement
function(

Characters \t\n\r get masked in output, \r\n as \R.
Date or time 0000-00-00 -> 0000-  1970-01-01 -> 1970-  00:00:00 -> 00:  23:59:59 -> 24:
HELP
    } elsif( $_[0] eq '#' ) {
	@keys_Table_Columns = keys %Table_Columns unless @keys_Table_Columns;
	helphash $_[1], '#', '', %Tables, @keys_Table_Columns;
    } elsif( $_[0] eq '.' ) {
	helphashalt %Columns, 'ptr' unless $_[1]; # \todo WIN@
	$error or print "$_\n" if
	    $_[1] and $_ = find $_[1], '.', '', %Columns; # \todo, @column;
    } elsif( $_[0] eq '&' ) {
	print <<\HELP unless $_[1];
&{ Query name => 'doc', 'query' }   define query &name on the fly
	query may contain arguments a bit like the Shell: $1, $2, ..., $*
	they can become quoted: $\1, $\"2, $\`*, $\[3, $\{}>
	$* means all args; $> the remaining args after using up the numbered ones
	if it is quoted, each arg gets quoted, separated by a comma
	$?arg?arg-replacement?no-arg-replacement? 1st if $arg has a value
HELP
	helphash $_[1], '&', '', %Queries_help;
    } elsif( $_[0] eq '\\' ) {
	print <<\HELP unless $_[1];
:\namespec(arg,...) or func\namespec(arg,...) quotes args for you.
&{ Quote name => 'doc', 'namespec' }   define quote \name on the fly
	namespec may another name and/or any splitter chars (-,:;./ ),
	preventer chars (#?ω^\@!), quoting chars ('"`[]{}) and/or
	a string to join the results with after a %.
HELP
	helphash $_[1], '\\', '', %Quotes_help;
    } else {
	print <<\HELP unless $_[1];
:\(...)	 split arguments and quote in many ways
HELP
	local $Tables{TBL} = 'TABLE';
	helphash $_[1], ':', '', %Macros;
    }
}

1;

=head1 YOUR SCRIPT

    package SQL::Steno;		# doesn't export yet, so get the functions easily
    use SQL::Steno;
    use DBI;
    our $dbh = DBI->connect( ... ); # preferably mysql, but other DBs should work (with limitations).
    # If you want #tbl and .col to work, (only) one of:
    init_from_query;		# fast, defaults to mysql information_schema, for which you need read permission
    init;			# slow, using DBI dbh methods.
    # Set any of the variables mentioned above to get you favourite abbreviations.
    shell;

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<DBI>, L<SQL::Interp>, L<SQL::Preproc>, L<SQL::Yapp>, L<Jade|http://jade-lang.com/>

=head1 AUTHOR

(C) 2015, 2016 by Daniel Pfeiffer <occitan@esperanto.org>.
