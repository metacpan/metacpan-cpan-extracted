=head1 NAME

Parse::BooleanLogic - parser of boolean expressions

=head1 SYNOPSIS

    use Parse::BooleanLogic;
    use Data::Dumper;

    my $parser = Parse::BooleanLogic->new( operators => ['', 'OR'] );
    my $tree = $parser->as_array( 'label:parser subject:"boolean logic"' );
    print Dumper($tree);

    $parser = new Parse::BooleanLogic;
    $tree = $parser->as_array( 'x = 10' );
    print Dumper($tree);

    $tree = $parser->as_array( 'x = 10 OR (x > 20 AND x < 30)' );
    print Dumper($tree);

    # custom parsing using callbacks
    $parser->parse(
        string   => 'x = 10 OR (x > 20 AND x < 30)',
        callback => {
            open_paren   => sub { ... },
            operator     => sub { ... },
            operand      => sub { ... },
            close_paren  => sub { ... },
            error        => sub { ... },
        },
    );

=head1 DESCRIPTION

This module is quite fast parser for boolean expressions. Originally it's been writen for
Request Tracker to parse SQL like expressions and it's still capable, but
it can be used to parse other boolean logic sentences with OPERANDs joined using
binary OPERATORs and grouped and nested using parentheses (OPEN_PAREN and CLOSE_PAREN).

Operand is not qualified strictly what makes parser flexible enough to parse different
things, for example:

    # SQL like expressions
    (task.status = "new" OR task.status = "open") AND task.owner_id = 123

    # Google like search syntax used in Gmail and other service
    subject:"some text" (from:me OR to:me) label:todo !label:done

    # Binary boolean logic expressions
    (a | b) & (c | d)

You can change literals used for boolean operators and parens. Read more
about this in description of constructor's arguments.

As you can see quoted strings are supported. Read about that below in
L<Quoting and dequoting>.

=cut

use 5.008;
use strict;
use warnings;

package Parse::BooleanLogic;

our $VERSION = '0.09';

use constant OPERAND     => 1;
use constant OPERATOR    => 2;
use constant OPEN_PAREN  => 4;
use constant CLOSE_PAREN => 8;
use constant STOP        => 16;
my @tokens = qw[OPERAND OPERATOR OPEN_PAREN CLOSE_PAREN STOP];

