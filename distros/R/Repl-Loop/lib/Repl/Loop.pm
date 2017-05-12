package Repl::Loop;

our $VERSION = '1.00';

use strict;
use warnings;

use Repl::Core::Parser;
use Repl::Core::Eval;
    
use constant PROMPT_NORMAL => "> ";
use constant PROMPT_CONTINUE => "+ > ";

sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    
    my $self= {};
    $self->{PARSER} = new Repl::Core::Parser();
    $self->{EVAL} = new Repl::Core::Eval();
    $self->{STOPREQUESTED} = 0;
    $self->{PROMPT} = PROMPT_NORMAL;
    $self->{CURRCMD} = "";
    return bless $self, $class;
}

sub start
{
    my $self = shift;
    while(!$self->{STOPREQUESTED})
    {
        print $self->{PROMPT};
        my $line = <STDIN> || '';
        $self->handleLine($line);
    }
    $self->{STOPREQUESTED} = 0;    
}

sub stop
{
    my $self = shift;
    $self->{STOPREQUESTED} = 1;    
}

sub handleLine
{
    my $self = shift;
    my $line = shift;
    
    return if(!$line || $line =~ /^\s*$/);
    if($line =~ /\s*break\s*/i)
    {
        $self->recover();
        print "Canceling the command.\n";
        return;
    }
    
    if($line =~ /^(.+)\\$/)
    {
        # The line ends with a backslash (line continuation).
        $self->{CURRCMD} = $self->{CURRCMD} . $1;
        $self->{PROMPT} = PROMPT_CONTINUE;
    }
    else
    {        
        my $expr = $self->{CURRCMD} . $line;
        $self->{CURRCMD} = $expr;
        
        if(!($expr =~ /\A\s*\(.+\)\s*\Z/s ))
        {
            $expr = "(" . $expr . ")";
        }
        
        my $parsed = $self->{PARSER}->parseString($expr);
        if(ref($parsed) eq "ARRAY")
        {
            $self->recover();
            eval {$self->{EVAL}->evalExpr($parsed)};
            print cutat($@) if($@);                  
        }
        elsif (ref($parsed) eq "Repl::Core::Token")
        {
            if($parsed->isEof())
            {
                $self->{PROMPT} = PROMPT_CONTINUE;                
            }
            else
            {
                print $parsed->getValue() . "\n";
                $self->recover();                
            }            
        }
        else
        {
            $self->recover();
        }        
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
         # Cut of the "at <file name> line dddd." part.
         # Because it will always point to this location here.
        $msg = $1 . "\n";
    }
    return $msg;    
}

sub recover
{
    my $self = shift;
    $self->{CURRCMD} = "";
    $self->{PROMPT} = PROMPT_NORMAL;
}

# Two parameters:
# - A name
# - A command instance.
sub registerCommand
{
    my $self = shift;
    my $name = shift;
    my $cmd = shift;
    $self->{EVAL}->registerCommand($name, $cmd);    
}

# Two parameters:
# - A name
# - A command instance.
sub registerMacro
{
    my $self = shift;
    my $name = shift;
    my $cmd = shift;
    $self->{EVAL}->{MACREPO}->registerMacro($name, $cmd);  
}

# One parameter
# An expression that will be evaluated in the repl.
# Can be useful to add pre-defined functions to the eval.
# Single string argument.
sub eval
{
    my $self = shift;
    my $expr = shift;
    
    return $self->{EVAL}->evalExpr($self->{PARSER}->parseString($expr));
}

# Single parsed expression argument.
sub evalExpr
{
    my $self = shift;
    my $expr = shift;
    
    return $self->{EVAL}->evalExpr($expr);
}

# Get the internal eval.
sub getEval
{
    my $self = shift;
    return $self->{EVAL};
}

1;

__END__

=head1 NAME

Repl::Loop -- A command interpreter for applications.

