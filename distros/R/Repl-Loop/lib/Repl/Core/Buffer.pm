package Repl::Core::Buffer;

# Pragma's.
use strict;

sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my %args = (SENTENCE=>"", LINENO=>0, COLNO=>0, @_);
    
    # Initialize the instance.
    my $self = {};
    # Split the sentence into characters.
    $self->{BUFFER} = [split(//, $args{SENTENCE})];
    $self->{POS} = 0;
    $self->{LINENO} = $args{LINENO};
    $self->{COLNO} = $args{COLNO};
    return bless($self, $class);
}

sub eof
{
    my $self = shift;
    my $pos = $self->{POS};
    my $buf = $self->{BUFFER};
    return $pos >= scalar(@{$buf});
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
    return if $self->eof();
    
    my $pos = $self->{POS};
    my $buf = $self->{BUFFER};
    return @{$buf}[$pos];    
}

sub consumeChar
{
    my $self = shift;
    return if $self->eof();
    
    my $pos = $self->{POS};
    my $buf = $self->{BUFFER};
    my $char = @{$buf}[$pos];
    
    if($char eq "\n")
    {
        $self->{LINENO} +=1;
        $self->{COLNO} = 1;
    }
    else
    {
        $self->{COLNO} +=1;
    }
    
    $self->{POS} += 1;
    return $char;    
}

1;