use Regexp::Common qw(delimited);
my $re_delim = qr{$RE{delimited}{-delim=>qq{\'\"}}{-esc=>'\\'}};

=head1 METHODS

=head2 Building parser

=head3 new

A constuctor, takes the following named arguments:

=over 4

=item operators, default is ['AND' 'OR']

Pair of literal strings representing boolean operators AND and OR,
pass it as array reference. For example:

    # from t/custom_ops.t
    my $parser = Parse::BooleanLogic->new( operators => [qw(& |)] );

    # from t/custom_googlish.t
    my $parser = Parse::BooleanLogic->new( operators => ['', 'OR'] );

It's ok to have any operators and even empty.

=item parens, default is ['(', ')']

Pair of literal strings representing parentheses, for example it's
possible to use curly braces:

    # from t/custom_parens.t
    my $parser = Parse::BooleanLogic->new( parens => [qw({ })] );

No matter which pair is used parens must be balanced in expression.

=back

This constructor compiles several heavy weight regular expressions
so it's better avoid building object each time right before parsing,
but instead use global or cached one.

=cut

sub new {
    my $proto = shift;
    my $self = bless {}, ref($proto) || $proto;
    return $self->init( @_ );
}

=head3 init

An initializer, called from the constructor. Compiles regular expressions
and do other things with constructor's arguments. Returns this object back.

=cut

sub init {
    my $self = shift;
    my %args = @_;
    if ( $args{'operators'} ) {
        my @ops = map lc $_, @{ $args{'operators'} };
        $self->{'operators'} = [ @ops ];
        @ops = reverse @ops if length $ops[1] > length $ops[0];
        foreach ( @ops ) {
            unless ( length ) {
                $_ = "(?<=\\s)";
            }
            else {
                if ( /^\w/ ) {
                    $_ = '\b'. "\Q$_\E";
                }
                else {
                    $_ = "\Q$_\E";
                }
                if ( /\w$/ ) {
                    $_ .= '\b';
                }
            }
            $self->{'re_operator'} = qr{(?:$ops[0]|$ops[1])}i;
        }
    } else {
        $self->{'operators'} = [qw(and or)];
        $self->{'re_operator'} = qr{\b(?:AND|OR)\b}i;
    }

    if ( $args{'parens'} ) {
        $self->{'parens'} = $args{'parens'};
        $self->{'re_open_paren'} = qr{\Q$args{'parens'}[0]\E};
        $self->{'re_close_paren'} = qr{\Q$args{'parens'}[1]\E};
    } else {
        $self->{'re_open_paren'} = qr{\(};
        $self->{'re_close_paren'} = qr{\)};
    }
    $self->{'re_tokens'}  = qr{(?:$self->{'re_operator'}|$self->{'re_open_paren'}|$self->{'re_close_paren'})};
# the following need some explanation
# operand is something consisting of delimited strings and other strings that are not our major tokens
# so it's a (delim string or anything until a token, ['"](start of a delim) or \Z) - this is required part
# then you can have zero or more ocurences of above group, but with one exception - "anything" can not start with a token or ["']
    $self->{'re_operand'} = qr{(?:$re_delim|.+?(?=$self->{re_tokens}|["']|\Z))(?:$re_delim|(?!$self->{re_tokens}|["']).+?(?=$self->{re_tokens}|["']|\Z))*};

    foreach my $re (qw(re_operator re_operand re_open_paren re_close_paren)) {
        $self->{"m$re"} = qr{\G($self->{$re})};
    }

    return $self;
}


=head2 Parsing expressions

=head3 as_array $string [ %options ]

Takes a string and parses it into perl structure, where parentheses represented using
array references, operands are hash references with one key/value pair: operand,
when binary operators are simple scalars. So string C<x = 10 OR (x > 20 AND x < 30)>
is parsed into the following structure:

    [
        { operand => 'x = 10' },
        'OR',
        [
            { operand => 'x > 20' },
            'AND',
            { operand => 'x < 30' },
        ]
    ]

Aditional options:

=over 4

=item operand_cb - custom operands handler, for example:

    my $tree = $parser->as_array(
        "some string",
        operand_cb => sub {
            my $op = shift;
            if ( $op =~ m/^(!?)(label|subject|from|to):(.*)/ ) {
                ...
            } else {
                die "You have an error in your query, in '$op'";
            }
        },
    );


=item error_cb - custom errors handler

    my $tree = $parser->as_array(
        "some string",
        error_cb => sub {
            my $msg = shift;
            MyParseException->throw($msg);
        },
    );

=back

=cut

{ # static variables

my ($tree, $node, @pnodes);
my %callback;
$callback{'open_paren'} = sub {
    push @pnodes, $node;
    push @{ $pnodes[-1] }, $node = []
};
$callback{'close_paren'}     = sub { $node = pop @pnodes };
$callback{'operator'} = sub { push @$node, $_[0] };
$callback{'operand'} = sub { push @$node, { operand => $_[0] } };

sub as_array {
    my $self = shift;
    my $string = shift;
    my %arg = (@_);

    $node = $tree = [];
    @pnodes = ();

    unless ( $arg{'operand_cb'} || $arg{'error_cb'} ) {
        $self->parse(string => $string, callback => \%callback);
        return $tree;
    }

    my %cb = %callback;
    if ( $arg{'operand_cb'} ) {
        $cb{'operand'} = sub { push @$node, $arg{'operand_cb'}->( $_[0] ) };
    }
    $cb{'error'} = $arg{'error_cb'} if $arg{'error_cb'};
    $self->parse(string => $string, callback => \%cb);
    return $tree;
} }

=head3 parse

Takes named arguments: string and callback. Where the first one is scalar with
expression, the latter is a reference to hash with callbacks: open_paren, operator
operand, close_paren and error. Callback for errors is optional and parser dies if
it's omitted. Each callback is called when parser finds corresponding element in the
string. In all cases the current match is passed as argument into the callback.

Here is simple example based on L</as_array> method:

    # result tree and the current group
    my ($tree, $node);
    $tree = $node = [];

    # stack with nested groups, outer most in the bottom, inner on the top
    my @pnodes = ();

    my %callback;
    # on open_paren put the current group on top of the stack,
    # create new empty group and at the same time put it into
    # the end of previous one
    $callback{'open_paren'} = sub {
        push @pnodes, $node;
        push @{ $pnodes[-1] }, $node = []
    };

    # on close_paren just switch to previous group by taking it
    # from the top of the stack
    $callback{'close_paren'} = sub { $node = pop @pnodes };

    # push binary operators as is and operands as hash references
    $callback{'operator'} = sub { push @$node, $_[0] };
    $callback{'operand'}  = sub { push @$node, { operand => $_[0] } };

    # run parser
    $parser->parse( string => $string, callback => \%callback );

    return $tree;

Using this method you can build other representations of an expression.

=cut

sub parse {
    my $self = shift;
    my %args = (
        string => '',
        callback => {},
        @_
    );
    my ($string, $cb) = @args{qw(string callback)};
    $string = '' unless defined $string;

    # States
    my $want = OPERAND | OPEN_PAREN | STOP;
    my $last = 0;
    my $depth = 0;

    while (1) {
        # State Machine
        if ( $string =~ /\G\s+/gc ) {
        }
        elsif ( ($want & OPERATOR   ) && $string =~ /$self->{'mre_operator'}/gc ) {
            $cb->{'operator'}->( $1 );
            $last = OPERATOR;
            $want = OPERAND | OPEN_PAREN;
        }
        elsif ( ($want & OPEN_PAREN ) && $string =~ /$self->{'mre_open_paren'}/gc ) {
            $cb->{'open_paren'}->( $1 );
            $depth++;
            $last = OPEN_PAREN;
            $want = OPERAND | OPEN_PAREN;
        }
        elsif ( ($want & CLOSE_PAREN) && $string =~ /$self->{'mre_close_paren'}/gc ) {
            $cb->{'close_paren'}->( $1 );
            $depth--;
            $last = CLOSE_PAREN;
            $want = OPERATOR;
            $want |= $depth? CLOSE_PAREN : STOP;
        }
        elsif ( ($want & OPERAND    ) && $string =~ /$self->{'mre_operand'}/gc ) {
            my $m = $1;
            $m=~ s/\s+$//;
            $cb->{'operand'}->( $m );
            $last = OPERAND;
            $want = OPERATOR;
            $want |= $depth? CLOSE_PAREN : STOP;
        }
        elsif ( ($want & STOP) && $string =~ /\G\s*$/igc ) {
            $last = STOP;
            last;
        }
        else {
            last;
        }
    }

    if (!$last || !($want & $last)) {
        my $tmp = substr( $string, 0, pos($string) );
        $tmp .= '>>>here<<<'. substr($string, pos($string));
        my $msg = "Incomplete or incorrect expression, expecting a ". $self->bitmask_to_string($want) ." in '$tmp'";
        $cb->{'error'}? $cb->{'error'}->($msg): die $msg;
        return;
    }

    if ( $depth ) {
        my $msg = "Incomplete query, $depth paren(s) isn't closed in '$string'";
        $cb->{'error'}? $cb->{'error'}->($msg): die $msg;
        return;
    }
}

sub bitmask_to_string {
    my $self = shift;
    my $mask = shift;

    my @res;
    for( my $i = 0; $i < @tokens; $i++ ) {
        next unless $mask & (1<<$i);
        push @res, $tokens[$i];
    }

    my $tmp = join ', ', splice @res, 0, -1;
    unshift @res, $tmp if $tmp;
    return join ' or ', @res;
}

=head2 Quoting and dequoting

This module supports quoting with single quote ' and double ",
literal quotes escaped with \.

from L<Regexp::Common::delimited> with ' and " as delimiters.

=head3 q, qq, fq and dq

Four methods to work with quotes:

=over 4

=item q - quote a string with single quote character.

=item qq - quote a string with double quote character.

=item fq - quote with single if string has no single quote character, otherwisee use double quotes.

=item dq - delete either single or double quotes from a string if it's quoted.

=back

All four works either in place or return result, for example:

    $parser->q($str); # inplace

    my $q = $parser->q($s); # $s is untouched

=cut

sub q {
    if ( defined wantarray ) {
        my $s = $_[1];
        $s =~ s/(?=['\\])/\\/g;
        return "'$s'";
    } else {
        $_[1] =~ s/(?=['\\])/\\/g;
        substr($_[1], 0, 0) = "'";
        $_[1] .= "'";
        return;
    }
}

sub qq {
    if ( defined wantarray ) {
        my $s = $_[1];
        $s =~ s/(?=["\\])/\\/g;
        return "\"$s\"";
    } else {
        $_[1] =~ s/(?=["\\])/\\/g;
        substr($_[1], 0, 0) = '"';
        $_[1] .= '"';
        return;
    }
}

sub fq {
    if ( index( $_[1], "'" ) >= 0 ) {
        if ( defined wantarray ) {
            my $s = $_[1];
            $s =~ s/(?=["\\])/\\/g;
            return "\"$s\"";
        } else {
            $_[1] =~ s/(?=["\\])/\\/g;
            substr($_[1], 0, 0) = '"';
            $_[1] .= '"';
            return;
        }
    } else {
        if ( defined wantarray ) {
            my $s = $_[1];
            $s =~ s/(?=\\)/\\/g;
            return "'$s'";
        } else {
            $_[1] =~ s/(?=\\)/\\/g;
            substr($_[1], 0, 0) = "'";
            $_[1] .= "'";
            return;
        }
    }
}

sub dq {
    return defined wantarray? $_[1] : ()
        unless $_[1] =~ /^$re_delim$/o;

    if ( defined wantarray ) {
        my $s = $_[1];
        my $q = substr( $s, 0, 1, '' );
        substr( $s, -1   ) = '';
        $s =~ s/\\([$q\\])/$1/g;
        return $s;
    } else {
        my $q = substr( $_[1], 0, 1, '' );
        substr( $_[1], -1 ) = '';
        $_[1] =~ s/\\([$q\\])/$1/g;
        return;
    }
}

=head2 Tree evaluation and modification

Several functions taking a tree of boolean expressions as returned by
L<as_array> method and evaluating or changing it using a callback.

=head3 walk $tree $callbacks @rest

A simple method for walking a $tree using four callbacks: open_paren,
close_paren, operand and operator. All callbacks are optional.

Example:

    $parser->walk(
        $tree,
        {
            open_paren => sub { ... },
            close_paren => sub { ... },
            ...
        },
        $some_context_argument, $another, ...
    );

Any additional arguments (@rest) are passed all the time into callbacks.

=cut

sub walk {
    my ($self, $tree, $cb, @rest) = @_;

    foreach my $entry ( @$tree ) {
        if ( ref $entry eq 'ARRAY' ) {
            $cb->{'open_paren'}->( @rest ) if $cb->{'open_paren'};
            $self->walk( $entry, $cb, @rest );
            $cb->{'close_paren'}->( @rest ) if $cb->{'close_paren'};
        } elsif ( ref $entry ) {
            $cb->{'operand'}->( $entry, @rest ) if $cb->{'operand'};
        } else {
            $cb->{'operator'}->( $entry, @rest ) if $cb->{'operator'};
        }
    }
}

=head3 filter $tree $callback @rest

Filters a $tree using provided $callback. The callback is called for each operand
in the tree and operand is left when it returns true value.

Any additional arguments (@rest) are passed all the time into the callback.
See example below.

Boolean operators (AND/OR) are skipped according to parens and left first rule,
for example:

    X OR Y AND Z -> X AND Z
    X OR (Y AND Z) -> X OR Z
    X OR Y AND Z -> Y AND Z
    X OR (Y AND Z) -> Y AND Z
    X OR Y AND Z -> X OR Y
    X OR (Y AND Z) -> X OR Y

Returns new sub-tree. Original tree is not changed, but operands in new tree
still refer to the same hashes in the original.

Example:

    my $filter = sub {
        my ($condition, $some) = @_;
        return 1 if $condition->{'operand'} eq $some;
        return 0;
    };
    my $new_tree = $parser->filter( $tree, $filter, $some );

See also L<solve|/"solve $tree $callback @rest">

=cut

sub filter {
    my ($self, $tree, $cb, @rest) = @_;

    my $skip_next = 0;

    my @res;
    foreach my $entry ( @$tree ) {
        $skip_next-- and next if $skip_next > 0;

        if ( ref $entry eq 'ARRAY' ) {
            my $tmp = $self->filter( $entry, $cb, @rest );
            $tmp = $tmp->[0] if @$tmp == 1;
            if ( !$tmp || (ref $tmp eq 'ARRAY' && !@$tmp) ) {
                pop @res;
                $skip_next++ unless @res;
            } else {
                push @res, $tmp;
            }
        } elsif ( ref $entry ) {
            if ( $cb->( $entry, @rest ) ) {
                push @res, $entry;
            } else {
                pop @res;
                $skip_next++ unless @res;
            }
        } else {
            push @res, $entry;
        }
    }
    return $res[0] if @res == 1 && ref $res[0] eq 'ARRAY';
    return \@res;
}

=head3 solve $tree $callback @rest

Solves a boolean expression represented by a $tree using provided $callback.
The callback is called for operands and should return a boolean value
(0 or 1 will work).

Any additional arguments (@rest) are passed all the time into the callback.
See example below.

Functions matrixes:

    A B AND OR
    0 0 0   0
    0 1 0   1
    1 0 0   1
    1 1 1   1

Whole branches of the tree can be skipped when result is obvious, for example:

    1 OR  (...)
    0 AND (...)

Returns result of the expression.

Example:

    my $solver = sub {
        my ($condition, $some) = @_;
        return 1 if $condition->{'operand'} eq $some;
        return 0;
    };
    my $result = $parser->solve( $tree, $filter, $some );

See also L<filter|/"filter $tree $callback @rest">.

=cut

sub solve {
    my ($self, $tree, $cb, @rest) = @_;

    my ($res, $ea, $skip_next) = (0, $self->{'operators'}[1], 0);
    foreach my $entry ( @$tree ) {
        $skip_next-- and next if $skip_next > 0;
        unless ( ref $entry ) {
            $ea = lc $entry;
            $skip_next++ if
                   ( $res && $ea eq $self->{'operators'}[1])
                || (!$res && $ea eq $self->{'operators'}[0]);
            next;
        }

        my $cur;
        if ( ref $entry eq 'ARRAY' ) {
            $cur = $self->solve( $entry, $cb, @rest );
        } else {
            $cur = $cb->( $entry, @rest );
        }
        if ( $ea eq $self->{'operators'}[1] ) {
            $res ||= $cur;
        } else {
            $res &&= $cur;
        }
    }
    return $res;
}

=head3 fsolve $tree $callback @rest

Does in filter+solve in one go. Callback can return undef to filter out an operand,
and a defined boolean value to be used in solve.

Any additional arguments (@rest) are passed all the time into the callback.

Returns boolean result of the equation or undef if all operands have been filtered.

See also L<filter|/"filter $tree $callback @rest"> and L<solve|/"solve $tree $callback @rest">.

=cut

sub fsolve {
    my ($self, $tree, $cb, @rest) = @_;

    my ($res, $ea, $skip_next) = (undef, $self->{'operators'}[1], 0);
    foreach my $entry ( @$tree ) {
        $skip_next-- and next if $skip_next > 0;
        unless ( ref $entry ) {
            $ea = lc $entry;
            $skip_next++ if
                   ( $res && $ea eq $self->{'operators'}[1])
                || (!$res && $ea eq $self->{'operators'}[0]);
            next;
        }

        my $cur;
        if ( ref $entry eq 'ARRAY' ) {
            $cur = $self->fsolve( $entry, $cb, @rest );
        } else {
            $cur = $cb->( $entry, @rest );
        }
        if ( defined $cur ) {
            $res ||= 0;
            if ( $ea eq $self->{'operators'}[1] ) {
                $res ||= $cur;
            } else {
                $res &&= $cur;
            }
        } else {
            $skip_next++ unless defined $res;
        }
    }
    return $res;
}

=head3 partial_solve $tree $callback @rest

Partially solve a $tree. Callback can return undef or a new expression
and a defined boolean value to be used in solve.

Returns either result or array reference with expression.

Any additional arguments (@rest) are passed all the time into the callback.

=cut

sub partial_solve {
    my ($self, $tree, $cb, @rest) = @_;

    my @res;

    my ($last, $ea, $skip_next) = (0, $self->{'operators'}[1], 0);
    foreach my $entry ( @$tree ) {
        $skip_next-- and next if $skip_next > 0;
        unless ( ref $entry ) {
            $ea = lc $entry;
            unless ( ref $last ) {
                $skip_next++ if
                       ( $last && $ea eq $self->{'operators'}[1])
                    || (!$last && $ea eq $self->{'operators'}[0]);
            } else {
                push @res, $entry;
            }
            next;
        }

        if ( ref $entry eq 'ARRAY' ) {
            $last = $self->solve( $entry, $cb, @rest );
            # drop parens with one condition inside
            $last = $last->[0] if ref $last && @$last == 1;
        } else {
            $last = $cb->( $entry, @rest );
            $last = $entry unless defined $last;
        }
        unless ( ref $last ) {
            if ( $ea eq $self->{'operators'}[0] ) {
                # (...) AND 0
                unless ( $last ) { @res = () } else { pop @res };
            }
            elsif ( $ea eq $self->{'operators'}[1] ) {
                # (...) OR 1
                if ( $last ) { @res = () } else { pop @res };
            }
        } else {
            push @res, $last;
        }
    }

    return $last unless @res; # solution
    return \@res; # more than one condition
}

1;

=head1 ALTERNATIVES

There are some alternative implementations available on the CPAN.

=over 4

=item L<Search::QueryParser> - similar purpose with several differences.

=item Another?

=back

=head1 AUTHORS

Ruslan Zakirov E<lt>ruz@cpan.orgE<gt>, Robert Spier E<lt>rspier@pobox.comE<gt>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
