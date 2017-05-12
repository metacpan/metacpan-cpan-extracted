package Repl::Core::Eval;

# Pragma's.
use strict;
use warnings;
no warnings 'recursion';

# Uses.
use Repl::Core::BasicContext;
use Repl::Core::CompositeContext;
use Repl::Core::Pair;
use Repl::Core::CommandRepo;
use Repl::Core::MacroRepo;
use Repl::Core::Lambda;

use Time::HiRes qw/gettimeofday/;
use Carp;

sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    # Initialize the token instance.
    my $self = {};
    $self->{CTX} = new Repl::Core::BasicContext;
    $self->{CMDREPO} = new Repl::Core::CommandRepo;
    $self->{MACREPO} = new Repl::Core::MacroRepo;
    return bless($self, $class);
}

# Getter and setter.
sub commandRepo
{
    my $self = shift;
    my $arg = shift;
    $self->{CMDREPO} = $arg if $arg;
    return $self->{CMDREPO};
}

# Two parameters:
# - A name
# - A command instance.
sub registerCommand
{
    my $self = shift;
    my $name = shift;
    my $cmd = shift;
    $self->{CMDREPO}->registerCommand($name, $cmd);    
}


# Getter and setter.
sub context
{
    my $self = shift;
    my $arg = shift;
    $self->{CTX} = $arg if $arg;
    return $self->{CTX};
}

# The eval that should be called from the outside.
# A single parameter: the expression.
sub evalExpr
{
    my ($self, $expr) = @_;
    my $result;
    eval {$result = $self->evalInContext($expr, $self->{CTX});};
    croak sprintf("ERROR: An error occured while evaluating an expression.\n%s", cutat($@)) if($@);
    return $result;
}

