package OTRS::OPM::Maker::Utils::Git;

use strict;
use warnings;

use List::Util qw(first);
use Carp;

our $GIT = 'git';

sub commits {
    my ($class, %params) = @_;

    chdir $params{dir};

    my $log = qx{$GIT log -G"<Version>" --pretty=format:"%H %aI" *.sopm};

    my @lines = split /\n/, $log;

    my @found_commits;

    for my $line ( reverse @lines ) {
        my ($commit_hash, $date)  = split /\s+/, $line, 2;

        my $commit_log = qx{ $GIT log -p $commit_hash };
        my ($version)  = $commit_log =~ m{\+ \s+ <Version> (.*?) </Version> }xms;

        my $is_found_version_greater = _check_version(
            old_version => $params{version},
            new_version => $version,
        );

        if ( $is_found_version_greater ) {
            push @found_commits, { hash => $commit_hash, version => $version, date => $date };
        }
    }

    return if !@found_commits;

    my $changes = '';
    for my $index ( reverse 0 .. $#found_commits ) {
        my $commit  = $found_commits[$index];
        my $version = $commit->{version};
        my $hash    = $commit->{hash};
        my $date    = $commit->{date};

        my $next_hash = $index >= $#found_commits ? '' : $found_commits[$index+1]->{hash};
        my $range     = $hash . '..' . $next_hash;

        my $all_commits = qx{ $GIT log --pretty=format:"---%n%m%H%n%B" $range};

        my @commits = split /^---\n>/ms, $all_commits;

        $changes .= sprintf "%s    %s\n\n", $version, $date;

        COMMIT_ENTITY:
        for my $commit_entity ( @commits ) {
            my ($commit_hash, @message) = split /\n/, $commit_entity;

            next COMMIT_ENTITY if !$commit_hash;
            next COMMIT_ENTITY if !@message;

            my $i = 0;
            $changes .= join "\n", map{ my $indent = $i++ ? 8 : 4; (" " x $indent) . $_ }@message;
            $changes .= "\n\n";
        }

        $changes .= "\n";
    }

    return $changes
}

sub find_toplevel {
    my ($class, %params) = @_;

    return if !$params{dir};

    chdir $params{dir};

    my $path = qx{$GIT rev-parse --show-toplevel};
    return $path;
}

sub _check_version {
    my (%params) = @_;

    return 1 if !$params{old_version};

    my $old = sprintf "%03d%03d%03d", split /\./, $params{old_version};
    my $new = sprintf "%03d%03d%03d", split /\./, $params{new_version};

    return $new > $old;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OTRS::OPM::Maker::Utils::Git

=head1 VERSION

version 0.02

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
