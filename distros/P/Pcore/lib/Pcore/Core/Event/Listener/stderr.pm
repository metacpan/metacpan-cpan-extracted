package Pcore::Core::Event::Listener::stderr;

use Pcore -class, -ansi, -const;
use Pcore::Lib::Text qw[remove_ansi];
use Pcore::Lib::Data qw[to_json];
use Pcore::Lib::Scalar qw[is_ref];
use Time::HiRes qw[];

with qw[Pcore::Core::Event::Listener];

has tmpl => $BOLD . $GREEN . '[<: $date.strftime("%Y-%m-%d %H:%M:%S.%4N") :>]' . $BOLD . $YELLOW . '[<: $channel :>]' . $BOLD . $RED . '[<: $level :>]' . $RESET . ' <: $title | raw :>' . "\n" . '<: $text | raw :>';

has _tmpl    => ( init_arg => undef );    # InstanceOf ['Pcore::Lib::Tmpl']
has _is_ansi => ( init_arg => undef );

const our $INDENT => $SPACE x 4;

sub BUILD ( $self, $args ) {

    # init template
    $self->{_tmpl} = P->tmpl;

    $self->{_tmpl}->add_tmpl( message => "$self->{tmpl}\n" );

    # check ansi support
    $self->{_is_ansi} //= -t *STDERR ? 1 : 0;    ## no critic qw[InputOutput::ProhibitInteractiveTest]

    return;
}

sub _build_id ($self) { return 'stderr:' }

sub forward_event ( $self, $ev ) {
    return if !defined *STDERR;

    # sendlog
    {
        # prepare date object
        local $ev->{date} = P->date->from_epoch( $ev->{timestamp} // Time::HiRes::time() );

        # prepare text
        local $ev->{text};

        if ( defined $ev->{data} ) {

            # serialize reference
            $ev->{text} = is_ref $ev->{data} ? to_json $ev->{data}, readable => 1 : $ev->{data};

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
## |    3 | 42                   | Variables::RequireInitializationForLocalVars - "local" variable not initialized                                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 39, 42               | Variables::ProhibitLocalVars - Variable declared as "local"                                                    |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 11                   | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Event::Listener::stderr

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
