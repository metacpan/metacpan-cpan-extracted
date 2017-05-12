package Mysql::PrettyPrinter;

use strict;
use warnings;

our $VERSION = 0.10;

# Knowledge of MySQL keywords is stored in class variables to aid efficiency in
# persistent environments (eg mod_perl)
my $Keywords = [];
# First-level keywords; outdent
$Keywords->[0] = [ qw(
    ALTER CHANGE CREATE DELETE DROP FROM GRANT GROUP HAVING INSERT LIMIT MODIFY
    ORDER SELECT SET SHOW UNION UPDATE WHERE
) ];
# Second-level keywords; prepend a linebreak
$Keywords->[1] = [ qw(
    CROSS INNER JOIN LEFT OUTER RIGHT
    ELSE ELSEIF THEN WHEN
) ];
# Third-level keywords; prepend a linebreak if within a join
$Keywords->[2] = [ qw(
    AND OR
) ];
# Other keywords; no intention to treat specially
$Keywords->[3] = [ qw(
    ACCESSIBLE ADD ALL ANALYZE AS ASC ASENSITIVE BEFORE BETWEEN BIGINT BINARY
    BLOB BOTH BY CALL CASCADE CASE CHAR CHARACTER CHECK COLLATE COLUMN
    CONDITION CONNECTION CONSTRAINT CONTINUE CONVERT CURRENT_DATE CURRENT_TIME
    CURRENT_TIMESTAMP CURRENT_USER CURSOR DATABASE DATABASES DAY_HOUR
    DAY_MICROSECOND DAY_MINUTE DAY_SECOND DEC DECIMAL DECLARE DEFAULT DELAYED
    DESC DESCRIBE DETERMINISTIC DISTINCT DISTINCTROW DIV DOUBLE DUAL EACH
    ELSEIF ENCLOSED ESCAPED EXISTS EXIT EXPLAIN FALSE FETCH FLOAT FLOAT4 FLOAT8
    FOR FORCE FOREIGN FULLTEXT GOTO HIGH_PRIORITY HOUR_MICROSECOND HOUR_MINUTE
    HOUR_SECOND IF IGNORE IN INDEX INFILE INOUT INSENSITIVE INT INT1 INT2 INT3
    INT4 INT8 INTEGER INTERVAL INTO IS ITERATE KEY KEYS KILL LABEL LEADING
    LEAVE LIKE LIMIT LINEAR LINES LOAD LOCALTIME LOCALTIMESTAMP LOCK LONG
    LONGBLOB LONGTEXT LOOP LOW_PRIORITY MASTER_SSL_VERIFY_SERVER_CERT MATCH
    MEDIUMBLOB MEDIUMINT MEDIUMTEXT MIDDLEINT MINUTE_MICROSECOND MINUTE_SECOND
    MOD MODIFIES NATURAL NOT NO_WRITE_TO_BINLOG NULL NUMERIC ON OPTIMIZE OPTION
    OPTIONALLY OUT OUTFILE PRECISION PRIMARY PROCEDURE PURGE RANGE READ
    READ_ONLY READS READ_WRITE REAL REFERENCES REGEXP RELEASE RENAME REPEAT
    REPLACE REQUIRE RESTRICT RETURN REVOKE RLIKE SCHEMA SCHEMAS
    SECOND_MICROSECOND SENSITIVE SEPARATOR SHOW SMALLINT SPATIAL SPECIFIC SQL
    SQL_BIG_RESULT SQL_CALC_FOUND_ROWS SQLEXCEPTION SQL_SMALL_RESULT SQLSTATE
    SQLWARNING SSL STARTING STRAIGHT_JOIN TABLE TABLES TEMPORARY TERMINATED
    TINYBLOB TINYINT TINYTEXT TO TRAILING TRIGGER TRUE UNDO UNIQUE UNLOCK
    UNSIGNED UPGRADE USAGE USE USING UTC_DATE UTC_TIME UTC_TIMESTAMP VALUES
    VARBINARY VARCHAR VARCHARACTER VARYING WHILE WITH WRITE XOR YEAR_MONTH
    ZEROFILL
) ];
my $Keyword = { map { $_ => 4 } @{$Keywords->[3]} };
foreach my $n (1..3) {
    %$Keyword = (%$Keyword, map { $_ => $n } @{$Keywords->[$n - 1]});
}

sub new {
    my ($class, %param) = @_;
    return bless {
        space => ' ',
        break => "\n",
        indent => '    ',
        wrap => undef,
        sql => '',
        tokens => [],
        _level => 0,
        _pending => 1,
        %param
    }, $class;
}