=head1 SYNOPSIS

    # Create a Repl.
    #    
    my $repl = new Repl::Loop;
    
    # Register some functionality.
    #
    $repl->registerCommand("print", new Repl::Cmd::PrintCmd);
    $repl->registerCommand("exit", new Repl::Cmd::ExitCmd($repl));
    $repl->registerCommand("sleep", new Repl::Cmd::SleepCmd());
    
    # Start the loop, the user can interact.
    #
    $repl->start();

=head1 DESCRIPTION

It is a read-eval-print loop that supports a lisp-like syntax. It is meant as the top-level for
command line oriented applications or for telnet access into an application (for monitoring, configuration or debuggin). Behind the
screens it is a small lisp interpreter, but the syntax is tweaked so that it is more suited for
top-level commands. Some examples from the file system command library, these commands immitate
the standard directory browsing commands:

    ls recursive=true
    ls files=true dirs=false
    pwd quiet=true
    
Some examples from the math library:

    print (+ 1 2 3)
    print (+ (* 2 3) (* 4 5))
    print (fac 5) 

The repl supports LISP expressions, but the outermost parenthesis for the topmost expression
can be omitted for the convenience of the user so that the commands look like real commands.
But the full power of LISP expressions can be used if necessary especially for formulating subexpressions.
As a result, C<ls recursive=true> is equivalent to C<(ls recursive=true)>.

Another unconventional concept in the command syntax is the presence of "pairs".
These are syntactical constructs, they look like named parameters and they can be used as such.
Again, this is for the convenience of the user. The difference with other REPL's is that
the left side and the right side of a pair can be full expressions.

The read-eval-print loop understands basic constructs like tests, loops and so on but all real
functionality should be added in command libraries. It is up to the developer to decide
which functionality will be included in the loop. A number of command libraries are included, but
these are not activated by default.

The REPL provides a service to your application, it provides a full blown expression language
that you get for free. The only thing you have to do to create an application is to create
one or more commands that can be glued together using the  REPL commands. The parser will parse lists, pairs and strings
for you (as a developer), it will evaluate subexpressions and will call your commands.

To be honest, the read-eval-print loop is in reality a read-eval loop. You have to do the printing yourself.
It is up to the commands to decide whether the result should be printed or not.
The "ls" command in in the file system library for example returns a list of file names.
The printing can be turned on or off using the 'quiet' option  and the command looks like "ls quiet=true".
The command could be used to provide a list of path names as an input for other commands (that you write).
So you can tap into the power of other commands while writing your own commands. While writing your
application, the trick is to find a set of commands that work well together, that use each others results so that
they can build on each others functionality.

=head1 EXPRESSION SYNTAX

In this section we will describe the complete syntax of the repl expressions.
The evaluator understands a simplified lisp syntax.
Explicitly lacking: data structures, data structure manipulation. It should be done using Perl commands and an
underlying Perl model. The language on top should help to manipulate the underlying Perl model.

=over 4

=item C<quote>

It prevents evaluation of an expression: C<(quote E<lt>exprE<gt>)> or the shorthand C<'E<lt>exprE<gt>>.
It is necessary to provide this construct so that the user can use unevaluated expressions to describe data structures or other parameters
that can be provided to the commands.

=item C<if>

The if expression has the form C<(if E<lt>bool-exprE<gt> E<lt>then-exprE<gt> E<lt>else-exprE<gt>)>.
It is a special form because the evaluation of the then-expr or else-expr depends on the outcome of the test.
Since the evaluation order of all boolean constructs is deviant from normal evaluation they have to be built into the core.

=over 4

=item TRUTHY

Strings of the form (case insensitive) "true", "ok", "on", "yes", "y", "t".

=item FALSY

Undefined Perl values, zero, empty strings, empty arrays and strings of the form (case insensitive)
"false", "nok", "off", "no", "n", "f".

=back

=item C<while>

C<(while E<lt>bool-exprE<gt> E<lt>exprE<gt>)>.

