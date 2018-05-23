package Pcore::Dist::CLI::Issues;

use Pcore -class;

extends qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return {
        abstract => 'view project issues',
        help     => <<'TXT',
issues --<ISSUE-STATUS> [--<ISSUE-STATUS> ...] - get issues, filtered by statuses;
issues <ID> - print full issue #ID details;
issues <ID> --<ISSUE-STATUS> - set new issue #ID status;
TXT
        opt => {
            active    => { desc  => 'issues with statuses "open", "resolved"' },
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
    my $dist = $self->get_dist;

    if ( $dist->build->issues ) {
        if ( defined $arg->{id} ) {

            # set new issue status
            if ( $opt->%* ) {
                if ( $opt->%* > 1 ) {
                    say q[Issue status is invalid];

                    exit 3;
                }

                my $issue = $dist->build->issues->set_issue_status( $arg->{id}, ( keys $opt->%* )[0] );

                # print issue without content
                $dist->build->issues->print_issue( $issue->{data}, 0 );
            }

            # print issue
            else {
                my $issue = $dist->build->issues->get_issue( $arg->{id} );

                # print issue with content
                $dist->build->issues->print_issue( $issue->{data} );
            }
        }

        # get issues
        else {
            my $issues = $dist->build->issues->search_issues($opt);

            $dist->build->issues->print_issues( $issues->{data} );
        }
    }
    else {
        say 'No issues';
    }

    return;
}

1;
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
