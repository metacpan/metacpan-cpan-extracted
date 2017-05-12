package Pcore::Core::Log::Channel;

use Pcore -class, -ansi;

has name => ( is => 'ro', isa => Str, required => 1 );
has header => ( is => 'ro', isa => Maybe [Str], default => BOLD GREEN . '[<: $date.strftime("%H:%M:%S.%6N") :>]' . BOLD CYAN . '[<: $pid :>]' . BOLD YELLOW . '[<: $package :>]' . BOLD RED . '[<: $channel :>]' . RESET );

has pipe => ( is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef );

has _def_tag => ( is => 'lazy', isa => HashRef, init_arg => undef );
has _header_tmpl => ( is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef );

sub _build__def_tag ($self) {
    return {
        channel     => uc $self->name,
        script_name => $ENV->{SCRIPT_NAME},
        script_dir  => $ENV->{SCRIPT_DIR},
        script_path => $ENV->{SCRIPT_PATH},
    };
}

sub add_pipe ( $self, $pipe ) {
    $self->pipe->{ $pipe->id } = $pipe if !$self->pipe->{ $pipe->id };

    return;
}

sub sendlog ( $self, $data, @ ) {
    return if !defined $data;

    my @caller = caller 1;

    # collect tags
    my $tag = {
        package    => $caller[0],
        filename   => $caller[1],
        line       => $caller[2],
        subroutine => $caller[3],
        splice( @_, 2 ),
        $self->_def_tag->%*,
        pid  => $$,
        date => P->date->now,
    };

    my $header_cache = {};

    my $data_cache = {};

    # dump ref
    $data = dump $data if ref $data;

    for my $pipe ( sort { $a->priority <=> $b->priority } values $self->{pipe}->%* ) {
        my $data_type = $pipe->data_type;

        my $header;

        if ( $self->header ) {

            # prepare and cache header template
            if ( !exists $self->{_header_tmpl}->{$data_type} ) {
                $self->{_header_tmpl}->{$data_type} = P->tmpl;

                $self->{_header_tmpl}->{$data_type}->cache_string_tmpl( header => \$pipe->prepare_data( $self->header . q[ ] ) );
            }

            # render and cache header
            if ( !exists $header_cache->{$data_type} ) {
                $header_cache->{$data_type} = $self->{_header_tmpl}->{$data_type}->render( 'header', $tag );
            }

            $header = $header_cache->{$data_type}->$*;
        }
        else {
            $header = q[];
        }

        # prepare and cache data
        $data_cache->{$data_type} = $pipe->prepare_data($data) if !exists $data_cache->{$data_type};

        $pipe->sendlog( $header, $data_cache->{$data_type}, $tag );
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
## |    1 | 6                    | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Log::Channel

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