=item C<set>

Changes an existing binding. It evaluates the value before setting, the result is the value: C<(set name val)> | C<(set name=val)>.
Set generates an error if the binding does not exist. A binding can initially be created using one of the following constructs. Afther a binding is created it 
can be modified with C<set>.

=over 4

=item A C<defvar>

Which creates/overwrites a global binding.

=item A C<defun>

Which (re-)binds a global variable to a lambda.

=item A C<let> or C<let*> block.

Which adds a number of bindings for the duration of a block.

=item Other

Some commands add something to the context too. It is up to the various commands to specify this.

=back

=item C<get>

Retrieves a binding. It does not do any evaluation: C<(get name)> or the shorthand notational convenience C<$name> does exactly the same thing.
It does not do Perl-like interpolation in strings, don't let the shorthand notation mislead you.

=item C<defvar>

Creates a global binding. It evaluates the value before setting, the result is the value: C<(defvar name val)> | C<(defvar name=val)>. The value can be changed with C<set>.

=item C<let, let*>

Defines variables locally: C<(let ((var val) | var=val | var ...) E<lt>exprE<gt>)>

=item C<and, or, not>

Shortcut boolean evaluation operators.

=item C<eq>

Has Perl equals semantics. It is the only data inspection that is implemented in the Eval.
It is included because it is a standard Perl function applicable to all data structures.

=item C<eval>

Evaluate an expression.

=item C<lambda>

A nameless function, it contains a reference to the lexical context where it was defined. So this creates closures.
It can be handy for the user to pass nameless functions as command parameters. The "ls" command is such an example, the
user can pass a lambda function which receives the file name and does some other processing.

=item C<defun>

C<(defun name (E<lt>paramsE<gt>) E<lt>exprE<gt>)> User defined functions, they are bound in the
same context as the variables are. Functions are bound in the global context.

=over 4

=item *

Name should be a string. The name is not evaluated.

=item *

C<(E<lt>paramsE<gt>)>, the parameter list a list of strings. The list of names is not evaluated.

=back

=item C<funcall>

C<(funcall name E<lt>argsE<gt>)>. It is the official way to call a user defined function,
but the shorthand is a call of the form C<(name arg-list)>. This form will lead to a function call if there was no registered command with the same name.

=over 4

=item *

Name should be a string and is not evaluated.

=item *

E<lt>argsE<gt>, the arguments in a separate list.

=back

=item C<progn>

Which accepts a list of expressions which are evaluated in order: C<(progn E<lt>expr1E<gt> E<lt>expr2E<gt> ...)>.

=item Remarks

=over 4

=item *

Lists are Perl arrays and not conses. So list semantics is different (and maybe less efficient).
There is no 'nil' concept; a list does not end with a nil, a nil is not the same as an empty array.

=item *

No separate name spaces for different constructs, there is only a single context stack.

=item *

Contexts have side effects, bindings can be changed.

=item *

Only strings are provided, there is no 'symbol' concept. If an application wants e.g. numbers
for calculation, the commands should parse the strings.

=item *

Binding context lookup order. Scoping is lexical. The global context is always available for everybody,
there is no need to introduce dynamic scoping.

=over 4

=item *

Call context, arguments are bound to parameters. This context is especially created for this call. It contains all local bindings.

=item *

Lexical (static) context, where the function or lambda was defined. It is the closure of the lambda.

=back

=back

=back

=head1 USING COMMAND LIBRARIES

Command libraries are the link between the repl and the business functionality. You can make use
of the command libraries that come with the repl, these are described here. Later on we will
describe how you can add your own command libraries (its not difficult).

=head2 PrintCmd

A single command to print stuff to the stdout.

=head2 ExitCmd

A command to exit the repl.

=head2 FileSysCmd

A command library to work with directories and files. It can be used in combination
with your own command library. The file system command library provides the commands to look up files
to go to directories and so on, your own command library could provide the commands to
do some processing on these files.

