package Repl::Spec::Type::FileType;

use strict;
use warnings;
use Carp;

# Parameters
# - isDir
# - isFile
# - isReadable
# - exists
sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    
    my %params = (ISDIR=>0, ISFILE=>1, READABLE=>1, WRITEABLE=> 0, EXECUTABLE=>0, @_);
    
    my $self = {};
    $self->{ISDIR} = $params{ISDIR};
    $self->{ISFILE} = $params{ISFILE};
    $self->{READABLE} = $params{READABLE};
    
    return bless $self, $class;    
}

sub guard
{
    my $self = shift;
    my $arg = shift;
    
    my $isdir = $self->{ISDIR};
    my $isfile = $self->{ISFILE};
    my $readable = $self->{READABLE};
    my $writable = $self->{WRITABLE};
    my $executable = $self->{EXECUTABLE};
    
    croak sprintf("The file '%s' does not exist, it is not a file nor a directory.", $arg) if(! -e $arg);
    croak sprintf("The file '%s' is a plain file and not a directory.", $arg) if($isdir && !(-d $arg));
    croak sprintf("The file '%s' is a directory and not a plain file.") if($isfile && !(-f $arg));
    croak sprintf("The file '%s' is not readable.", $arg) if($readable && !(-r $arg));
    croak sprintf("The file '%s' is not writable.", $arg) if($writable && !(-w $arg));
    croak sprintf("The file '%s' is not executable.", $arg) if($executable && !(-x $arg));

    return $arg;
}

sub name
{
    return 'file';
}

1;
