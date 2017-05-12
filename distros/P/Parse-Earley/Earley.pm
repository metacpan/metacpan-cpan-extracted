package Parse::Earley;

#Parse::Earley
#By Luke Palmer
#Copyright (C) 2002, Luke Palmer. All rights reserved.
#This module is free software. It may used, redistributed, and/or modified
#under the terms of the Perl Artistic Licence: 
#        http://www.perl.com/perl/misc/Artistic.html

use Text::Balanced qw( extract_quotelike extract_codeblock 
                       extract_bracketed extract_multiple );
use Carp;

use strict;

our $VERSION = '0.15';
our $DEBUG;

sub new($)
{
    my $self = bless { 
        rules => { },
        sets =>  { },           # Sparse array by pos()
        set =>   [ ],           # Not an index, rather, something to be pushed
        ncset => [ ],
        skip => qr/\s*/,
        no_code => undef,
    } => shift
}

sub pushset(\$$) 
{
# rule lhs dot pos ref
    my ($self, $set) = @_;
    my $change = 0;
    for my $state (@$set) {
        my $s = $self->{sets}{$state->{pos}};
#        unless (grep { $_->{rule} == $state->{rule} &&
#                       $_->{lhs} eq $state->{lhs} &&
#                       $_->{dot} == $state->{dot} &&
#                       $_->{pos} == $state->{pos} &&
#                       $_->{ref} == $state->{ref} } 
        unless (grep { $_ == $state } 
                    @{$self->{sets}{$state->{pos}}} ) {
            push @{$self->{sets}{$state->{pos}}}, $state;
            $change++;
        }
    }
    return $change;
}

