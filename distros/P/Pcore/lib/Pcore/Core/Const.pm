package Pcore::Core::Const;

use common::header;
use Const::Fast qw[const];
use Pcore::Core::Exporter;

# <<<
const our $ANSI => {
    RESET          => 0,
    BOLD           => 1,
    DARK           => 2,
    ITALIC         => 3,
    UNDERLINE      => 4,
    BLINK          => 5,
    REVERSE        => 7,
    CONCEALED      => 8,

    BLACK          => 30,   ON_BLACK          => 40,
    RED            => 31,   ON_RED            => 41,
    GREEN          => 32,   ON_GREEN          => 42,
    YELLOW         => 33,   ON_YELLOW         => 43,
    BLUE           => 34,   ON_BLUE           => 44,
    MAGENTA        => 35,   ON_MAGENTA        => 45,
    CYAN           => 36,   ON_CYAN           => 46,
    WHITE          => 37,   ON_WHITE          => 47,

    BRIGHT_BLACK   => 90,   ON_BRIGHT_BLACK   => 100,
    BRIGHT_RED     => 91,   ON_BRIGHT_RED     => 101,
    BRIGHT_GREEN   => 92,   ON_BRIGHT_GREEN   => 102,
    BRIGHT_YELLOW  => 93,   ON_BRIGHT_YELLOW  => 103,
    BRIGHT_BLUE    => 94,   ON_BRIGHT_BLUE    => 104,
    BRIGHT_MAGENTA => 95,   ON_BRIGHT_MAGENTA => 105,
    BRIGHT_CYAN    => 96,   ON_BRIGHT_CYAN    => 106,
    BRIGHT_WHITE   => 97,   ON_BRIGHT_WHITE   => 107,
};
# >>>

for my $name ( keys $ANSI->%* ) {
    eval qq[const our \$$name => "\e\[$ANSI->{$name}m"];    ## no critic qw[BuiltinFunctions::ProhibitStringyEval]
}

our $EXPORT = {
    CORE    => [qw[$MSWIN $CRLF $LF]],
    DEFAULT => [':CORE'],
    ANSI    => [ map { '$' . $_ } keys $ANSI->%* ],
};

const our $MSWIN => $^O =~ /MSWin/sm ? 1 : 0;
const our $CRLF  => qq[\x0D\x0A];                           ## no critic qw[ValuesAndExpressions::ProhibitEscapedCharacters]
const our $LF    => qq[\x0A];                               ## no critic qw[ValuesAndExpressions::ProhibitEscapedCharacters]

const our $DIST_CFG_TYPE => 'yaml';

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "common" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 39                   | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 1                    | Modules::RequireVersionVar - No package-scoped "$VERSION" variable found                                       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Const

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
