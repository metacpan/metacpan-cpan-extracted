use warnings;
use strict;
use Test::More tests => 32;
use lib           qw {blib/lib};
use Regex::Common qw /RE_ALL/;

my @fixtures = (
    [ [qw /num hex/]        => [ 'abcdef',            '123.456', '1a2B.3c' ] ],
    [ [qw /comment ILLGOL/] => [ "NB foo bar\n",      "nb foo bar\n" ] ],
    [ [qw /net domain/]     => [ 'www.perl.com',      'WWW.PERL.COM' ] ],
    [ [qw /net MAC/]        => [ 'a0:b0:c0:d0:e0:f0', 'A0:B0:C0:D0:E0:F0' ] ],
    [ [qw /zip Dutch/]      => [ '1234 ab', '1234 AB', 'nl-1234 AB' ] ],
    [ [qw /URI HTTP/]       => ['HTTP://WWW.PERL.COM'] ],
    [
        [qw /profanity/] => [
            map {
                local $_ = $_;
                y/a-zA-Z/n-za-mN-ZA-M/;
                $_
              } qw /
              pbpx-fhpxre srygpuvat zhgure-shpxre
              zhgun-shpxvat fuvgf fuvgre penccvat
              nefr-ubyr cvff-gnxr jnaxf/
        ]
    ],
    [ [qw /num roman/] => [qw /I i II ii XvIiI CXxxVIiI MmclXXviI/] ],
);

push( @fixtures, ( [ [qw /balanced/] => [ "()", "(a( )b)" ] ], ) );

note('Testing all regular expressions with case insensitive switch');

foreach my $data_ref (@fixtures) {
    my ( $name_ref, $samples_ref ) = @{$data_ref};
    my ( $regex, $regex_name );

    if ( scalar( @{$name_ref} ) == 2 ) {
        my ( $first, $second ) = @{$name_ref};
        $regex      = qr/$RE{$first}{$second}{-i}/;
        $regex_name = "{$first}{$second}";
    }
    elsif ( scalar( @{$name_ref} ) == 1 ) {
        $regex      = qr/$RE{$name_ref->[0]}{-i}/;
        $regex_name = "{$name_ref->[0]}";
    }

    foreach my $str ( @{$samples_ref} ) {
        like( $str, $regex, "'$str' matches $regex_name" );
    }
}
