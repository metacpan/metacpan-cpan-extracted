
package SQL::Beautify;

use strict;
use warnings;

our $VERSION = 0.04;

use SQL::Tokenizer;
use Carp;


# Keywords from SQL-92, SQL-99 and SQL-2003.
use constant KEYWORDS => qw(
	ABSOLUTE ACTION ADD AFTER ALL ALLOCATE ALTER AND ANY ARE ARRAY AS ASC
	ASENSITIVE ASSERTION ASYMMETRIC AT ATOMIC AUTHORIZATION AVG BEFORE BEGIN
	BETWEEN BIGINT BINARY BIT BIT_LENGTH BLOB BOOLEAN BOTH BREADTH BY CALL
	CALLED CASCADE CASCADED CASE CAST CATALOG CHAR CHARACTER CHARACTER_LENGTH
	CHAR_LENGTH CHECK CLOB CLOSE COALESCE COLLATE COLLATION COLUMN COMMIT
	CONDITION CONNECT CONNECTION CONSTRAINT CONSTRAINTS CONSTRUCTOR CONTAINS
	CONTINUE CONVERT CORRESPONDING COUNT CREATE CROSS CUBE CURRENT CURRENT_DATE
	CURRENT_DEFAULT_TRANSFORM_GROUP CURRENT_PATH CURRENT_ROLE CURRENT_TIME
	CURRENT_TIMESTAMP CURRENT_TRANSFORM_GROUP_FOR_TYPE CURRENT_USER CURSOR
	CYCLE DATA DATE DAY DEALLOCATE DEC DECIMAL DECLARE DEFAULT DEFERRABLE
	DEFERRED DELETE DEPTH DEREF DESC DESCRIBE DESCRIPTOR DETERMINISTIC
	DIAGNOSTICS DISCONNECT DISTINCT DO DOMAIN DOUBLE DROP DYNAMIC EACH ELEMENT
	ELSE ELSEIF END EPOCH EQUALS ESCAPE EXCEPT EXCEPTION EXEC EXECUTE EXISTS
	EXIT EXTERNAL EXTRACT FALSE FETCH FILTER FIRST FLOAT FOR FOREIGN FOUND FREE
	FROM FULL FUNCTION GENERAL GET GLOBAL GO GOTO GRANT GROUP GROUPING HANDLER
	HAVING HOLD HOUR IDENTITY IF IMMEDIATE IN INDICATOR INITIALLY INNER INOUT
	INPUT INSENSITIVE INSERT INT INTEGER INTERSECT INTERVAL INTO IS ISOLATION
	ITERATE JOIN KEY LANGUAGE LARGE LAST LATERAL LEADING LEAVE LEFT LEVEL LIKE
	LIMIT LOCAL LOCALTIME LOCALTIMESTAMP LOCATOR LOOP LOWER MAP MATCH MAX
	MEMBER MERGE METHOD MIN MINUTE MODIFIES MODULE MONTH MULTISET NAMES
	NATIONAL NATURAL NCHAR NCLOB NEW NEXT NO NONE NOT NULL NULLIF NUMERIC
	OBJECT OCTET_LENGTH OF OLD ON ONLY OPEN OPTION OR ORDER ORDINALITY OUT
	OUTER OUTPUT OVER OVERLAPS PAD PARAMETER PARTIAL PARTITION PATH POSITION
	PRECISION PREPARE PRESERVE PRIMARY PRIOR PRIVILEGES PROCEDURE PUBLIC RANGE
	READ READS REAL RECURSIVE REF REFERENCES REFERENCING RELATIVE RELEASE
	REPEAT RESIGNAL RESTRICT RESULT RETURN RETURNS REVOKE RIGHT ROLE ROLLBACK
	ROLLUP ROUTINE ROW ROWS SAVEPOINT SCHEMA SCOPE SCROLL SEARCH SECOND SECTION
	SELECT SENSITIVE SESSION SESSION_USER SET SETS SIGNAL SIMILAR SIZE SMALLINT
	SOME SPACE SPECIFIC SPECIFICTYPE SQL SQLCODE SQLERROR SQLEXCEPTION SQLSTATE
	SQLWARNING START STATE STATIC SUBMULTISET SUBSTRING SUM SYMMETRIC SYSTEM
	SYSTEM_USER TABLE TABLESAMPLE TEMPORARY TEXT THEN TIME TIMESTAMP
	TIMEZONE_HOUR TIMEZONE_MINUTE TINYINT TO TRAILING TRANSACTION TRANSLATE
	TRANSLATION TREAT TRIGGER TRIM TRUE UNDER UNDO UNION UNIQUE UNKNOWN UNNEST
	UNTIL UPDATE UPPER USAGE USER USING VALUE VALUES VARCHAR VARYING VIEW WHEN
	WHENEVER WHERE WHILE WINDOW WITH WITHIN WITHOUT WORK WRITE YEAR ZONE
);


