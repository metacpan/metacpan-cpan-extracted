package t::Module::ShortRegexOk;

# ABSTRACT: This module does nothing 

sub test {
    my $file = __FILE__;
    my ($suffix) = $file =~ /(\..*?)\z/;

    my $long_regex = qr{ThisIsALongerRegexToTestTheParameter};

    my $another_test = $file =~ m{A long path name};
}

1;
