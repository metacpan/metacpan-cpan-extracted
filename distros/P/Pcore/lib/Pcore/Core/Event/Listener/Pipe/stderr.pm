package Pcore::Core::Event::Listener::Pipe::stderr;

use Pcore -class, -ansi, -const;
use Pcore::Util::Text qw[remove_ansi];
use Pcore::Util::Data qw[to_json];

with qw[Pcore::Core::Event::Listener::Pipe];

has tmpl => ( is => 'ro', isa => Str, default => $BOLD . $GREEN . '[<: $date.strftime("%Y-%m-%d %H:%M:%S.%4N") :>]' . $BOLD . $YELLOW . '[<: $channel :>]' . $BOLD . $RED . '[<: $level :>]' . $RESET . ' <: $title | raw :><: $text | raw :>' );

has _tmpl => ( is => 'ro', isa => InstanceOf ['Pcore::Util::Template'], init_arg => undef );
has _is_ansi => ( is => 'ro', isa => Bool, init_arg => undef );

has _init => ( is => 'ro', isa => Bool, init_arg => undef );

const our $INDENT => q[ ] x 4;

sub sendlog ( $self, $ev ) {
    return if $ENV->{PCORE_LOG_STDERR_DISABLED} || !defined $STDERR_UTF8;

    # init
    if ( !$self->{_init} ) {
        $self->{_init} = 1;

        # init template
        $self->{_tmpl} = P->tmpl;

        $self->{_tmpl}->cache_string_tmpl( message => \"$self->{tmpl}$LF" );

        # check ansi support
        $self->{_is_ansi} //= -t $STDERR_UTF8 ? 1 : 0;    ## no critic qw[InputOutput::ProhibitInteractiveTest]
    }

    # sendlog
    {
        # prepare date object
        local $ev->{date} = P->date->from_epoch( $ev->{timestamp} );

        # prepare text
        local $ev->{text};

        if ( defined $ev->{data} ) {

            # serialize reference
            $ev->{text} = $LF . ( ref $ev->{data} ? to_json( $ev->{data}, readable => 1 )->$* : $ev->{data} );

            # indent
            $ev->{text} =~ s/^/$INDENT/smg;

            # remove all trailing "\n"
            local $/ = '';

            chomp $ev->{text};
        }

        my $message = $self->{_tmpl}->render( 'message', $ev );

        remove_ansi $message->$* if !$self->{_is_ansi};

        print {$STDERR_UTF8} $message->$*;
    }

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 40                   | Variables::RequireInitializationForLocalVars - "local" variable not initialized                                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 37, 40               | Variables::ProhibitLocalVars - Variable declared as "local"                                                    |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 51                   | ValuesAndExpressions::ProhibitEmptyQuotes - Quotes used with a string containing no non-whitespace characters  |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 9                    | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Event::Listener::Pipe::stderr

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
