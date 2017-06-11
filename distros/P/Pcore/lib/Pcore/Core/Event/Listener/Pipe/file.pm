package Pcore::Core::Event::Listener::Pipe::file;

use Pcore -class, -ansi, -const;
use Pcore::Util::Data qw[to_json];
use Fcntl qw[:flock];
use IO::File;

with qw[Pcore::Core::Event::Listener::Pipe];

has tmpl => ( is => 'ro', isa => Str, default => '[<: $date.strftime("%Y-%m-%d %H:%M:%S.%4N") :>][<: $channel :>][<: $level :>] <: $title | raw :><: $text | raw :>' );

has _tmpl => ( is => 'ro', isa => InstanceOf ['Pcore::Util::Template'], init_arg => undef );
has _path => ( is => 'ro', isa => InstanceOf ['Pcore::Util::Path'],     init_arg => undef );
has _h    => ( is => 'ro', isa => InstanceOf ['IO::File'],              init_arg => undef );

has _init => ( is => 'ro', isa => Bool, init_arg => undef );

const our $INDENT => q[ ] x 4;

sub sendlog ( $self, $ev ) {

    # init
    if ( !$self->{_init} ) {
        $self->{_init} = 1;

        # init template
        $self->{_tmpl} = P->tmpl;

        $self->{_tmpl}->cache_string_tmpl( message => \"$self->{tmpl}$LF" );

        # init path
        if ( $self->{uri}->path->is_abs ) {
            P->file->mkpath( $self->{uri}->path->dirname );

            $self->{_path} = $self->{uri}->path;
        }
        else {
            $self->{_path} = P->path( $ENV->{DATA_DIR} . $self->{uri}->path );
        }
    }

    # open filehandle
    if ( !-f $self->{_path} || !$self->{_h} ) {
        $self->{_h} = IO::File->new( $self->{_path}, '>>', P->file->calc_chmod('rw-------') ) or die qq[Unable to open "$self->{_path}"];

        $self->{_h}->binmode(':encoding(UTF-8)');

        $self->{_h}->autoflush(1);
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
## |    3 | 57                   | Variables::RequireInitializationForLocalVars - "local" variable not initialized                                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 54, 57               | Variables::ProhibitLocalVars - Variable declared as "local"                                                    |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 68                   | ValuesAndExpressions::ProhibitEmptyQuotes - Quotes used with a string containing no non-whitespace characters  |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 10                   | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Event::Listener::Pipe::file

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
