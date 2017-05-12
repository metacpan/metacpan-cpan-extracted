package Repl::Core::Token;

# Pragma's.
use strict;

# Uses.

our %tokenTypes = (beginlist=>1,endlist=>1,string=>1,pair=>1,whitespace=>1,quote=>1,eof=>1,error=>1);

sub new
{
    my $invocant = shift;
    my %args = (TYPE=>"error", VALUE=>"", LINENO=>0, COLNO=>0, @_);
    my $class = ref($invocant) || $invocant;
    
    # Argument checking.
    die sprintf("Tokentype %s does not exist.", $args{TYPE}) unless exists $tokenTypes{$args{TYPE}};
    
    # Initialize the token instance.
    my $self = {};
    $self->{TYPE} = $args{TYPE};
    $self->{VALUE} = $args{VALUE};
    $self->{LINENO} = $args{LINENO};
    $self->{COLNO} = $args{COLNO};
    
    return bless($self, $class);
}

sub getType
{
    my $self = shift;
    return $self->{TYPE};
}

sub getValue
{
    my $self = shift;
    return $self->{VALUE};
}

sub getLineNo
{
    my $self = shift;
    return $self->{LINENO};
}

sub getColNo
{
    my $self = shift;
    return $self->{COLONO};
}

sub isBeginList
{
    my $self = shift;
    return $self->{TYPE} eq "beginlist";
}

sub isEndList
{
    my $self = shift;
    return $self->{TYPE} eq "endlist";
}

sub isWhitespace
{
    my $self = shift;
    return $self->{TYPE} eq "whitespace";
}

sub isString
{
    my $self = shift;
    return $self->{TYPE} eq "string";
}

sub isError
{
    my $self = shift;
    return $self->{TYPE} eq "error";
}

sub isEof
{
    my $self = shift;
    return $self->{TYPE} eq "eof";
}

sub isErroneous
{
    my $self = shift;
    return $self->isError() || $self->isEof();
}

sub isQuote
{
    my $self = shift;
    return $self->{TYPE} eq "quote";
}

sub isPair
{
    my $self = shift;
    return $self->{TYPE} eq "pair";
}

1;