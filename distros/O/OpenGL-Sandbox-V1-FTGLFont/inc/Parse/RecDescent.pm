# GENERATE RECURSIVE DESCENT PARSER OBJECTS FROM A GRAMMAR

use 5.006;
use strict;

package Parse::RecDescent;

use Text::Balanced qw ( extract_codeblock extract_bracketed extract_quotelike extract_delimited );

use vars qw ( $skip );

   *defskip  = \ '\s*'; # DEFAULT SEPARATOR IS OPTIONAL WHITESPACE
   $skip  = '\s*';      # UNIVERSAL SEPARATOR IS OPTIONAL WHITESPACE
my $MAXREP  = 100_000_000;  # REPETITIONS MATCH AT MOST 100,000,000 TIMES


#ifndef RUNTIME
sub import  # IMPLEMENT PRECOMPILER BEHAVIOUR UNDER:
        #    perl -MParse::RecDescent - <grammarfile> <classname>
{
    local *_die = sub { print @_, "\n"; exit };

    my ($package, $file, $line) = caller;

    if ($file eq '-' && $line == 0)
    {
        _die("Usage: perl -MLocalTest - <grammarfile> <classname>")
            unless @ARGV == 2;

        my ($sourcefile, $class) = @ARGV;

        local *IN;
        open IN, $sourcefile
            or _die(qq{Can't open grammar file "$sourcefile"});
        local $/; #
        my $grammar = <IN>;
        close IN;

        Parse::RecDescent->Precompile($grammar, $class, $sourcefile);
        exit;
    }
}

sub Save
{
    my $self = shift;
    my %opt;
    if ('HASH' eq ref $_[0]) {
        %opt = (%opt, %{$_[0]});
        shift;
    }
    my ($class) = @_;
    $self->{saving} = 1;
    $self->Precompile(undef,$class);
    $self->{saving} = 0;
}

sub Precompile
{
    my $self = shift;
    my %opt = ( -standalone => 0 );
    if ('HASH' eq ref $_[0]) {
        %opt = (%opt, %{$_[0]});
        shift;
    }
    my ($grammar, $class, $sourcefile) = @_;

    $class =~ /^(\w+::)*\w+$/ or croak("Bad class name: $class");

    my $modulefile = $class;
    $modulefile =~ s/.*:://;
    $modulefile .= ".pm";

    my $runtime_package = 'Parse::RecDescent::_Runtime';
    my $code;

    local *OUT;
    open OUT, ">", $modulefile
      or croak("Can't write to new module file '$modulefile'");

    print STDERR "precompiling grammar from file '$sourcefile'\n",
      "to class $class in module file '$modulefile'\n"
      if $grammar && $sourcefile;

    # Make the resulting pre-compiled parser stand-alone by
    # including the contents of Parse::RecDescent as
    # Parse::RecDescent::Runtime in the resulting precompiled
    # parser.
    if ($opt{-standalone}) {
        local *IN;
        open IN, '<', $Parse::RecDescent::_FILENAME
          or croak("Can't open $Parse::RecDescent::_FILENAME for standalone pre-compilation: $!\n");
        my $exclude = 0;
        print OUT "{\n";
        while (<IN>) {
            if ($_ =~ /^\s*#\s*ifndef\s+RUNTIME\s*$/) {
                ++$exclude;
            }
            if ($exclude) {
                if ($_ =~ /^\s*#\s*endif\s$/) {
                    --$exclude;
                }
            } else {
                if ($_ =~ m/^__END__/) {
                    last;
                }
                s/Parse::RecDescent/$runtime_package/gs;
                print OUT $_;
            }
        }
        close IN;
        print OUT "}\n";
    }

    $self = Parse::RecDescent->new($grammar,  # $grammar
                                   1,         # $compiling
                                   $class     # $namespace
                             )
      || croak("Can't compile bad grammar")
      if $grammar;

    # Do not allow &DESTROY to remove the precompiled namespace
    delete $self->{_not_precompiled};

    foreach ( keys %{$self->{rules}} ) {
        $self->{rules}{$_}{changed} = 1;
    }


    print OUT "package $class;\n";
    if (not $opt{-standalone}) {
        print OUT "use Parse::RecDescent;\n";
    }

    print OUT "{ my \$ERRORS;\n\n";

    $code = $self->_code();
    if ($opt{-standalone}) {
        $code =~ s/Parse::RecDescent/$runtime_package/gs;
    }
    print OUT $code;

    print OUT "}\npackage $class; sub new { ";
    print OUT "my ";

    require Data::Dumper;
    $code = Data::Dumper->Dump([$self], [qw(self)]);
    if ($opt{-standalone}) {
        $code =~ s/Parse::RecDescent/$runtime_package/gs;
    }
    print OUT $code;

    print OUT "}";

    close OUT
      or croak("Can't write to new module file '$modulefile'");
}
#endif

package Parse::RecDescent::LineCounter;


sub TIESCALAR   # ($classname, \$text, $thisparser, $prevflag)
{
    bless {
        text    => $_[1],
        parser  => $_[2],
        prev    => $_[3]?1:0,
          }, $_[0];
}

sub FETCH
{
    my $parser = $_[0]->{parser};
    my $cache = $parser->{linecounter_cache};
    my $from = $parser->{fulltextlen}-length(${$_[0]->{text}})-$_[0]->{prev}
;

    unless (exists $cache->{$from})
    {
        $parser->{lastlinenum} = $parser->{offsetlinenum}
          - Parse::RecDescent::_linecount(substr($parser->{fulltext},$from))
          + 1;
        $cache->{$from} = $parser->{lastlinenum};
    }
    return $cache->{$from};
}

sub STORE
{
    my $parser = $_[0]->{parser};
    $parser->{offsetlinenum} -= $parser->{lastlinenum} - $_[1];
    return undef;
}

sub resync   # ($linecounter)
{
    my $self = tied($_[0]);
    die "Tried to alter something other than a LineCounter\n"
        unless $self =~ /Parse::RecDescent::LineCounter/;

    my $parser = $self->{parser};
    my $apparently = $parser->{offsetlinenum}
             - Parse::RecDescent::_linecount(${$self->{text}})
             + 1;

    $parser->{offsetlinenum} += $parser->{lastlinenum} - $apparently;
    return 1;
}

package Parse::RecDescent::ColCounter;

sub TIESCALAR   # ($classname, \$text, $thisparser, $prevflag)
{
    bless {
        text    => $_[1],
        parser  => $_[2],
        prev    => $_[3]?1:0,
          }, $_[0];
}

sub FETCH
{
    my $parser = $_[0]->{parser};
    my $missing = $parser->{fulltextlen}-length(${$_[0]->{text}})-$_[0]->{prev}+1;
    substr($parser->{fulltext},0,$missing) =~ m/^(.*)\Z/m;
    return length($1);
}

sub STORE
{
    die "Can't set column number via \$thiscolumn\n";
}


package Parse::RecDescent::OffsetCounter;

sub TIESCALAR   # ($classname, \$text, $thisparser, $prev)
{
    bless {
        text    => $_[1],
        parser  => $_[2],
        prev    => $_[3]?-1:0,
          }, $_[0];
}

sub FETCH
{
    my $parser = $_[0]->{parser};
    return $parser->{fulltextlen}-length(${$_[0]->{text}})+$_[0]->{prev};
}

sub STORE
{
    die "Can't set current offset via \$thisoffset or \$prevoffset\n";
}



package Parse::RecDescent::Rule;

sub new ($$$$$)
{
    my $class = ref($_[0]) || $_[0];
    my $name  = $_[1];
    my $owner = $_[2];
    my $line  = $_[3];
    my $replace = $_[4];

    if (defined $owner->{"rules"}{$name})
    {
        my $self = $owner->{"rules"}{$name};
        if ($replace && !$self->{"changed"})
        {
            $self->reset;
        }
        return $self;
    }
    else
    {
        return $owner->{"rules"}{$name} =
            bless
            {
                "name"     => $name,
                "prods"    => [],
                "calls"    => [],
                "changed"  => 0,
                "line"     => $line,
                "impcount" => 0,
                "opcount"  => 0,
                "vars"     => "",
            }, $class;
    }
}

sub reset($)
{
    @{$_[0]->{"prods"}} = ();
    @{$_[0]->{"calls"}} = ();
    $_[0]->{"changed"}  = 0;
    $_[0]->{"impcount"}  = 0;
    $_[0]->{"opcount"}  = 0;
    $_[0]->{"vars"}  = "";
}

sub DESTROY {}

sub hasleftmost($$)
{
    my ($self, $ref) = @_;

    my $prod;
    foreach $prod ( @{$self->{"prods"}} )
    {
        return 1 if $prod->hasleftmost($ref);
    }

    return 0;
}

sub leftmostsubrules($)
{
    my $self = shift;
    my @subrules = ();

    my $prod;
    foreach $prod ( @{$self->{"prods"}} )
    {
        push @subrules, $prod->leftmostsubrule();
    }

    return @subrules;
}

sub expected($)
{
    my $self = shift;
    my @expected = ();

    my $prod;
    foreach $prod ( @{$self->{"prods"}} )
    {
        my $next = $prod->expected();
        unless (! $next or _contains($next,@expected) )
        {
            push @expected, $next;
        }
    }

    return join ', or ', @expected;
}

sub _contains($@)
{
    my $target = shift;
    my $item;
    foreach $item ( @_ ) { return 1 if $target eq $item; }
    return 0;
}

sub addcall($$)
{
    my ( $self, $subrule ) = @_;
    unless ( _contains($subrule, @{$self->{"calls"}}) )
    {
        push @{$self->{"calls"}}, $subrule;
    }
}

sub addprod($$)
{
    my ( $self, $prod ) = @_;
    push @{$self->{"prods"}}, $prod;
    $self->{"changed"} = 1;
    $self->{"impcount"} = 0;
    $self->{"opcount"} = 0;
    $prod->{"number"} = $#{$self->{"prods"}};
    return $prod;
}

sub addvar
{
    my ( $self, $var, $parser ) = @_;
    if ($var =~ /\A\s*local\s+([%@\$]\w+)/)
    {
        $parser->{localvars} .= " $1";
        $self->{"vars"} .= "$var;\n" }
    else
        { $self->{"vars"} .= "my $var;\n" }
    $self->{"changed"} = 1;
    return 1;
}

sub addautoscore
{
    my ( $self, $code ) = @_;
    $self->{"autoscore"} = $code;
    $self->{"changed"} = 1;
    return 1;
}

sub nextoperator($)
{
    my $self = shift;
    my $prodcount = scalar @{$self->{"prods"}};
    my $opcount = ++$self->{"opcount"};
    return "_operator_${opcount}_of_production_${prodcount}_of_rule_$self->{name}";
}

sub nextimplicit($)
{
    my $self = shift;
    my $prodcount = scalar @{$self->{"prods"}};
    my $impcount = ++$self->{"impcount"};
    return "_alternation_${impcount}_of_production_${prodcount}_of_rule_$self->{name}";
}


sub code
{
    my ($self, $namespace, $parser, $check) = @_;

eval 'undef &' . $namespace . '::' . $self->{"name"} unless $parser->{saving};

    my $code =
'
# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub ' . $namespace . '::' . $self->{"name"} .  '
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"' . $self->{"name"} . '"};

    Parse::RecDescent::_trace(q{Trying rule: [' . $self->{"name"} . ']},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{' . $self->{"name"} . '},
                  $tracelevel)
                    if defined $::RD_TRACE;

    ' . ($parser->{deferrable}
        ? 'my $def_at = @{$thisparser->{deferred}};'
        : '') .
    '
    my $err_at = @{$thisparser->{errors}};

    my $score;
    my $score_return;
    my $_tok;
    my $return = undef;
    my $_matched=0;
    my $commit=0;
    my @item = ();
    my %item = ();
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{' . $self->expected() . '});
    $expectation->at($_[1]);
    '. ($parser->{_check}{thisoffset}?'
    my $thisoffset;
    tie $thisoffset, q{Parse::RecDescent::OffsetCounter}, \$text, $thisparser;
    ':'') . ($parser->{_check}{prevoffset}?'
    my $prevoffset;
    tie $prevoffset, q{Parse::RecDescent::OffsetCounter}, \$text, $thisparser, 1;
    ':'') . ($parser->{_check}{thiscolumn}?'
    my $thiscolumn;
    tie $thiscolumn, q{Parse::RecDescent::ColCounter}, \$text, $thisparser;
    ':'') . ($parser->{_check}{prevcolumn}?'
    my $prevcolumn;
    tie $prevcolumn, q{Parse::RecDescent::ColCounter}, \$text, $thisparser, 1;
    ':'') . ($parser->{_check}{prevline}?'
    my $prevline;
    tie $prevline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser, 1;
    ':'') . '
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    '. $self->{vars} .'
';

    my $prod;
    foreach $prod ( @{$self->{"prods"}} )
    {
        $prod->addscore($self->{autoscore},0,0) if $self->{autoscore};
        next unless $prod->checkleftmost();
        $code .= $prod->code($namespace,$self,$parser);

        $code .= $parser->{deferrable}
                ? '     splice
                @{$thisparser->{deferred}}, $def_at unless $_matched;
                  '
                : '';
    }

    $code .=
