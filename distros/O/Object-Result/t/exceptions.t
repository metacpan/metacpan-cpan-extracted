use 5.014;
use Test::More;
use Object::Result;

sub is_ex (&$$$) {
    my ($block, $expected_err, $line, $desc) = @_;

    my $file = (caller 0)[1];

    is eval{ $block->(); }, undef()  => "$desc (threw exception)";
    like $@, qr{\Q$expected_err\E}   => "$desc (right error message)";
    like $@, qr{at $file line $line} => "$desc (right error location)";
}

sub is_wn (&$$$) {
    my ($block, $expected_warning, $line, $desc) = @_;

    my $file = (caller 0)[1];

    my $warning;
    local $SIG{__WARN__} = sub { $warning = "@_" };

    $block->();

    like $warning, qr{\Q$expected_warning\E} => "$desc (right warning message)";
    like $warning, qr{at $file line $line}   => "$desc (right warning location)";
}

use Carp;

my $die_warn_line = -1;

sub get_result {
    $die_warn_line = __LINE__ + 1;
    result {
        confess { confess 'confessed' }
        croak   { croak 'croaked' }
        carp    { carp 'carped' }
        die     { die 'died' }
        warn    { warn 'warned' }
    };
}

my $result = get_result();

ok $result=> "Boolean coercion";

is_wn { $result->warn    } "warned",    $die_warn_line => '->warn';
is_wn { $result->carp    } "carped",    (__LINE__)     => '->carp';

is_ex { $result->die     } "died",      $die_warn_line => '->die';
is_ex { $result->croak   } "croaked",   $die_warn_line => '->croak';
is_ex { $result->confess } "confessed", (__LINE__)     => '->confess';


done_testing();

