package t::testml::bridge;

sub upper {
    my $string = (shift)->value;
    return uc($string);
}

1;