sub new {
	my ($class, %options) = @_;

	my $self = bless { %options }, $class;

	# Set some defaults.
	$self->{query}    = ''   unless defined($self->{query});
	$self->{spaces}   = 4    unless defined($self->{spaces});
	$self->{space}    = ' '  unless defined($self->{space});
	$self->{break}    = "\n" unless defined($self->{break});
	$self->{wrap}     = {}   unless defined($self->{wrap});
	$self->{keywords} = []   unless defined($self->{keywords});
	$self->{rules}    = {}   unless defined($self->{rules});
	$self->{uc_keywords} = 0 unless defined $self->{uc_keywords};

	push @{$self->{keywords}}, KEYWORDS;

	# Initialize internal stuff.
	$self->{_level} = 0;

	return $self;
}


# Add more SQL.
sub add {
	my ($self, $addendum) = @_;

	$addendum =~ s/^\s*/ /;

	$self->{query} .= $addendum;
}


# Set SQL to beautify.
sub query {
	my ($self, $query) = @_;

	$self->{query} = $query if(defined($query));

	return $self->{query};
}


# Beautify SQL.
sub beautify {
	my ($self) = @_;

	$self->{_output} = '';
	$self->{_level_stack} = [];
	$self->{_new_line} = 1;

	my $last;

	$self->{_tokens} = [ SQL::Tokenizer->tokenize($self->query, 1) ];

	while(defined(my $token = $self->_token)) {
		my $rule = $self->_get_rule($token);

		# Allow custom rules to override defaults.
		if($rule) {
			$self->_process_rule($rule, $token);
		}

		elsif($token eq '(') {
			$self->_add_token($token);
			$self->_new_line;
			push @{$self->{_level_stack}}, $self->{_level};
			$self->_over unless $last and uc($last) eq 'WHERE';
		}

		elsif($token eq ')') {
			$self->_new_line;
			$self->{_level} = pop(@{$self->{_level_stack}}) || 0;
			$self->_add_token($token);
			$self->_new_line;
		}

		elsif($token eq ',') {
			$self->_add_token($token);
			$self->_new_line;
		}

		elsif($token eq ';') {
			$self->_add_token($token);
			$self->_new_line;

			# End of statement; remove all indentation.
			@{$self->{_level_stack}} = ();
			$self->{_level} = 0;
		}

		elsif($token =~ /^(?:SELECT|FROM|WHERE|HAVING)$/i) {
			$self->_back unless $last and $last eq '(';
			$self->_new_line;
			$self->_add_token($token);
			$self->_new_line if($self->_next_token and $self->_next_token ne '(');
			$self->_over;
		}

		elsif($token =~ /^(?:GROUP|ORDER|LIMIT)$/i) {
			$self->_back;
			$self->_new_line;
			$self->_add_token($token);
		}

		elsif($token =~ /^(?:BY)$/i) {
			$self->_add_token($token);
			$self->_new_line;
			$self->_over;
		}

		elsif($token =~ /^(?:UNION|INTERSECT|EXCEPT)$/i) {
			$self->_new_line;
			$self->_add_token($token);
			$self->_new_line;
		}

		elsif($token =~ /^(?:LEFT|RIGHT|INNER|OUTER|CROSS)$/i) {
			$self->_back;
			$self->_new_line;
			$self->_add_token($token);
			$self->_over;
		}

		elsif($token =~ /^(?:JOIN)$/i) {
			if($last and $last !~ /^(?:LEFT|RIGHT|INNER|OUTER|CROSS)$/) {
				$self->_new_line;
			}

			$self->_add_token($token);
		}

		elsif($token =~ /^(?:AND|OR)$/i) {
			$self->_new_line;
			$self->_add_token($token);
			$self->_new_line;
		}

		else {
			$self->_add_token($token, $last);
		}

		$last = $token;
	}

	$self->_new_line;

	$self->{_output};
}