sub sql {
    my ($self, $sql) = @_;
    if (defined($sql)) {
        # Setter
        $self->{sql} = $sql;
        $self->{_pending} = 1;
        return $self;
    }
    else {
        # Getter
        return $self->{sql};
    }
}

sub add_sql {
    my ($self, $sql) = @_;
    $sql =~ s/^\s*/ / if length $self->{sql};
    $self->{sql} .= $sql;
    $self->{_pending} = 1;
    return $self;
}

sub make_tokens {
    my ($self, %param) = @_;
    if (%param) {
        %$self = ( %$self, %param );
    }
    if (exists $param{sql}) {
        $self->{_pending} = 1;
    }
    if ($self->{_pending} and length $self->{sql}) {
        @{ $self->{tokens} } = $self->lexicals($self->{sql}, 1);
        $self->{_pending} = 0;
    }
    return $self;
}

sub tokens {
    my ($self, @toks) = @_;
    if (scalar @toks) {
        # Setter
        @{ $self->{sql} } = @toks;
        $self->{_pending} = 0;
        return $self;
    }
    else {
        # Getter
        if ($self->{_pending}) {
            warn "Probable data conflict; suspicious invocation sequence";
        }
        return wantarray ? @{$self->{tokens}} : $self->{tokens};
    }
}

sub add_tokens {
    my ($self, @toks) = @_;
    if ($self->{_pending}) {
        warn "Probable data conflict; suspicious invocation sequence";
    }
    push(@{$self->{tokens}}, @toks);
    $self->{_pending} = 0;
    return $self;
}

sub format {
    my $self = shift;
    unless (ref $self) {
        # Shortcut used; need to start from scratch
        $self = $self->new(@_);
        $self->make_tokens;
    }
    elsif ($self->{_pending}) {
        # SQL waiting to be tokenised
        $self->make_tokens(@_);
    }

    $self->{_output} = '';  # Ultimate output
    $self->{_levels} = [];  # Nested levels
    $self->{_blank_line} = 1;  # Whether in a blank line
    $self->{_previous} = '';  # Previous token
    $self->{_joining} = 0;  # Whether in a compound join
    $self->{_conditioning} = 0;  # Whether in a conditional

    while (defined(my $token = shift @{$self->{tokens}} )) {
        # Some preprocessing of token
        if ($self->_is_keyword(uc $token)) {
            # Keyword => uppercase
            $token = uc $token;
        }
        elsif ($token =~ /^[,.;\(\)]$/) {
            # Punctuation
            ;  # nothing
        }
        elsif ($self->{_pending_nl}) {
            # Non-keyword/punctuation
            $self->_new_line;
            $self->{_pending_nl} = 0;
        }

        # Build output
        if ($token eq '(') {
            push @{ $self->{_levels} }, $self->{_level};
            $self->_add_token($token)->_new_line->_over;
        }
        elsif ($token eq ')') {
            $self->{_level} = pop(@{ $self->{_levels} }) || 0;
            $self->_new_line->_add_token($token);
            $self->_new_line
                unless uc($self->_next_token) eq 'AS'
                    || $self->_next_token eq ',';
        }
        elsif ($token eq ',') {
            $self->_add_token($token)->_new_line;
        }
        elsif ($token eq ';') {
            $self->_add_token($token)->_new_line;
            # End of statement; remove all indentation
            @{ $self->{_levels} } = ();
            $self->{_level} = 0;
        }
        elsif ($token eq 'UNION') {
            # End of statement; remove all indentation
            @{ $self->{_levels} } = ();
            $self->{_level} = 0;
            $self->_new_line->_add_token($token, 'K')->_new_line;
        }
        elsif ($token eq 'JOIN') {
            unless ($self->_is_keyword($self->{_previous})) {
                $self->_new_line;
            }
            $self->_add_token($token, 'K');
        }
        elsif ($token eq 'ON') {
            $self->_add_token($token, 'K');
            if ($self->_is_keyword($self->_next_keyword) == 3) {
                $self->_new_line->_over;
                $self->{_joining} = 1;
            }
        }
        elsif ($token eq 'CASE') {
            $self->_add_token($token, 'K')->_over;
            $self->{_conditioning} = 1;
        }
        elsif ($token eq 'END' and $self->{_conditioning}) {
            $self->_back->_new_line->_add_token($token, 'K');
            $self->{_conditioning} = 0;
        }
        elsif ($self->_is_keyword($token) == 1) {
            # First-level keyword
            $self->_back unless $self->{_previous} eq '(';
            if ($self->{_joining}) {
                $self->_back;
                $self->{_joining} = 0;
            }
            $self->_new_line->_add_token($token, 'K')->_over;
            $self->{_pending_nl} = 1;
        }
        elsif ($self->_is_keyword($token) == 2) {
            # Second-level keyword
            if ($self->{_joining}) {
                $self->_back;
                $self->{_joining} = 0;
            }
            $self->_new_line->_add_token($token, 'K');
        }
        elsif ($self->_is_keyword($token) == 3) {
            # Third-level keyword
            $self->_new_line->_add_token($token, 'K');
        }
        elsif ($self->_is_keyword($token)) {
            # Other keyword
            $self->_add_token($token, 'K');
        }
        elsif ($token =~ /^"[^"']*"$/) {
            # Quoted string
            $token =~ s/"/'/g;
            $self->_add_token($token, 'L');
        }
        elsif ($token =~ /^'.*'$/) {
            # Quoted string
            $self->_add_token($token, 'L');
        }
        elsif ($token =~ /^\d+$/) {
            # Number
            $self->_add_token($token, 'L');
        }
        elsif ($self->_next_token eq '(') {
            $token = lc $token;
            $self->_add_token($token, 'F');
        }
        else {
            $self->_add_token($token);
        }
#TODO: Identify comments

        $self->{_previous} = $token;
    }

    $self->_new_line;
    return $self->{_output};
}

