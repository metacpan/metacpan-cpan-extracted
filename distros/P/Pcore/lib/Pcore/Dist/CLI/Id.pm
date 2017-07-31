package Pcore::Dist::CLI::Id;

use Pcore -class;

with qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return {
        abstract => 'show distribution info',
        opt      => { pcore => { desc => 'show info about currently used Pcore distribution', }, },
        arg      => [
            dist => {
                desc => 'show info about currently used Pcore distribution',
                isa  => 'Str',
                min  => 0,
            },
        ],
    };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    my $dist;

    if ( $opt->{pcore} ) {
        $dist = $ENV->pcore;
    }
    elsif ( $arg->{dist} ) {
        if ( $arg->{dist} =~ /\APcore\z/smi ) {
            $dist = $ENV->pcore;
        }
        else {
            $dist = Pcore::Dist->new( $arg->{dist} );
        }
    }
    else {
        $dist = $self->get_dist;
    }

    if ($dist) {
        $self->_show_dist_info($dist);
    }

    return;
}

sub _show_dist_info ( $self, $dist ) {
    say $dist->version_string;

    my $tbl = P->text->table(
        header => 0,
        grid   => undef,
        style  => 'compact',
        width  => 100,
        cols   => [
            1 => {
                width => 10,
                align => -1,
            },
            2 => { align => -1, },
        ],
    );

    print $tbl->render_all(
        [    #
            [ module => $dist->module->name, ],
            [ root   => $dist->root, ],
            [ lib    => $dist->module->lib, ],
            [ share  => $dist->share_dir, ],
            $dist->docker ? [ docker => $dist->docker->{repo_id} . ' FROM ' . $dist->docker->{from} ] : (),
        ]
    );

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 28                   | RegularExpressions::ProhibitFixedStringMatches - Use 'eq' or hash instead of fixed-pattern regexps             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::Id - show different distribution info

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
