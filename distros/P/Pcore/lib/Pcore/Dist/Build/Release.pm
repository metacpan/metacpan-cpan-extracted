package Pcore::Dist::Build::Release;

use Pcore -class;
use Pod::Markdown;
use CPAN::Meta;
use Pcore::API::PAUSE;

has dist   => ( required => 1 );    # InstanceOf ['Pcore::Dist']
has major  => 0;                    # Bool
has minor  => 0;                    # Bool
has bugfix => 0;                    # Bool

sub run ($self) {

    # check, if release can be performed
    return if !$self->_can_release;

    my $new_ver = $self->_compose_new_version;

    return if !$new_ver;

    say $EMPTY;

    say "Current release version is: @{[ $self->{dist}->id->{release} // 'v0.0.0' ]}";

    say "New release version will be: $new_ver\n";

    return if P->term->prompt( 'Continue release process?', [qw[yes no]], enter => 1 ) ne 'yes';

    say $EMPTY;

    # run tests
    return if !$self->{dist}->build->test( author => 1, release => 1 );

    say $EMPTY;

    # NOTE !!!WARNING!!! start release, next changes will be hard to revert

    # update CHANGES file
    $self->_create_changes( $self->{dist}->id->{release}, $new_ver );

    # update release version in the main module
    unless ( $self->{dist}->module->content->$* =~ s[^(\s*package\s+\w[\w\:\']*)(?:\s+v?[\d._]*)?(\s*;)][$1 $new_ver$2]sm ) {
        say q[Error updating version in the main dist module];

        return;
    }

    P->file->write_bin( $self->{dist}->module->path, $self->{dist}->module->content );

    # clear cached data
    $self->{dist}->clear;

    # update working copy
    $self->{dist}->build->update;

    # generate wiki
    if ( $self->{dist}->build->wiki ) {
        $self->{dist}->build->wiki->run;
    }

    # add/remove
    {
        print 'Add/remove changes ... ';

        my $res = $self->{dist}->git->git_run('add .');

        say $res && return if !$res;

        say 'done';
    }

    # commit
    {
        print 'Committing ... ';

        my $res = $self->{dist}->git->git_run(qq[commit -m"release $new_ver"]);

        say $res && return if !$res;

        say 'done';
    }

    # set release tags
    {
        print 'Setting tags ... ';

        my $res = $self->{dist}->git->git_run(qq[tag -a "$new_ver" -m "Released version: $new_ver" ]);
        say $res && return if !$res;

        $res = $self->{dist}->git->git_run( [ 'tag', 'latest', '--force' ] );
        say $res && return if !$res;

        say 'done';
    }

    if ( $self->{dist}->git->upstream ) {

        # pushing changesets
      GIT_PUSH:
        print 'Pushing changesets ... ';
        my $res = $self->{dist}->git->git_run('push');
        say $res->{reason};
        goto GIT_PUSH if !$res && P->term->prompt( q[Repeat?], [qw[yes no]], enter => 1 ) eq 'yes';

        # pushing tags
      GIT_PUSH_TAGS:
        print 'Pushing tags ... ';
        $res = $self->{dist}->git->git_run(qq[push origin -f "refs/tags/$new_ver" "refs/tags/latest"]);
        say $res->{reason};
        goto GIT_PUSH_TAGS if !$res && P->term->prompt( q[Repeat?], [qw[yes no]], enter => 1 ) eq 'yes';
    }

    # upload to the CPAN if this is the CPAN distribution, prompt before upload
    $self->_upload_to_cpan if $self->{dist}->cfg->{cpan};

    return 1;
}

sub _can_release ($self) {
    if ( !$self->{dist}->git ) {
        say q[Git was not found.];

        return;
    }

    my $id = $self->{dist}->id;

    # check master branch
    if ( !$id->{branch} || $id->{branch} ne 'master' ) {
        say q[Git is not on the "master" branch.];

        return;
    }

    # check for uncommited changes
    if ( $id->{is_dirty} ) {
        say q[Working copy or sub-repositories has uncommited changes or untracked files.];

        return;
    }

    if ( $self->{dist}->cfg->{cpan} && !$ENV->user_cfg->{PAUSE}->{username} || !$ENV->user_cfg->{PAUSE}->{password} ) {
        say q[You need to specify PAUSE credentials.];

        return;
    }

    # check distance from the last release
    if ( $id->{release} && !$id->{release_distance} ) {
        return if P->term->prompt( q[No changes since last release. Continue?], [qw[yes no]], enter => 1 ) eq 'no';
    }

    # docker
    if ( $self->{dist}->docker ) {
        say qq[Docker base image is "@{[$self->{dist}->docker->{from}]}".];

        # check parent docker repo tag
        if ( !$self->{dist}->is_pcore && $self->{dist}->docker->{from_tag} !~ /\Av\d+[.]\d+[.]\d+\z/sm ) {
            say q[Docker base image tag must be set to "vx.x.x". Use "pcore docker --from <TAG>" to set needed tag.];

            return;
        }
    }

    return 1;
}

sub _compose_new_version ($self) {

    # show current and new versions, take confirmation
    my $cur_ver = version->parse( $self->{dist}->id->{release} // 'v0.0.0' );

    if ( !$cur_ver && $self->{bugfix} ) {
        say 'Bugfix is impossible on first release';

        return;
    }

    my ( $major, $minor, $bugfix ) = $cur_ver->{version}->@*;

    # increment version
    if ( $self->{major} ) {
        $major++;
        $minor  = 0;
        $bugfix = 0;
    }
    elsif ( $self->{minor} ) {
        $minor++;
        $bugfix = 0;
    }
    elsif ( $self->{bugfix} ) {
        $bugfix++;
    }

    my $new_ver = version->parse("v$major.$minor.$bugfix");

    if ( $cur_ver eq $new_ver ) {
        say q[You forgot to specify release version];

        return;
    }

    if ( "$new_ver" ~~ $self->{dist}->releases ) {
        say qq[Version $new_ver is already released];

        return;
    }

    return $new_ver;
}

sub _upload_to_cpan ($self) {
    print 'Creating .tgz ... ';

    my $tgz = $self->{dist}->build->tgz;

    say 'done';

  REDO:
    print 'Uploading to CPAN ... ';

    my $pause = Pcore::API::PAUSE->new( {
        username => $ENV->user_cfg->{PAUSE}->{username},
        password => $ENV->user_cfg->{PAUSE}->{password},
    } );

    my $res = $pause->upload($tgz);

    say $res;

    if ($res) {
        unlink $tgz or 1;
    }
    else {
        goto REDO if P->term->prompt( 'Retry?', [qw[yes no]], enter => 1 ) eq 'yes';

        say qq[Upload to CPAN failed. You should upload manually: "$tgz"];
    }

    return;
}

sub _create_changes ( $self, $cur_ver, $new_ver ) {
    require CPAN::Changes;

    my $changes_path = "$self->{dist}->{root}/CHANGES";

    my $changes = -f $changes_path ? CPAN::Changes->load($changes_path) : CPAN::Changes->new;

    my $rel = CPAN::Changes::Release->new(
        version => $new_ver,
        date    => P->date->now_utc->to_w3cdtf,
    );

    # get changesets since latest release
    my $changesets = $self->{dist}->get_changesets_log($cur_ver);

    my $log = <<'TXT';
LOG: Edit changelog.  Lines beginning with 'LOG:' are removed.

TXT

    for my $changeset ( $changesets->@* ) {
        $log .= "- $changeset\n";
    }

    my $tempfile = P->file1->tempfile;

    P->file->write_text( $tempfile, $log );

    system $ENV->user_cfg->{editor}, $tempfile;    ## no critic qw[InputOutput::RequireCheckedSyscalls]

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
## |    3 | 13                   | Subroutines::ProhibitExcessComplexity - Subroutine "run" with high complexity score (21)                       |
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
