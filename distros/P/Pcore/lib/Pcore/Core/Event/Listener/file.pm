package Pcore::Core::Event::Listener::file;

use Pcore -class, -ansi, -const;
use Pcore::Util::Data qw[to_json];
use Pcore::Util::Scalar qw[is_ref];
use Fcntl qw[:flock];
use IO::File;
use Time::HiRes qw[];

with qw[Pcore::Core::Event::Listener];

has tmpl => '[<: $date.strftime("%Y-%m-%d %H:%M:%S.%4N") :>][<: $channel :>][<: $level :>] <: $title | raw :>' . $LF . '<: $text | raw :>';

has _tmpl => ( init_arg => undef );    # InstanceOf ['Pcore::Util::Tmpl']
has _path => ( init_arg => undef );    # InstanceOf ['Pcore::Util::Path']
has _h    => ( init_arg => undef );    # InstanceOf ['IO::File']
has _init => ( init_arg => undef );

const our $INDENT => q[ ] x 4;

sub _build_id ($self) { return "file:$self->{uri}->{path}->{path}" }

sub forward_event ( $self, $ev ) {
    $self->{_init} //= do {

        # init template
        $self->{_tmpl} = P->tmpl;

        $self->{_tmpl}->add_tmpl( message => "$self->{tmpl}$LF" );

        # init path
        if ( $self->{uri}->{path}->{is_abs} ) {
            P->file->mkpath( $self->{uri}->{path}->{dirname} );

            $self->{_path} = $self->{uri}->{path}->{path};
        }
        else {
            $self->{_path} = "$ENV->{DATA_DIR}/$self->{uri}->{path}";
        }

        1;
    };

    # open filehandle
    if ( !-f $self->{_path} || !$self->{_h} ) {
        $self->{_h} = IO::File->new( $self->{_path}, '>>', P->file->calc_chmod('rw-------') ) or die qq[Unable to open "$self->{_path}"];

        $self->{_h}->binmode(':encoding(UTF-8)');

        $self->{_h}->autoflush(1);
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

        # remove all trailing "\n"
        $message->$* =~ s/\s+\z/\n/sm;

        flock $self->{_h}, LOCK_EX or die;

        print { $self->{_h} } $message->$*;

        flock $self->{_h}, LOCK_UN or die;
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
## |    3 | 59                   | Variables::RequireInitializationForLocalVars - "local" variable not initialized                                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 56, 59               | Variables::ProhibitLocalVars - Variable declared as "local"                                                    |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 12                   | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Event::Listener::file

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
