use 5.010;
use warnings;

    use Regexp::Grammars;

    my $balanced_brackets = qr{
        <debug:step>

        <left_delim=(  \( )>
        (?:
            <[escape=(  \\ )]>
        |   <recurse=( (?R) )>
        |   <[simple=(  .  )]>
        )*
        <right_delim=( \) )>
    }xms;

    while (<>) {
        if (/$balanced_brackets/) {
            say 'matched:';
            use Data::Dumper 'Dumper';
            warn Dumper \%/;
        }
    }