# Internal, private eval.
sub evalInContext
{
    my ($self, $expr, $ctx) = @_;
    my $evalres = eval {
    if(!(ref($expr) eq 'ARRAY'))
    {
        # I. Atomic expressions.
        ########################
        
        if($expr =~ /\$(.+)/)
        {
            return $ctx->getBinding($1);            
        }
        elsif(ref($expr) && $expr->isa("Repl::Core::Pair"))
        {
            my $left = $self->evalInContext($expr->getLeft(), $ctx);
            my $right = $self->evalInContext($expr->getRight(), $ctx);
            return new Repl::Core::Pair(LEFT=>$left, RIGHT=>$right);            
        }
        else
        {
            return $expr;
        }
    }
    else
    {
        # II. ARRAY composite expressions.
        ##################################
        
        # An empty list is not evaluated, it evaluates to itself.
        return $expr if ! scalar($expr);
        # We have a non-empty list here.
        my $cmdCandidate = @$expr[0] || '';
        my $listsize = scalar(@{$expr});
        
        # 1. Special forms.
        
        if("quote" eq $cmdCandidate)
        {
            return @$expr[1] if $listsize == 2;
            die "ERROR: Quote bad format."                        
        }
        elsif("if" eq $cmdCandidate)
        {
            die "ERROR: If bad format" if $listsize < 3 || $listsize > 4;
            if($self->boolEval($self->evalInContext($expr->[1], $ctx)))
            {
                return $self->evalInContext($expr->[2], $ctx);             
            }
            elsif($listsize == 4)
            {
                return $self->evalInContext($expr->[3], $ctx);             
            }
            else
            {
                return;
            }                              
        }
        elsif("while" eq $cmdCandidate)
        {
            die "ERROR: While bad format" if $listsize < 2 || $listsize > 3;
            my $result;
            while($self->boolEval($self->evalInContext($expr->[1], $ctx)))
            {
                if($listsize == 3)
                {
                    $result = $self->evalInContext($expr->[2], $ctx);
                }                
            }
            return $result;
        }
        elsif("and" eq $cmdCandidate)
        {
            die "ERROR: And bad format" if $listsize < 2;
            for(my $i = 1; $i < $listsize; $i = $i + 1)
            {
                my $el = $expr->[$i];
                return 0 if !$self->boolEval($self->evalInContext($el, $ctx));                 
            }
            return 1;
        }
        elsif("or" eq $cmdCandidate)
        {
            die "ERROR: Or bad format" if $listsize < 2;
            for(my $i = 1; $i < $listsize;$i = $i + 1)
            {
                my $el = $expr->[$i];
                return 1 if $self->boolEval($self->evalInContext($el, $ctx));                 
            }
            return 0;           
        }
        elsif("not" eq $cmdCandidate)
        {
            die "ERROR: Not bad format." if $listsize != 2;
            if($self->evalInContext($expr->[1], $ctx))
            {
                return 0;
            }
            else
            {
                return 1;
            }            
        }
        elsif("set" eq $cmdCandidate || "defvar" eq $cmdCandidate)
        {
            my $name;
            my $value;
            
            if($listsize == 2)
            {
                my $paircand = $expr->[1];
                if(ref($paircand) && $paircand->isa("Repl::Core::Pair"))
                {
                    $name = $self->evalInContext($paircand->getLeft(), $ctx);
                    $value = $self->evalInContext($paircand->getRight(), $ctx);                    
                }
                else
                {
                    die "ERROR: set bad format. Expected pair.";
                }                
            }
            elsif($listsize ==3)
            {
                $name = $self->evalInContext($expr->[1], $ctx);
                $value = $self->evalInContext($expr->[2], $ctx);                
            }
            else
            {
                die "ERROR: set is badly formed.";                
            }
            
            die "ERROR: set name should be scalar." if ref($name);
            
            if("set" eq $cmdCandidate)
            {
                # set.
                $ctx->setBinding($name, $value);
            }
            else
            {
                # defvar.
                $ctx->getRootContext()->defBinding($name, $value);                
            }
            return $value;
        }
        elsif("let" eq $cmdCandidate || "let*" eq $cmdCandidate)
        {
            die "ERROR: bad let/let* form." if $listsize != 3;
            my $bindings = $expr->[1];
            my $letexpr = $expr->[2];
            my $isletrec = ($cmdCandidate eq "let*");
            
            die "ERROR: bad let/let* form. Bindings should be array." if "ARRAY" ne ref($bindings);
            my $bindingprep = [];
            my $letctx = new Repl::Core::CompositeContext(new Repl::Core::BasicContext(), $ctx);
            
            foreach my $binding (@$bindings)
            {
                if(ref($binding) eq 'ARRAY')
                {
                    die "ERROR: bad binding." if scalar(@$binding) != 2;
                    my $key = $binding->[0];
                    my $val = $self->evalInContext($$binding->[1], $letctx);
                    if($isletrec)
                    {
                        $letctx->defBinding($key,$val);
                    }
                    else
                    {
                        push(@$bindingprep, new Repl::Core::Pair(LEFT=>$key, RIGHT=>$val));
                    }
                }
                elsif(ref($binding) eq 'Repl::Core::Pair')
                {
                    my $key = $binding->getLeft();
                    my $val = $self->evalInContext($binding->getRight(), $letctx);
                    
                    if($isletrec)
                    {
                        $letctx->defBinding($key,$val);
                    }
                    else
                    {
                        push(@$bindingprep, new Repl::Core::Pair(LEFT=>$key, RIGHT=>$val));
                    }                    
                }
                elsif(!ref($binding) && $binding)
                {
                    if($isletrec)
                    {
                        $letctx->defBinding($binding, "");
                    }
                    else
                    {
                        push(@$bindingprep, new Repl::Core::Pair($binding, ""));
                    }                    
                }
                else
                {
                    die "ERROR: bad let/let* binding list.";
                }
            }
            
            if(!$isletrec)
            {
                foreach my $pair (@$bindingprep)
                {
                    $letctx->defBinding($pair->getLeft(), $pair->getRight());
                }
            }
            
            # Evaluate the let body.
            return $self->evalInContext($letexpr, $letctx);            
        }
        elsif ("get" eq $cmdCandidate)
        {
            die "ERROR: get format." if $listsize != 2;
            my $name = $self->evalInContext($expr->[1], $ctx);
            die "ERROR: get not string." if ref($name);
            return $ctx->getBinding($name);                        
        }
        elsif("lambda" eq $cmdCandidate)
        {
            die "ERROR: lambda bad form." if $listsize != 3;
            my $params = $expr->[1];
            my $body = $expr->[2];
            
            die "ERROR: lambda param list." if(ref($params) ne 'ARRAY');                
            die "ERROR: lambda body." if !$body;
            foreach my $param (@$params)
            {
                die "ERROR: Lambda bad parameter" if ref($param) || !$param;
            }    
            
            # Create a new parameter list copy.
            my $paramlist = [@$params];
            return new Repl::Core::Lambda($paramlist, $body, $ctx);                        
        }
        elsif("defun" eq $cmdCandidate)
        {
            die "ERROR: defun form." if $listsize != 4;
            my $name = $expr->[1];
            my $params = $expr->[2];
            my $body = $expr->[3];
            
            die "ERROR: defun name." if(!$name || ref($name));
            die "ERROR: defun params." if(ref($params) ne 'ARRAY');
            die "ERROR: defun body." if !$body;
            foreach my $param (@$params)
            {
                die "ERROR: defun bad parameter" if ref($param) || !$param;
            }
            
            my $lambdamacro = ["lambda", $params, $body];
            my $lambda = $self->evalInContext($lambdamacro, $ctx);
            $ctx->getRootContext()->defBinding($name, $lambda);
            
            return $lambda;
        }
        elsif("timer" eq $cmdCandidate)
        {
            die "ERROR: timer form." if $listsize != 2;
            my $start = gettimeofday() * 1000;
            my $result = $self->evalInContext($expr->[1], $ctx);
            my $stop = gettimeofday() * 1000;
            return $stop - $start;                 
        }
        elsif($self->{MACREPO}->hasMacro($cmdCandidate))
        {
            my $macro = $self->{MACREPO}->getCommand($cmdCandidate);
            my $transformed = $macro->transform(@$expr[1..($listsize -1)]);
            return $self->eval($transformed, $ctx);
        }
        
        # 2. All the other arrays are evaluated in a standard way.
        
        my $evallist  = [];
        
        foreach my $el (@$expr)
        {
            push @$evallist, $self->evalInContext($el, $ctx);
            
        }
        $cmdCandidate = $evallist->[0] || '';
        
        die "ERROR: An empty list cannot be executed." if(scalar(@$evallist) == 0);
        
        if("eval" eq $cmdCandidate)
        {
            die "ERROR: bad eval form." if $listsize != 2;
            return $self->evalInContext($evallist->[1], $ctx);            
        }
        elsif("eq" eq $cmdCandidate)
        {
            die "ERROR: eq bad form." if$listsize != 3;
            my $arg1 = $self->evalInContext($evallist->[1], $ctx);
            my $arg2 = $self->evalInContext($evallist->[2], $ctx);
            return $arg1 eq $arg2;            
        }
        elsif("progn" eq $cmdCandidate)
        {
            die "ERROR: progn bad form" if $listsize < 2;
            return $evallist->[$listsize - 1];            
        }
        elsif("funcall" eq $cmdCandidate)
        {
            die "ERROR: funcall bad form." if $listsize < 2;
            my $name = $evallist->[1];
            my $lambda;
            
            if(ref($name) eq 'Repl::Core::Lambda')
            {
                $lambda = $name;
            }
            elsif(!ref($name))
            {
                my $obj = $ctx->getBinding($name);
                if(ref($obj) eq 'Repl::Core::Lambda')
                {
                    $lambda = $obj;
                }
                else 
                {
                    die "ERROR: function not found in the context.";
                }                
            }
            else
            {
                die "ERROR: first part of funcall is not a function name or a lambda.";
            }
            
            my $callctx;
            eval {$callctx = $lambda->createContext(@$evallist[2..($listsize-1)])};
            die sprintf("ERROR in arglist.\n%s", $@) if $@;
            
            my $result;
            eval {$result = $self->evalInContext($lambda->getExpr(), $callctx)};
            die sprintf("ERROR in call of %s.\n%s", $name, $@) if $@;
            
            return $result;
        }
        elsif($self->{CMDREPO}->hasCommand($cmdCandidate))
        {
            my $cmd = $self->{CMDREPO}->getCommand($cmdCandidate);            
            my $result;
            eval {$result = $cmd->execute($ctx, $evallist)};
            if($@)
            {
                # Leave the line number in this case, the author of the command
                # might need this information to pinpoint the location of the error.
                die sprintf("ERROR: Command '%s' generated an error.\n%s", $cmdCandidate, $@);                
            }
            else
            {
                # Simply return the result.
                return $result;
            }
        }
        elsif($ctx->isBound($cmdCandidate) && ref($ctx->getBinding($cmdCandidate)) eq "Repl::Core::Lambda")
        {
            # Convenience, funcall shorthand.
            # When a name is used, the eval tries to use the lambda in the context.
            
            my $lambda = $ctx->getBinding($cmdCandidate);
            my $macro = ["funcall", $lambda, @$evallist[1..($listsize-1)]];
            return $self->evalInContext($macro, $ctx);            
        }
        elsif(ref($cmdCandidate) eq "Repl::Core::Lambda")
        {
            # Convenience, funcall shorthand.
            # A lambda as first argument.
            
            my $macro = ["funcall", @$evallist];
            return $self->evalInContext($macro, $ctx);            
        }
        else
        {
            if($cmdCandidate)
            {
                die sprintf("ERROR: The command name should evaluate to a string or a lambda.\nFound '%s' which cannot be interpreted as a function.", $cmdCandidate);                
            }
            else
            {
                die "ERROR: The command name should evaluate to a string or a lambda. Found null.";    
            }            
        }                          
    }
    };
    if($@)
    {
        my $totalMsgLim = 1000;
        my $entryMsgLim = 80;
        
        my $prettyexpr = $expr;
        $prettyexpr = pretty($expr);
        
        my $msg = cutat($@);        
        if(length($msg) >= $totalMsgLim)
        {
            if(! ($msg =~ /.*-> \.\.\. $/))
            {
                $msg = $msg . "\n-> ...";
            }
        }
        else
        {
            $msg = sprintf("%s-> %s", $msg, $prettyexpr);
        }
        
        croak $msg;
    }
    else
    {
        return $evalres;
    }
}

