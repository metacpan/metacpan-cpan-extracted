package Repl::Cmd::FileSysCmd;

use strict;
use warnings;

use Repl::Spec::Args::OptionalArg;
use Repl::Spec::Args::NamedArg;
use Repl::Spec::Types;
use Carp;

use Cwd qw(getcwd abs_path);
use File::Spec;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();

# Ordinary function, not a method.
sub registerCommands
{
    my $repl = shift;
    
    # ls
    # - Optional directory parameter, default is '.' if omitted.
    # - quiet=true|false*. To prevent console output.
    # - files=true*|false. Include files in the result.
    # - dirs=true*|false. Include dirs in the result.
    # - exec=... Execute a function on the filtered files.
    # - recursive=true|false*. Dive into the subdirectoris as well.
    $repl->registerCommand("ls", new Repl::Cmd::FileSysCmd("ls", $repl->getEval()));
    # pwd
    # - quiet=true|false*.
    $repl->registerCommand("pwd", new Repl::Cmd::FileSysCmd("pwd", $repl->getEval()));
    # cd
    # - Optional directory.
    $repl->registerCommand("cd", new Repl::Cmd::FileSysCmd("cd", $repl->getEval()));
     
    #my $parser = new Repl::Core::Parser();    
    #$repl->evalExpr($parser->parseString("(defun fac (n) (if \$n (* \$n (fac (- \$n 1))) 1))"));
}

our $opt_dir = new Repl::Spec::Args::OptionalArg(SCALAR_TYPE, '.');
our $named_quiet = new Repl::Spec::Args::NamedArg("quiet", BOOLEAN_TYPE, "false", 1);
our $named_files = new Repl::Spec::Args::NamedArg("files", BOOLEAN_TYPE, "true", 1);
our $named_dirs = new Repl::Spec::Args::NamedArg("dirs", BOOLEAN_TYPE, "true", 1);
our $named_grep = new Repl::Spec::Args::NamedArg("grep", SCALAR_TYPE, '.*' , 1);
our $named_lambda = new Repl::Spec::Args::NamedArg("exec", LAMBDA_TYPE, undef, 1);
our $named_recursive = new Repl::Spec::Args::NamedArg("recursive", BOOLEAN_TYPE, "false", 1);

our $ls_args = new Repl::Spec::Args::StdArgList([], [$opt_dir], [$named_quiet, $named_files, $named_dirs, $named_grep, $named_lambda, $named_recursive]);
our $pwd_args = new Repl::Spec::Args::StdArgList([], [], [$named_quiet]);
our $cd_args = new Repl::Spec::Args::StdArgList([], [$opt_dir], []);

sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $type = shift;
    my $eval = shift;
    
    my $self= {};
    $self->{TYPE} = $type;
    $self->{EVAL} = $eval;
    return bless $self, $class;
}

sub execute
{
    my $self = shift;
    my $ctx = shift;
    my $args = shift;
    my $type = $self->{TYPE};
    
    # Remove the command name.    
    #my $command = shift @$args;
    
    if($type eq 'ls')
    {
        my $checked = $ls_args->guard($args, $ctx);
        my $dir = abs_path($checked->[1]);
        my $quiet = $checked->[2];
        my $incl_files = $checked->[3];
        my $incl_dirs = $checked->[4];
        my $grep = $checked->[5];
        my $lambda = $checked->[6];
        my $recursive = $checked->[7];
        
        croak sprintf("ERROR") if (! -e $dir);
        croak sprintf("ERROR") if (! -d $dir);
        
        # Push the requested dir on the worklist.
        # The worklist will handle recursion.
        my @worklist = ($dir);
        my @files = ();
        
        while(@worklist)
        {
            # Get one from the worklist.
            $dir = shift @worklist;
            
            opendir my($dh), $dir or die "Couldn't open dir $dir': $!"; 
            my @xfiles = readdir $dh; 
            closedir $dh;
            
            # Filter out . and ..
            # Convert to abslute pathnames.            
            foreach my $file (@xfiles)
            {            
               if($file ne '.' && $file ne '..')
               {
                    # Compose absolute pathname.
                    $file = File::Spec->catfile($dir, $file);
                    if(-d $file)
                    {
                        # Remember it if we want dirs.
                        push @files, $file if $incl_dirs && $file =~ /^$grep$/i;
                        # Push it on the worklist if recursive.
                        push @worklist, $file if $recursive;                                                
                    }
                    elsif(-f $file)
                    {
                        # Remember the file if we want files.
                        push @files, $file if $incl_files && $file =~ /^$grep$/i;                     
                    }                                        
               }
            }
        }
                      
        @files = sort @files;
        foreach my $file (@files)
        {
            # Execute the user function if there is one.
            if($lambda)
            {
                $self->{EVAL}->evalInContext([$lambda, $file], $ctx);                    
            }
            
            # Print the lot.
            if(!$quiet)
            {
                my $fileordir = 'd';
                $fileordir = ' ' if(-f $file);                
                my @attrs = stat($file);
                printf("%s %04o %s\t$file\n", $fileordir, $attrs[2] & 07777, $attrs[7]);
            }
        }
        # Return the list of files.
        return [@files];
    }
    elsif($type eq "pwd")
    {
        my $checked = $pwd_args->guard($args, $ctx);
        my $quiet = $checked->[1];
        
        my $dir = getcwd();
        print "$dir\n" if !$quiet;
        return $dir;
    }
    elsif($type eq "cd")
    {
        my $checked = $cd_args->guard($args, $ctx);
        my $arg = $checked->[1];
        
        croak "ERROR: Could not go to '$arg'." if !chdir($arg);
        return getcwd();
    }
    else
    {
        croak sprintf("ERROR: Command '%s' internal error.", $args->[0]);
    }
}

1;
