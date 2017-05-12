package t::Module::SimpleRegex;

# ABSTRACT: This module does nothing 

sub test {
    my $file = __FILE__;
    my ($suffix) = $file =~ /(\..*?)\z/;
}

1;
