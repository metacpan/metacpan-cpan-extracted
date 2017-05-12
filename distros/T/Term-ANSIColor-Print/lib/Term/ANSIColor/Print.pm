package Term::ANSIColor::Print;

$VERSION = '0.08';

use strict;
use warnings;
use Carp;
use vars qw( $AUTOLOAD );

my ( $COLOR_REGEX, $SUB_COLOR_REGEX, %ANSI_CODE_FOR );
{
    use Readonly;

    Readonly $COLOR_REGEX => qr{
        \A ( . \[\d+m .*? . \[0m ) \z
    }xms;

    Readonly $SUB_COLOR_REGEX => qr{
        \A ( .+? )
           ( . \[\d+m .* . \[0m )
           (?! . \[0m )
           ( .+ ) \z
    }xms;

    # http://en.wikipedia.org/wiki/ANSI_escape_code
    Readonly %ANSI_CODE_FOR => (
        black     => 30,
        blue      => 94,
        bold      => 1,
        cyan      => 96,
        green     => 92,
        grey      => 37,
        magenta   => 95,
        red       => 91,
        white     => 97,
        yellow    => 93,
        conceal   => 8,
        faint     => 2,
        italic    => 3,
        negative  => 7,
        positive  => 27,
        reset     => 0,
        reveal    => 28,
        underline => 4,
        normal    => {
            foreground => 39,
            background => 99,
        },
        blink     => {
            slow  => 5,
            rapid => 6,
        },
        light => {
            black => 90,
        },
        double => {
            underline => 21,
        },
        normal => {
            intensity => 22,
        },
        no => {
            underline => 24,
            blink     => 25,
        },
        dark => {
            red     => 31,
            green   => 32,
            yellow  => 33,
            blue    => 34,
            magenta => 35,
            cyan    => 36,
        },
        on => {
            red     => 101,
            green   => 102,
            yellow  => 103,
            blue    => 104,
            magenta => 105,
            cyan    => 106,
            white   => 107,
            normal  => 109,
            black   => 40,
            grey    => 47,
            light   => {
                black => 100,
            },
            dark => {
                red     => 41,
                green   => 42,
                yellow  => 43,
                blue    => 44,
                magenta => 45,
                cyan    => 46,
                normal  => 49,
            },
        },
    );
}

sub new {
    my $class = shift;
    my %args  = @_;

    my $self = bless {
        output => defined $args{output} ? $args{output} : \*STDOUT,
        eol    => defined $args{eol}    ? $args{eol}    : "\n",
        pad    => defined $args{pad}    ? $args{pad}    : "",
        alias  => defined $args{alias}  ? $args{alias}  : {},
    }, $class;

    delete @args{qw( output eol pad alias )};

    for my $arg ( keys %args ) {
        warn "unrecognized argument $arg";
    }

    return $self;
}

sub AUTOLOAD {
    my ($self,@strings) = @_;

    my $method = ( split /::/, $AUTOLOAD )[-1];

    ALIAS:
    while ( my ( $alias, $token ) = each %{ $self->{alias} } ) {

        if ( $token !~ m{\A \w+ \z}xms ) {

            carp "alias '$alias': token '$token' is invalid\n";
            next ALIAS;
        }

        if ( $alias !~ m{\A \w+ \z}xms ) {

            carp "alias key '$alias' is a invalid\n";
            next ALIAS;
        }

        $method =~ s{$alias}{$token}g;
    }

    my $eol = $method =~ s{ _+ \z}{}xms ? "" : $self->{eol};

    my @tokens = split /_/, $method;

    my $color_start = "";
    my $color_end   = "\x{1B}[0m";

    my $code_for_rh = \%ANSI_CODE_FOR;

    TOK:
    for my $token (@tokens) {

        my $code = $code_for_rh->{$token};

        if ( ref $code eq 'HASH' ) {
            $code_for_rh = $code;
            next TOK;
        }

        if ( not $code ) {

            if ( defined $ANSI_CODE_FOR{$token} ) {

                $code_for_rh = \%ANSI_CODE_FOR;
                redo TOK;
            }

            carp "unrecognized token: $token";
            next TOK;
        }

        $color_start .= "\x{1B}[${code}m";
    }

    my @color_strings;

    @strings = map { ref $_ eq 'ARRAY' ? @{ $_ } : $_ } @strings;

    for my $string ( @strings ) {

        # pre text ESC sub text ESC end text
        if ( $string =~ $SUB_COLOR_REGEX ) {

            my $pre
                = $1
                ? $color_start . $1 . $color_end
                : "";

            my $sub = $2;

            my $end
                = $3
                ? $color_start . $3 . $color_end
                : "";

            $string
                = $pre
                . $sub
                . $end;
        }

        # no color ESC
        elsif ( $string !~ $COLOR_REGEX ) {

            $string
                = $color_start
                . $string
                . $color_end;
        }

        # else ESC text ESC

        push @color_strings, $string;
    }

    if ( @strings ) {

        $strings[-1] .= $eol;
    }
    else {

        push @strings, $eol;
    }

    my $string = join $self->{pad}, @strings;

    if ( ref $self->{output} eq 'GLOB' ) {

        print { $self->{output} } $string;
    }

    return $string;
}

sub DESTROY {
    return;
}

1;