# Add a token to the formatted string.
sub _add_token {
    my ($self, $token, $type) = @_;
    $type ||= '';

    if ($self->{wrap}) {
        # Format wrapping of keywords, etc
        if ($type eq 'K' and exists $self->{wrap}->{keyword}) {
            # Keyword
            $token = $self->{wrap}->{keyword}->[0]
                . $token
                . $self->{wrap}->{keyword}->[1];
        }
        elsif ($type eq 'F' and exists $self->{wrap}->{function}) {
            # Function
            $token = $self->{wrap}->{function}->[0]
                . $token
                . $self->{wrap}->{function}->[1];
        }
        elsif ($type eq 'L' and exists $self->{wrap}->{literal}) {
            # Literal
            $token = $self->{wrap}->{literal}->[0]
                . $token
                . $self->{wrap}->{literal}->[1];
        }
        elsif ($type eq 'C' and exists $self->{wrap}->{comment}) {
            # Comment
            $token = $self->{wrap}->{comment}->[0]
                . $token
                . $self->{wrap}->{comment}->[1];
        }
    }

    if ($token =~ /^[,.;]$/ or $self->{_previous} eq '.') {
        # Punctuation => no indent
        ;
    }
    elsif ($token eq '('
            and not $self->_is_keyword($self->{_previous})
            and not $self->{_previous} eq ',') {
        # Function => no indent
        ;
    }
    else {
        $self->{_output} .= $self->_indent;
    }

    $self->{_output} .= $token;

    # This can't be the beginning of a new line anymore.
    $self->{_blank_line} = 0;
    return $self;
}

# Increase the indentation level.
sub _over {
    my ($self) = @_;
    ++$self->{_level};
    return $self;
}

# Decrease the indentation level.
sub _back {
    my ($self) = @_;
    --$self->{_level} if $self->{_level} > 0;
    return $self;
}

# Return a string of spaces according to the current indentation level and the
# spaces setting for indenting.
sub _indent {
    my ($self) = @_;
    if ($self->{_blank_line}) {
        return $self->{indent} x $self->{_level};
    }
    else {
        return $self->{space};
    }
}

# Add a line break, but make sure there are no empty lines.
sub _new_line {
    my ($self) = @_;
    $self->{_output} .= $self->{break} unless $self->{_blank_line};
    $self->{_blank_line} = 1;
    return $self;
}

sub _next_token { scalar @{ $_[0]->{tokens} } ? $_[0]->{tokens}->[0] : '' }

sub _next_keyword {
    my ($self) = @_;
    my $len = scalar @{ $self->{tokens} };
    for (my $i = 0; $i < $len; $i++) {
        if ($self->_is_keyword(uc $self->{tokens}->[$i])) {
            return(uc $self->{tokens}->[$i]);
        }
    }
    return '';
}

sub _is_keyword { defined $_[1] && exists $Keyword->{$_[1]} ? $Keyword->{$_[1]} : 0 }

