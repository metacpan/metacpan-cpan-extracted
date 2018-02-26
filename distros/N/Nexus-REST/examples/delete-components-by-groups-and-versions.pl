#!/usr/bin/env perl

use 5.010;
use utf8;
use strict;
use autodie;
use warnings;
use open qw(:locale :std);
use Encode;
use Encode::Locale;
use Getopt::Long::Descriptive;
use Log::Any '$log';
use Log::Any::Adapter;
use Set::Scalar;

use lib "../lib";
use Nexus::REST;

sub grok_options {
    Encode::Locale::decode_argv();

    my ($opt, $usage) = describe_options(
        '%c %o <parameters>',
        ['nexus=s',  "Nexus base URL", {required => 1}],
        [],
        ['repository=s', "Repository name", {required => 1}],
        ['groups=s@',    "Component groups", {required => 1}],
        ['versions=s@',  "Component versions", {required => 1}],
        [],
        ['yes',     "Really delete components"],
        ['debug',   "Show debug information"],
        ['help',    "Print usage message and exit"],
        { show_defaults => 1},
    );

    if ($opt->help) {
        print $usage->text;
        exit 0;
    }

    Log::Any::Adapter->set('Stderr', log_level => $opt->debug ? 'debug' : 'info');

    return ($opt, $usage, @ARGV);
}

sub get_credentials {
    my ($userenv, $passenv, %opts) = @_;

    require Term::Prompt; Term::Prompt->import();

    $opts{prompt}      ||= '';
    $opts{userhelp}    ||= '';
    $opts{passhelp}    ||= '';
    $opts{userdefault} ||= $ENV{USER};

    my $user = $ENV{$userenv} || prompt('x', "$opts{prompt} Username: ", $opts{userhelp}, $opts{userdefault});
    my $pass = $ENV{$passenv};
    unless ($pass) {
	$pass = prompt('p', "$opts{prompt} Password: ", $opts{passhelp}, '');
	print "\n";
    }

    return ($user, $pass);
}

sub main {
    my ($opt, $usage, @args) = grok_options();

    my $errors = 0;

    $log->debugf('Connecting to %s', $opt->nexus);
    my $nexus = Nexus::REST->new($opt->nexus, get_credentials('nexususer', 'nexuspass'));

    my @groups   = split(',', join(',', @{$opt->groups}));
    my @versions = split(',', join(',', @{$opt->versions}));

    foreach my $version (@versions) {
        foreach my $group (@groups) {
            $log->debug("Searching components with version $version and group $group...");

            my $components = $nexus->get_iterator(
                '/rest/beta/search',
                {
                    repository => $opt->repository,
                    group      => $group,
                    version    => $version,
                },
            );

            while (my $c = $components->next) {
                $log->info("Deleting component $c->{group}.$c->{name}:$c->{version}");
                if ($opt->yes) {
                    $@ = undef;
                    eval { $nexus->DELETE("/rest/beta/components/$c->{id}") };
                    if ($@) {
                        ++$errors;
                        $log->error("ERROR: $@");
                    }
                }
            }
        }
    }

    $log->debug('Finishing up');

    return $errors;
}

exit main();


__END__
=encoding utf8

=head1 NAME

delete-components-by-groups-and-versions.pl - Delete Nexus components

=head1 SYNOPSIS

    delete-components-by-groups-and-versions.pl [long options...] <parameters>
	--nexus STR       Nexus base URL

	--repository STR  Repository name
	--groups STR       Component group
	--versions STR     Component version

	--yes             really delete components
	--debug           show debug information
	--help            print usage message and exit

=head1 DESCRIPTION

Deletes components from a Nexus 3 server based on a few search criteria.

ATTENTION! Please, be careful to specify the search criteria exactly or else you
run the risk of deleting more than you want. Run the script once without the
--yes option to see which components it tells you it would delete. Check the
list and after being sure, rerun the script with the --yes option to make it
effectively delete them.

=head1 OPTIONS

=over

=item * B<nexus URL>

Inform the Nexus 3 base URL.

This option is required.

=item * B<repository NAME>

Delete components from this repository only.

=item * B<group NAME>

Delete components from this group only.

=item * B<name NAME>

Delete components with this name only.

=item * B<version VERSION>

Delete components with this version only.

=item * B<yes>

By default the script does not delete the components, it only shows which
components were found. Specify this option to make it really delete them.

=item * B<debug>

Make it more verbose.

=item * B<help>

Shows the option syntax and exits.

=back

=head1 ENVIRONMENT

In order to connect to Nexus we need credentials. They're asked interactively,
but you may pass them via these envorinment variables too:

=over

=item B<nexususer>

=item B<nexuspass>

=back

=head1 COPYRIGHT

Copyright 2018 CPqD.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Gustavo Chaves <gustavo@cpqd.com.br>
