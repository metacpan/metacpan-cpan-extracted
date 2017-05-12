package Repl::Cmd::MathCmd;

use strict;
use warnings;

use Repl::Spec::Types;
use Carp;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();

# Ordinary function, not a method.
sub registerCommands
{
    my $repl = shift;
    $repl->registerCommand("+", new Repl::Cmd::MathCmd("add"));
    $repl->registerCommand("-", new Repl::Cmd::MathCmd("sub"));
    $repl->registerCommand("*", new Repl::Cmd::MathCmd("mult"));
    $repl->registerCommand("/", new Repl::Cmd::MathCmd("div"));
    $repl->registerCommand("^", new Repl::Cmd::MathCmd("pow"));
    $repl->registerCommand("fin", new Repl::Cmd::MathCmd("fin"));
    $repl->registerCommand("float->int", new Repl::Cmd::MathCmd("toInt"));
    $repl->registerCommand("zero?", new Repl::Cmd::MathCmd("isZero"));
    $repl->registerCommand("<", new Repl::Cmd::MathCmd("lt"));
    $repl->registerCommand("<~", new Repl::Cmd::MathCmd("le"));
    $repl->registerCommand(">", new Repl::Cmd::MathCmd("gt"));
    $repl->registerCommand(">~", new Repl::Cmd::MathCmd("ge"));
    
    my $parser = new Repl::Core::Parser();    
    $repl->evalExpr($parser->parseString("(defun fac (n) (if \$n (* \$n (fac (- \$n 1))) 1))"));
}

sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $type = shift;
    
    my $self= {};
    $self->{TYPE} = $type;
    return bless $self, $class;
}

sub execute
{
    my $self = shift;
    my $ctx = shift;
    my $args = shift;
    my $type = $self->{TYPE};
    
    # Remove the command name.    
    my $command = shift @$args;
    
    if($type eq 'add')
    {
        # Argument testing.
        my $checked = ARRAY_NUMBER_TYPE->guard($args);
        
        my $total = 0;
        foreach my $num (@$checked)
        {
            $total += $num;
        }
        return $total;
    }
    elsif($type eq 'sub')
    {
        my $checked = ARRAY_NUMBER_TYPE->guard($args);
        my $checkedsize = scalar(@$checked);
        croak sprintf("ERROR: Command '%s' expected at least one argument.", $command) if $checkedsize < 1;
        
        my $total = $checked->[0];
        my $i = 1;
        while ($i < $checkedsize)
        {
            $ total -= $checked->[$i];
            $i = $i + 1;
        }        
        return $total;
    }
    elsif($type eq 'mult')
    {
        my $checked = ARRAY_NUMBER_TYPE->guard($args);
        
        my $total = 1;
        foreach my $num (@$checked)
        {
            $total *= $num;
        }
        return $total;
    }
    elsif($type eq 'div')
    {
        my $checked = ARRAY_NUMBER_TYPE->guard($args);
        my $checkedsize = scalar(@$checked);
        croak sprintf("ERROR: Command '%s' expected at least one argument.", $command) if $checkedsize < 1;
        
        my $total = $checked->[0];
        my $i = 1;
        while ($i < $checkedsize)
        {
            $total /= $checked->[$i];
            $i = $i + 1;
        }        
        return $total;
    }
    elsif($type eq 'pow')
    {
        my $arg1 = NUMBER_TYPE->guard($args->[0]);
        my $arg2 = NUMBER_TYPE->guard($args->[1]);
        return $arg1 ** $arg2;
    }
    elsif($type eq 'fin')
    {
        my $checked = NUMBER_TYPE->guard($args->[0]);
        return sprintf ("%.2f", $checked);        
    }
    elsif($type eq 'toInt')
    {
        my $checked = NUMBER_TYPE->guard($args->[0]);
        return sprintf ("%.d", $checked);        
    }
    elsif($type eq 'isZero')
    {
        my $checked = NUMBER_TYPE->guard($args->[0]);
        return $checked == 0;        
    }
    elsif($type eq 'lt')
    {
        my $arg1 = NUMBER_TYPE->guard($args->[0]);
        my $arg2 = NUMBER_TYPE->guard($args->[1]);
        return $arg1 < $arg2;
    }
    elsif($type eq 'le')
    {
        my $arg1 = NUMBER_TYPE->guard($args->[0]);
        my $arg2 = NUMBER_TYPE->guard($args->[1]);
        return $arg1 <= $arg2;
    }
    elsif($type eq 'gt')
    {
        my $arg1 = NUMBER_TYPE->guard($args->[0]);
        my $arg2 = NUMBER_TYPE->guard($args->[1]);
        return $arg1 > $arg2;
    }
    elsif($type eq 'ge')
    {
        my $arg1 = NUMBER_TYPE->guard($args->[0]);
        my $arg2 = NUMBER_TYPE->guard($args->[1]);
        return $arg1 >= $arg2;
    }
    else
    {
        croak sprintf("ERROR: Command '%s' internal error.", $command);
    }
}

1;