# Add a token to the beautified string.
sub _add_token {
	my ($self, $token, $last_token) = @_;

	if($self->{wrap}) {
		my $wrap;

		if($self->_is_keyword($token)) {
			$wrap = $self->{wrap}->{keywords};
		}
		elsif($self->_is_constant($token)) {
			$wrap = $self->{wrap}->{constants};
		}

		if($wrap) {
			$token = $wrap->[0] . $token . $wrap->[1];
		}
	}

	my $last_is_dot =
		defined($last_token) && $last_token eq '.';

	if(!$self->_is_punctuation($token) and !$last_is_dot) {
		$self->{_output} .= $self->_indent;
	}

	# uppercase keywords
	$token = uc $token
		if $self->_is_keyword($token) and $self->{uc_keywords};

	$self->{_output} .= $token;

	# This can't be the beginning of a new line anymore.
	$self->{_new_line} = 0;
}


# Increase the indentation level.
sub _over {
	my ($self) = @_;

	++$self->{_level};
}


# Decrease the indentation level.
sub _back {
	my ($self) = @_;

	--$self->{_level} if($self->{_level} > 0);
}


# Return a string of spaces according to the current indentation level and the
# spaces setting for indenting.
sub _indent {
	my ($self) = @_;

	if($self->{_new_line}) {
		return $self->{space} x ($self->{spaces} * $self->{_level});
	}
	else {
		return $self->{space};
	}
}


# Add a line break, but make sure there are no empty lines.
sub _new_line {
	my ($self) = @_;

	$self->{_output} .= $self->{break} unless($self->{_new_line});
	$self->{_new_line} = 1;
}


# Have a look at the token that's coming up next.
sub _next_token {
	my ($self) = @_;

	return @{$self->{_tokens}} ? $self->{_tokens}->[0] : undef;
}


# Get the next token, removing it from the list of remaining tokens.
sub _token {
	my ($self) = @_;

	return shift @{$self->{_tokens}};
}


# Check if a token is a known SQL keyword.
sub _is_keyword {
	my ($self, $token) = @_;

	return ~~ grep { $_ eq uc($token) } @{$self->{keywords}};
}


# Add new keywords to highlight.
sub add_keywords {
	my $self = shift;

	for my $keyword (@_) {
		push @{$self->{keywords}}, ref($keyword) ? @{$keyword} : $keyword;
	}
}


# Add new rules.
sub add_rule {
	my ($self, $format, $token) = @_;

	my $rules = $self->{rules}    ||= {};
	my $group = $rules->{$format} ||= [];

	push @{$group}, ref($token) ? @{$token} : $token;
}


# Find custom rule for a token.
sub _get_rule {
	my ($self, $token) = @_;

	values %{$self->{rules}}; # Reset iterator.

	while(my ($rule, $list) = each %{$self->{rules}}) {
		return $rule if(grep { uc($token) eq uc($_) } @$list);
	}

	return undef;
}


