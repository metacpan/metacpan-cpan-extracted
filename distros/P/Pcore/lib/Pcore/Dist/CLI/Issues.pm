package Pcore::Dist::CLI::Issues;

use Pcore -class;

with qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return {
        abstract => 'view project issues',
        opt      => {
            active    => { desc  => 'issues with statuses "open", "resolved" or "closed"' },
            new       => { desc  => 'issues with status "new"' },
            open      => { desc  => 'issues with status "open"' },
            resolved  => { desc  => 'issues with status "resolved"' },
            closed    => { desc  => 'issues with status "closed"' },
            hold      => { short => 'H', desc => 'issues with status "on hold"' },
            invalid   => { desc  => 'issues with status "invalid"' },
            duplicate => { desc  => 'issues with status "duplicate"' },
            wontfix   => { desc  => 'issues with status "wonfix"' },
        },
        arg => [    #
            id => { desc => 'issue ID', isa => 'PositiveInt', min => 0 },
        ],
    };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    $self->new->run( $opt, $arg );

    return;
}

sub run ( $self, $opt, $arg ) {
    if ( $self->dist->build->issues ) {
        my $issues = $self->dist->build->issues->get(
            id => $arg->{id},
            $opt->%*,
        );

        if ( $arg->{id} && $opt->%* ) {

            # issue status changed, show only issue header, without content
            if ($issues) {
                $self->dist->build->issues->print_issues( $issues, 0 );
            }
            else {
                say 'Error update issue status';
            }
        }
        else {
            $self->dist->build->issues->print_issues( $issues, 1 );
        }
    }
    else {
        say 'No issues';
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
## |    2 | 35, 44, 51           | ValuesAndExpressions::ProhibitLongChainsOfMethodCalls - Found method-call chain of length 4                    |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::Issues

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
