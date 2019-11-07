package Pcore::Dist::Build::Issues;

use Pcore -class, -const, -ansi;

has dist => ( required => 1 );    # InstanceOf ['Pcore::Dist']

const our $PRIORITY_ID => {
    trivial  => 1,
    minor    => 2,
    major    => 3,
    critical => 4,
    blocker  => 5,
};

const our $PRIORITY_COLOR => {
    trivial  => $WHITE,
    minor    => $BLACK . $ON_WHITE,
    major    => $BLACK . $ON_YELLOW,
    critical => $WHITE . $ON_RED,
    blocker  => $BOLD . $WHITE . $ON_RED,
};

const our $KIND => {
    bug         => [ 'bug',  $WHITE . $ON_RED ],
    enhancement => [ 'enh',  $WHITE ],
    proposal    => [ 'prop', $WHITE ],
    task        => [ 'task', $WHITE ],
};

const our $STATUS_ID => {
    new       => 1,
    open      => 2,
    resolved  => 3,
    closed    => 4,
    'on hold' => 5,
    invalid   => 6,
    duplicate => 7,
    wontfix   => 8,
};

const our $STATUS_COLOR => {
    new       => $BLACK . $ON_WHITE,
    open      => $BLACK . $ON_WHITE,
    resolved  => $WHITE . $ON_RED,
    closed    => $BLACK . $ON_GREEN,
    'on hold' => $WHITE . $ON_BLUE,
    invalid   => $WHITE . $ON_BLUE,
    duplicate => $WHITE . $ON_BLUE,
    wontfix   => $WHITE . $ON_BLUE,
};

around new => sub ( $orig, $self, $args ) {
    my $git = $args->{dist}->git;

    return if !$git || !$git->upstream;

    return $self->$orig($args);
};

sub search_issues ( $self, $filters ) {
    my $upstream = $self->{dist}->git->upstream;

    my $api = $upstream->get_hosting_api;

    my $status;

    if ( !$filters->%* || $filters->{active} ) {
        $status = [ 'open', 'resolved' ];
    }
    else {
        $status = [ keys $filters->%* ];
    }

    return $api->get_issues( $upstream->{repo_id}, status => $status, );
}

sub print_issues ( $self, $issues ) {
    if ( !$issues ) {
        say 'No issues';
    }
    else {
        my $tbl = P->text->table(
            style => 'full',
            width => 120,
            cols  => [
                id => {
                    width => 6,
                    align => 1,
                },
                status   => { width => 15, },
                priority => { width => 15, },
                kind     => {
                    width => 10,
                    align => 0,
                },
                title => { title_align => -1, },
            ],
        );

        print $tbl->render_header;

        for my $issue ( sort { $STATUS_ID->{ $a->{status} } <=> $STATUS_ID->{ $b->{status} } or $PRIORITY_ID->{ $b->{priority} } <=> $PRIORITY_ID->{ $a->{priority} } or $b->{utc_last_updated} cmp $a->{utc_last_updated} } values $issues->%* ) {
            print $tbl->render_row( [
                $issue->{local_id},    #
                $STATUS_COLOR->{ $issue->{status} } . " $issue->{status} " . $RESET,
                $PRIORITY_COLOR->{ $issue->{priority} } . " $issue->{priority} " . $RESET,
                $KIND->{ $issue->{metadata}->{kind} }->[1] . " $KIND->{ $issue->{metadata}->{kind} }->[0] " . $RESET,
                $issue->{title}
            ] );
        }

        print $tbl->finish;

        say 'max. 50 first issues shown';
    }

    return;
}

sub get_issue ( $self, $id ) {
    my $upstream = $self->{dist}->git->upstream;

    my $api = $upstream->get_hosting_api;

    return $api->get_issue( $upstream->{repo_id}, $id );
}

sub print_issue ( $self, $issue, $print_content = 1 ) {
    my $tbl = P->text->table(
        style => 'full',
        width => 120,
        cols  => [
            id => {
                width => 6,
                align => 1,
            },
            status   => { width => 15, },
            priority => { width => 15, },
            kind     => {
                width => 10,
                align => 0,
            },
            title => { title_align => -1, },
        ],
    );

    print $tbl->render_header;

    print $tbl->render_row( [
        $issue->{local_id},    #
        $STATUS_COLOR->{ $issue->{status} } . " $issue->{status} " . $RESET,
        $PRIORITY_COLOR->{ $issue->{priority} } . " $issue->{priority} " . $RESET,
        $KIND->{ $issue->{metadata}->{kind} }->[1] . " $KIND->{ $issue->{metadata}->{kind} }->[0] " . $RESET,
        $issue->{title}
    ] );

    print $tbl->finish;

    say "\n" . ( $issue->{content} || 'No content' ) if $print_content;

    return;
}

sub set_issue_status ( $self, $id, $status ) {
    my $upstream = $self->{dist}->git->upstream;

    my $api = $upstream->get_hosting_api;

    return $api->update_issue( $upstream->{repo_id}, $id, { status => $status } );
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    1 | 102                  | BuiltinFunctions::ProhibitReverseSortBlock - Forbid $b before $a in sort blocks                                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::Build::Issues

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
