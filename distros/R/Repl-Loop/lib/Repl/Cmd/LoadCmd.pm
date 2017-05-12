package Repl::Cmd::LoadCmd;

use strict;
use warnings;
use Carp;

use IO::File;

use Repl::Spec::Types;
use Repl::Core::StreamBuffer;
use Repl::Core::Parser;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();

our $BINDING_LOADEDFILES = "*loaded-files";

# Ordinary function, not a method.
sub registerCommands
{
    my $repl = shift;
    $repl->registerCommand("load", new Repl::Cmd::LoadCmd("load", $repl));
    $repl->registerCommand("reload", new Repl::Cmd::LoadCmd("reload", $repl));
}

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
    my $eval = $self->{EVAL};
    
    my @files = ();
    my $rootctx = $ctx->getRootContext();
    my $ctxfiles;
    
    if($rootctx->isBound($BINDING_LOADEDFILES))
    {
        $ctxfiles = $rootctx->getBinding($BINDING_LOADEDFILES);
        if(!(ref($ctxfiles) eq 'ARRAY'))
        {
            $ctxfiles = [];
            $rootctx->defBinding($BINDING_LOADEDFILES, $ctxfiles);        
        }
    }
    else
    {
        $ctxfiles = [];
        $rootctx->defBinding($BINDING_LOADEDFILES, $ctxfiles);        
    }
    
    if($type eq "load")
    {
        # Copy the files part from the argument list.
        # Omit the command name.
        @files = (@$args);
        shift @files;
        # Now check the list.
        ARRAY_READABLEFILE_TYPE->guard(\@files);                
    }
    elsif ($type eq "reload")
    {
        # No arguments allowed.
        NO_ARGS->guard($args, $ctx);
        @files = @$ctxfiles;
    }
    else
    {
        croak sprintf ("ERROR: Command '%s' internal error.", $type);
    }
    
    # Load all files.
    foreach my $file (@files)
    {
        my $newctxfiles = [];
        # Delete from the array, this can lead to empty slots.
        for(my $i = 0; $i < scalar(@$ctxfiles); $i = $i + 1)
        {
            push @$newctxfiles, $ctxfiles->[$i] if $ctxfiles->[$i] ne $file;
        }
        # Remove empty slots.
        @$ctxfiles = (@$newctxfiles);
        # Add it again.
        push @$ctxfiles, $file;
        
        # Read the complete file for the time being.
        # We should have a streambuffer.
        my $io = IO::File->new($file);
        my $streambuf = new Repl::Core::StreamBuffer($io);
        my $streamparser = new Repl::Core::Parser();
             
        # Keep on evaluating expressions as long as there
        # is a chance we could find one in the stream buffer.
        while(!$streambuf->eof())
        {
            my $expr = $streamparser->parseExpression($streambuf);
            if(ref($expr) eq "Repl::Core::Token")
            {
                # Oops, we received a plain token.
                # If it is an error we have to report it.
                # If it is eof, we let it pass, the eval loop will simply end.
                croak sprintf("ERROR: While parsing '%s'.\n%s", $file, $expr->getValue()) if $expr->isError();
            }
            else
            {
                # No problems, we evaluate the expression.
                # This is the normal case.
                $eval->evalExpr($expr);                
            }
        }
    }
}

1;
