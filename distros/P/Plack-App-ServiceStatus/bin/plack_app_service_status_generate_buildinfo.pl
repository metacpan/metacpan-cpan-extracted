#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;

# ABSTRACT: Script to generate buildinfo.json for Plack::App::ServiceStatus
# PODNAME: plack_app_service_status_generate_buildinfo.pl
our $VERSION = '0.913'; # VERSION

use POSIX qw(strftime);
use Getopt::Long;
use Pod::Usage;

my $man            = 0;
my $help           = 0;
my $buildinfo_file = "./buildinfo.json";
my $project_dir    = '';
GetOptions(
    'help|?'    => \$help,
    man         => \$man,
    "project=s" => \$project_dir,
    "output:s"  => \$buildinfo_file,
) or pod2usage(2);
pod2usage(1)                              if $help;
pod2usage( -exitval => 0, -verbose => 2 ) if $man;

die "required param --project missing" unless $project_dir;

die "Cannot find project directory at $project_dir"
  unless $project_dir && -d $project_dir;
open( my $out, ">", $buildinfo_file )
  || die "Cannot write to $buildinfo_file: $!";

chdir($project_dir);

my $data = '{';    # just concat the JSON :-)

my $now = strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime( time() ) );
$data .= qq{"date":"$now"};

my $has_git = `git --version`;
if ( $has_git =~ /^git version/ ) {
    my $commit = `git rev-parse HEAD`;
    my $branch = `git rev-parse --abbrev-ref HEAD`;
    chomp($commit);
    chomp($branch);
    $data .= qq{, "git-commit":"$commit", "git-branch": "$branch"};
}

$data .= '}';

print $out $data;
close $out;

say "Wrote buildinfo for $project_dir to $buildinfo_file";

__END__

=pod

=encoding UTF-8

=head1 NAME

plack_app_service_status_generate_buildinfo.pl - Script to generate buildinfo.json for Plack::App::ServiceStatus

=head1 VERSION

version 0.913

=head1 SYNOPSIS

  plack_app_service_status_generate_buildinfo.pl --project path/to/repo --output path/to/buildinfo.json

=head1 DESCRIPTION

Generate a small JSON file containg information about a build to be shown by Plack::App::ServiceStatus.

It will make most sense to run this script during your build pipeline
and include the produced file in your release. Then let
Plack::App::ServiceStatus use this file to display some helpful info
when / how your app was build alongside the other ServiceStatus info.

=head1 OPTIONS

=head2 --project path/to/project

The path to the project repo, used to collect info.

=head2 --output path/to/buildinfo.json

Location of the buildinfo file that will be generated.

=head2 --help

Show short help

=head2 --man

Show more help

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2022 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