sub lexicals {
    my ($proto, $sql, $omit_whitespace_tokens) = @_;
    my @tokens = $sql =~ m{
        (?:--|\#)[\ \t\S]*      # single line comments
        |
        (?:<>|<=>|>=|<=|==|=|!=|!|<<|>>|<|>|\|\||\||&&|&|-|\+|\*(?!/)|/(?!\*)|\%|~|\^|\?)
                                # operators and tests
        |
        [\[\]\(\),;.]            # punctuation (parenthesis, comma)
        |
        \'\'(?!\')              # empty single quoted string
        |
        \"\"(?!\"")             # empty double quoted string
        |
        ".*?(?:(?:""){1,}"|(?<!["\\])"(?!")|\\"{2})
                                # anything inside double quotes, ungreedy
		|
        `.*?(?:(?:``){1,}`|(?<![`\\])`(?!`)|\\`{2})
                                # anything inside backticks quotes, ungreedy
        |
        '.*?(?:(?:''){1,}'|(?<!['\\])'(?!')|\\'{2})
                                # anything inside single quotes, ungreedy.
        |
        /\*[\ \t\n\S]*?\*/      # C style comments
        |
        (?:[\w:@]+(?:\.(?:\w+|\*)?)*)
                                # words, standard named placeholders, db.table.*, db.*
        |
        (?:\${1,2})             # dollars
        |
        [\t\ ]+                 # any kind of white spaces
    }mxg;

    @tokens = grep(!/^[\s\n\r]*$/, @tokens) if $omit_whitespace_tokens;
    return wantarray ? @tokens : \@tokens;
}

sub passthrough {
    my ($class, @args) = @_;
    my %param;
    if (ref($class)) {
        die "'passthrough' is a class method";
    }
    eval {
        %param = @args || ();
    };
    if ($@) {
        die "Options should be passed in hash style\n". $@;
    }
    local($/) = '';
    print $class->format(sql => <>);
}

1;
__END__

=head1 NAME

Mysql::PrettyPrinter - A lean, efficient SQL pretty-printer for MySQL

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

The pretty-printer uses capitalisation, line-breaks, and indentation to
reformat the given chunk of SQL into a standardised form.

    $formatted = Mysql::PrettyPrinter->format(sql => $sql);

or

    my $pp = Mysql::PrettyPrinter->new;
    $pp->sql($sql);
    $pp->add_sql($sql2);
    $pp->make_tokens;
    $pp->add_tokens($tok0, $tok1, $tok2);
    # ...do some processing on @{$pp->{tokens}}
    my $output = $pp->format(indent => '  ');

or

    mysqlbinlog /data/log/binlog.001 \
        | head -n 40 \
        | perl -MMysql::PrettyPrinter \
            -e'Mysql::PrettyPrinter->passthrough' \
        | a2ps

=head1 DESCRIPTION

Very simple-minded pretty-printer for MySQL SQL.  It gets 'almost there'
results with terse efficient code.  It sets line-breaks and
probably-appropriate indentation, and optionally wraps token classes in markup.

If your requirements are more sophisticated, this class will never do the whole
job for you, however you might get a lot of mileage from using this class as a
pre-processor, extracting the tokens from $pp->tokens (and never calling
$pp->format).

=head1 METHODS

=over 4

=item B<new>(wordsep => ' ', linesep => "\n",
    indent => '    ', wrap => undef, sql => $sql)

Constructor.  If you're only invoking B<format> once then you can probably skip
the constructor.  On the other hand, if you want to construct the object once
and use it many times, you can set your default options here.

=over 4

=item wordsep

Character or string to use as a word separator, default: ' '.

=item linesep

Character or string to use as a line separator, default: "\n".
You may want to specify "\r\n" for Windows, or "\n\r" for old Mac.

=item indent

String equating to one level of indentation, default: wordsep x 4.
You may want to specify "\t" if that suits your coding standard.

=item wrap

Markup for wrapping token classes, default: undef.  The example from
L<SQL::Beautify> is

    wrap => { keyword => [ "\x1B[0;31m", "\x1B[0m" ] }

which will make keywords red on some terminals.

Another example is

    wrap => { keyword => [ '<div class="keyword">', '</div>' ] }

which will wrap keywords in HTML+CSS markup.

If you specify a hash for wrap, you must specify a pair of strings for one or
more of the token classes: keyword, function, literal.  (If you want to omit
one half of the wrapping pair, use an empty string in its place.)

=item sql

The SQL string to be formatted.  Useful if you want to manipulate the SQL or
token list before calling B<format>, or you are going to invoke B<format>
several times on the same SQL string.  Otherwise just specify it when calling
B<format>.

=back

=item B<sql>($sql)

Another place for specifying the string to be formatted.  Useful if you want to
re-use the same object with different SQL.

Returns the current SQL string if invoked without argument.

=item B<add_sql>($sql)

Lets you append a string before lexical analysis.  Useful if you want to build
up SQL in more than one pass.

=item B<make_tokens>(sql => $sql)

Invokes lexical analysis.  An additional place where you can specify the SQL.
Useful if you want to examine or manipulate tokens before formatting.

=item B<tokens>(@tokens)

Lets you specify your own list of tokens, perhaps a result of your own lexical
analysis or a result of manipulation you performed on the previous list.

Returns the current token list if invoked without argument.  Relevance depends
on you invoking B<make_tokens> or B<tokens> beforehand.

=item B<add_tokens>(@tokens)

Lets you append a list of tokens to the current token list.  Usefulness depends
on you invoking B<make_tokens> or B<tokens> beforehand.

=item B<format>(wordsep => ' ', linesep => "\n",
    indent => '    ', wrap => undef, sql => $sql)

Returns the formatted output string.  Takes same arguments as B<new>.  Can be
invoked as a class method, which is very convenient in the simple (most common)
use case.

    my $pp = Mysql::PrettyPrinter->new;
    print $pp->format(sql => 'SELECT 1 + 1');

or

    print Mysql::PrettyPrinter->format(sql => 'SELECT 1 + 1');

=item B<lexicals>($sql, $omit_whitespace_tokens)

Utility method for lexical analysis, returning the list of lexical tokens from
a given string of SQL.  This is not specific to MySQL, and is only a minor
performance enhancement over L<SQL::Tokenizer>.  A true value for
$omit_whitespace_tokens causes it to strip out tokens of pure whitespace such
as blank lines.

=item B<passthrough>(%options)

A convenience method for invoking B<format> from the commandline.
It's arguable whether the example at the top of these notes is any more
convenient than using

    | perl -MMysql::PrettyPrinter -e'BEGIN{$/=q{}}
        print Mysql::PrettyPrinter->format(%options, sql => <>)'

One advantage is it avoids issues when using double quotes.

=back

=head1 INVOCATION STYLE

Most methods support method chaining.  So you can invoke

    print Mysql::PrettyPrinter->new
    ->sql('SELECT')->add_sql('1 + 1')
    ->make_tokens->tokens('SELECT')->add_tokens('2', '+', '2')
    ->format

The exceptions are when used as getters:

    my $sql = $pp->sql;
    my @tokens = $pp->tokens;

=head1 LIMITATIONS

The strengths of this module are simplicity and speed.  The main weakness is
that it does very little semantic processing.  So the C<IF> in C<DROP TABLE IF
EXISTS> is treated the same as in C<SELECT IF (...>.

The second weakness is it provides little flexibility on style.  You can
specify strings for line-break and word-break, what string equates to a 'tab',
and whether keywords, functions, and constants should be wrapped in any markup,
but that's about it.  You cannot say "I want to align on neighbouring
'ON'/'AS'/comparitor".  The simplicity of its approach means it can be adapted
easily to other purposes, eg modify the keywords to let it handle oracle
instead, eg modify its I/O so it can process on a pipeline with minimal
lookahead and buffering.

Ideas for future enhancements include:

It should be extended to handle comments, both in indentation and markup.
It should provide more output options, eg PHP, Perl, HTML+CSS.
It could provide smart processing, eg remove redundant parentheses.
If the list of options grows, it would be nice to support having a
configuration file.

=head1 AUTHOR

Nic Sandfield, C<< <niczero at cpan.org> >>

=head1 BUGS

It has no unit tests.

Please report bugs, issues, or feature requests to C<bug-mysql-prettyprinter at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mysql-PrettyPrinter>.  I will
be notified and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 INSTALLATION

To install this module from its CPAN source package, run the following
commands:

	perl Makefile.PL
	make
	make test
	make install

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mysql::PrettyPrinter

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mysql-PrettyPrinter>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mysql-PrettyPrinter>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mysql-PrettyPrinter>

=item * Search CPAN

L<http://search.cpan.org/dist/Mysql-PrettyPrinter/>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item L<SQL::Beautify>

My module owes its existence to the fine beginnings in this module (C) 2009
Jonas Kramer.  I merely fixed some bugs, extended the usability, made it more
efficient, and specialised it to the syntax of MySQL (v5.1).

=item L<SQL::Tokenizer>

The regular expression within B<lexicals> was lifted from this module (C) 2010
Igor Sutton.  I merely made it fractionally more efficient.

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2010 Nic Sandfield.  All rights reserved.

This program is free software; you may use it, redistribute it, or modify it
under the terms of the GNU General Public Licence (GPL) v3 (or any later
version) as published by the Free Software Foundation.

See L<http://dev.perl.org/licenses/> or
L<http://www.gnu.org/licenses/license-list.html> for more information.

=cut

Mysql-PrettyPrinter

