use 5.010;
use warnings;

    use Regexp::Grammars;

    my $balanced_brackets = qr{
        <debug:step>

        cat
        | dog
        | fish \d++ chips
    }xms;

#    say $balanced_brackets; exit;

    while (<>) {
        if (/$balanced_brackets/) {
            say 'matched:';
            use Data::Dumper 'Dumper';
            warn Dumper \%/;
        }
    }
