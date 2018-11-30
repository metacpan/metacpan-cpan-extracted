package t::Module::ShortRegex;

# ABSTRACT: This module does nothing 

sub test {
    my $file = __FILE__;
    my ($suffix) = $file =~ /(\..*?)\z/;

    my $long_regex  = qr{ThisIsALongerRegexToTestTheParameter};
    my $long_regex2 = qr{ThisIsALongerRegexToTestTheParameter}x;

    my $another_test  = $file =~ m{A long path name};
    my $another_test2 = $file =~ m{A long path name}x;

    $file =~ s{Short}{Strict};
    $file =~ s{Short}{Strict}x;
}

1;
