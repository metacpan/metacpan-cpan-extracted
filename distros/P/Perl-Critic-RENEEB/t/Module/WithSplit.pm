package t::Module::WithSplit;

# ABSTRACT: This module does nothing 

sub test {
    my $file = __FILE__;
    my @liste_1 = split /\./, $file;
    my @liste_2 = split( /\./, $file );
    my $elem = (split /\./, $file )[-1];

    print $_ for split /\./, $file;
    for my $var ( split /\./, $file ) {
    }

    my ($one, $two) = split /\./, $file;
}

1;
