package Repl::Cmd::LispCmd;

use strict;
use warnings;

use Repl::Spec::Args::OptionalArg;
use Repl::Spec::Args::NamedArg;
use Repl::Spec::Args::FixedArg;
use Repl::Spec::Args::VarArg;
use Repl::Spec::Args::StdArgList;
use Repl::Spec::Args::VarArgList;
use Repl::Spec::Types;
use Carp;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();

# Ordinary function, not a method.
sub registerCommands
{
    my $repl = shift;
    
    # $repl->registerCommand("ls", new Repl::Cmd::FileSysCmd("ls", $repl->getEval()));
    $repl->registerCommand("size", new Repl::Cmd::LispCmd("size"));
    $repl->registerCommand("car", new Repl::Cmd::LispCmd("car"));
    $repl->registerCommand("cdr", new Repl::Cmd::LispCmd("cdr"));
    $repl->registerCommand("push", new Repl::Cmd::LispCmd("push"));
    $repl->registerCommand("pop", new Repl::Cmd::LispCmd("pop"));
    $repl->registerCommand("shift", new Repl::Cmd::LispCmd("shift"));
    $repl->registerCommand("unshift", new Repl::Cmd::LispCmd("unshift"));
    $repl->registerCommand("append", new Repl::Cmd::LispCmd("append"));
    $repl->registerCommand("list?", new Repl::Cmd::LispCmd("list?"));
    $repl->registerCommand("empty?", new Repl::Cmd::LispCmd("empty?"));
    $repl->registerCommand("member?", new Repl::Cmd::LispCmd("member?"));
}

our $fix_arr = new Repl::Spec::Args::FixedArg(ARRAY_TYPE);
our $fix_whatever = new Repl::Spec::Args::FixedArg(WHATEVER_TYPE);
our $var_defined = new Repl::Spec::Args::VarArg(DEFINED_TYPE);
our $var_arr = new Repl::Spec::Args::VarArg(ARRAY_TYPE);

our $size_args = new Repl::Spec::Args::StdArgList([$fix_arr], [], []);
our $car_args = $size_args;
our $cdr_args = $size_args;
our $push_args = new Repl::Spec::Args::VarArgList([$fix_arr], $var_defined, 1, -1, []);
our $pop_args = $size_args;
our $shift_args = $size_args;
our $unshift_args = $push_args;
our $append_args = new Repl::Spec::Args::VarArgList([], $var_arr, 0, -1, []);
our $list_args = new Repl::Spec::Args::StdArgList([$fix_whatever], [], []);
our $empty_args = $size_args;
our $member_args = new Repl::Spec::Args::StdArgList([$fix_arr, $fix_whatever], [], []);

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
    
    if($type eq 'size')
    {
        my $checked = $size_args->guard($args, $ctx);
        my $arrref = $checked->[1];
        return scalar(@$arrref);
    }
    elsif($type eq "car")
    {
        my $checked = $car_args->guard($args, $ctx);
        my $arrref = $checked->[1];
        croak sprintf("ERROR: Command '%s' expects a non-empty array.", $args->[0]) if(!@$arrref);
        return $arrref->[0];
      
    }
    elsif($type eq "cdr")
    {
        my $checked = $cdr_args->guard($args, $ctx);
        my $arrref = $checked->[1];
        croak sprintf("ERROR: Command '%s' expects a non-empty array.", $args->[0]) if(!@$arrref);
        my @arr = @$arrref;
        # Return a new reference.
        return [@arr[1..$#arr]];
    }
    elsif($type eq "push")
    {
        my $checked = $push_args->guard($args, $ctx);
        my $arrref = $checked->[1];
        
        for(my $i = 2; $i < @$checked; $i = $i + 1)
        {
            push @$arrref, $checked->[$i];            
        }
        return $arrref;       
    }
    elsif($type eq "pop")
    {
        my $checked = $pop_args->guard($args, $ctx);
        my $arrref = $checked->[1];
        croak sprintf("ERROR: Command '%s' expects a non-empty array.", $args->[0]) if(!@$arrref);
        return pop @$arrref;      
    }
    elsif($type eq "shift")
    {
        my $checked = $shift_args->guard($args, $ctx);
        my $arrref = $checked->[1];
        croak sprintf("ERROR: Command '%s' expects a non-empty array.", $args->[0]) if(!@$arrref);
        return shift @$arrref;      
    }
    elsif($type eq "unshift")
    {
        my $checked = $unshift_args->guard($args, $ctx);
        my $arrref = $checked->[1];
        
        for(my $i = 2; $i < @$checked; $i = $i + 1)
        {
            unshift @$arrref, $checked->[$i];            
        }
        return $arrref;    
    }
    elsif($type eq "append")
    {
        my $checked = $append_args->guard($args, $ctx);
        my $result = [];        
        for(my $i = 1; $i < @$checked; $i = $i + 1)
        {
            my $arr = $checked->[$i];
            push @$result, @$arr;         
        }
        return $result;    
    }
    elsif($type eq "list?")
    {
        my $checked = $list_args->guard($args, $ctx);
        return 0 if(@$checked <= 1);
        return 0 if !(ref($checked->[1]) eq 'ARRAY');
        return 1;        
    }
    elsif($type eq "empty?")
    {
        my $checked = $empty_args->guard($args, $ctx);
        my $arr = $checked->[1];
        return @$arr <= 0;
    }
    elsif($type eq "member?")
    {
        my $checked = $member_args->guard($args, $ctx);
        my $arr = $checked->[1];
        my $el = $checked->[2];
        
        my %members = ();
        for (@$arr) { $members{$_} = 1; }
        return 1 if $members{$el};
        return 0;
    }
    else
    {
        croak sprintf("ERROR: Command '%s' internal error.", $args->[0]);
    }
}

1;
