package Pcore::Core::PerlIOviaWinUniCon;

use Pcore;
use Encode qw[];    ## no critic qw[Modules::ProhibitEvilModules]

use Inline(
    C => <<'C',
# include "windows.h"

void *get_std_handle(U32 std_handle) {
    return GetStdHandle(std_handle);
}

bool is_console(void *handle) {
    CONSOLE_SCREEN_BUFFER_INFO info;

    return GetConsoleScreenBufferInfo(handle, &info);
}

bool write_console(void *handle, wchar_t *buff) {
    U32 write_size;

    return WriteConsoleW(handle, buff, wcslen(buff), &write_size, NULL);
}

// TODO convert ANSI ESC sequeces to windows, look at Win32::Console::ANSI
bool write_console1 ( void *handle, char *buf, size_t len ) {
    size_t len16 = MultiByteToWideChar(CP_UTF8, 0, buf, len, NULL, 0);

    if (len16) {
        wchar_t *buf16;
        Newx(buf16, len16, wchar_t);

        MultiByteToWideChar(CP_UTF8, 0, buf, len, buf16, len16);

        U32 write_size;

        return WriteConsoleW(handle, buf16, len16, &write_size, NULL);
    }
    else {
        return 0;
    }
}

C
    ccflagsex => '-Wall -Wextra -Wno-unused-parameter -Ofast -std=c11',

    # build_noisy => 1,
    # force_build => 1,
);

my $ANSI_RE           = qr/\e.+?m/sm;
my $STD_OUTPUT_HANDLE = -11;
my $STD_ERROR_HANDLE  = -12;
my $MAX_BUFFER_SIZE   = 20_000;
my $UTF16             = Encode::find_encoding('UTF-16LE');
my $STD_HANDLE        = {
    $STD_OUTPUT_HANDLE => get_std_handle($STD_OUTPUT_HANDLE),
    $STD_ERROR_HANDLE  => get_std_handle($STD_ERROR_HANDLE),
};

sub UTF8 { return 1 }

sub PUSHED ( $self, $mode, $fh ) {
    return bless \*PUSHED, $self;
}

sub WRITE ( $self, $buf, $fh ) {
    my $handle = $fh->fileno == fileno STDOUT ? $STD_HANDLE->{$STD_OUTPUT_HANDLE} : $STD_HANDLE->{$STD_ERROR_HANDLE};

    # console handle
    if ( is_console($handle) ) {

        # PerlIO perform utf8::encode($buf) for scalars without UTF8 flag if filehandle has :utf8 layer
        # so we need to decode
        utf8::decode($buf);    # decode octets to utf-8

        for my $str ( split /($ANSI_RE)/sm, $buf ) {
            next if $str eq $EMPTY;

            # ANSII escape sequence
            if ( substr( $str, 0, 1 ) eq "\e" ) {

                print {$fh} $str;

                $fh->flush;
            }

            # text
            else {
                while ( length $str ) {
                    write_console( $handle, $UTF16->encode( substr $str, 0, $MAX_BUFFER_SIZE, $EMPTY ) . "\x00" );
                }
            }
        }
    }

    # redirected filehandle, |, >, ...
    else {

        # strip ANSI escape sequencies
        $buf =~ s/$ANSI_RE//smg;

        print {$fh} $buf;

        $fh->flush;
    }

    return bytes::length $buf;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 92                   | ValuesAndExpressions::ProhibitEscapedCharacters - Numeric escapes in interpolated string                       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::PerlIOviaWinUniCon

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
