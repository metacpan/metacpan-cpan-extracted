package Pcore::Core::Event::Listener::Pipe::stderr;

use Pcore -class, -ansi, -const;
use Pcore::Util::Text qw[remove_ansi];
use Pcore::Util::Data qw[to_json];
use Pcore::Util::Scalar qw[is_ref];
use Time::HiRes qw[];

with qw[Pcore::Core::Event::Listener::Pipe];

has tmpl => $BOLD . $GREEN . '[<: $date.strftime("%Y-%m-%d %H:%M:%S.%4N") :>]' . $BOLD . $YELLOW . '[<: $channel :>]' . $BOLD . $RED . '[<: $level :>]' . $RESET . ' <: $title | raw :>' . $LF . '<: $text | raw :>';

has _tmpl    => ();    # isa => InstanceOf ['Pcore::Util::Tmpl'], init_arg => undef );
has _is_ansi => ();    # isa => Bool, init_arg => undef );
has _init    => ();    # isa => Bool, init_arg => undef );

const our $INDENT => q[ ] x 4;

sub sendlog ( $self, $ev ) {
    return if $ENV->{PCORE_LOG_STDERR_DISABLED} || !defined *STDERR;

    # init
    if ( !$self->{_init} ) {
        $self->{_init} = 1;

        # init template
        $self->{_tmpl} = P->tmpl;

        $self->{_tmpl}->cache_string_tmpl( message => \"$self->{tmpl}$LF" );

        # check ansi support
        $self->{_is_ansi} //= -t *STDERR ? 1 : 0;    ## no critic qw[InputOutput::ProhibitInteractiveTest]
    }

    # sendlog
    {
        # prepare date object
        local $ev->{date} = P->date->from_epoch( $ev->{timestamp} // Time::HiRes::time() );

        # prepare text
        local $ev->{text};

        if ( defined $ev->{data} ) {

            # serialize reference
            $ev->{text} = is_ref $ev->{data} ? to_json( $ev->{data}, readable => 1 )->$* : $ev->{data};

            # indent
            $ev->{text} =~ s/^/$INDENT/smg;
        }

        my $message = $self->{_tmpl}->render( 'message', $ev );

        remove_ansi $message->$* if !$self->{_is_ansi};

        # remove all trailing "\n"
        $message->$* =~ s/\s+\z/\n/sm;

        print {*STDERR} $message->$*;
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
## |    3 | 41                   | Variables::RequireInitializationForLocalVars - "local" variable not initialized                                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 38, 41               | Variables::ProhibitLocalVars - Variable declared as "local"                                                    |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 11                   | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
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
