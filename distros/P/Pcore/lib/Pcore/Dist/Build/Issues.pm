package Pcore::Dist::Build::Issues;

use Pcore -class;
use Pcore::Util::Scalar qw[blessed];

has dist => ( is => 'ro', isa => InstanceOf ['Pcore::Dist'], required => 1 );

has api => ( is => 'lazy', isa => InstanceOf ['Pcore::API::Bitbucket'], init_arg => undef );

around new => sub ( $orig, $self, $args ) {
    my $scm = $args->{dist}->scm;

    return if !$scm || !$scm->upstream;

    return $self->$orig($args);
};

sub _build_api ($self) {
    state $init = !!require Pcore::API::Bitbucket;

    my $scm_upstream = $self->dist->scm->upstream;

    return Pcore::API::Bitbucket->new(
        {   namespace => $scm_upstream->namespace,
            repo_name => $scm_upstream->repo_name,
        }
    );
}

sub get ( $self, @ ) {
    my $blocking_cv = AE::cv;

    my %args = (
        id        => undef,
        active    => undef,
        new       => undef,
        open      => undef,
        resolved  => undef,
        closed    => undef,
        hold      => undef,
        invalid   => undef,
        duplicate => undef,
        wontfix   => undef,
        splice @_, 1,
    );

    my $status = {};

    $status->@{qw[open resolved closed]} = () if $args{active};

    $status->{new} = undef if $args{new};

    $status->{open} = undef if $args{open};

    $status->{resolved} = undef if $args{resolved};

    $status->{closed} = undef if $args{closed};

    $status->{'on hold'} = undef if $args{hold};

    $status->{invalid} = undef if $args{invalid};

    $status->{duplicate} = undef if $args{duplicate};

    $status->{wontfix} = undef if $args{wontfix};

    # default
    $status->@{qw[open resolved closed]} = () if !$args{id} && !$status->%*;

    my @status = keys $status->%*;

    if ( $args{id} && @status ) {

        # impossible to set multiple statuses
        croak q[Can't set multiply issue statuses] if @status > 1;

        $self->api->set_issue_status(
            $args{id},
            $status[0],
            sub ($res) {
                $blocking_cv->($res);

                return;
            }
        );
    }
    else {
        if ( $args{id} ) {
            $self->api->get_issue( $args{id}, $blocking_cv );
        }
        else {
            $self->api->get_issues(
                status    => \@status,
                milestone => $args{milestone},
                $blocking_cv
            );
        }
    }

    return $blocking_cv->recv;
}

sub print_issues ( $self, $issues, $content = 1 ) {
    if ( !$issues ) {
        say 'No issues';
    }
    else {
        my $tbl = P->text->table(
            style => 'pcore',
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

        if ( blessed $issues ) {
            my $issue = $issues;

            print $tbl->render_row( [ $issue->{local_id}, $issue->status_color, $issue->priority_color, $issue->kind_color, $issue->{title} ] );

            print $tbl->finish;

            say $LF, $issue->{content} || 'No content' if $content;
        }
        else {
            for my $issue ( sort { $a->status_id <=> $b->status_id or $b->priority_id <=> $a->priority_id or $b->utc_last_updated_ts <=> $a->utc_last_updated_ts } $issues->@* ) {
                print $tbl->render_row( [ $issue->{local_id}, $issue->status_color, $issue->priority_color, $issue->kind_color, $issue->{title} ] );
            }

            print $tbl->finish;

            say 'max. 50 first issues shown';
        }
    }

    return;
}

sub create_version ( $self, $ver, $cb ) {
    return $self->api->create_version( $ver, $cb );
}

sub create_milestone ( $self, $milestone, $cb ) {
    return $self->api->create_milestone( $milestone, $cb );
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    1 | 138                  | BuiltinFunctions::ProhibitReverseSortBlock - Forbid $b before $a in sort blocks                                |
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
