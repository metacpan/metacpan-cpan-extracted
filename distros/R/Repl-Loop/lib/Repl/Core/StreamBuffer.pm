package Repl::Core::StreamBuffer;

use strict;
use warnings;
use Carp;

sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    
    my $iohandle = shift;
    my %args = (LINENO=>1, COLNO=>1, @_);
    
    # Initialize the instance.
    my $self = {};
    $self->{IOHANDLE} = $iohandle;
    $self->{BUFFER} = [];

    $self->{LINENO} = $args{LINENO};
    $self->{COLNO} = $args{COLNO};
    return bless($self, $class);
}

sub eof
{
    my $self = shift;
    $self->fillbuf();
    
    my $buf = $self->{BUFFER};    
    return scalar(@$buf) == 0;
}

sub getLineNo
{
    my $self = shift;
    return $self->{LINENO};
}

sub getColNo
{
    my $self = shift;
    return $self->{COLNO};
}

sub peekChar
{
    my $self = shift;
    $self->fillbuf();
    
    my $buf = $self->{BUFFER};    
    return if $self->eof();
    return $buf->[0];
}

sub consumeChar
{
    my $self = shift;
    $self->fillbuf();
    
    my $buf = $self->{BUFFER}; 
    return if $self->eof();
    
    my $result = shift(@$buf);
    if($result eq "\n")
    {
        $self->{LINENO} = $self->{LINENO} + 1;
        $self->{COLNO} = 1;        
    }
    else
    {
        $self->{COLNO} = $self->{COLNO} + 1;        
    }
    return $result;
}

sub fillbuf
{
    my $self = shift;
    my $iohandle = $self->{IOHANDLE};
    my $buf = $self->{BUFFER};
    
    if(!scalar(@$buf))
    {
        my $result = "";
        my $nrread = $iohandle->read($result, 1024);
        
        if($nrread)
        {
            # Fill the buffer with the new characters.
            push @$buf, split(//, $result);                        
        }
    }
}

1;