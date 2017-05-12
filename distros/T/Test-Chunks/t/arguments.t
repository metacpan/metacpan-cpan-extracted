use Test::Chunks tests => 3;

run {};

sub Test::Chunks::Filter::something {
    my $self = shift;
    my $value = shift;
    my $arguments = $self->arguments;
    is $value, 
       "candle\n", 
       'value is ok';
    is $arguments, 
       "wicked", 
       'arguments is ok';
    is $Test::Chunks::Filter::arguments, 
       "wicked", 
       '$arguments global variable is ok';
}

__END__
=== One
--- foo something=wicked
candle