sub _process_rule {
	my ($self, $rule, $token) = @_;

	my $format = {
		break => sub { $self->_new_line                                     },
		over  => sub { $self->_over                                         },
		back  => sub { $self->_back                                         },
		token => sub { $self->_add_token($token)                            },
		push  => sub { push @{$self->{_level_stack}}, $self->{_level}       },
		pop   => sub { $self->{_level} = pop(@{$self->{_level_stack}}) || 0 },
		reset => sub { $self->{_level} = 0; @{$self->{_level_stack}} = ();  },
	};

	for(split /-/, lc $rule) {
		&{$format->{$_}} if($format->{$_});
	}
}


# Check if a token is a constant.
sub _is_constant {
	my ($self, $token) = @_;

	return ($token =~ /^\d+$/ or $token =~ /^(['"`]).*\1$/);
}


# Check if a token is punctuation.
sub _is_punctuation {
	my ($self, $token) = @_;

	return ($token =~ /^[,;.]$/);
}


1

__END__

=head1 NAME

SQL::Beautify - Beautify SQL statements by adding line breaks indentation

=head1 SYNOPSIS

	my $sql = SQL::Beautify->new;

	$sql->query($sql_query);

	my $nice_sql = $sql->beautify;

=head1 DESCRIPTION

Beautifies SQL statements by adding line breaks indentation.

=head1 METHODS

=over 4

=item B<new>(query => '', spaces => 4, space => ' ', break => "\n", wrap => {})

Constructor. Takes a few options.

=over 4

=item B<query> => ''

Initialize the instance with a SQL string. Defaults to an empty string.

=item B<spaces> => 4

Number of spaces that make one indentation level. Defaults to 4.

=item B<space> => ' '

A string that is used as space. Default is an ASCII space character.

=item B<break> => "\n"

String that is used for linebreaks. Default is "\n".

=item B<wrap> => {}

Use this if you want to surround certain tokens with markup stuff. Known token
types are "keywords" and "constants" for now. The value of each token type
should be an array with two elements, one that is placed before the token and
one that is placed behind it. For example, use make keywords red using terminal
color escape sequences.

	{ keywords => [ "\x1B[0;31m", "\x1B[0m" ] }

=item B<uc_keywords> => 1|0

When true (1) all SQL keywords will be uppercased in output.  Default is false (0).

=back

=item B<add>($more_sql)

Appends another chunk of SQL.

=item B<query>($query)

Sets the query to the new query string. Overwrites anything that was added with
prior calls to B<query> or B<add>.

=item B<beautify>

Beautifies the internally saved SQL string and returns the result.

=item B<add_keywords>($keyword, $another_keyword, \@more_keywords)

Add any amount of keywords of arrays of keywords to highlight.

=item B<add_rule>($rule, $token)

Add a custom formatting rule. The first argument is the rule, a string
containing one or more commands (explained below), separated by dashes. The
second argument may be either a token (string) or a list of strings. Tokens are
grouped by rules internally, so you may call this method multiple times with
the same rule string and different tokens, and the rule will apply to all of
the tokens.

The following formatting commands are known at the moment:

=over 4

=item B<token> - insert the token this rule applies to

=item B<over> - increase indentation level

=item B<back> - decrease indentation level

=item B<break> - insert line break

=item B<push> - push current indentation level to an internal stack

=item B<pop> - restore last indentation level from the stack

=item B<reset> - reset internal indentation level stack

=back

B<push>, B<pop> and B<reset> should be rarely needed.


B<NOTE>:
Custom rules override default rules. Some default rules do things that
can't be done using custom rules, such as changing the format of a token
depending on the last or next token.


B<NOTE>:
I'm trying to provide sane default rules. If you find that a custom
rule of yours would make more sense as a default rule, please create a ticket.


=back

=head1 BUGS

Needs more tests.

Please report bugs in the CPAN bug tracker.

This module is not complete (known SQL keywords, special formatting of
keywords), so if you want see something added, just send me a patch.

=head1 COPYRIGHT

Copyright (C) 2009 by Jonas Kramer.  Published under the terms of the Artistic
License 2.0.

=cut
