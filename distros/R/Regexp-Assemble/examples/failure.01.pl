use v5.14;
use strict;
use warnings;
use Regexp::Assemble;
use Data::Dumper;

my $re = Regexp::Assemble->new(flags => 'i')->track(1);

foreach my $reg ( 
  '(?^ux: Coneheads(?^ux: [^\\p{Alnum}] )(?^ux: [^\\p{Alnum}] )(?^ux: [^\\p{Alnum}] )Dan(?^ux: [^\\p{Alnum}] )Aykroyd(?^ux: [^\\p{Alnum}] )Comedy(?^ux: [^\\p{Alnum}] )Eng )|(?^ux: Coneheads(?:[+]|%20)-(?:[+]|%20)Dan(?:[+]|%20)Aykroyd(?:[+]|%20)Comedy(?:[+]|%20)Eng)',
#  'Coneheads(?^ux: [^\\p{Alnum}] )(?^ux: [^\\p{Alnum}] )(?^ux: [^\\p{Alnum}] )Dan(?^ux: [^\\p{Alnum}] )Aykroyd(?^ux: [^\\p{Alnum}] )Comedy(?^ux: [^\\p{Alnum}] )Eng',
#  'Coneheads(?:[+]|%20)-(?:[+]|%20)Dan(?:[+]|%20)Aykroyd(?:[+]|%20)Comedy(?:[+]|%20)Eng',
  '(?^u:Coneheads\\ 1993)',
) {
    $re->add( $reg );
}

foreach my $string ( 
    "Coneheads - Dan Aykroyd Comedy Eng",
    "Coneheads+-+Dan+Aykroyd+Comedy+Eng",
    "Coneheads%20-%20Dan%20Aykroyd%20Comedy%20Eng",
    "Coneheads 1993",
) {
    if( $string =~ /$re/ ) {
        say "matched $string";

        if( my $matched = $re->matched() ) {
            say "matched with: $matched";
        }
        if( my $matched = $re->source($^R) ) {
            say "\$^R: $^R";
            say "match source: $matched";
        }

        say "work around: ", get_source($re, $string);
    }
    else {
        say "no match on $string";
        say "get_source returns: ",  get_source($re, $string);
    }
    say "-" x 70;
}

print Dumper $re;

sub get_source {
    my ($re, $string) = @_;

    foreach my $r ( @{$re->{mlist}} ) {
        if( $string =~ /$r/ ) {
            return $r;
        }
    }
    return;
}