# XXX: This is a I<really> simple processor: make it better
sub grammar(\$$)
{
    my ($self, $g) = @_;
    local $_ = $g;              # XXX: Pseudo hack. I don't know why I can't
                                # extract_multiple($g, ...)
    my @toks = extract_multiple($_, [
                   qr/[a-zA-Z_]\w*\s*:/,        # LHS
                   qr/[a-zA-Z_]\w*/,            # Nonterminal
                   sub { scalar extract_quotelike($_); },
                   sub { scalar extract_bracketed($_, '<>') },
                   sub { scalar extract_codeblock($_, '{}') },
                   qr/\|/,
                   qr/#.*/m,
                   ]);
    my @rulebuf;
    my $curule;
    my $errors;
    my $noskip_f;
    my $lineno;

    for (@toks)
    {
        $lineno++ for (/\n/g);
        
        my %cp = (line => $lineno);
        if ($noskip_f) {
            $noskip_f = 0;
            %cp = (%cp, noskip => 1);
        }
        
        s/^\s+//;
        s/\s+$//;
        
        if (/^(\w+)\s*:$/) {           # LHS
            push @{$self->{rules}{$curule}}, [ @rulebuf ];
            undef @rulebuf;
            $curule = $1;
        }
        elsif (/^\|$/) {
            push @{$self->{rules}{$curule}}, [ @rulebuf ];
            undef @rulebuf;
        }
        elsif (/^(\w+)$/) {           # Nonterminal
            push @rulebuf, { %cp,
                             match => $1,
                             type => 'nonterminal' };
        }
        elsif (/^['"]/) {         # Terminal
            push @rulebuf, { %cp,
                             match => eval "$_",
                             type => 'literal' };
        }
        elsif (/^q/) {
            push @rulebuf, { %cp,
                             match => eval "$_",
                             type => 'literal' };
        }
        elsif (/^\/(.*)\/$/ || /^m.(.*).$/) {
            push @rulebuf, { %cp,
                             match => qr/$1/,
                             type => 'regex' };
        }
        elsif (/^<\s*(.*)\s*>$/) {
            my $dir = $1;
            if ($dir eq 'noskip') {
                $noskip_f = 1;
            }
            else {
                $errors .= "Unrecognized directive: <$dir> at line $lineno\n";
            }
        }
        elsif (/^{/) {
            if ($self->{no_code}) {
                $errors .= "Code not allowed\n";
            }
            elsif (@rulebuf) {
                $rulebuf[$#rulebuf]{code} = eval "sub $_";
                $errors .= "$@\n" if $@;
            }
            else {
                $errors .= "Condition does not follow anything at line $lineno\n";
            }
        }
        elsif (/^#/ || /^\s*$/) {
        }
        else {
            $errors .= "Unrecognized pattern '$_' at line $lineno\n";
        }
    }
    push @{$self->{rules}{$curule}}, [ @rulebuf ];
    if ($errors) {
        croak $errors;
    }
    else {
        return 1;
    }
}

sub start(\$$)
{
    my ($self, $rule) = @_;
    my @newset;
    $self->{sets} = { };
    $self->{set} = [ ];
    $self->{ncset} = [ ];
    for (@{$self->{rules}{$rule}}) {
        push @newset, { rule => $_,
                        lhs  => $rule,
                        dot  => 0,
                        pos  => 0,
                        ref  => 0 };
    }
    push @{$self->{ncset}}, @newset;
    $self->pushset(\@newset);
}

sub advance(\$$) 
{
    my ($self, $str) = @_;

    $self->pushset($self->{ncset}); 
    $self->{set} = $self->{ncset};
    $self->{ncset} = [ ];

    for (@{$self->{set}}) {
        #This is the main huffmanized switch. 
        #The heart of the algorithm is here.
        
        my $p = $_->{rule}[$_->{dot}];
        if ($p) {
            if ($p->{type} eq 'nonterminal') {
                $self->predict($_);
            }
            else {
                $self->scan($_, $str);
            }
        }
        else {
            $self->complete($_);
        }
    }
    
    if ($DEBUG) {
        my $displen = 7;
        my $sp = ' ' x 4;
      for (qw(set ncset)) {
        print /nc/ ? 'advance(): NEXT SET' : 'advance(): CURRENT SET';
        print "\n";
        for my $state (@{$self->{$_}}) {
            print $sp;
            my (@p);
            if ($state->{pos} < $displen) {
                $p[0] = substr($str, 0, $state->{pos});
            }
            else {
                $p[0] = substr($str, $state->{pos}-$displen, $displen);
            }
            $p[1] = substr($str, $state->{pos}, 5);
            s/(.)/ord($1)<32 || ord($1)>127 ? '.' : $1/seg for @p;
            printf "\%${displen}s * \%-${displen}s\%s", $p[0], $p[1], $sp;
            print "($state->{pos}) $state->{lhs}: ";
            for (my $i= 0; $i < @{$state->{rule}} || $i <= $state->{dot}; $i++){
                if ($state->{dot} == $i) {
                    print "* ";
                }
                if (exists $state->{rule}[$i]) {
                    my $t = $state->{rule}[$i]{type};
                    my $p = $state->{rule}[$i]{match};
                    if ($t eq 'literal') {
                        print "'$p' "
                    }
                    elsif ($t eq 'regex') {
                        $p =~ s/^.*?://;        # Get rid of the qr// stuff
                        $p =~ s/\)$//;
                        print "/$p/ "
                    
                    }
                    else {
                        print "$p ";
                    }
                }
            }
            print "($state->{ref})\n";
        }
      }
        
    }
   
}

#This function checks for matching the entire input. Sub matches
#are seldom of use, and so they are discarded (as they make the
#parse graph needlessly huge).
sub matches(\$$$)
{
    my ($self, $str, $rule) = @_;
    $str =~ s/$self->{skip}$//;
    my $cset = $self->{sets}{length($str)} or return;
    return grep { $_->{lhs} eq $rule &&
                  $_->{dot} == @{$_->{rule}} &&
                  $_->{ref} == 0 }
                          @$cset;
}

sub matches_all(\$$$)
{
    my ($self, $str, $rule) = @_;
    my $cset = $self->{ncset};
    unless (@$cset) {
        return $self->matches($str, $rule);
    }
    return;
}

sub fails(\$$$)
{
    my ($self, $str, $rule) = @_;
    if ($self->matches($str, $rule)) {
        return 0;
    }
    else {
        return @{$self->{set}} ? 0 : 1;
    }
}

sub predict(\$$) 
{
    my ($self, $state) = @_;
    my $cset = $self->{set};
    my $p = $state->{rule}[$state->{dot}];
    
    unless ($self->{rules}{$p->{match}}) {
        croak "No definition for nonterminal '$p->{match}'\n";
    }
    my @newset = @{$self->{rules}{$p->{match}}};
    @newset = map {
        my $m = $_;
        unless (grep { $_->{rule} == $m && 
                       $_->{lhs} eq $p->{match} &&
                       $_->{dot} == 0 &&
                       $_->{pos} == $state->{pos} &&
                       $_->{ref} == $state->{pos} } @$cset) {
                    { rule => $m,
                      lhs  => $p->{match},
                      dot  => 0,
                      pos  => $state->{pos},
                      ref  => $state->{pos} }
        }
        else {
            ()
        }
    } @newset;
    push @$cset, @newset;
    $self->pushset(\@newset);
}


sub scan(\$$$)
{
    my ($self, $state, $str) = @_;
    my $cset = $self->{set};
    my $skipos = $state->{pos};
    my $p = $state->{rule}[$state->{dot}]; 

    unless ($state->{rule}[$state->{dot}]{noskip}) {
        pos $str = $skipos;
        $str =~ /\G$self->{skip}/g;      # Terminal Seperator!
        $skipos = pos $str;
    }

    if ($p->{type} eq 'literal') {
        my $tok = substr($str, $skipos, length $p->{match});
        my $res = 1;
        if ($p->{code}) {
            local $_ = $tok;
            $res = eval { $p->{code}() };
            croak "$@ near line $p->{line} of grammar\n" if $@;
        }
        if ($res and $tok eq $p->{match}){
            my $push = { 
                rule => $state->{rule},
                lhs => $state->{lhs},
                dot => $state->{dot}+1,
                pos => $skipos+length $p->{match},
                ref => $state->{ref},
                tok => $tok ,
                left => [ $state ] };
            unless (grep {
                $_->{rule} == $push->{rule} &&
                $_->{lhs} eq $push->{lhs} &&
                $_->{dot} == $push->{dot} &&
                $_->{pos} == $push->{pos} &&
                $_->{ref} == $push->{ref} } @{$self->{ncset}} ) {
                    push @{$self->{ncset}}, $push;
#                    push @{$self->{sets}{$push->{pos}}}, $push;
            }
        }
    }
    elsif ($p->{type} eq 'regex') {
        pos $str = $skipos;
        if ($str =~ /\G($p->{match})/g) {
            my $tok = $1;
            if ($p->{code}) {
                local $_ = $tok;
                my $res = eval { $p->{code}() };
                croak "$@ near line $p->{line} of grammar\n" if $@;
                return unless $res;     # Should make this some sort of break
            }
            my $push = {
                rule => $state->{rule},
                lhs => $state->{lhs},
                dot => $state->{dot}+1,
                pos => pos $str,
                ref => $state->{ref},
                tok => $tok,
                left => [ $state ] };
            unless (grep {
                $_->{rule} == $push->{rule} &&
                $_->{lhs} eq $push->{lhs} &&
                $_->{dot} == $push->{dot} &&
                $_->{pos} == $push->{pos} &&
                $_->{ref} == $push->{ref} } @{$self->{ncset}} ) {
                    push @{$self->{ncset}}, $push;
                    push @{$self->{sets}{$push->{pos}}}, $push;
            }
        }
    }
}

sub complete(\$$)
{
    my ($self, $state) = @_;
    my $cset = $self->{set};
    my @newset = grep { 
                    (exists $_->{rule}[$_->{dot}] && 
                     $_->{rule}[$_->{dot}]{match}) eq $state->{lhs} }
                    @{$self->{sets}{$state->{ref}}};
    my @reval;
    @newset = map { 
        my $m = $_;
        my @g;
        unless (@g = grep { $_->{rule} == $m->{rule} && 
                       $_->{lhs} eq $m->{lhs} &&
                       $_->{dot} == $m->{dot}+1 &&
                       $_->{pos} == $state->{pos} &&
                       $_->{ref} == $m->{ref} } @$cset) {
            
                    my $push = { rule => $m->{rule},
                                 lhs  => $m->{lhs},
                                 dot  => $m->{dot}+1,
                                 pos  => $state->{pos},
                                 ref  => $m->{ref},
                                 down => [ $state ],
                                 left => [ $m ],
                               };
                    if ($m->{rule}[$m->{dot}]{code}) {
                        local $_ = $state;
                        my $res = eval { $m->{rule}[$m->{dot}]{code}() };
                        croak "$@ near line $m->{rule}[$m->{dot}]{line} "
                             ."of grammar\n" if $@;
                        $res ? $push : ()
                    }
                    else {
                        $push
                    }
        }
        else {
            for (@g) {
                unless (grep { $_ == $state } @{$_->{down}} and 
                        grep { $_ == $m } @{$_->{left}}) {
                    my $succ = 1;
                    if ($m->{rule}[$m->{dot}]{code}) {
                        my $left;
                        local $_ = $state;
                        $succ = eval { $m->{rule}[$m->{dot}]{code}() };
                        croak "$@ near line $m->{rule}[$m->{dot}]{line} "
                             ."of grammar\n" if $@;
                    }
                    if ($succ) {
                        push @{$_->{down}}, $state;
                        push @{$_->{left}}, $m;
                    }
                }
            }
            ()
        }
    } @newset;
    push @$cset, @newset;
    $self->pushset(\@newset);
}

1;

__END__

=pod

=head1 NAME

Parse::Earley - Parse I<any> Context-Free Grammar

=head1 VERSION

Parse::Earley version 0.15, July 24, 2002.  I first began work on this module
on July 17, 2002.

=head1 SYNOPSIS

  use Parse::Earley;

  $parser = new Parse::Earley;

  # Set the grammar rules to those specified in $grammar
  $parser->grammar($grammar);

  # Initialize the parser state
  $parser->start('mystartrule');

  while (1) {
    # Advance the parser state to the next token of $str
    $parser->advance($str);
    print "Parse failed" if $parser->fails($str, 'mystartrule');
    print "Parse succeeded" if $parser->matches($str, 'mystartrule');
  }

  # Get parse graph
  ($tree) = $parser->matches($str, 'mystartrule');

=head1 DESCRIPTION 

=head2 Overview

Parse::Earley accepts or rejects a string based on I<any> Context-Free grammar,
specified by a simplified I<yacc>-like specification. It provides:

=over 4

=item @

Regular expressions or literal strings as terminals,

=item @

Multiple (non-contiguous) productions for any rule,

=item @

The ability to extract all possible parse trees for a given input string (the
parse graph),

=item @

Incremental extention of the parsing grammar (I<especially> during a parse),

=item @

Boolean selection of whether a rule succeeds (but not return values).

=item @

(And the big win, once again) The ability to use I<any> Context-Free Grammar
you choose.

=back

=head2 Comparison

When should you use Parse::Earley instead of Parse::RecDescent or Parse::Yapp?

=over 4

=item @

When you need to match extremely complex and ambiguous grammars (for instance,
a natural language :),

=item @

When you need all the possible parse trees, not just the left- or right-most.

=back

That's surprisingly few.  That's because Earley's algorithm is not economical
for most causes regarding Context-Free Grammars.  It runs in cubic time (that's
slow) for any grammar, and quadratic time for unambiguous grammars.

However, there are no restrictions on the grammar whatsoever.  This makes it
one of the most popular algorithms for natural language processing.  Not to
mention, it runs quickly (sometimes moreso than RecDescent or Yapp) if the
size of the input is sufficiently small.

=head2 Using Parse::Earley

You can create a parser object with the C<Parse::Earley::new> function. It
accepts no arguments; it just prepares the state of the parser so you can do
more with it.  This creation should always succeed.

Next, you should prime it with a grammar.  Store the specification in a string,
and pass it to the C<grammar> method. The exact syntax of grammars will be
discussed shortly.  If you call C<grammar> later, it extends the current
grammar to include the new rules.

And there's just one more thing to do: Initialize the parser state with a
start rule. Just call the C<start> method, passing it the name of the rule 
with which to initialize the parser.

Now you can start matching the input string, by repeatedly calling the
C<advance> method. Each call advances the input by one token, in hope of someday
allowing clean introspection.

The methods C<matched> and C<failed> check whether the parser accepts or rejects
the input. Note that these can both be false (though they cannot both be true),
and always are in the middle of parsing.  C<matched_all> checks whether the
input match, and that no more parses are still possible; C<matched_all> is
more restrictive than C<matched>.

The C<matched> and C<matched_all> functions, if true, return a list of complete
states. You can use these to extract the parse graph, as discussed later.

=head2 Rules

Considering the early version, and the fact that I don't like hand-made parsers,
the grammar specification is quite simple.  It is I<mostly> free-form.  The
only restriction is that productions must start in column 0, and nothing
else (except comments) can.

Terminals can be specified using single- or double- quoted strings, as well as
the q[] construct (with any delimiters).  They can also be specified with a
regular expression, using the usual /regex/ syntax, or the m|syntax| (with
any delimiters). You cannot use # as a delimiter, because of the simple comment
processing.

However, keep away from the null string ''. Because of the way C<Parse::Earley>
stores its states, this will not work the way you want.  This includes regexes
that will match nothing successfully.  Just use a null rule alternated with
an always-matching pattern.

Unlike C<Parse::RecDescent>, no interpolation happens.  But code conditions
are still evaluated at runtime, however, their return value is only evaluated
for truth, and not stored or pointed to.  This may change in a future release.

Here's an example grammar of a simple calculator expression
supporting +, -, *, /, and () grouping; it will only match values that will
fit in one byte:

    input: expr         # this represents the entire input
    
    expr:  mul_expr '+' expr
        |  mul_expr '-' expr
    
    # This is higher precedence.
    mul_expr:  term q<*> mul_expr
            |  term q|/| mul_expr

    term: '(' expr ')'  |  /\d+/  { $_ < 256 }

In that example you have seen all the features of the grammar specification.

=head2 Conditions

Above you saw the condition C< { $_ < 256 } >.  If the condition is after
a terminal, C<$_> is set to the text matched by the terminal.  If it's
after a nonterminal, C<$_> is set to the parse graph rooted at the nonterminal
it follows. This parse graph will only be as complete as it can at that point
in the input. You should have to use the latter form.

Keep in mind that conditions are fundamentally different from actions.  You
can't use them to build a parse tree, because their return values are only
boolean.  They're there only to promote conditional matching of a rule,
for instance, to see whether a particular word is an adjective.

If security is a concern, you may set the value C<< $parser->{no_code} >> to
disable conditions,  where C<$parser> is the parser object.  You would do
this if you allowed web users (like I do) to input their own grammars.

=head2 Terminal Separators

C<Parse::Earley> now supports terminal seperators; that is, a pattern that
is implicitly matched before each rule.  If the directive <noskip> appears
before a terminal, the terminal seperator is ignored for that match.
However, this doesn't propigate (yet), so you have to put it before a terminal,
otherwise it doesn't do any good.

The terminal seperator can be set with C<< $parser->{skip} >>.  It's a regular
expression.  It defaults to C<qr/\s*/>.

=head2 The Parse Graph

Now, as useful as checking whether a certain string can be generated is, some
people want to know I<how>. Well, the parse graph tells you all ways you can
possibly generate it.

First, after you've successfully matched an input string, get the matching
parser state with the C<matched> function. C<matched> returns an array, though
there's usually only one such state.  So, just listify your variable:

  ($graph) = $parser->matched($input, 'mystartrule');

or

  ($graph) = $parser->matched_all($input, 'mystartrule');

if you want to be sure that you have all possible ways of matching.

Of course, you should get the whole list if you're really trying to be robust.
Each element refers to a different way to match the start rule. This may
change in the future to a "dummy state" that has it's C<down> and C<left>
set up appropriately.

C<$graph> should now have a parser state in it, but only if the input was 
accepted.  If not, C<$graph> will be C<undef>.

C<$graph> is a reference to a hash that has many things inside it, specifically 
everything the parser needs to know about this rule at this position.  But
you're probably only interested in the array refs C<< $graph->{left} >>,
C<< $graph->{down} >>, and the scalars C<< $graph->{tok} >> and 
C<< $graph->{lhs} >>.

You traverse the parse graph backwards. If you're wondering why, it's because
this is the only way to allow all possible parses in the same data structure.
So you start at the end, and move C<< $graph->{left} >> along it. If 
C<< $graph->{left} >> has more than one element, those are possible 
alternatives at that point.

Essentially, C<< $graph->{left} >> will move you backwards down the same 
production.

You'd also like to move down the tree, not just sideways. That's what
C<< $graph->{down} >> is for. It allows you to introspect inside a nonterminal
to see what reduced to it.  When you go C<< $graph->{down} >>, you end up at
the I<end> of the nonterminal's production.  If << $graph->{down} >> has more 
than one element, each corresponds to the same path as that index in the
<< $graph->{left} >> array.

C<< $graph->{tok} >> is the actual text matched if the current state (or
"node") refers to a terminal.

C<< $graph->{lhs} >> is the name of the nonterminal that this state is 
attached to.

C<< $graph->{tag} >> may eventually be added, to differentiate between two rules
with the same C<lhs>.

Parallel choices are given in canonical order, so if you want the leftmost tree,
you always traverse C<< $tree->{left}[0] >> and C<< $tree->{down}[0] >>.  
Along the same lines, the rightmost tree is given by the last element in each 
array.

=head2 The Debugger

If the package variable C<$Parse::Earley::DEBUG> is true, then after each state,
C<Parse::Earley> will output a summary of it's current state. For the following
grammar:

    S: E
    E: E '+' T  |  T
    T: /\d+/

And the following input:

    1 + 2 + 3
    
After matching the first '+', the  debugger output would look like this:

    advance(): CURRENT SET
            1 + *  2 +       (3) E: E '+' * T (0)
            1 + *  2 +       (3) T: * /\d+/ (3)
    advance(): NEXT SET
         1 + 2 *  + 3        (5) T: /\d+/ * (3)

If you are familiar with Earley's algorithm, this probably already makes sense
to you.  If not, it's pretty simple:

CURRENT SET represents what the parsers current state is.  NEXT SET says
what the parser will start with for the next token it matches.

The left side is a portion of the input, with a * stuck in there.  The *
represents where the parser is in the input.  If you're tricky, you can
create a grammar where rules in the same set have different input positions,
but that's usually not the case.

The right side has a lot of information.  The number in parentheses on the
left displays the current input position, in numbers.  The one on the right
says where the rule in between them started (I should probably switch the
two).  In between, you see the definition of the rule, with another *
stuck in there.  This represents how much of the rule we've currently matched.

It's kinda fun to enable C<DEBUG>, and put a <STDIN> after each
C<advance>. You can keep hitting enter and watch the parser progress.

=head2 Performance Issues

What if the parser's too slow?  Well, there's one thing that I know of at
this point that can speed it up: left recursion.  Unlike C<Parse::RecDescent>,
C<Parse::Earley> can handle left recursion... and it actually prefers it.
If you can optimize your recursive rules to left recursive, you will see
a significant performance increase, though it does change how your parse
graph is ordered.

=head2 Future Versions

This is a useful module, but it is definitely minimalist.  In future versions
I expect to add:

=over 4

=item @

A <commit> directive, to remove extraneous states if the current one matches.
This could be a profound performance boost.

=item @

Perhaps change I<condition> to I<action>, in that, I could store return values.
This could be misleading, however, because if you tried syntax-directed 
translation, you'd be traversing all the parse trees simultaneously.

=item @

Add m//X modifiers on matches.  Right now it is a syntax error to specify
C</foo/i> in a rule.

=item @

A lookahead string to improve performance, as specified in Jay Earley's
paper.

=back

Among many other things.

=head1 BUGS

There are undoubtedly bugs.  I'm open to bug reports and patches.  I'll 
get around to making the source more readable, so people can actually write
patches. 

Mail all of that to fibonaci@babylonia.flatirons.org

=head1 AUTHORS

Luke Palmer wrote the module and the documentation.

Jay Earley is the author of B<An Efficient Context-Free Parsing Algorithm.>
Communications of the ACM, 1970.

Damian Conway wrote Parse::RecDescent, which gave me the inspiration to take
this on.  The documentation for that module was also used as a loose template
for this one.

=head1 COPYRIGHT

Copyright (C) 2002, Luke Palmer. All rights reserved. This module is free
software. It may be used, redistributed and/or modified under the terms
of the Perl Artistic License 
        (http://www.perl.com/perl/misc/Artistic.html)
