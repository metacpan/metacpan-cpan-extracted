package Pcore::Core::Const;

use common::header;
use Const::Fast qw[const];
use Pcore::Core::Exporter -export,
  { ALL     => [qw[$MSWIN $CRLF $LF $TRUE $FALSE $STDOUT_UTF8 $STDERR_UTF8]],
    CORE    => [':ALL'],
    DEFAULT => [':ALL'],
  };

our $STDOUT_UTF8;
our $STDERR_UTF8;

const our $MSWIN => $^O =~ /MSWin/sm ? 1 : 0;
const our $CRLF => qq[\x0D\x0A];    ## no critic qw[ValuesAndExpressions::ProhibitEscapedCharacters]
const our $LF   => qq[\x0A];        ## no critic qw[ValuesAndExpressions::ProhibitEscapedCharacters]

use Types::Serialiser qw[];
const our $TRUE  => Types::Serialiser::true;
const our $FALSE => Types::Serialiser::false;

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "common" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
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