'
    unless ( $_matched || defined($score) )
    {
        ' .($parser->{deferrable}
            ? '     splice @{$thisparser->{deferred}}, $def_at;
              '
            : '') . '

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<'.Parse::RecDescent::_matchtracemessage($self,1).' rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{' . $self->{"name"} .'},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{' . $self->{"name"} .'},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $return = $score_return;
    }
    splice @{$thisparser->{errors}}, $err_at;
    $return = $item[$#item] unless defined $return;
    if (defined $::RD_TRACE)
    {
        Parse::RecDescent::_trace(q{>>'.Parse::RecDescent::_matchtracemessage($self).' rule<< (return value: [} .
                      $return . q{])}, "",
                      q{' . $self->{"name"} .'},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{' . $self->{"name"} .'},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}
';

    return $code;
}

my @left;
sub isleftrec($$)
{
    my ($self, $rules) = @_;
    my $root = $self->{"name"};
    @left = $self->leftmostsubrules();
    my $next;
    foreach $next ( @left )
    {
        next unless defined $rules->{$next}; # SKIP NON-EXISTENT RULES
        return 1 if $next eq $root;
        my $child;
        foreach $child ( $rules->{$next}->leftmostsubrules() )
        {
            push(@left, $child)
            if ! _contains($child, @left) ;
        }
    }
    return 0;
}

package Parse::RecDescent::Production;

sub describe ($;$)
{
    return join ' ', map { $_->describe($_[1]) or () } @{$_[0]->{items}};
}

sub new ($$;$$)
{
    my ($self, $line, $uncommit, $error) = @_;
    my $class = ref($self) || $self;

    bless
    {
        "items"    => [],
        "uncommit" => $uncommit,
        "error"    => $error,
        "line"     => $line,
        strcount   => 0,
        patcount   => 0,
        dircount   => 0,
        actcount   => 0,
    }, $class;
}

sub expected ($)
{
    my $itemcount = scalar @{$_[0]->{"items"}};
    return ($itemcount) ? $_[0]->{"items"}[0]->describe(1) : '';
}

sub hasleftmost ($$)
{
    my ($self, $ref) = @_;
    return ${$self->{"items"}}[0] eq $ref  if scalar @{$self->{"items"}};
    return 0;
}

sub isempty($)
{
    my $self = shift;
    return 0 == @{$self->{"items"}};
}

sub leftmostsubrule($)
{
    my $self = shift;

    if ( $#{$self->{"items"}} >= 0 )
    {
        my $subrule = $self->{"items"}[0]->issubrule();
        return $subrule if defined $subrule;
    }

    return ();
}

sub checkleftmost($)
{
    my @items = @{$_[0]->{"items"}};
    if (@items==1 && ref($items[0]) =~ /\AParse::RecDescent::Error/
        && $items[0]->{commitonly} )
    {
        Parse::RecDescent::_warn(2,"Lone <error?> in production treated
                        as <error?> <reject>");
        Parse::RecDescent::_hint("A production consisting of a single
                      conditional <error?> directive would
                      normally succeed (with the value zero) if the
                      rule is not 'commited' when it is
                      tried. Since you almost certainly wanted
                      '<error?> <reject>' Parse::RecDescent
                      supplied it for you.");
        push @{$_[0]->{items}},
            Parse::RecDescent::UncondReject->new(0,0,'<reject>');
    }
    elsif (@items==1 && ($items[0]->describe||"") =~ /<rulevar|<autoscore/)
    {
        # Do nothing
    }
    elsif (@items &&
        ( ref($items[0]) =~ /\AParse::RecDescent::UncondReject/
        || ($items[0]->describe||"") =~ /<autoscore/
        ))
    {
        Parse::RecDescent::_warn(1,"Optimizing away production: [". $_[0]->describe ."]");
        my $what = $items[0]->describe =~ /<rulevar/
                ? "a <rulevar> (which acts like an unconditional <reject> during parsing)"
             : $items[0]->describe =~ /<autoscore/
                ? "an <autoscore> (which acts like an unconditional <reject> during parsing)"
                : "an unconditional <reject>";
        my $caveat = $items[0]->describe =~ /<rulevar/
                ? " after the specified variable was set up"
                : "";
        my $advice = @items > 1
                ? "However, there were also other (useless) items after the leading "
                  . $items[0]->describe
                  . ", so you may have been expecting some other behaviour."
                : "You can safely ignore this message.";
        Parse::RecDescent::_hint("The production starts with $what. That means that the
                      production can never successfully match, so it was
                      optimized out of the final parser$caveat. $advice");
        return 0;
    }
    return 1;
}

sub changesskip($)
{
    my $item;
    foreach $item (@{$_[0]->{"items"}})
    {
        if (ref($item) =~ /Parse::RecDescent::(Action|Directive)/)
        {
            return 1 if $item->{code} =~ /\$skip\s*=/;
        }
    }
    return 0;
}

sub adddirective
{
    my ( $self, $whichop, $line, $name ) = @_;
    push @{$self->{op}},
        { type=>$whichop, line=>$line, name=>$name,
          offset=> scalar(@{$self->{items}}) };
}

sub addscore
{
    my ( $self, $code, $lookahead, $line ) = @_;
    $self->additem(Parse::RecDescent::Directive->new(
                  "local \$^W;
                   my \$thisscore = do { $code } + 0;
                   if (!defined(\$score) || \$thisscore>\$score)
                    { \$score=\$thisscore; \$score_return=\$item[-1]; }
                   undef;", $lookahead, $line,"<score: $code>") )
        unless $self->{items}[-1]->describe =~ /<score/;
    return 1;
}

sub check_pending
{
    my ( $self, $line ) = @_;
    if ($self->{op})
    {
        while (my $next = pop @{$self->{op}})
        {
        Parse::RecDescent::_error("Incomplete <$next->{type}op:...>.", $line);
        Parse::RecDescent::_hint(
            "The current production ended without completing the
             <$next->{type}op:...> directive that started near line
             $next->{line}. Did you forget the closing '>'?");
        }
    }
    return 1;
}

sub enddirective
{
    my ( $self, $line, $minrep, $maxrep ) = @_;
    unless ($self->{op})
    {
        Parse::RecDescent::_error("Unmatched > found.", $line);
        Parse::RecDescent::_hint(
            "A '>' angle bracket was encountered, which typically
             indicates the end of a directive. However no suitable
             preceding directive was encountered. Typically this
             indicates either a extra '>' in the grammar, or a
             problem inside the previous directive.");
        return;
    }
    my $op = pop @{$self->{op}};
    my $span = @{$self->{items}} - $op->{offset};
    if ($op->{type} =~ /left|right/)
    {
        if ($span != 3)
        {
        Parse::RecDescent::_error(
            "Incorrect <$op->{type}op:...> specification:
             expected 3 args, but found $span instead", $line);
        Parse::RecDescent::_hint(
            "The <$op->{type}op:...> directive requires a
             sequence of exactly three elements. For example:
             <$op->{type}op:leftarg /op/ rightarg>");
        }
        else
        {
        push @{$self->{items}},
            Parse::RecDescent::Operator->new(
                $op->{type}, $minrep, $maxrep, splice(@{$self->{"items"}}, -3));
        $self->{items}[-1]->sethashname($self);
        $self->{items}[-1]{name} = $op->{name};
        }
    }
}

sub prevwasreturn
{
    my ( $self, $line ) = @_;
    unless (@{$self->{items}})
    {
        Parse::RecDescent::_error(
            "Incorrect <return:...> specification:
            expected item missing", $line);
        Parse::RecDescent::_hint(
            "The <return:...> directive requires a
            sequence of at least one item. For example:
            <return: list>");
        return;
    }
    push @{$self->{items}},
        Parse::RecDescent::Result->new();
}

sub additem
{
    my ( $self, $item ) = @_;
    $item->sethashname($self);
    push @{$self->{"items"}}, $item;
    return $item;
}

sub _duplicate_itempos
{
    my ($src) = @_;
    my $dst = {};

    foreach (keys %$src)
    {
        %{$dst->{$_}} = %{$src->{$_}};
    }
    $dst;
}

sub _update_itempos
{
    my ($dst, $src, $typekeys, $poskeys) = @_;

    my @typekeys = 'ARRAY' eq ref $typekeys ?
      @$typekeys :
      keys %$src;

    foreach my $k (keys %$src)
    {
        if ('ARRAY' eq ref $poskeys)
        {
            @{$dst->{$k}}{@$poskeys} = @{$src->{$k}}{@$poskeys};
        }
        else
        {
            %{$dst->{$k}} = %{$src->{$k}};
        }
    }
}

sub preitempos
{
    return q
    {
        push @itempos, {'offset' => {'from'=>$thisoffset, 'to'=>undef},
                        'line'   => {'from'=>$thisline,   'to'=>undef},
                        'column' => {'from'=>$thiscolumn, 'to'=>undef} };
    }
}

sub incitempos
{
    return q
    {
        $itempos[$#itempos]{'offset'}{'from'} += length($lastsep);
        $itempos[$#itempos]{'line'}{'from'}   = $thisline;
        $itempos[$#itempos]{'column'}{'from'} = $thiscolumn;
    }
}

sub unincitempos
{
    # the next incitempos will properly set these two fields, but
    # {'offset'}{'from'} needs to be decreased by length($lastsep)
    # $itempos[$#itempos]{'line'}{'from'}
    # $itempos[$#itempos]{'column'}{'from'}
    return q
    {
        $itempos[$#itempos]{'offset'}{'from'} -= length($lastsep) if defined $lastsep;
    }
}

sub postitempos
{
    return q
    {
        $itempos[$#itempos]{'offset'}{'to'} = $prevoffset;
        $itempos[$#itempos]{'line'}{'to'}   = $prevline;
        $itempos[$#itempos]{'column'}{'to'} = $prevcolumn;
    }
}

sub code($$$$)
{
    my ($self,$namespace,$rule,$parser) = @_;
    my $code =
'
    while (!$_matched'
    . (defined $self->{"uncommit"} ? '' : ' && !$commit')
    . ')
    {
        ' .
        ($self->changesskip()
            ? 'local $skip = defined($skip) ? $skip : $Parse::RecDescent::skip;'
            : '') .'
        Parse::RecDescent::_trace(q{Trying production: ['
                      . $self->describe . ']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{' . $rule ->{name}. '},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[' . $self->{"number"} . '];
        ' . (defined $self->{"error"} ? '' : '$text = $_[1];' ) . '
        my $_savetext;
        @item = (q{' . $rule->{"name"} . '});
        %item = (__RULE__ => q{' . $rule->{"name"} . '});
        my $repcount = 0;

';
    $code .=
'        my @itempos = ({});
'           if $parser->{_check}{itempos};

    my $item;
    my $i;

    for ($i = 0; $i < @{$self->{"items"}}; $i++)
    {
        $item = ${$self->{items}}[$i];

        $code .= preitempos() if $parser->{_check}{itempos};

        $code .= $item->code($namespace,$rule,$parser->{_check});

        $code .= postitempos() if $parser->{_check}{itempos};

    }

    if ($parser->{_AUTOACTION} && defined($item) && !$item->isa("Parse::RecDescent::Action"))
    {
        $code .= $parser->{_AUTOACTION}->code($namespace,$rule);
        Parse::RecDescent::_warn(1,"Autogenerating action in rule
                       \"$rule->{name}\":
                        $parser->{_AUTOACTION}{code}")
        and
        Parse::RecDescent::_hint("The \$::RD_AUTOACTION was defined,
                      so any production not ending in an
                      explicit action has the specified
                      \"auto-action\" automatically
                      appended.");
    }
    elsif ($parser->{_AUTOTREE} && defined($item) && !$item->isa("Parse::RecDescent::Action"))
    {
        if ($i==1 && $item->isterminal)
        {
            $code .= $parser->{_AUTOTREE}{TERMINAL}->code($namespace,$rule);
        }
        else
        {
            $code .= $parser->{_AUTOTREE}{NODE}->code($namespace,$rule);
        }
        Parse::RecDescent::_warn(1,"Autogenerating tree-building action in rule
                       \"$rule->{name}\"")
        and
        Parse::RecDescent::_hint("The directive <autotree> was specified,
                      so any production not ending
                      in an explicit action has
                      some parse-tree building code
                      automatically appended.");
    }

    $code .=
'
        Parse::RecDescent::_trace(q{>>'.Parse::RecDescent::_matchtracemessage($self).' production: ['
                      . $self->describe . ']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{' . $rule->{name} . '},
                      $tracelevel)
                        if defined $::RD_TRACE;

' . ( $parser->{_check}{itempos} ? '
        if ( defined($_itempos) )
        {
            Parse::RecDescent::Production::_update_itempos($_itempos, $itempos[ 1], undef, [qw(from)]);
            Parse::RecDescent::Production::_update_itempos($_itempos, $itempos[-1], undef, [qw(to)]);
        }
' : '' ) . '

        $_matched = 1;
        last;
    }

';
    return $code;
}

1;

package Parse::RecDescent::Action;

sub describe { undef }

sub sethashname { $_[0]->{hashname} = '__ACTION' . ++$_[1]->{actcount} .'__'; }

sub new
{
    my $class = ref($_[0]) || $_[0];
    bless
    {
        "code"      => $_[1],
        "lookahead" => $_[2],
        "line"      => $_[3],
    }, $class;
}

sub issubrule { undef }
sub isterminal { 0 }

sub code($$$$)
{
    my ($self, $namespace, $rule) = @_;

'
        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{' . $rule->{name} . '},
                      $tracelevel)
                        if defined $::RD_TRACE;
        ' . ($self->{"lookahead"} ? '$_savetext = $text;' : '' ) .'

        $_tok = ($_noactions) ? 0 : do ' . $self->{"code"} . ';
        ' . ($self->{"lookahead"}<0?'if':'unless') . ' (defined $_tok)
        {
            Parse::RecDescent::_trace(q{<<'.Parse::RecDescent::_matchtracemessage($self,1).' action>> (return value: [undef])})
                    if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>'.Parse::RecDescent::_matchtracemessage($self).' action<< (return value: [}
                      . $_tok . q{])},
                      Parse::RecDescent::_tracefirst($text))
                        if defined $::RD_TRACE;
        push @item, $_tok;
        ' . ($self->{line}>=0 ? '$item{'. $self->{hashname} .'}=$_tok;' : '' ) .'
        ' . ($self->{"lookahead"} ? '$text = $_savetext;' : '' ) .'
'
}


1;

package Parse::RecDescent::Directive;

sub sethashname { $_[0]->{hashname} = '__DIRECTIVE' . ++$_[1]->{dircount} .  '__'; }

sub issubrule { undef }
sub isterminal { 0 }
sub describe { $_[1] ? '' : $_[0]->{name} }

sub new ($$$$$)
{
    my $class = ref($_[0]) || $_[0];
    bless
    {
        "code"      => $_[1],
        "lookahead" => $_[2],
        "line"      => $_[3],
        "name"      => $_[4],
    }, $class;
}

sub code($$$$)
{
    my ($self, $namespace, $rule) = @_;

'
        ' . ($self->{"lookahead"} ? '$_savetext = $text;' : '' ) .'

        Parse::RecDescent::_trace(q{Trying directive: ['
                    . $self->describe . ']},
                    Parse::RecDescent::_tracefirst($text),
                      q{' . $rule->{name} . '},
                      $tracelevel)
                        if defined $::RD_TRACE; ' .'
        $_tok = do { ' . $self->{"code"} . ' };
        if (defined($_tok))
        {
            Parse::RecDescent::_trace(q{>>'.Parse::RecDescent::_matchtracemessage($self).' directive<< (return value: [}
                        . $_tok . q{])},
                        Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        }
        else
        {
            Parse::RecDescent::_trace(q{<<'.Parse::RecDescent::_matchtracemessage($self,1).' directive>>},
                        Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        }
        ' . ($self->{"lookahead"} ? '$text = $_savetext and ' : '' ) .'
        last '
        . ($self->{"lookahead"}<0?'if':'unless') . ' defined $_tok;
        push @item, $item{'.$self->{hashname}.'}=$_tok;
        ' . ($self->{"lookahead"} ? '$text = $_savetext;' : '' ) .'
'
}

1;

package Parse::RecDescent::UncondReject;

sub issubrule { undef }
sub isterminal { 0 }
sub describe { $_[1] ? '' : $_[0]->{name} }
sub sethashname { $_[0]->{hashname} = '__DIRECTIVE' . ++$_[1]->{dircount} .  '__'; }

sub new ($$$;$)
{
    my $class = ref($_[0]) || $_[0];
    bless
    {
        "lookahead" => $_[1],
        "line"      => $_[2],
        "name"      => $_[3],
    }, $class;
}

# MARK, YOU MAY WANT TO OPTIMIZE THIS.


sub code($$$$)
{
    my ($self, $namespace, $rule) = @_;

'
        Parse::RecDescent::_trace(q{>>Rejecting production<< (found '
                     . $self->describe . ')},
                     Parse::RecDescent::_tracefirst($text),
                      q{' . $rule->{name} . '},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $return;
        ' . ($self->{"lookahead"} ? '$_savetext = $text;' : '' ) .'

        $_tok = undef;
        ' . ($self->{"lookahead"} ? '$text = $_savetext and ' : '' ) .'
        last '
        . ($self->{"lookahead"}<0?'if':'unless') . ' defined $_tok;
'
}

1;

package Parse::RecDescent::Error;

sub issubrule { undef }
sub isterminal { 0 }
sub describe { $_[1] ? '' : $_[0]->{commitonly} ? '<error?:...>' : '<error...>' }
sub sethashname { $_[0]->{hashname} = '__DIRECTIVE' . ++$_[1]->{dircount} .  '__'; }

sub new ($$$$$)
{
    my $class = ref($_[0]) || $_[0];
    bless
    {
        "msg"        => $_[1],
        "lookahead"  => $_[2],
        "commitonly" => $_[3],
        "line"       => $_[4],
    }, $class;
}

sub code($$$$)
{
    my ($self, $namespace, $rule) = @_;

    my $action = '';

    if ($self->{"msg"})  # ERROR MESSAGE SUPPLIED
    {
        #WAS: $action .= "Parse::RecDescent::_error(qq{$self->{msg}}" .  ',$thisline);';
        $action .= 'push @{$thisparser->{errors}}, [qq{'.$self->{msg}.'},$thisline];';

    }
    else      # GENERATE ERROR MESSAGE DURING PARSE
    {
        $action .= '
        my $rule = $item[0];
           $rule =~ s/_/ /g;
        #WAS: Parse::RecDescent::_error("Invalid $rule: " . $expectation->message() ,$thisline);
        push @{$thisparser->{errors}}, ["Invalid $rule: " . $expectation->message() ,$thisline];
        ';
    }

    my $dir =
          new Parse::RecDescent::Directive('if (' .
        ($self->{"commitonly"} ? '$commit' : '1') .
        ") { do {$action} unless ".' $_noactions; undef } else {0}',
                    $self->{"lookahead"},0,$self->describe);
    $dir->{hashname} = $self->{hashname};
    return $dir->code($namespace, $rule, 0);
}

1;

package Parse::RecDescent::Token;

sub sethashname { $_[0]->{hashname} = '__PATTERN' . ++$_[1]->{patcount} . '__'; }

sub issubrule { undef }
sub isterminal { 1 }
sub describe ($) { shift->{'description'}}


# ARGS ARE: $self, $pattern, $left_delim, $modifiers, $lookahead, $linenum
sub new ($$$$$$)
{
    my $class = ref($_[0]) || $_[0];
    my $pattern = $_[1];
    my $pat = $_[1];
    my $ldel = $_[2];
    my $rdel = $ldel;
    $rdel =~ tr/{[(</}])>/;

    my $mod = $_[3];

    my $desc;

    if ($ldel eq '/') { $desc = "$ldel$pattern$rdel$mod" }
    else          { $desc = "m$ldel$pattern$rdel$mod" }
    $desc =~ s/\\/\\\\/g;
    $desc =~ s/\$$/\\\$/g;
    $desc =~ s/}/\\}/g;
    $desc =~ s/{/\\{/g;

    if (!eval "no strict;
           local \$SIG{__WARN__} = sub {0};
           '' =~ m$ldel$pattern$rdel$mod" and $@)
    {
        Parse::RecDescent::_warn(3, "Token pattern \"m$ldel$pattern$rdel$mod\"
                         may not be a valid regular expression",
                       $_[5]);
        $@ =~ s/ at \(eval.*/./;
        Parse::RecDescent::_hint($@);
    }

    # QUIETLY PREVENT (WELL-INTENTIONED) CALAMITY
    $mod =~ s/[gc]//g;
    $pattern =~ s/(\A|[^\\])\\G/$1/g;

    bless
    {
        "pattern"   => $pattern,
        "ldelim"      => $ldel,
        "rdelim"      => $rdel,
        "mod"         => $mod,
        "lookahead"   => $_[4],
        "line"        => $_[5],
        "description" => $desc,
    }, $class;
}


sub code($$$$$)
{
    my ($self, $namespace, $rule, $check) = @_;
    my $ldel = $self->{"ldelim"};
    my $rdel = $self->{"rdelim"};
    my $sdel = $ldel;
    my $mod  = $self->{"mod"};

    $sdel =~ s/[[{(<]/{}/;

my $code = '
        Parse::RecDescent::_trace(q{Trying terminal: [' . $self->describe
                      . ']}, Parse::RecDescent::_tracefirst($text),
                      q{' . $rule->{name} . '},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{' . ($rule->hasleftmost($self) ? ''
                : $self->describe ) . '})->at($text);
        ' . ($self->{"lookahead"} ? '$_savetext = $text;' : '' ) . '

        ' . ($self->{"lookahead"}<0?'if':'unless')
        . ' ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and '
        . ($check->{itempos}? 'do {'.Parse::RecDescent::Production::incitempos().' 1} and ' : '')
        . '  $text =~ m' . $ldel . '\A(?:' . $self->{"pattern"} . ')' . $rdel . $mod . ')
        {
            '.($self->{"lookahead"} ? '$text = $_savetext;' : '$text = $lastsep . $text if defined $lastsep;') .
            ($check->{itempos} ? Parse::RecDescent::Production::unincitempos() : '') . '
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn\'t match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{'.$self->{hashname}.'}=$current_match;
        ' . ($self->{"lookahead"} ? '$text = $_savetext;' : '' ) .'
';

    return $code;
}

1;

package Parse::RecDescent::Literal;

sub sethashname { $_[0]->{hashname} = '__STRING' . ++$_[1]->{strcount} . '__'; }

sub issubrule { undef }
sub isterminal { 1 }
sub describe ($) { shift->{'description'} }

sub new ($$$$)
{
    my $class = ref($_[0]) || $_[0];

    my $pattern = $_[1];

    my $desc = $pattern;
    $desc=~s/\\/\\\\/g;
    $desc=~s/}/\\}/g;
    $desc=~s/{/\\{/g;

    bless
    {
        "pattern"     => $pattern,
        "lookahead"   => $_[2],
        "line"        => $_[3],
        "description" => "'$desc'",
    }, $class;
}


sub code($$$$)
{
    my ($self, $namespace, $rule, $check) = @_;

my $code = '
        Parse::RecDescent::_trace(q{Trying terminal: [' . $self->describe
                      . ']},
                      Parse::RecDescent::_tracefirst($text),
                      q{' . $rule->{name} . '},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{' . ($rule->hasleftmost($self) ? ''
                : $self->describe ) . '})->at($text);
        ' . ($self->{"lookahead"} ? '$_savetext = $text;' : '' ) . '

        ' . ($self->{"lookahead"}<0?'if':'unless')
        . ' ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and '
        . ($check->{itempos}? 'do {'.Parse::RecDescent::Production::incitempos().' 1} and ' : '')
        . '  $text =~ m/\A' . quotemeta($self->{"pattern"}) . '/)
        {
            '.($self->{"lookahead"} ? '$text = $_savetext;' : '$text = $lastsep . $text if defined $lastsep;').'
            '. ($check->{itempos} ? Parse::RecDescent::Production::unincitempos() : '') . '
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn\'t match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{'.$self->{hashname}.'}=$current_match;
        ' . ($self->{"lookahead"} ? '$text = $_savetext;' : '' ) .'
';

    return $code;
}

1;

package Parse::RecDescent::InterpLit;

sub sethashname { $_[0]->{hashname} = '__STRING' . ++$_[1]->{strcount} . '__'; }

sub issubrule { undef }
sub isterminal { 1 }
sub describe ($) { shift->{'description'} }

sub new ($$$$)
{
    my $class = ref($_[0]) || $_[0];

    my $pattern = $_[1];
    $pattern =~ s#/#\\/#g;

    my $desc = $pattern;
    $desc=~s/\\/\\\\/g;
    $desc=~s/}/\\}/g;
    $desc=~s/{/\\{/g;

    bless
    {
        "pattern"   => $pattern,
        "lookahead" => $_[2],
        "line"      => $_[3],
        "description" => "'$desc'",
    }, $class;
}

sub code($$$$)
{
    my ($self, $namespace, $rule, $check) = @_;

my $code = '
        Parse::RecDescent::_trace(q{Trying terminal: [' . $self->describe
                      . ']},
                      Parse::RecDescent::_tracefirst($text),
                      q{' . $rule->{name} . '},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{' . ($rule->hasleftmost($self) ? ''
                : $self->describe ) . '})->at($text);
        ' . ($self->{"lookahead"} ? '$_savetext = $text;' : '' ) . '

        ' . ($self->{"lookahead"}<0?'if':'unless')
        . ' ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and '
        . ($check->{itempos}? 'do {'.Parse::RecDescent::Production::incitempos().' 1} and ' : '')
        . '  do { $_tok = "' . $self->{"pattern"} . '"; 1 } and
             substr($text,0,length($_tok)) eq $_tok and
             do { substr($text,0,length($_tok)) = ""; 1; }
        )
        {
            '.($self->{"lookahead"} ? '$text = $_savetext;' : '$text = $lastsep . $text if defined $lastsep;').'
            '. ($check->{itempos} ? Parse::RecDescent::Production::unincitempos() : '') . '
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn\'t match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $_tok . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{'.$self->{hashname}.'}=$_tok;
        ' . ($self->{"lookahead"} ? '$text = $_savetext;' : '' ) .'
';

    return $code;
}

1;

package Parse::RecDescent::Subrule;

sub issubrule ($) { return $_[0]->{"subrule"} }
sub isterminal { 0 }
sub sethashname {}

sub describe ($)
{
    my $desc = $_[0]->{"implicit"} || $_[0]->{"subrule"};
    $desc = "<matchrule:$desc>" if $_[0]->{"matchrule"};
    return $desc;
}

sub callsyntax($$)
{
    if ($_[0]->{"matchrule"})
    {
        return "&{'$_[1]'.qq{$_[0]->{subrule}}}";
    }
    else
    {
        return $_[1].$_[0]->{"subrule"};
    }
}

sub new ($$$$;$$$)
{
    my $class = ref($_[0]) || $_[0];
    bless
    {
        "subrule"   => $_[1],
        "lookahead" => $_[2],
        "line"      => $_[3],
        "implicit"  => $_[4] || undef,
        "matchrule" => $_[5],
        "argcode"   => $_[6] || undef,
    }, $class;
}


sub code($$$$)
{
    my ($self, $namespace, $rule, $check) = @_;

'
        Parse::RecDescent::_trace(q{Trying subrule: [' . $self->{"subrule"} . ']},
                  Parse::RecDescent::_tracefirst($text),
                  q{' . $rule->{"name"} . '},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(' . ($rule->hasleftmost($self) ? 'q{}'
                # WAS : 'qq{'.$self->describe.'}' ) . ')->at($text);
                : 'q{'.$self->describe.'}' ) . ')->at($text);
        ' . ($self->{"lookahead"} ? '$_savetext = $text;' : '' )
        . ($self->{"lookahead"}<0?'if':'unless')
        . ' (defined ($_tok = '
        . $self->callsyntax($namespace.'::')
        . '($thisparser,$text,$repeating,'
        . ($self->{"lookahead"}?'1':'$_noactions')
        . ($self->{argcode} ? ",sub { return $self->{argcode} }"
                   : ',sub { \\@arg }')
        . ($check->{"itempos"}?',$itempos[$#itempos]':',undef')
        . ')))
        {
            '.($self->{"lookahead"} ? '$text = $_savetext;' : '').'
            Parse::RecDescent::_trace(q{<<'.Parse::RecDescent::_matchtracemessage($self,1).' subrule: ['
            . $self->{subrule} . ']>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{' . $rule->{"name"} .'},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>'.Parse::RecDescent::_matchtracemessage($self).' subrule: ['
                    . $self->{subrule} . ']<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{' . $rule->{"name"} .'},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{' . $self->{subrule} . '}} = $_tok;
        push @item, $_tok;
        ' . ($self->{"lookahead"} ? '$text = $_savetext;' : '' ) .'
        }
'
}

package Parse::RecDescent::Repetition;

sub issubrule ($) { return $_[0]->{"subrule"} }
sub isterminal { 0 }
sub sethashname {  }

sub describe ($)
{
    my $desc = $_[0]->{"expected"} || $_[0]->{"subrule"};
    $desc = "<matchrule:$desc>" if $_[0]->{"matchrule"};
    return $desc;
}

sub callsyntax($$)
{
    if ($_[0]->{matchrule})
        { return "sub { goto &{''.qq{$_[1]$_[0]->{subrule}}} }"; }
    else
        { return "\\&$_[1]$_[0]->{subrule}"; }
}

sub new ($$$$$$$$$$)
{
    my ($self, $subrule, $repspec, $min, $max, $lookahead, $line, $parser, $matchrule, $argcode) = @_;
    my $class = ref($self) || $self;
    ($max, $min) = ( $min, $max) if ($max<$min);

    my $desc;
    if ($subrule=~/\A_alternation_\d+_of_production_\d+_of_rule/)
        { $desc = $parser->{"rules"}{$subrule}->expected }

    if ($lookahead)
    {
        if ($min>0)
        {
           return new Parse::RecDescent::Subrule($subrule,$lookahead,$line,$desc,$matchrule,$argcode);
        }
        else
        {
            Parse::RecDescent::_error("Not symbol (\"!\") before
                        \"$subrule\" doesn't make
                        sense.",$line);
            Parse::RecDescent::_hint("Lookahead for negated optional
                       repetitions (such as
                       \"!$subrule($repspec)\" can never
                       succeed, since optional items always
                       match (zero times at worst).
                       Did you mean a single \"!$subrule\",
                       instead?");
        }
    }
    bless
    {
        "subrule"   => $subrule,
        "repspec"   => $repspec,
        "min"       => $min,
        "max"       => $max,
        "lookahead" => $lookahead,
        "line"      => $line,
        "expected"  => $desc,
        "argcode"   => $argcode || undef,
        "matchrule" => $matchrule,
    }, $class;
}

sub code($$$$)
{
    my ($self, $namespace, $rule, $check) = @_;

    my ($subrule, $repspec, $min, $max, $lookahead) =
        @{$self}{ qw{subrule repspec min max lookahead} };

'
        Parse::RecDescent::_trace(q{Trying repeated subrule: [' . $self->describe . ']},
                  Parse::RecDescent::_tracefirst($text),
                  q{' . $rule->{"name"} . '},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(' . ($rule->hasleftmost($self) ? 'q{}'
                # WAS : 'qq{'.$self->describe.'}' ) . ')->at($text);
                : 'q{'.$self->describe.'}' ) . ')->at($text);
        ' . ($self->{"lookahead"} ? '$_savetext = $text;' : '' ) .'
        unless (defined ($_tok = $thisparser->_parserepeat($text, '
        . $self->callsyntax($namespace.'::')
        . ', ' . $min . ', ' . $max . ', '
        . ($self->{"lookahead"}?'1':'$_noactions')
        . ',$expectation,'
        . ($self->{argcode} ? "sub { return $self->{argcode} }"
                        : 'sub { \\@arg }')
        . ($check->{"itempos"}?',$itempos[$#itempos]':',undef')
        . ')))
        {
            Parse::RecDescent::_trace(q{<<'.Parse::RecDescent::_matchtracemessage($self,1).' repeated subrule: ['
            . $self->describe . ']>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{' . $rule->{"name"} .'},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>'.Parse::RecDescent::_matchtracemessage($self).' repeated subrule: ['
                    . $self->{subrule} . ']<< (}
                    . @$_tok . q{ times)},

                      Parse::RecDescent::_tracefirst($text),
                      q{' . $rule->{"name"} .'},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{' . "$self->{subrule}($self->{repspec})" . '}} = $_tok;
        push @item, $_tok;
        ' . ($self->{"lookahead"} ? '$text = $_savetext;' : '' ) .'

'
}

package Parse::RecDescent::Result;

sub issubrule { 0 }
sub isterminal { 0 }
sub describe { '' }

sub new
{
    my ($class, $pos) = @_;

    bless {}, $class;
}

sub code($$$$)
{
    my ($self, $namespace, $rule) = @_;

    '
        $return = $item[-1];
    ';
}

package Parse::RecDescent::Operator;

my @opertype = ( " non-optional", "n optional" );

sub issubrule { 0 }
sub isterminal { 0 }

sub describe { $_[0]->{"expected"} }
sub sethashname { $_[0]->{hashname} = '__DIRECTIVE' . ++$_[1]->{dircount} .  '__'; }


sub new
{
    my ($class, $type, $minrep, $maxrep, $leftarg, $op, $rightarg) = @_;

    bless
    {
        "type"      => "${type}op",
        "leftarg"   => $leftarg,
        "op"        => $op,
        "min"       => $minrep,
        "max"       => $maxrep,
        "rightarg"  => $rightarg,
        "expected"  => "<${type}op: ".$leftarg->describe." ".$op->describe." ".$rightarg->describe.">",
    }, $class;
}

sub code($$$$)
{
    my ($self, $namespace, $rule, $check) = @_;

    my @codeargs = @_[1..$#_];

    my ($leftarg, $op, $rightarg) =
        @{$self}{ qw{leftarg op rightarg} };

    my $code = '
        Parse::RecDescent::_trace(q{Trying operator: [' . $self->describe . ']},
                  Parse::RecDescent::_tracefirst($text),
                  q{' . $rule->{"name"} . '},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(' . ($rule->hasleftmost($self) ? 'q{}'
                # WAS : 'qq{'.$self->describe.'}' ) . ')->at($text);
                : 'q{'.$self->describe.'}' ) . ')->at($text);

        $_tok = undef;
        OPLOOP: while (1)
        {
          $repcount = 0;
          my @item;
          my %item;
';

    $code .= '
          my  $_itempos = $itempos[-1];
          my  $itemposfirst;
' if $check->{itempos};

    if ($self->{type} eq "leftop" )
    {
        $code .= '
          # MATCH LEFTARG
          ' . $leftarg->code(@codeargs) . '

';

        $code .= '
          if (defined($_itempos) and !defined($itemposfirst))
          {
              $itemposfirst = Parse::RecDescent::Production::_duplicate_itempos($_itempos);
          }
' if $check->{itempos};

        $code .= '
          $repcount++;

          my $savetext = $text;
          my $backtrack;

          # MATCH (OP RIGHTARG)(s)
          while ($repcount < ' . $self->{max} . ')
          {
            $backtrack = 0;
            ' . $op->code(@codeargs) . '
            ' . ($op->isterminal() ? 'pop @item;' : '$backtrack=1;' ) . '
            ' . (ref($op) eq 'Parse::RecDescent::Token'
                ? 'if (defined $1) {push @item, $item{'.($self->{name}||$self->{hashname}).'}=$1; $backtrack=1;}'
                : "" ) . '
            ' . $rightarg->code(@codeargs) . '
            $savetext = $text;
            $repcount++;
          }
          $text = $savetext;
          pop @item if $backtrack;

          ';
    }
    else
    {
        $code .= '
          my $savetext = $text;
          my $backtrack;
          # MATCH (LEFTARG OP)(s)
          while ($repcount < ' . $self->{max} . ')
          {
            $backtrack = 0;
            ' . $leftarg->code(@codeargs) . '
';
        $code .= '
            if (defined($_itempos) and !defined($itemposfirst))
            {
                $itemposfirst = Parse::RecDescent::Production::_duplicate_itempos($_itempos);
            }
' if $check->{itempos};

        $code .= '
            $repcount++;
            $backtrack = 1;
            ' . $op->code(@codeargs) . '
            $savetext = $text;
            ' . ($op->isterminal() ? 'pop @item;' : "" ) . '
            ' . (ref($op) eq 'Parse::RecDescent::Token' ? 'do { push @item, $item{'.($self->{name}||$self->{hashname}).'}=$1; } if defined $1;' : "" ) . '
          }
          $text = $savetext;
          pop @item if $backtrack;

          # MATCH RIGHTARG
          ' . $rightarg->code(@codeargs) . '
          $repcount++;
          ';
    }

    $code .= 'unless (@item) { undef $_tok; last }' unless $self->{min}==0;

    $code .= '
          $_tok = [ @item ];
';


    $code .= '
          if (defined $itemposfirst)
          {
              Parse::RecDescent::Production::_update_itempos(
                  $_itempos, $itemposfirst, undef, [qw(from)]);
          }
' if $check->{itempos};

    $code .= '
          last;
        } # end of OPLOOP
';

    $code .= '
        unless ($repcount>='.$self->{min}.')
        {
            Parse::RecDescent::_trace(q{<<'.Parse::RecDescent::_matchtracemessage($self,1).' operator: ['
                          . $self->describe
                          . ']>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{' . $rule->{"name"} .'},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>'.Parse::RecDescent::_matchtracemessage($self).' operator: ['
                      . $self->describe
                      . ']<< (return value: [}
                      . qq{@{$_tok||[]}} . q{]},
                      Parse::RecDescent::_tracefirst($text),
                      q{' . $rule->{"name"} .'},
                      $tracelevel)
                        if defined $::RD_TRACE;

        push @item, $item{'.($self->{name}||$self->{hashname}).'}=$_tok||[];
';

    return $code;
}


package Parse::RecDescent::Expectation;

sub new ($)
{
    bless {
        "failed"      => 0,
        "expected"    => "",
        "unexpected"      => "",
        "lastexpected"    => "",
        "lastunexpected"  => "",
        "defexpected"     => $_[1],
          };
}

sub is ($$)
{
    $_[0]->{lastexpected} = $_[1]; return $_[0];
}

sub at ($$)
{
    $_[0]->{lastunexpected} = $_[1]; return $_[0];
}

sub failed ($)
{
    return unless $_[0]->{lastexpected};
    $_[0]->{expected}   = $_[0]->{lastexpected}   unless $_[0]->{failed};
    $_[0]->{unexpected} = $_[0]->{lastunexpected} unless $_[0]->{failed};
    $_[0]->{failed} = 1;
}

sub message ($)
{
    my ($self) = @_;
    $self->{expected} = $self->{defexpected} unless $self->{expected};
    $self->{expected} =~ s/_/ /g;
    if (!$self->{unexpected} || $self->{unexpected} =~ /\A\s*\Z/s)
    {
        return "Was expecting $self->{expected}";
    }
    else
    {
        $self->{unexpected} =~ /\s*(.*)/;
        return "Was expecting $self->{expected} but found \"$1\" instead";
    }
}

1;

package Parse::RecDescent;

use Carp;
use vars qw ( $AUTOLOAD $VERSION $_FILENAME);

my $ERRORS = 0;

our $VERSION = '1.967009';
$VERSION = eval $VERSION;
$_FILENAME=__FILE__;

# BUILDING A PARSER

my $nextnamespace = "namespace000001";

sub _nextnamespace()
{
    return "Parse::RecDescent::" . $nextnamespace++;
}

# ARGS ARE: $class, $grammar, $compiling, $namespace
sub new ($$$$)
{
    my $class = ref($_[0]) || $_[0];
    local $Parse::RecDescent::compiling = $_[2];
    my $name_space_name = defined $_[3]
        ? "Parse::RecDescent::".$_[3]
        : _nextnamespace();
    my $self =
    {
        "rules"     => {},
        "namespace" => $name_space_name,
        "startcode" => '',
        "localvars" => '',
        "_AUTOACTION" => undef,
        "_AUTOTREE"   => undef,

        # Precompiled parsers used to set _precompiled, but that
        # wasn't present in some versions of Parse::RecDescent used to
        # build precompiled parsers.  Instead, set a new
        # _not_precompiled flag, which is remove from future
        # Precompiled parsers at build time.
        "_not_precompiled" => 1,
    };


    if ($::RD_AUTOACTION) {
        my $sourcecode = $::RD_AUTOACTION;
        $sourcecode = "{ $sourcecode }"
            unless $sourcecode =~ /\A\s*\{.*\}\s*\Z/;
        $self->{_check}{itempos} =
            $sourcecode =~ /\@itempos\b|\$itempos\s*\[/;
        $self->{_AUTOACTION}
            = new Parse::RecDescent::Action($sourcecode,0,-1)
    }

    bless $self, $class;
    return $self->Replace($_[1])
}

sub Compile($$$$) {
    die "Compilation of Parse::RecDescent grammars not yet implemented\n";
}

sub DESTROY {
    my ($self) = @_;
    my $namespace = $self->{namespace};
    $namespace =~ s/Parse::RecDescent:://;
    if ($self->{_not_precompiled}) {
        # BEGIN WORKAROUND
        # Perl has a bug that creates a circular reference between
        # @ISA and that variable's stash:
        #   https://rt.perl.org/rt3/Ticket/Display.html?id=92708
        # Emptying the array before deleting the stash seems to
        # prevent the leak.  Once the ticket above has been resolved,
        # these two lines can be removed.
        no strict 'refs';
        @{$self->{namespace} . '::ISA'} = ();
        # END WORKAROUND

        # Some grammars may contain circular references between rules,
        # such as:
        #   a: 'ID' | b
        #   b: '(' a ')'
        # Unless these references are broken, the subs stay around on
        # stash deletion below.  Iterate through the stash entries and
        # for each defined code reference, set it to reference sub {}
        # instead.
        {
            local $^W; # avoid 'sub redefined' warnings.
            my $blank_sub = sub {};
            while (my ($name, $glob) = each %{"Parse::RecDescent::$namespace\::"}) {
                *$glob = $blank_sub if defined &$glob;
            }
        }

        # Delete the namespace's stash
        delete $Parse::RecDescent::{$namespace.'::'};
    }
}

# BUILDING A GRAMMAR....

# ARGS ARE: $self, $grammar, $isimplicit, $isleftop
sub Replace ($$)
{
    # set $replace = 1 for _generate
    splice(@_, 2, 0, 1);

    return _generate(@_);
}

# ARGS ARE: $self, $grammar, $isimplicit, $isleftop
sub Extend ($$)
{
    # set $replace = 0 for _generate
    splice(@_, 2, 0, 0);

    return _generate(@_);
}

sub _no_rule ($$;$)
{
    _error("Ruleless $_[0] at start of grammar.",$_[1]);
    my $desc = $_[2] ? "\"$_[2]\"" : "";
    _hint("You need to define a rule for the $_[0] $desc
           to be part of.");
}

my $NEGLOOKAHEAD    = '\G(\s*\.\.\.\!)';
my $POSLOOKAHEAD    = '\G(\s*\.\.\.)';
my $RULE        = '\G\s*(\w+)[ \t]*:';
my $PROD        = '\G\s*([|])';
my $TOKEN       = q{\G\s*/((\\\\/|\\\\\\\\|[^/])*)/([cgimsox]*)};
my $MTOKEN      = q{\G\s*(m\s*[^\w\s])};
my $LITERAL     = q{\G\s*'((\\\\['\\\\]|[^'])*)'};
my $INTERPLIT       = q{\G\s*"((\\\\["\\\\]|[^"])*)"};
my $SUBRULE     = '\G\s*(\w+)';
my $MATCHRULE       = '\G(\s*<matchrule:)';
my $SIMPLEPAT       = '((\\s+/[^/\\\\]*(?:\\\\.[^/\\\\]*)*/)?)';
my $OPTIONAL        = '\G\((\?)'.$SIMPLEPAT.'\)';
my $ANY         = '\G\((s\?)'.$SIMPLEPAT.'\)';
my $MANY        = '\G\((s|\.\.)'.$SIMPLEPAT.'\)';
my $EXACTLY     = '\G\(([1-9]\d*)'.$SIMPLEPAT.'\)';
my $BETWEEN     = '\G\((\d+)\.\.([1-9]\d*)'.$SIMPLEPAT.'\)';
my $ATLEAST     = '\G\((\d+)\.\.'.$SIMPLEPAT.'\)';
my $ATMOST      = '\G\(\.\.([1-9]\d*)'.$SIMPLEPAT.'\)';
my $BADREP      = '\G\((-?\d+)?\.\.(-?\d+)?'.$SIMPLEPAT.'\)';
my $ACTION      = '\G\s*\{';
my $IMPLICITSUBRULE = '\G\s*\(';
my $COMMENT     = '\G\s*(#.*)';
my $COMMITMK        = '\G\s*<commit>';
my $UNCOMMITMK      = '\G\s*<uncommit>';
my $QUOTELIKEMK     = '\G\s*<perl_quotelike>';
my $CODEBLOCKMK     = '\G\s*<perl_codeblock(?:\s+([][()<>{}]+))?>';
my $VARIABLEMK      = '\G\s*<perl_variable>';
my $NOCHECKMK       = '\G\s*<nocheck>';
my $AUTOACTIONPATMK = '\G\s*<autoaction:';
my $AUTOTREEMK      = '\G\s*<autotree(?::\s*([\w:]+)\s*)?>';
my $AUTOSTUBMK      = '\G\s*<autostub>';
my $AUTORULEMK      = '\G\s*<autorule:(.*?)>';
my $REJECTMK        = '\G\s*<reject>';
my $CONDREJECTMK    = '\G\s*<reject:';
my $SCOREMK     = '\G\s*<score:';
my $AUTOSCOREMK     = '\G\s*<autoscore:';
my $SKIPMK      = '\G\s*<skip:';
my $OPMK        = '\G\s*<(left|right)op(?:=(\'.*?\'))?:';
my $ENDDIRECTIVEMK  = '\G\s*>';
my $RESYNCMK        = '\G\s*<resync>';
my $RESYNCPATMK     = '\G\s*<resync:';
my $RULEVARPATMK    = '\G\s*<rulevar:';
my $DEFERPATMK      = '\G\s*<defer:';
my $TOKENPATMK      = '\G\s*<token:';
my $AUTOERRORMK     = '\G\s*<error(\??)>';
my $MSGERRORMK      = '\G\s*<error(\??):';
my $NOCHECK     = '\G\s*<nocheck>';
my $WARNMK      = '\G\s*<warn((?::\s*(\d+)\s*)?)>';
my $HINTMK      = '\G\s*<hint>';
my $TRACEBUILDMK    = '\G\s*<trace_build((?::\s*(\d+)\s*)?)>';
my $TRACEPARSEMK    = '\G\s*<trace_parse((?::\s*(\d+)\s*)?)>';
my $UNCOMMITPROD    = $PROD.'\s*<uncommit';
my $ERRORPROD       = $PROD.'\s*<error';
my $LONECOLON       = '\G\s*:';
my $OTHER       = '\G\s*([^\s]+)';

my @lines = 0;

sub _generate
{
    my ($self, $grammar, $replace, $isimplicit, $isleftop) = (@_, 0);

    my $aftererror = 0;
    my $lookahead = 0;
    my $lookaheadspec = "";
    my $must_pop_lines;
    if (! $lines[-1]) {
        push @lines, _linecount($grammar) ;
        $must_pop_lines = 1;
    }
    $self->{_check}{itempos} = ($grammar =~ /\@itempos\b|\$itempos\s*\[/)
        unless $self->{_check}{itempos};
    for (qw(thisoffset thiscolumn prevline prevoffset prevcolumn))
    {
        $self->{_check}{$_} =
            ($grammar =~ /\$$_/) || $self->{_check}{itempos}
                unless $self->{_check}{$_};
    }
    my $line;

    my $rule = undef;
    my $prod = undef;
    my $item = undef;
    my $lastgreedy = '';
    pos $grammar = 0;
    study $grammar;

    local $::RD_HINT  = $::RD_HINT;
    local $::RD_WARN  = $::RD_WARN;
    local $::RD_TRACE = $::RD_TRACE;
    local $::RD_CHECK = $::RD_CHECK;

    while (pos $grammar < length $grammar)
    {
        $line = $lines[-1] - _linecount($grammar) + 1;
        my $commitonly;
        my $code = "";
        my @components = ();
        if ($grammar =~ m/$COMMENT/gco)
        {
            _parse("a comment",0,$line, substr($grammar, $-[0], $+[0] - $-[0]) );
            next;
        }
        elsif ($grammar =~ m/$NEGLOOKAHEAD/gco)
        {
            _parse("a negative lookahead",$aftererror,$line, substr($grammar, $-[0], $+[0] - $-[0]) );
            $lookahead = $lookahead ? -$lookahead : -1;
            $lookaheadspec .= $1;
            next;   # SKIP LOOKAHEAD RESET AT END OF while LOOP
        }
        elsif ($grammar =~ m/$POSLOOKAHEAD/gco)
        {
            _parse("a positive lookahead",$aftererror,$line, substr($grammar, $-[0], $+[0] - $-[0]) );
            $lookahead = $lookahead ? $lookahead : 1;
            $lookaheadspec .= $1;
            next;   # SKIP LOOKAHEAD RESET AT END OF while LOOP
        }
        elsif ($grammar =~ m/(?=$ACTION)/gco
            and do { ($code) = extract_codeblock($grammar); $code })
        {
            _parse("an action", $aftererror, $line, $code);
            $item = new Parse::RecDescent::Action($code,$lookahead,$line);
            $prod and $prod->additem($item)
                  or  $self->_addstartcode($code);
        }
        elsif ($grammar =~ m/(?=$IMPLICITSUBRULE)/gco
            and do { ($code) = extract_codeblock($grammar,'{([',undef,'(',1);
                $code })
        {
            $code =~ s/\A\s*\(|\)\Z//g;
            _parse("an implicit subrule", $aftererror, $line,
                "( $code )");
            my $implicit = $rule->nextimplicit;
            return undef
                if !$self->_generate("$implicit : $code",$replace,1);
            my $pos = pos $grammar;
            substr($grammar,$pos,0,$implicit);
            pos $grammar = $pos;;
        }
        elsif ($grammar =~ m/$ENDDIRECTIVEMK/gco)
        {

        # EXTRACT TRAILING REPETITION SPECIFIER (IF ANY)

            my ($minrep,$maxrep) = (1,$MAXREP);
            if ($grammar =~ m/\G[(]/gc)
            {
                pos($grammar)--;

                if ($grammar =~ m/$OPTIONAL/gco)
                    { ($minrep, $maxrep) = (0,1) }
                elsif ($grammar =~ m/$ANY/gco)
                    { $minrep = 0 }
                elsif ($grammar =~ m/$EXACTLY/gco)
                    { ($minrep, $maxrep) = ($1,$1) }
                elsif ($grammar =~ m/$BETWEEN/gco)
                    { ($minrep, $maxrep) = ($1,$2) }
                elsif ($grammar =~ m/$ATLEAST/gco)
                    { $minrep = $1 }
                elsif ($grammar =~ m/$ATMOST/gco)
                    { $maxrep = $1 }
                elsif ($grammar =~ m/$MANY/gco)
                    { }
                elsif ($grammar =~ m/$BADREP/gco)
                {
                    _parse("an invalid repetition specifier", 0,$line, substr($grammar, $-[0], $+[0] - $-[0]) );
                    _error("Incorrect specification of a repeated directive",
                           $line);
                    _hint("Repeated directives cannot have
                           a maximum repetition of zero, nor can they have
                           negative components in their ranges.");
                }
            }

            $prod && $prod->enddirective($line,$minrep,$maxrep);
        }
        elsif ($grammar =~ m/\G\s*<[^m]/gc)
        {
            pos($grammar)-=2;

            if ($grammar =~ m/$OPMK/gco)
            {
                # $DB::single=1;
                _parse("a $1-associative operator directive", $aftererror, $line, "<$1op:...>");
                $prod->adddirective($1, $line,$2||'');
            }
            elsif ($grammar =~ m/$UNCOMMITMK/gco)
            {
                _parse("an uncommit marker", $aftererror,$line, substr($grammar, $-[0], $+[0] - $-[0]) );
                $item = new Parse::RecDescent::Directive('$commit=0;1',
                                  $lookahead,$line,"<uncommit>");
                $prod and $prod->additem($item)
                      or  _no_rule("<uncommit>",$line);
            }
            elsif ($grammar =~ m/$QUOTELIKEMK/gco)
            {
                _parse("an perl quotelike marker", $aftererror,$line, substr($grammar, $-[0], $+[0] - $-[0]) );
                $item = new Parse::RecDescent::Directive(
                    'my ($match,@res);
                     ($match,$text,undef,@res) =
                          Text::Balanced::extract_quotelike($text,$skip);
                      $match ? \@res : undef;
                    ', $lookahead,$line,"<perl_quotelike>");
                $prod and $prod->additem($item)
                      or  _no_rule("<perl_quotelike>",$line);
            }
            elsif ($grammar =~ m/$CODEBLOCKMK/gco)
            {
                my $outer = $1||"{}";
                _parse("an perl codeblock marker", $aftererror,$line, substr($grammar, $-[0], $+[0] - $-[0]) );
                $item = new Parse::RecDescent::Directive(
                    'Text::Balanced::extract_codeblock($text,undef,$skip,\''.$outer.'\');
                    ', $lookahead,$line,"<perl_codeblock>");
                $prod and $prod->additem($item)
                      or  _no_rule("<perl_codeblock>",$line);
            }
            elsif ($grammar =~ m/$VARIABLEMK/gco)
            {
                _parse("an perl variable marker", $aftererror,$line, substr($grammar, $-[0], $+[0] - $-[0]) );
                $item = new Parse::RecDescent::Directive(
                    'Text::Balanced::extract_variable($text,$skip);
                    ', $lookahead,$line,"<perl_variable>");
                $prod and $prod->additem($item)
                      or  _no_rule("<perl_variable>",$line);
            }
            elsif ($grammar =~ m/$NOCHECKMK/gco)
            {
                _parse("a disable checking marker", $aftererror,$line, substr($grammar, $-[0], $+[0] - $-[0]) );
                if ($rule)
                {
                    _error("<nocheck> directive not at start of grammar", $line);
                    _hint("The <nocheck> directive can only
                           be specified at the start of a
                           grammar (before the first rule
                           is defined.");
                }
                else
                {
                    local $::RD_CHECK = 1;
                }
            }
            elsif ($grammar =~ m/$AUTOSTUBMK/gco)
            {
                _parse("an autostub marker", $aftererror,$line, substr($grammar, $-[0], $+[0] - $-[0]) );
                $::RD_AUTOSTUB = "";
            }
            elsif ($grammar =~ m/$AUTORULEMK/gco)
            {
                _parse("an autorule marker", $aftererror,$line, substr($grammar, $-[0], $+[0] - $-[0]) );
                $::RD_AUTOSTUB = $1;
            }
            elsif ($grammar =~ m/$AUTOTREEMK/gco)
            {
                my $base = defined($1) ? $1 : "";
                my $current_match = substr($grammar, $-[0], $+[0] - $-[0]);
                $base .= "::" if $base && $base !~ /::$/;
                _parse("an autotree marker", $aftererror,$line, $current_match);
                if ($rule)
                {
                    _error("<autotree> directive not at start of grammar", $line);
                    _hint("The <autotree> directive can only
                           be specified at the start of a
                           grammar (before the first rule
                           is defined.");
                }
                else
                {
                    undef $self->{_AUTOACTION};
                    $self->{_AUTOTREE}{NODE}
                        = new Parse::RecDescent::Action(q({bless \%item, ').$base.q('.$item[0]}),0,-1);
                    $self->{_AUTOTREE}{TERMINAL}
                        = new Parse::RecDescent::Action(q({bless {__VALUE__=>$item[1]}, ').$base.q('.$item[0]}),0,-1);
                }
            }

            elsif ($grammar =~ m/$REJECTMK/gco)
            {
                _parse("an reject marker", $aftererror,$line, substr($grammar, $-[0], $+[0] - $-[0]) );
                $item = new Parse::RecDescent::UncondReject($lookahead,$line,"<reject>");
                $prod and $prod->additem($item)
                      or  _no_rule("<reject>",$line);
            }
            elsif ($grammar =~ m/(?=$CONDREJECTMK)/gco
                and do { ($code) = extract_codeblock($grammar,'{',undef,'<');
                      $code })
            {
                _parse("a (conditional) reject marker", $aftererror,$line, $code );
                $code =~ /\A\s*<reject:(.*)>\Z/s;
                my $cond = $1;
                $item = new Parse::RecDescent::Directive(
                          "($1) ? undef : 1", $lookahead,$line,"<reject:$cond>");
                $prod and $prod->additem($item)
                      or  _no_rule("<reject:$cond>",$line);
            }
            elsif ($grammar =~ m/(?=$SCOREMK)/gco
                and do { ($code) = extract_codeblock($grammar,'{',undef,'<');
                      $code })
            {
                _parse("a score marker", $aftererror,$line, $code );
                $code =~ /\A\s*<score:(.*)>\Z/s;
                $prod and $prod->addscore($1, $lookahead, $line)
                      or  _no_rule($code,$line);
            }
            elsif ($grammar =~ m/(?=$AUTOSCOREMK)/gco
                and do { ($code) = extract_codeblock($grammar,'{',undef,'<');
                     $code;
                       } )
            {
                _parse("an autoscore specifier", $aftererror,$line,$code);
                $code =~ /\A\s*<autoscore:(.*)>\Z/s;

                $rule and $rule->addautoscore($1,$self)
                      or  _no_rule($code,$line);

                $item = new Parse::RecDescent::UncondReject($lookahead,$line,$code);
                $prod and $prod->additem($item)
                      or  _no_rule($code,$line);
            }
            elsif ($grammar =~ m/$RESYNCMK/gco)
            {
                _parse("a resync to newline marker", $aftererror,$line, substr($grammar, $-[0], $+[0] - $-[0]) );
                $item = new Parse::RecDescent::Directive(
                          'if ($text =~ s/(\A[^\n]*\n)//) { $return = 0; $1; } else { undef }',
                          $lookahead,$line,"<resync>");
                $prod and $prod->additem($item)
                      or  _no_rule("<resync>",$line);
            }
            elsif ($grammar =~ m/(?=$RESYNCPATMK)/gco
                and do { ($code) = extract_bracketed($grammar,'<');
                      $code })
            {
                _parse("a resync with pattern marker", $aftererror,$line, $code );
                $code =~ /\A\s*<resync:(.*)>\Z/s;
                $item = new Parse::RecDescent::Directive(
                          'if ($text =~ s/(\A'.$1.')//) { $return = 0; $1; } else { undef }',
                          $lookahead,$line,$code);
                $prod and $prod->additem($item)
                      or  _no_rule($code,$line);
            }
            elsif ($grammar =~ m/(?=$SKIPMK)/gco
                and do { ($code) = extract_codeblock($grammar,'<');
                      $code })
            {
                _parse("a skip marker", $aftererror,$line, $code );
                $code =~ /\A\s*<skip:(.*)>\Z/s;
                if ($rule) {
                    $item = new Parse::RecDescent::Directive(
                        'my $oldskip = $skip; $skip='.$1.'; $oldskip',
                        $lookahead,$line,$code);
                    $prod and $prod->additem($item)
                      or  _no_rule($code,$line);
                } else {
                    #global <skip> directive
                    $self->{skip} = $1;
                }
            }
            elsif ($grammar =~ m/(?=$RULEVARPATMK)/gco
                and do { ($code) = extract_codeblock($grammar,'{',undef,'<');
                     $code;
                       } )
            {
                _parse("a rule variable specifier", $aftererror,$line,$code);
                $code =~ /\A\s*<rulevar:(.*)>\Z/s;

                $rule and $rule->addvar($1,$self)
                      or  _no_rule($code,$line);

                $item = new Parse::RecDescent::UncondReject($lookahead,$line,$code);
                $prod and $prod->additem($item)
                      or  _no_rule($code,$line);
            }
            elsif ($grammar =~ m/(?=$AUTOACTIONPATMK)/gco
                and do { ($code) = extract_codeblock($grammar,'{',undef,'<');
                     $code;
                       } )
            {
                _parse("an autoaction specifier", $aftererror,$line,$code);
                $code =~ s/\A\s*<autoaction:(.*)>\Z/$1/s;
                if ($code =~ /\A\s*[^{]|[^}]\s*\Z/) {
                    $code = "{ $code }"
                }
        $self->{_check}{itempos} =
            $code =~ /\@itempos\b|\$itempos\s*\[/;
        $self->{_AUTOACTION}
            = new Parse::RecDescent::Action($code,0,-$line)
            }
            elsif ($grammar =~ m/(?=$DEFERPATMK)/gco
                and do { ($code) = extract_codeblock($grammar,'{',undef,'<');
                     $code;
                       } )
            {
                _parse("a deferred action specifier", $aftererror,$line,$code);
                $code =~ s/\A\s*<defer:(.*)>\Z/$1/s;
                if ($code =~ /\A\s*[^{]|[^}]\s*\Z/)
                {
                    $code = "{ $code }"
                }

                $item = new Parse::RecDescent::Directive(
                          "push \@{\$thisparser->{deferred}}, sub $code;",
                          $lookahead,$line,"<defer:$code>");
                $prod and $prod->additem($item)
                      or  _no_rule("<defer:$code>",$line);

                $self->{deferrable} = 1;
            }
            elsif ($grammar =~ m/(?=$TOKENPATMK)/gco
                and do { ($code) = extract_codeblock($grammar,'{',undef,'<');
                     $code;
                       } )
            {
                _parse("a token constructor", $aftererror,$line,$code);
                $code =~ s/\A\s*<token:(.*)>\Z/$1/s;

                my $types = eval 'no strict; local $SIG{__WARN__} = sub {0}; my @arr=('.$code.'); @arr' || ();
                if (!$types)
                {
                    _error("Incorrect token specification: \"$@\"", $line);
                    _hint("The <token:...> directive requires a list
                           of one or more strings representing possible
                           types of the specified token. For example:
                           <token:NOUN,VERB>");
                }
                else
                {
                    $item = new Parse::RecDescent::Directive(
                              'no strict;
                               $return = { text => $item[-1] };
                               @{$return->{type}}{'.$code.'} = (1..'.$types.');',
                              $lookahead,$line,"<token:$code>");
                    $prod and $prod->additem($item)
                          or  _no_rule("<token:$code>",$line);
                }
            }
            elsif ($grammar =~ m/$COMMITMK/gco)
            {
                _parse("an commit marker", $aftererror,$line, substr($grammar, $-[0], $+[0] - $-[0]) );
                $item = new Parse::RecDescent::Directive('$commit = 1',
                                  $lookahead,$line,"<commit>");
                $prod and $prod->additem($item)
                      or  _no_rule("<commit>",$line);
            }
            elsif ($grammar =~ m/$NOCHECKMK/gco) {
                _parse("an hint request", $aftererror,$line, substr($grammar, $-[0], $+[0] - $-[0]) );
        $::RD_CHECK = 0;
        }
            elsif ($grammar =~ m/$HINTMK/gco) {
                _parse("an hint request", $aftererror,$line, substr($grammar, $-[0], $+[0] - $-[0]) );
        $::RD_HINT = $self->{__HINT__} = 1;
        }
            elsif ($grammar =~ m/$WARNMK/gco) {
                _parse("an warning request", $aftererror,$line, substr($grammar, $-[0], $+[0] - $-[0]) );
        $::RD_WARN = $self->{__WARN__} = $1 ? $2+0 : 1;
        }
            elsif ($grammar =~ m/$TRACEBUILDMK/gco) {
                _parse("an grammar build trace request", $aftererror,$line, substr($grammar, $-[0], $+[0] - $-[0]) );
        $::RD_TRACE = $1 ? $2+0 : 1;
        }
            elsif ($grammar =~ m/$TRACEPARSEMK/gco) {
                _parse("an parse trace request", $aftererror,$line, substr($grammar, $-[0], $+[0] - $-[0]) );
        $self->{__TRACE__} = $1 ? $2+0 : 1;
        }
            elsif ($grammar =~ m/$AUTOERRORMK/gco)
            {
                $commitonly = $1;
                _parse("an error marker", $aftererror,$line, substr($grammar, $-[0], $+[0] - $-[0]) );
                $item = new Parse::RecDescent::Error('',$lookahead,$1,$line);
                $prod and $prod->additem($item)
                      or  _no_rule("<error>",$line);
                $aftererror = !$commitonly;
            }
            elsif ($grammar =~ m/(?=$MSGERRORMK)/gco
                and do { $commitonly = $1;
                     ($code) = extract_bracketed($grammar,'<');
                    $code })
            {
                _parse("an error marker", $aftererror,$line,$code);
                $code =~ /\A\s*<error\??:(.*)>\Z/s;
                $item = new Parse::RecDescent::Error($1,$lookahead,$commitonly,$line);
                $prod and $prod->additem($item)
                      or  _no_rule("$code",$line);
                $aftererror = !$commitonly;
            }
            elsif (do { $commitonly = $1;
                     ($code) = extract_bracketed($grammar,'<');
                    $code })
            {
                if ($code =~ /^<[A-Z_]+>$/)
                {
                    _error("Token items are not yet
                    supported: \"$code\"",
                           $line);
                    _hint("Items like $code that consist of angle
                    brackets enclosing a sequence of
                    uppercase characters will eventually
                    be used to specify pre-lexed tokens
                    in a grammar. That functionality is not
                    yet implemented. Or did you misspell
                    \"$code\"?");
                }
                else
                {
                    _error("Untranslatable item encountered: \"$code\"",
                           $line);
                    _hint("Did you misspell \"$code\"
                           or forget to comment it out?");
                }
            }
        }
        elsif ($grammar =~ m/$RULE/gco)
        {
            _parseunneg("a rule declaration", 0,
                    $lookahead,$line, substr($grammar, $-[0], $+[0] - $-[0]) ) or next;
            my $rulename = $1;
            if ($rulename =~ /Replace|Extend|Precompile|Save/ )
            {
                _warn(2,"Rule \"$rulename\" hidden by method
                       Parse::RecDescent::$rulename",$line)
                and
                _hint("The rule named \"$rulename\" cannot be directly
                       called through the Parse::RecDescent object
                       for this grammar (although it may still
                       be used as a subrule of other rules).
                       It can't be directly called because
                       Parse::RecDescent::$rulename is already defined (it
                       is the standard method of all
                       parsers).");
            }
            $rule = new Parse::RecDescent::Rule($rulename,$self,$line,$replace);
            $prod->check_pending($line) if $prod;
            $prod = $rule->addprod( new Parse::RecDescent::Production );
            $aftererror = 0;
        }
        elsif ($grammar =~ m/$UNCOMMITPROD/gco)
        {
            pos($grammar)-=9;
            _parseunneg("a new (uncommitted) production",
                    0, $lookahead, $line, substr($grammar, $-[0], $+[0] - $-[0]) ) or next;

            $prod->check_pending($line) if $prod;
            $prod = new Parse::RecDescent::Production($line,1);
            $rule and $rule->addprod($prod)
                  or  _no_rule("<uncommit>",$line);
            $aftererror = 0;
        }
        elsif ($grammar =~ m/$ERRORPROD/gco)
        {
            pos($grammar)-=6;
            _parseunneg("a new (error) production", $aftererror,
                    $lookahead,$line, substr($grammar, $-[0], $+[0] - $-[0]) ) or next;
            $prod->check_pending($line) if $prod;
            $prod = new Parse::RecDescent::Production($line,0,1);
            $rule and $rule->addprod($prod)
                  or  _no_rule("<error>",$line);
            $aftererror = 0;
        }
        elsif ($grammar =~ m/$PROD/gco)
        {
            _parseunneg("a new production", 0,
                    $lookahead,$line, substr($grammar, $-[0], $+[0] - $-[0]) ) or next;
            $rule
              and (!$prod || $prod->check_pending($line))
              and $prod = $rule->addprod(new Parse::RecDescent::Production($line))
            or  _no_rule("production",$line);
            $aftererror = 0;
        }
        elsif ($grammar =~ m/$LITERAL/gco)
        {
            my $literal = $1;
            ($code = $literal) =~ s/\\\\/\\/g;
            _parse("a literal terminal", $aftererror,$line,$literal);
            $item = new Parse::RecDescent::Literal($code,$lookahead,$line);
            $prod and $prod->additem($item)
                  or  _no_rule("literal terminal",$line,"'$literal'");
        }
        elsif ($grammar =~ m/$INTERPLIT/gco)
        {
            _parse("an interpolated literal terminal", $aftererror,$line, substr($grammar, $-[0], $+[0] - $-[0]) );
            $item = new Parse::RecDescent::InterpLit($1,$lookahead,$line);
            $prod and $prod->additem($item)
                  or  _no_rule("interpolated literal terminal",$line,"'$1'");
        }
        elsif ($grammar =~ m/$TOKEN/gco)
        {
            _parse("a /../ pattern terminal", $aftererror,$line, substr($grammar, $-[0], $+[0] - $-[0]) );
            $item = new Parse::RecDescent::Token($1,'/',$3?$3:'',$lookahead,$line);
            $prod and $prod->additem($item)
                  or  _no_rule("pattern terminal",$line,"/$1/");
        }
        elsif ($grammar =~ m/(?=$MTOKEN)/gco
            and do { ($code, undef, @components)
                    = extract_quotelike($grammar);
                 $code }
              )

        {
            _parse("an m/../ pattern terminal", $aftererror,$line,$code);
            $item = new Parse::RecDescent::Token(@components[3,2,8],
                                 $lookahead,$line);
            $prod and $prod->additem($item)
                  or  _no_rule("pattern terminal",$line,$code);
        }
        elsif ($grammar =~ m/(?=$MATCHRULE)/gco
                and do { ($code) = extract_bracketed($grammar,'<');
                     $code
                       }
               or $grammar =~ m/$SUBRULE/gco
                and $code = $1)
        {
            my $name = $code;
            my $matchrule = 0;
            if (substr($name,0,1) eq '<')
            {
                $name =~ s/$MATCHRULE\s*//;
                $name =~ s/\s*>\Z//;
                $matchrule = 1;
            }

        # EXTRACT TRAILING ARG LIST (IF ANY)

            my ($argcode) = extract_codeblock($grammar, "[]",'') || '';

        # EXTRACT TRAILING REPETITION SPECIFIER (IF ANY)

            if ($grammar =~ m/\G[(]/gc)
            {
                pos($grammar)--;

                if ($grammar =~ m/$OPTIONAL/gco)
                {
                    _parse("an zero-or-one subrule match", $aftererror,$line,"$code$argcode($1)");
                    $item = new Parse::RecDescent::Repetition($name,$1,0,1,
                                       $lookahead,$line,
                                       $self,
                                       $matchrule,
                                       $argcode);
                    $prod and $prod->additem($item)
                          or  _no_rule("repetition",$line,"$code$argcode($1)");

                    !$matchrule and $rule and $rule->addcall($name);
                }
                elsif ($grammar =~ m/$ANY/gco)
                {
                    _parse("a zero-or-more subrule match", $aftererror,$line,"$code$argcode($1)");
                    if ($2)
                    {
                        my $pos = pos $grammar;
                        substr($grammar,$pos,0,
                               "<leftop='$name(s?)': $name $2 $name>(s?) ");

                        pos $grammar = $pos;
                    }
                    else
                    {
                        $item = new Parse::RecDescent::Repetition($name,$1,0,$MAXREP,
                                           $lookahead,$line,
                                           $self,
                                           $matchrule,
                                           $argcode);
                        $prod and $prod->additem($item)
                              or  _no_rule("repetition",$line,"$code$argcode($1)");

                        !$matchrule and $rule and $rule->addcall($name);

                        _check_insatiable($name,$1,$grammar,$line) if $::RD_CHECK;
                    }
                }
                elsif ($grammar =~ m/$MANY/gco)
                {
                    _parse("a one-or-more subrule match", $aftererror,$line,"$code$argcode($1)");
                    if ($2)
                    {
                        # $DB::single=1;
                        my $pos = pos $grammar;
                        substr($grammar,$pos,0,
                               "<leftop='$name(s)': $name $2 $name> ");

                        pos $grammar = $pos;
                    }
                    else
                    {
                        $item = new Parse::RecDescent::Repetition($name,$1,1,$MAXREP,
                                           $lookahead,$line,
                                           $self,
                                           $matchrule,
                                           $argcode);

                        $prod and $prod->additem($item)
                              or  _no_rule("repetition",$line,"$code$argcode($1)");

                        !$matchrule and $rule and $rule->addcall($name);

                        _check_insatiable($name,$1,$grammar,$line) if $::RD_CHECK;
                    }
                }
                elsif ($grammar =~ m/$EXACTLY/gco)
                {
                    _parse("an exactly-$1-times subrule match", $aftererror,$line,"$code$argcode($1)");
                    if ($2)
                    {
                        my $pos = pos $grammar;
                        substr($grammar,$pos,0,
                               "<leftop='$name($1)': $name $2 $name>($1) ");

                        pos $grammar = $pos;
                    }
                    else
                    {
                        $item = new Parse::RecDescent::Repetition($name,$1,$1,$1,
                                           $lookahead,$line,
                                           $self,
                                           $matchrule,
                                           $argcode);
                        $prod and $prod->additem($item)
                              or  _no_rule("repetition",$line,"$code$argcode($1)");

                        !$matchrule and $rule and $rule->addcall($name);
                    }
                }
                elsif ($grammar =~ m/$BETWEEN/gco)
                {
                    _parse("a $1-to-$2 subrule match", $aftererror,$line,"$code$argcode($1..$2)");
                    if ($3)
                    {
                        my $pos = pos $grammar;
                        substr($grammar,$pos,0,
                               "<leftop='$name($1..$2)': $name $3 $name>($1..$2) ");

                        pos $grammar = $pos;
                    }
                    else
                    {
                        $item = new Parse::RecDescent::Repetition($name,"$1..$2",$1,$2,
                                           $lookahead,$line,
                                           $self,
                                           $matchrule,
                                           $argcode);
                        $prod and $prod->additem($item)
                              or  _no_rule("repetition",$line,"$code$argcode($1..$2)");

                        !$matchrule and $rule and $rule->addcall($name);
                    }
                }
                elsif ($grammar =~ m/$ATLEAST/gco)
                {
                    _parse("a $1-or-more subrule match", $aftererror,$line,"$code$argcode($1..)");
                    if ($2)
                    {
                        my $pos = pos $grammar;
                        substr($grammar,$pos,0,
                               "<leftop='$name($1..)': $name $2 $name>($1..) ");

                        pos $grammar = $pos;
                    }
                    else
                    {
                        $item = new Parse::RecDescent::Repetition($name,"$1..",$1,$MAXREP,
                                           $lookahead,$line,
                                           $self,
                                           $matchrule,
                                           $argcode);
                        $prod and $prod->additem($item)
                              or  _no_rule("repetition",$line,"$code$argcode($1..)");

                        !$matchrule and $rule and $rule->addcall($name);
                        _check_insatiable($name,"$1..",$grammar,$line) if $::RD_CHECK;
                    }
                }
                elsif ($grammar =~ m/$ATMOST/gco)
                {
                    _parse("a one-to-$1 subrule match", $aftererror,$line,"$code$argcode(..$1)");
                    if ($2)
                    {
                        my $pos = pos $grammar;
                        substr($grammar,$pos,0,
                               "<leftop='$name(..$1)': $name $2 $name>(..$1) ");

                        pos $grammar = $pos;
                    }
                    else
                    {
                        $item = new Parse::RecDescent::Repetition($name,"..$1",1,$1,
                                           $lookahead,$line,
                                           $self,
                                           $matchrule,
                                           $argcode);
                        $prod and $prod->additem($item)
                              or  _no_rule("repetition",$line,"$code$argcode(..$1)");

                        !$matchrule and $rule and $rule->addcall($name);
                    }
                }
                elsif ($grammar =~ m/$BADREP/gco)
                {
                    my $current_match = substr($grammar, $-[0], $+[0] - $-[0]);
                    _parse("an subrule match with invalid repetition specifier", 0,$line, $current_match);
                    _error("Incorrect specification of a repeated subrule",
                           $line);
                    _hint("Repeated subrules like \"$code$argcode$current_match\" cannot have
                           a maximum repetition of zero, nor can they have
                           negative components in their ranges.");
                }
            }
            else
            {
                _parse("a subrule match", $aftererror,$line,$code);
                my $desc;
                if ($name=~/\A_alternation_\d+_of_production_\d+_of_rule/)
                    { $desc = $self->{"rules"}{$name}->expected }
                $item = new Parse::RecDescent::Subrule($name,
                                       $lookahead,
                                       $line,
                                       $desc,
                                       $matchrule,
                                       $argcode);

                $prod and $prod->additem($item)
                      or  _no_rule("(sub)rule",$line,$name);

                !$matchrule and $rule and $rule->addcall($name);
            }
        }
        elsif ($grammar =~ m/$LONECOLON/gco   )
        {
            _error("Unexpected colon encountered", $line);
            _hint("Did you mean \"|\" (to start a new production)?
                   Or perhaps you forgot that the colon
                   in a rule definition must be
                   on the same line as the rule name?");
        }
        elsif ($grammar =~ m/$ACTION/gco   ) # BAD ACTION, ALREADY FAILED
        {
            _error("Malformed action encountered",
                   $line);
            _hint("Did you forget the closing curly bracket
                   or is there a syntax error in the action?");
        }
        elsif ($grammar =~ m/$OTHER/gco   )
        {
            _error("Untranslatable item encountered: \"$1\"",
                   $line);
            _hint("Did you misspell \"$1\"
                   or forget to comment it out?");
        }

        if ($lookaheadspec =~ tr /././ > 3)
        {
            $lookaheadspec =~ s/\A\s+//;
            $lookahead = $lookahead<0
                    ? 'a negative lookahead ("...!")'
                    : 'a positive lookahead ("...")' ;
            _warn(1,"Found two or more lookahead specifiers in a
                   row.",$line)
            and
            _hint("Multiple positive and/or negative lookaheads
                   are simply multiplied together to produce a
                   single positive or negative lookahead
                   specification. In this case the sequence
                   \"$lookaheadspec\" was reduced to $lookahead.
                   Was this your intention?");
        }
        $lookahead = 0;
        $lookaheadspec = "";

        $grammar =~ m/\G\s+/gc;
    }

    if ($must_pop_lines) {
        pop @lines;
    }

    unless ($ERRORS or $isimplicit or !$::RD_CHECK)
    {
        $self->_check_grammar();
    }

    unless ($ERRORS or $isimplicit or $Parse::RecDescent::compiling)
    {
        my $code = $self->_code();
        if (defined $::RD_TRACE)
        {
            my $mode = ($nextnamespace eq "namespace000002") ? '>' : '>>';
            print STDERR "printing code (", length($code),") to RD_TRACE\n";
            local *TRACE_FILE;
            open TRACE_FILE, $mode, "RD_TRACE"
            and print TRACE_FILE "my \$ERRORS;\n$code"
            and close TRACE_FILE;
        }

        unless ( eval "$code 1" )
        {
            _error("Internal error in generated parser code!");
            $@ =~ s/at grammar/in grammar at/;
            _hint($@);
        }
    }

    if ($ERRORS and !_verbosity("HINT"))
    {
        local $::RD_HINT = defined $::RD_HINT ? $::RD_HINT : 1;
        _hint('Set $::RD_HINT (or -RD_HINT if you\'re using "perl -s")
               for hints on fixing these problems.  Use $::RD_HINT = 0
               to disable this message.');
    }
    if ($ERRORS) { $ERRORS=0; return }
    return $self;
}


sub _addstartcode($$)
{
    my ($self, $code) = @_;
    $code =~ s/\A\s*\{(.*)\}\Z/$1/s;

    $self->{"startcode"} .= "$code;\n";
}

# CHECK FOR GRAMMAR PROBLEMS....

sub _check_insatiable($$$$)
{
    my ($subrule,$repspec,$grammar,$line) = @_;
    pos($grammar)=pos($_[2]);
    return if $grammar =~ m/$OPTIONAL/gco || $grammar =~ m/$ANY/gco;
    my $min = 1;
    if ( $grammar =~ m/$MANY/gco
      || $grammar =~ m/$EXACTLY/gco
      || $grammar =~ m/$ATMOST/gco
      || $grammar =~ m/$BETWEEN/gco && do { $min=$2; 1 }
      || $grammar =~ m/$ATLEAST/gco && do { $min=$2; 1 }
      || $grammar =~ m/$SUBRULE(?!\s*:)/gco
       )
    {
        return unless $1 eq $subrule && $min > 0;
        my $current_match = substr($grammar, $-[0], $+[0] - $-[0]);
        _warn(3,"Subrule sequence \"$subrule($repspec) $current_match\" will
               (almost certainly) fail.",$line)
        and
        _hint("Unless subrule \"$subrule\" performs some cunning
               lookahead, the repetition \"$subrule($repspec)\" will
               insatiably consume as many matches of \"$subrule\" as it
               can, leaving none to match the \"$current_match\" that follows.");
    }
}

sub _check_grammar ($)
{
    my $self = shift;
    my $rules = $self->{"rules"};
    my $rule;
    foreach $rule ( values %$rules )
    {
        next if ! $rule->{"changed"};

    # CHECK FOR UNDEFINED RULES

        my $call;
        foreach $call ( @{$rule->{"calls"}} )
        {
            if (!defined ${$rules}{$call}
              &&!defined &{"Parse::RecDescent::$call"})
            {
                if (!defined $::RD_AUTOSTUB)
                {
                    _warn(3,"Undefined (sub)rule \"$call\"
                          used in a production.")
                    and
                    _hint("Will you be providing this rule
                           later, or did you perhaps
                           misspell \"$call\"? Otherwise
                           it will be treated as an
                           immediate <reject>.");
                    eval "sub $self->{namespace}::$call {undef}";
                }
                else    # EXPERIMENTAL
                {
                    my $rule = qq{'$call'};
                    if ($::RD_AUTOSTUB and $::RD_AUTOSTUB ne "1") {
                        $rule = $::RD_AUTOSTUB;
                    }
                    _warn(1,"Autogenerating rule: $call")
                    and
                    _hint("A call was made to a subrule
                           named \"$call\", but no such
                           rule was specified. However,
                           since \$::RD_AUTOSTUB
                           was defined, a rule stub
                           ($call : $rule) was
                           automatically created.");

                    $self->_generate("$call: $rule",0,1);
                }
            }
        }

    # CHECK FOR LEFT RECURSION

        if ($rule->isleftrec($rules))
        {
            _error("Rule \"$rule->{name}\" is left-recursive.");
            _hint("Redesign the grammar so it's not left-recursive.
                   That will probably mean you need to re-implement
                   repetitions using the '(s)' notation.
                   For example: \"$rule->{name}(s)\".");
            next;
        }

    # CHECK FOR PRODUCTIONS FOLLOWING EMPTY PRODUCTIONS
      {
          my $hasempty;
          my $prod;
          foreach $prod ( @{$rule->{"prods"}} ) {
              if ($hasempty) {
                  _error("Production " . $prod->describe . " for \"$rule->{name}\"
                         will never be reached (preceding empty production will
                         always match first).");
                  _hint("Reorder the grammar so that the empty production
                         is last in the list or productions.");
                  last;
              }
              $hasempty ||= $prod->isempty();
          }
      }
    }
}

# GENERATE ACTUAL PARSER CODE

sub _code($)
{
    my $self = shift;
    my $initial_skip = defined($self->{skip}) ? $self->{skip} : $skip;

    my $code = qq!
package $self->{namespace};
use strict;
use vars qw(\$skip \$AUTOLOAD $self->{localvars} );
\@$self->{namespace}\::ISA = ();
\$skip = '$initial_skip';
$self->{startcode}

{
local \$SIG{__WARN__} = sub {0};
# PRETEND TO BE IN Parse::RecDescent NAMESPACE
*$self->{namespace}::AUTOLOAD   = sub
{
    no strict 'refs';
!
# This generated code uses ${"AUTOLOAD"} rather than $AUTOLOAD in
# order to avoid the circular reference documented here:
#    https://rt.perl.org/rt3/Public/Bug/Display.html?id=110248
# As a result of the investigation of
#    https://rt.cpan.org/Ticket/Display.html?id=53710
. qq!
    \${"AUTOLOAD"} =~ s/^$self->{namespace}/Parse::RecDescent/;
    goto &{\${"AUTOLOAD"}};
}
}

!;
    $code .= "push \@$self->{namespace}\::ISA, 'Parse::RecDescent';";
    $self->{"startcode"} = '';

    my $rule;
    foreach $rule ( values %{$self->{"rules"}} )
    {
        if ($rule->{"changed"})
        {
            $code .= $rule->code($self->{"namespace"},$self);
            $rule->{"changed"} = 0;
        }
    }

    return $code;
}


# EXECUTING A PARSE....

sub AUTOLOAD    # ($parser, $text; $linenum, @args)
{
    croak "Could not find method: $AUTOLOAD\n" unless ref $_[0];
    my $class = ref($_[0]) || $_[0];
    my $text = ref($_[1]) eq 'SCALAR' ? ${$_[1]} : "$_[1]";
    $_[0]->{lastlinenum} = _linecount($text);
    $_[0]->{lastlinenum} += ($_[2]||0) if @_ > 2;
    $_[0]->{offsetlinenum} = $_[0]->{lastlinenum};
    $_[0]->{fulltext} = $text;
    $_[0]->{fulltextlen} = length $text;
    $_[0]->{linecounter_cache} = {};
    $_[0]->{deferred} = [];
    $_[0]->{errors} = [];
    my @args = @_[3..$#_];
    my $args = sub { [ @args ] };

    $AUTOLOAD =~ s/$class/$_[0]->{namespace}/;
    no strict "refs";

    local $::RD_WARN  = $::RD_WARN  || $_[0]->{__WARN__};
    local $::RD_HINT  = $::RD_HINT  || $_[0]->{__HINT__};
    local $::RD_TRACE = $::RD_TRACE || $_[0]->{__TRACE__};

    croak "Unknown starting rule ($AUTOLOAD) called\n"
        unless defined &$AUTOLOAD;
    my $retval = &{$AUTOLOAD}(
        $_[0], # $parser
        $text, # $text
        undef, # $repeating
        undef, # $_noactions
        $args, # \@args
        undef, # $_itempos
    );


    if (defined $retval)
    {
        foreach ( @{$_[0]->{deferred}} ) { &$_; }
    }
    else
    {
        foreach ( @{$_[0]->{errors}} ) { _error(@$_); }
    }

    if (ref $_[1] eq 'SCALAR') { ${$_[1]} = $text }

    $ERRORS = 0;
    return $retval;
}

sub _parserepeat($$$$$$$$$)    # RETURNS A REF TO AN ARRAY OF MATCHES
{
    my ($parser, $text, $prod, $min, $max, $_noactions, $expectation, $argcode, $_itempos) = @_;
    my @tokens = ();

    my $itemposfirst;
    my $reps;
    for ($reps=0; $reps<$max;)
    {
        $expectation->at($text);
        my $_savetext = $text;
        my $prevtextlen = length $text;
        my $_tok;
        if (! defined ($_tok = &$prod($parser,$text,1,$_noactions,$argcode,$_itempos)))
        {
            $text = $_savetext;
            last;
        }

        if (defined($_itempos) and !defined($itemposfirst))
        {
            $itemposfirst = Parse::RecDescent::Production::_duplicate_itempos($_itempos);
        }

        push @tokens, $_tok if defined $_tok;
        last if ++$reps >= $min and $prevtextlen == length $text;
    }

    do { $expectation->failed(); return undef} if $reps<$min;

    if (defined $itemposfirst)
    {
        Parse::RecDescent::Production::_update_itempos($_itempos, $itemposfirst, undef, [qw(from)]);
    }

    $_[1] = $text;
    return [@tokens];
}

sub set_autoflush {
    my $orig_selected = select $_[0];
    $| = 1;
    select $orig_selected;
    return;
}

# ERROR REPORTING....

sub _write_ERROR {
    my ($errorprefix, $errortext) = @_;
    return if $errortext !~ /\S/;
    $errorprefix =~ s/\s+\Z//;
    local $^A = q{};

    formline(<<'END_FORMAT', $errorprefix, $errortext);
@>>>>>>>>>>>>>>>>>>>>: ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
END_FORMAT
    formline(<<'END_FORMAT', $errortext);
~~                     ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
END_FORMAT
    print {*STDERR} $^A;
}

# TRACING

my $TRACE_FORMAT = <<'END_FORMAT';
@>|@|||||||||@^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<|
  | ~~       |^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<|
END_FORMAT

my $TRACECONTEXT_FORMAT = <<'END_FORMAT';
@>|@|||||||||@                                      |^<<<<<<<<<<<<<<<<<<<<<<<<<<<
  | ~~       |                                      |^<<<<<<<<<<<<<<<<<<<<<<<<<<<
END_FORMAT

sub _write_TRACE {
    my ($tracelevel, $tracerulename, $tracemsg) = @_;
    return if $tracemsg !~ /\S/;
    $tracemsg =~ s/\s*\Z//;
    local $^A = q{};
    my $bar = '|';
    formline($TRACE_FORMAT, $tracelevel, $tracerulename, $bar, $tracemsg, $tracemsg);
    print {*STDERR} $^A;
}

sub _write_TRACECONTEXT {
    my ($tracelevel, $tracerulename, $tracecontext) = @_;
    return if $tracecontext !~ /\S/;
    $tracecontext =~ s/\s*\Z//;
    local $^A = q{};
    my $bar = '|';
    formline($TRACECONTEXT_FORMAT, $tracelevel, $tracerulename, $bar, $tracecontext, $tracecontext);
    print {*STDERR} $^A;
}

sub _verbosity($)
{
       defined $::RD_TRACE
    or defined $::RD_HINT    and  $::RD_HINT   and $_[0] =~ /ERRORS|WARN|HINT/
    or defined $::RD_WARN    and  $::RD_WARN   and $_[0] =~ /ERRORS|WARN/
    or defined $::RD_ERRORS  and  $::RD_ERRORS and $_[0] =~ /ERRORS/
}

sub _error($;$)
{
    $ERRORS++;
    return 0 if ! _verbosity("ERRORS");
    my $errortext   = $_[0];
    my $errorprefix = "ERROR" .  ($_[1] ? " (line $_[1])" : "");
    $errortext =~ s/\s+/ /g;
    print {*STDERR} "\n" if _verbosity("WARN");
    _write_ERROR($errorprefix, $errortext);
    return 1;
}

sub _warn($$;$)
{
    return 0 unless _verbosity("WARN") && ($::RD_HINT || $_[0] >= ($::RD_WARN||1));
    my $errortext   = $_[1];
    my $errorprefix = "Warning" .  ($_[2] ? " (line $_[2])" : "");
    print {*STDERR} "\n" if _verbosity("HINT");
    $errortext =~ s/\s+/ /g;
    _write_ERROR($errorprefix, $errortext);
    return 1;
}

sub _hint($)
{
    return 0 unless $::RD_HINT;
    my $errortext = $_[0];
    my $errorprefix = "Hint" .  ($_[1] ? " (line $_[1])" : "");
    $errortext =~ s/\s+/ /g;
    _write_ERROR($errorprefix, $errortext);
    return 1;
}

sub _tracemax($)
{
    if (defined $::RD_TRACE
        && $::RD_TRACE =~ /\d+/
        && $::RD_TRACE>1
        && $::RD_TRACE+10<length($_[0]))
    {
        my $count = length($_[0]) - $::RD_TRACE;
        return substr($_[0],0,$::RD_TRACE/2)
            . "...<$count>..."
            . substr($_[0],-$::RD_TRACE/2);
    }
    else
    {
        return substr($_[0],0,500);
    }
}

sub _tracefirst($)
{
    if (defined $::RD_TRACE
        && $::RD_TRACE =~ /\d+/
        && $::RD_TRACE>1
        && $::RD_TRACE+10<length($_[0]))
    {
        my $count = length($_[0]) - $::RD_TRACE;
        return substr($_[0],0,$::RD_TRACE) . "...<+$count>";
    }
    else
    {
        return substr($_[0],0,500);
    }
}

my $lastcontext = '';
my $lastrulename = '';
my $lastlevel = '';

sub _trace($;$$$)
{
    my $tracemsg      = $_[0];
    my $tracecontext  = $_[1]||$lastcontext;
    my $tracerulename = $_[2]||$lastrulename;
    my $tracelevel    = $_[3]||$lastlevel;
    if ($tracerulename) { $lastrulename = $tracerulename }
    if ($tracelevel)    { $lastlevel = $tracelevel }

    $tracecontext =~ s/\n/\\n/g;
    $tracecontext =~ s/\s+/ /g;
    $tracerulename = qq{$tracerulename};
    _write_TRACE($tracelevel, $tracerulename, $tracemsg);
    if ($tracecontext ne $lastcontext)
    {
        if ($tracecontext)
        {
            $lastcontext = _tracefirst($tracecontext);
            $tracecontext = qq{"$tracecontext"};
        }
        else
        {
            $tracecontext = qq{<NO TEXT LEFT>};
        }
        _write_TRACECONTEXT($tracelevel, $tracerulename, $tracecontext);
    }
}

sub _matchtracemessage
{
    my ($self, $reject) = @_;

    my $prefix = '';
    my $postfix = '';
    my $matched = not $reject;
    my @t = ("Matched", "Didn't match");
    if (exists $self->{lookahead} and $self->{lookahead})
    {
        $postfix = $reject ? "(reject)" : "(keep)";
        $prefix = "...";
        if ($self->{lookahead} < 0)
        {
            $prefix .= '!';
            $matched = not $matched;
        }
    }
    $prefix . ($matched ? $t[0] : $t[1]) . $postfix;
}

sub _parseunneg($$$$$)
{
    _parse($_[0],$_[1],$_[3],$_[4]);
    if ($_[2]<0)
    {
        _error("Can't negate \"$_[4]\".",$_[3]);
        _hint("You can't negate $_[0]. Remove the \"...!\" before
               \"$_[4]\".");
        return 0;
    }
    return 1;
}

sub _parse($$$$)
{
    my $what = $_[3];
       $what =~ s/^\s+//;
    if ($_[1])
    {
        _warn(3,"Found $_[0] ($what) after an unconditional <error>",$_[2])
        and
        _hint("An unconditional <error> always causes the
               production containing it to immediately fail.
               \u$_[0] that follows an <error>
               will never be reached.  Did you mean to use
               <error?> instead?");
    }

    return if ! _verbosity("TRACE");
    my $errortext = "Treating \"$what\" as $_[0]";
    my $errorprefix = "Parse::RecDescent";
    $errortext =~ s/\s+/ /g;
    _write_ERROR($errorprefix, $errortext);
}

sub _linecount($) {
    scalar substr($_[0], pos $_[0]||0) =~ tr/\n//
}


package main;

use vars qw ( $RD_ERRORS $RD_WARN $RD_HINT $RD_TRACE $RD_CHECK );
$::RD_CHECK = 1;
$::RD_ERRORS = 1;
$::RD_WARN = 3;

1;