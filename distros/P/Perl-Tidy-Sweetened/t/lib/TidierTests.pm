package TidierTests;

use strict;
use warnings;
use Perl::Tidy::Sweetened;
use Test::Most;

use Exporter;
@TidierTests::ISA    = qw(Exporter);
@TidierTests::EXPORT = qw(run_test);

sub run_test {
    my ( $raw, $expected, $msg, $todo, @args ) = @_;

    my $errorbuffer = '';
    my @tidied;
    ## warn "# -nsyn -ce -npro -l=60 " . join( ' ', @args ), "\n";
    Perl::Tidy::Sweetened::perltidy(
        source      => \$raw,
        destination => \@tidied,
        perltidyrc  => undef,
        errorfile   => \$errorbuffer,
        argv        => '-nsyn -ce -npro -l=60 ' . join( ' ', @args ),
    );
    my $tidied = join '', @tidied;

    if ($todo) {

      TODO: {
            # Works with Test::More prior to 1.301001_?
            local $TidierTests::TODO = 'Not implmented';

            # Works with Test::More after 1.301001_021
            local $TODO = 'Not implmented';

            return check_test( $tidied, $expected, $errorbuffer, $msg );
        }

    } else {
        return check_test( $tidied, $expected, $errorbuffer, $msg );
    }
}

sub check_test {
    my ( $tidied, $expected, $errors, $msg ) = @_;

    my $ok_log = is( $errors, '', "$msg: no errors" );
    my $ok_tidy = eq_or_diff( $tidied, $expected, "$msg: matches" );

    return $ok_log && $ok_tidy;
}

1;