=head2 LispCmd

Basic Lisp commands to manipulate lists. 

=head2 LoadCmd

A command library to load scripts from files, to execute external files as if they were scripts.
It can also be used to process user preferences files during startup of the application.

=head2 MathCmd

Basic mathematicl operations.

=head2 SleepCmd

A test command, it can be handy when you need a command that takes a while to execute in order
to test the implementation of a function or anohter command.

=head2 DumpCmd

The command dumps the command line expression to the standard output. It can be handy for
the command library developer to study the way the expressions are passed to the command
implementations.

=head1 CREATING A COMMAND LIBRARY

Command libraries are the link between the repl and the business functionality. You can make use
of the command libraries that come with the repl, but you probably want to include some
new functionality as well. In this section we describe how you can add your own
commands.

A command is a Perl object that implements an C<execute()> method. Here is the implementation of the print command.

    sub execute
    {
        my $self = shift;
        my $ctx = shift;
        my $expr = shift;
        
        my @values = @$expr;
        print join(" ", @values[1..$#values]) if $#values >= 1;
        print "\n";
    }

=over 4

=item *

The first parameter is the object itself.

=item *

The second parameter is an instance of C<Repl::Core::BasicContext>, it is the data structure
that contains all bindings. Your command has access to these bindings and can even change
the context.

=item *

The third parameter is an array that represents the full command. The first element in the array
is a string and represents the name with which your command was called. The other elements
in the array are the parameters to your command.

=back

Command implementation is *very* straightforward. The only repetitive work that might crop up is the
validation of the parameters inside the expression. For simple parameters this can be done in the
command implementation. The type system provides support to automate these parameter checking tasks.

=head1 TYPE SYSTEM

The type system consist of a number of modules to make it easier for the command library author
to make argument checks and to report these in a consistent way. It is an optional component of
the project, you can completely ignore it if you don't need it.

There is support for two types of argument lists:

=over 4

=item *

Standard argument list. It can contain a number of required positional arguments,
followed by a number of optional positional arguments (which cannot be C<Repl::Core::Pair> instances) and finally
a number of named, possibly optional arguments represented by C<Repl::Core::Pair> objects.
It is implemented by C<Repl::Spec::Args::StdArgList>.

=item *

Variable argument list. It can contain a number of required positional arguments,
followed by a variable number (minimum and maximum number can be specified) of arguments of the same type and finally
a number of named, possibly optional arguments represented by Repl::Core::Pair objects.
It is implemented by C<Repl::Spec::Args::VarArgList>.

=back

=head2 STDANDARD ARG LIST

An example:

    # Declare the types you want to use in your parameter lists.
    # 
    my $int_type = new Repl::Spec::Type::IntegerType();
    my $bool_type = new Repl::Spec::Type::BooleanType();
    
    # Create argument specifiers with these types.
    #
    my $fixed_number_arg = new Repl::Spec::Args::FixedArg($int_type);
    my $named_force_arg = new Repl::Spec::Args::NamedArg("force", $bool_type, "false", 1);

    # Finally we can define an argument list that takes a single integer as required
    # parameter and a second optional boolean parameter.
    #
    my $stdlst = new Repl::Spec::Args::StdArgList([$fixed_number_arg], [], [$named_force_arg]);
    
    # In your command implementation you can check the expression:
    #
    eval {$stdlist->eval($expr);}
    if($@)
    {
        # Error handling.
        ...
    }
    
The Perl module C<Repl::Spec::Types> contains a number of frequently used types, you don't have
to create these for each script, simply reuse the types as they are defined in that module.

=head2 VARIABLE ARG LIST

An example. It uses the same type definitions as above and the evaluation of the expression is identical.

    # An argument list of 2-3 integers, followed by a named boolean.
    # 
    my $varlist = new Repl::Spec::Args::VarArgList([$fixed_number_arg], $vararg, 2, 3, [$named_force_arg]);