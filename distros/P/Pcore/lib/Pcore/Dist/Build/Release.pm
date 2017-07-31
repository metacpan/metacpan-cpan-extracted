package Pcore::Dist::Build::Release;

use Pcore -class;
use Pod::Markdown;
use CPAN::Meta;
use Pcore::API::PAUSE;

has dist => ( is => 'ro', isa => InstanceOf ['Pcore::Dist'], required => 1 );

has major  => ( is => 'ro', isa => Bool, default => 0 );
has minor  => ( is => 'ro', isa => Bool, default => 0 );
has bugfix => ( is => 'ro', isa => Bool, default => 0 );

sub run ($self) {

    # check, if release can be performed
    return if !$self->_can_release;

    # create new version
    my $cur_ver = $self->dist->id->{release};

    my $new_ver = $self->_compose_new_version;

    return if !$new_ver;

    # check for resolved issues without milestone
    # if ( $self->dist->build->issues ) {
    #     my $resolved_issues = $self->dist->build->issues->get( resolved => 1 );
    #
    #     if ( !$resolved_issues ) {
    #         say 'Error retrieving issues from tracker';
    #
    #         return;
    #     }
    #
    #     if ( $resolved_issues->{data} ) {
    #         say qq[Following issues are resolved and not closed:$LF];
    #
    #         $self->dist->build->issues->print_issues( $resolved_issues->{data} );
    #
    #         say qq[${LF}Close or re-open this issues. Release is impossible.$LF];
    #
    #         return;
    #     }
    # }

    # get closed issues sinse latest release
    # my $closed_issues = $self->dist->build->issues && $self->dist->build->issues->get( closed => 1 );

    say qq[${LF}Current version is: $cur_ver];

    say qq[New version will be: $new_ver$LF];

    return if P->term->prompt( q[Continue release process?], [qw[yes no]], enter => 1 ) ne 'yes';

    say q[];

    # run tests
    return if !$self->dist->build->test( author => 1, release => 1 );

    say q[];

    # NOTE !!!WARNING!!! start release, next changes will be hard to revert

    # working with the issue tracker
    # if ( $self->dist->build->issues ) {
    #     my $cv = AE::cv;
    #
    #     # create new version on issues tracker
    #     print q[Creating new version and milestone on issues tracker ... ];
    #
    #     $cv->begin;
    #
    #     $self->dist->build->issues->create_version(
    #         $new_ver,
    #         sub ($res) {
    #             if ( !$res ) {
    #                 say qq[Error creating new version on issues tracker: $res];
    #
    #                 exit;
    #             }
    #
    #             $cv->end;
    #
    #             return;
    #         }
    #     );
    #
    #     # create new milestone on issues tracker
    #     $cv->begin;
    #
    #     $self->dist->build->issues->create_milestone(
    #         $new_ver,
    #         sub ($res) {
    #             if ( !$res ) {
    #                 say qq[Error creating new milestone on issues tracker: $res];
    #
    #                 exit;
    #             }
    #
    #             $cv->end;
    #
    #             return;
    #         }
    #     );
    #
    #     $cv->recv;
    #
    #     say 'done';
    #
    #     # get closed issues, set milestone for closed issues
    #     if ( $closed_issues->{data} ) {
    #         $cv = AE::cv;
    #
    #         print q[Updating milestone for closed issues ... ];
    #
    #         for my $issue ( $closed_issues->{data}->@* ) {
    #             $cv->begin;
    #
    #             $issue->set_milestone(
    #                 $new_ver,
    #                 sub ($res) {
    #                     if ( !$res ) {
    #                         say qq[Error updating milestone for issue: $res];
    #
    #                         exit;
    #                     }
    #
    #                     $cv->end;
    #
    #                     return;
    #                 }
    #             );
    #         }
    #
    #         $cv->recv;
    #
    #         say 'done';
    #     }
    # }

    # update release version in the main module
    unless ( $self->dist->module->content->$* =~ s[^(\s*package\s+\w[\w\:\']*\s+)v?[\d._]+(\s*;)][$1$new_ver$2]sm ) {
        say q[Error updating version in the main dist module];

        return;
    }

    P->file->write_bin( $self->dist->module->path, $self->dist->module->content );

    # clear cached data
    $self->dist->clear;

    # update working copy
    $self->dist->build->update;

    # update CHANGES file
    # $self->_create_changes( $new_ver, $closed_issues->{data} );
    $self->_create_changes( $new_ver, undef );

    # generate wiki
    if ( $self->dist->build->wiki ) {
        $self->dist->build->wiki->run;
    }

    # add/remove
    {
        print 'Add/remove changes ... ';

        my $res = $self->dist->scm->scm_addremove;

        say $res && return if !$res;

        say 'done';
    }

    # commit
    {
        print 'Committing ... ';

        my $res = $self->dist->scm->scm_commit(qq[release $new_ver]);

        say $res && return if !$res;

        say 'done';
    }

    # set release tags
    {
        print 'Setting tags ... ';

        my $res = $self->dist->scm->scm_set_tag( [ 'latest', $new_ver ], 1 );

        say $res && return if !$res;

        say 'done';
    }

    if ( $self->dist->scm->upstream ) {
      PUSH_UPSTREAM:
        print 'Pushing to the upstream repository ... ';

        my $res = $self->dist->scm->scm_push;

        say $res->reason;

        if ( !$res ) {
            goto PUSH_UPSTREAM if P->term->prompt( q[Repeat?], [qw[yes no]], enter => 1 ) eq 'yes';
        }
    }

    if ( $self->dist->docker ) {
        require Pcore::API::DockerHub;

        my $dockerhub_api = Pcore::API::DockerHub->new;

      CREATE_DOCKERHUB_VERSION_TAG:
        if ( !$self->dist->build->docker->create_tag( $new_ver, $new_ver, $Pcore::API::DockerHub::DOCKERHUB_SOURCE_TYPE_TAG, '/' ) ) {
            goto CREATE_DOCKERHUB_VERSION_TAG if P->term->prompt( q[Repeat?], [qw[yes no]], enter => 1 ) eq 'yes';
        }

      CREATE_DOCKERHUB_LATEST_TAG:
        if ( !$self->dist->build->docker->create_tag( 'latest', 'latest', $Pcore::API::DockerHub::DOCKERHUB_SOURCE_TYPE_TAG, '/' ) ) {
            goto CREATE_DOCKERHUB_LATEST_TAG if P->term->prompt( q[Repeat?], [qw[yes no]], enter => 1 ) eq 'yes';
        }

      TRIGGER_BUILD_VERSION_TAG:
        if ( !$self->dist->build->docker->trigger_build($new_ver) ) {
            goto TRIGGER_BUILD_VERSION_TAG if P->term->prompt( q[Repeat?], [qw[yes no]], enter => 1 ) eq 'yes';
        }

      TRIGGER_BUILD_LATEST_TAG:
        if ( !$self->dist->build->docker->trigger_build('latest') ) {
            goto TRIGGER_BUILD_LATEST_TAG if P->term->prompt( q[Repeat?], [qw[yes no]], enter => 1 ) eq 'yes';
        }
    }

    # upload to the CPAN if this is the CPAN distribution, prompt before upload
    $self->_upload_to_cpan if $self->dist->cfg->{cpan};

    return 1;
}

sub _can_release ($self) {
    if ( !$self->dist->scm ) {
        say q[SCM is required.];

        return;
    }

    # check for uncommited changes
    if ( !$self->dist->is_commited ) {
        say q[Working copy or sub-repositories has uncommited changes or unknown files.];

        return;
    }

    if ( $self->dist->cfg->{cpan} && !$ENV->user_cfg->{PAUSE}->{username} || !$ENV->user_cfg->{PAUSE}->{password} ) {
        say q[You need to specify PAUSE credentials.];

        return;
    }

    # check distance from the last release
    if ( !$self->dist->id->{release_distance} ) {
        return if P->term->prompt( q[No changes since last release. Continue?], [qw[yes no]], enter => 1 ) eq 'no';
    }

    # check parent docker repo tag
    if ( $self->dist->docker ) {
        if ( !$ENV->user_cfg->{DOCKERHUB}->{username} || !$ENV->user_cfg->{DOCKERHUB}->{password} ) {
            say q[You need to specify DockerHub credentials.];

            return;
        }

        say qq[Docker base image is "@{[$self->dist->docker->{from}]}".];

        if ( $self->dist->docker->{from_tag} !~ /\Av\d+[.]\d+[.]\d+\z/sm ) {
            say q[Docker base image tag must be set to "vx.x.x". Use "pcore docker --from <TAG>" to set needed tag.];

            return;
        }
    }

    return 1;
}

sub _compose_new_version ($self) {

    # show current and new versions, take confirmation
    my $cur_ver = $self->dist->id->{release};

    if ( $cur_ver eq 'v0.0.0' && $self->bugfix ) {
        say 'Bugfix is impossible on first release';

        return;
    }

    my ( $major, $minor, $bugfix ) = $cur_ver =~ /v(\d+)[.](\d+)[.](\d+)/sm;

    # increment version
    if ( $self->major ) {
        $major++;
        $minor  = 0;
        $bugfix = 0;
    }
    elsif ( $self->minor ) {
        $minor++;
        $bugfix = 0;
    }
    elsif ( $self->bugfix ) {
        $bugfix++;
    }

    my $new_ver = 'v' . join q[.], $major, $minor, $bugfix;

    if ( $cur_ver eq $new_ver ) {
        say q[You forgot to specify release version];

        return;
    }

    if ( $new_ver ~~ $self->dist->releases ) {
        say qq[Version $new_ver is already released];

        return;
    }

    return $new_ver;
}

sub _upload_to_cpan ($self) {
    print 'Creating .tgz ... ';

    my $tgz = $self->dist->build->tgz;

    say 'done';

  REDO:
    print 'Uploading to CPAN ... ';

    my $pause = Pcore::API::PAUSE->new(
        {   username => $ENV->user_cfg->{PAUSE}->{username},
            password => $ENV->user_cfg->{PAUSE}->{password},
        }
    );

    my $res = $pause->upload($tgz);

    if ( $res->is_success ) {
        say $res->reason;

        unlink $tgz or 1;

        # print q[Removing old distributions from PAUSE ... ];
        #
        # $pause->clean;
        #
        # say 'done';
    }
    else {
        say join q[ ], $res->status, $res->reason;

        goto REDO if P->term->prompt( 'Retry?', [qw[yes no]], enter => 1 ) eq 'yes';

        say qq[Upload to CPAN failed. You should upload manually: "$tgz"];
    }

    return;
}

sub _create_changes ( $self, $ver, $issues ) {
    state $init = !!require CPAN::Changes;

    my $changes_path = $self->dist->root . 'CHANGES';

    my $changes = -f $changes_path ? CPAN::Changes->load($changes_path) : CPAN::Changes->new;

    my $rel = CPAN::Changes::Release->new(
        version => $ver,
        date    => P->date->now_utc->to_w3cdtf,
    );

    if ($issues) {
        my $group = {};

        for my $issue ( sort { $b->priority_id <=> $a->priority_id } $issues->@* ) {
            push $group->{ $issue->{metadata}->{kind} }->@*, qq[[$issue->{priority}] $issue->{title} (@{[$issue->url]})];
        }

        for my $group_name ( keys $group->%* ) {
            $rel->add_changes( { group => uc $group_name }, $group->{$group_name}->@* );
        }
    }

    # else {
    #     $rel->add_changes('No issues on bugtracker were closed since the last release');
    # }

    # get changesets since latest release
    my $tag = $ver eq 'v0.1.0' ? undef : 'latest';

    my $changesets = $self->dist->scm->scm_get_changesets($tag);

    my $summary_idx;

    my $log = <<'TXT';
LOG: Edit changelog.  Lines beginning with 'LOG:' are removed.

TXT
    for my $changeset ( $changesets->{data}->@* ) {
        if ( !exists $summary_idx->{ $changeset->{summary} } ) {
            $summary_idx->{ $changeset->{summary} } = undef;

            next if $changeset->{summary} =~ /\Arelease v[\d.]+\z/sm;

            next if $changeset->{summary} =~ /\AAdded tag/sm;

            $log .= "- $changeset->{summary}\n";
        }
    }

    my $tempfile = P->file->temppath;

    P->file->write_text( $tempfile, $log );

    system $ENV->user_cfg->{_}->{editor}, $tempfile;    ## no critic qw[InputOutput::RequireCheckedSyscalls]

    for my $line ( P->file->read_lines($tempfile)->@* ) {
        next if $line =~ /\ALOG:/sm;

        $line =~ s/\A[\s-]*//sm;

        $rel->add_changes($line);
    }

    say "\nCHANGES:";
    say $rel->serialize;

    $changes->add_release($rel);

    P->file->write_text( $changes_path, $changes->serialize );

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 14                   | Subroutines::ProhibitExcessComplexity - Subroutine "run" with high complexity score (26)                       |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 143, 163, 218, 223,  | ValuesAndExpressions::ProhibitLongChainsOfMethodCalls - Found method-call chain of length 4                    |
## |      | 228, 233             |                                                                                                                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 388                  | BuiltinFunctions::ProhibitReverseSortBlock - Forbid $b before $a in sort blocks                                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::Build::Release

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
