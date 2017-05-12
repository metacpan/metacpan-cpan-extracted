package Pcore::Core::PerlIOviaWinUniCon;

use Pcore -inline;
use Encode qw[];    ## no critic qw[Modules::ProhibitEvilModules]

use Inline(
    C => <<'CPP',
void* get_std_handle(U32 std_handle) {
    return GetStdHandle(std_handle);
}

bool is_console(void* handle) {
    CONSOLE_SCREEN_BUFFER_INFO info;

    return GetConsoleScreenBufferInfo(handle, &info);
}

bool write_console(void* handle, wchar_t* buff) {
    U32 write_size;

    return WriteConsoleW(handle, buff, wcslen(buff), &write_size, NULL);
}
CPP
    ccflagsex => '-Wall -Wextra -O3',
);

my $ANSI_RE           = qr/\e.+?m/sm;
my $STD_OUTPUT_HANDLE = -11;
my $STD_ERROR_HANDLE  = -12;
my $MAX_BUFFER_SIZE   = 20_000;
my $NULL              = qq[\x00];
my $UTF16             = Encode::find_encoding('UTF-16LE');
my $STD_HANDLE        = {
    $STD_OUTPUT_HANDLE => get_std_handle($STD_OUTPUT_HANDLE),
    $STD_ERROR_HANDLE  => get_std_handle($STD_ERROR_HANDLE),
};

sub PUSHED {
    my $self = shift;
    my $mode = shift;
    my $fh   = shift;

    return bless \*PUSHED, $self;
}

sub UTF8 {
    my $self = shift;

    return 1;
}

sub WRITE {
    my $self = shift;
    my $buf  = shift;
    my $fh   = shift;

    my $handle = $fh->fileno == fileno STDOUT ? $STD_HANDLE->{$STD_OUTPUT_HANDLE} : $STD_HANDLE->{$STD_ERROR_HANDLE};

    if ( is_console($handle) ) {    # console handle

        # PerlIO perform utf8::encode($buf) for scalars without UTF8 flag if filehandle has :utf8 layer
        # so we need to decode
        utf8::decode($buf);    # decode octets to utf-8

        for my $str ( split /($ANSI_RE)/sm, $buf ) {
            next if $str eq q[];

            if ( substr( $str, 0, 1 ) eq qq[\e] ) {    # ANSII escape sequence

                print {$fh} $str;

                $fh->flush;
            }
            else {                                     #
                while ( length $str ) {
                    write_console( $handle, $UTF16->encode( substr $str, 0, $MAX_BUFFER_SIZE, q[] ) . $NULL );
                }
            }
        }
    }
    else {                                             # redirected filehandle, |, >, ...
        $buf =~ s/$ANSI_RE//smg;                       # strip ANSI escape sequencies

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
## |    2 | 31                   | ValuesAndExpressions::ProhibitEscapedCharacters - Numeric escapes in interpolated string                       |
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
