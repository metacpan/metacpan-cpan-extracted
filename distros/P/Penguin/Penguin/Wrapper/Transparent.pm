package Penguin::Wrapper::Transparent;

sub new {
    bless { Wrapmethod => 'Transparent' }, shift;
}

sub wrap {
    my ($self, %args)  = @_;
    return $args{'Text'}; # NOTE: NO ATTEMPT MADE TO ENCRYPT OR SIGN
}

sub unwrap {
    my ($self, %args)  = @_;
    return ("NO SIGNING AUTHORITY", $args{'Text'});
}

1;