# Ordinary function, not a method.
# Cut of the "at <file> <line>." part of the error message.
sub cutat
{
    my $msg = shift;
    # Note the 's' regexp option to allow . to match newlines.
    if($msg =~ /\A(.*) at .+ line .*\Z/s)
    {
         # Cut of the "at <filename> line dddd." part.
         # Because it will always point to this location here.
        $msg = $1 . "\n";
    }
    return $msg;    
}

# Ordinary function, not a method.
# Pretty print an array (recursively).
sub pretty
{
    my $arr = shift;
    if(ref($arr) eq "ARRAY")
    {
        my $arrsize = scalar(@$arr);
        my $i = 0;
        
        my $buf = "(";
        foreach my $el (@$arr)
        {
            $buf = $buf . pretty($el);
            $buf = $buf . " " if($i != ($arrsize - 1)) ;
            $i = $i + 1;            
        }
        $buf = $buf . ")";
        return $buf;
    }
    
    return $arr;    
}

sub boolEval
{
    my $self = shift;
    my $expr = shift;
    
    return 0 if !defined $expr;
    return 1 if($expr =~ /true|ok|on|yes|y|t/i );
    return 0 if($expr =~ /false|nok|off|no|n|f/i);
    return 1 if ($expr != 0);
    if(ref($expr) eq 'ARRAY')
    {
        return scalar($expr) > 0;
    }    
    return 0;    
}

1;
