package Test::BrewBuild::Dispatch;
use strict;
use warnings;

use Capture::Tiny qw(:all);
use Carp qw(croak);
use Config::Tiny;
use Cwd qw(getcwd);
use IO::Socket::INET;
use Logging::Simple;
use Parallel::ForkManager;
use POSIX;
use Storable;
use Test::BrewBuild;
use Test::BrewBuild::Git;

our $VERSION = '2.17';

$| = 1;

my ($log, $last_run_status, $results_returned);
$ENV{BB_RUN_STATUS} = 'PASS';

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    $log = Logging::Simple->new(level => 0, name => 'Dispatch');

    if (defined $args{debug}){
        $log->level($args{debug}) if defined $args{debug};
        $self->{debug} = $args{debug};
    }

    $log->child('new')->_5("instantiating new object");

    if (defined $args{auto}){
        $self->{auto} = $args{auto};
        $self->{auto} = 0 if $self->{auto} == 1;
    }

    $self->{autotest} = $args{autotest} if defined $args{autotest};
    $self->{forks} = defined $args{forks} ? $args{forks} : 4;
    $self->{rpi} = defined $args{rpi} ? $args{rpi} : undef;

    $self->_config;

    return $self;
}
sub auto {
    my ($self, %params) = @_;

    my $log = $log->child('auto');

    $log->_5("commencing auto run dispatch sequence");

    $last_run_status = $ENV{BB_RUN_STATUS};

    if (! defined $params{repo}){
        $log->_5("auto() requires the --repo param sent in. Can't continue...");
        croak "auto mode requires the repository parameter sent in.\n";
    }

    my $sleep = defined $self->{auto_sleep} ? $self->{auto_sleep} : 60;

    my $runs = $self->{auto};
    my $run_count = 1;

    $log->_7("$runs auto runs planned") if $runs > 0;
    $log->_7("continuous integration mode enabled") if $runs == 0;

    my $git = Test::BrewBuild::Git->new;

    while (1){

        if (! $runs){
            $log->_6("commencing run $run_count");
        }
        else {
            $log->_6("commencing run $run_count of $runs");
        }

        my $results = $self->dispatch(%params);

        my @short_results = $results =~ /(5\.\d{1,2}\.\d{1,2} :: \w{4})/g;

        print "$_\n" for @short_results;

        if (grep /FAIL/, @short_results){
            $log->_5("auto run status: FAIL");
            $ENV{BB_RUN_STATUS} = 'FAIL';
            $results_returned = 1;
        }
        elsif (grep /PASS/, @short_results){
            $log->_5("auto run status: PASS");
            $ENV{BB_RUN_STATUS} = 'PASS';
            $results_returned = 1;
        }
        else {
            $log->_5("no results returned");
            $results_returned = 0;
        }

    
        if ($self->{rpi}){
            $log->_7("RPi specific testing enabled");

            if ($ENV{BB_RPI_LCD}){
                my @pins = split /,/, $ENV{BB_RPI_LCD};
                if (@pins == 6){
                    if ($results_returned){
                        my $commit = $git->revision(remote => 1, repo => $params{repo});
                        $commit = substr $commit, 0, 8;

                        my $time = strftime(
                            "%Y-%m-%d %H:%M:%S", localtime(time)
                        );
                        
                        my $lcd = _lcd(@pins);

                        $lcd->clear;

                        $lcd->position(0, 0);
                        $lcd->print($time);

                        $lcd->position(0, 1);
                        $lcd->print($ENV{BB_RUN_STATUS});

                        $lcd->position(8, 1);
                        $lcd->print($commit);
                    }
                }
                else {
                    $log->_1(
                        "in --rpi mode, but BB_RPI_LCD env var not set " .
                        "correctly"
                    );
                    warn "bbdispatch is in --rpi mode, but the BB_RPI_LCD ".
                         " env var isn't set. See the documentation...\n";
                }
            }
            else {
                $log->_7("in --rpi mode, but BB_RPI_LCD env var not set");
            }
        }
        else {
            $log->_7("not in --rpi mode");
        }

        $log->_6(
            "auto run complete. Sleeping, then restarting if more runs required"
        );

        exit() if $run_count >= $runs && $runs != 0;
        $run_count++;

        sleep $sleep;
    }
}
sub _lcd {
    # used only for dispatching to an RPi in auto mode

    my @pins = @_;

    require RPi::LCD;

    my $lcd = RPi::LCD->new;

    $lcd->init(
        rows    => 2,
        cols    => 16,
        bits    => 4,
        rs      => $pins[0],
        strb    => $pins[1],
        d0      => $pins[2],
        d1      => $pins[3],
        d2      => $pins[4],
        d3      => $pins[5],
        d4      => 0,
        d5      => 0,
        d6      => 0,
        d7      => 0
    );

    return $lcd;
}
sub dispatch {
    my ($self, %params) = @_;

    my $cmd = $params{cmd} || $self->{cmd};
    $cmd = 'brewbuild' if ! $cmd;
    my $repo = $params{repo} || $self->{repo};
    my $testers = $params{testers} || $self->{testers};

    my $log = $log->child('dispatch');

    my %remotes;

    if (! $testers->[0]){
        $log->_6("no --testers passed in, and failed to fetch testers from " .
                 "config file, croaking"
        );
        croak "dispatch requires testers sent in or config file, which " .
              "can't be found. Run \"bbdispatch -h\" for help.\n";
    }
    else {
        $log->_7("working on testers: " . join ', ', @$testers);

        for my $tester (@$testers){
            my ($host, $port);
            if ($tester =~ /:/){
                ($host, $port) = split /:/, $tester;
            }
            else {
                $host = $tester;
                $port = 7800;
            }
            $remotes{$host}{port} = $port;
            $log->_5("configured $host with port $port");
        }
    }

    # spin up the comms

    %remotes = $self->_fork(\%remotes, $cmd, $repo);

    if (! -d 'bblog'){
        mkdir 'bblog' or croak $!;
        $log->_7("created log dir: bblog");
    }

    # init the return string

    my $return = "\n";

    for my $ip (keys %remotes){
        if (! defined $remotes{$ip}{build}){
            $log->_5("tester: $ip didn't supply results... deleting");
            delete $remotes{$ip};
            next;
        }

        # build log file generation

        for my $build_log (keys %{ $remotes{$ip}{build}{files} }){
            $log->_7("generating build log: $build_log");

            my $content = $remotes{$ip}{build}{files}{$build_log};
            $log->_7("writing out log: " . getcwd() . "/bblog/$ip\_$build_log");
            open my $wfh, '>', "bblog/$ip\_$build_log" or croak $!;
            for (@$content){
                print $wfh $_;
            }
        }

        # build the return string

        my $build = $remotes{$ip}{build};

        $return .= "$ip - $build->{platform}\n";
        $return .= "$build->{log}" if $build->{log};

        if (ref $build->{data} eq 'ARRAY'){
            $return .= $_ for @{ $build->{data} };
        }
        else {
            $build->{data} = '' if ! $build->{data};
            $return .= "$build->{data}\n";
        }
    }
    $log->_7("returning results if available...");
    return $return;
}
sub _config {
    # slurp in config file elements

    my $self = shift;

     my $conf_file = Test::BrewBuild->config_file;

    if (-f $conf_file){
        my $conf = Config::Tiny->read($conf_file)->{dispatch};
        if ($conf->{testers}){
            $conf->{testers} =~ s/\s+//;
            $self->{testers} = [ split /,/, $conf->{testers} ];
        }
        $self->{repo} = $conf->{repo} if $conf->{repo};
        $self->{cmd} = $conf->{cmd} if $conf->{cmd};
        $self->{auto_sleep} = $conf->{cmd} if defined $conf->{auto_sleep};
    }
}
sub _fork {
    # handles the tester communications

    my ($self, $remotes, $cmd, $repo) = @_;

    my $log = $log->child('_fork');

    my $pm = Parallel::ForkManager->new($self->{forks});

    $pm->run_on_finish(
        sub {
            my (undef, undef, undef, undef, undef, $tester_data) = @_;
            map {$remotes->{$_} = $tester_data->{$_}} keys %$tester_data;
            $log->_5("tester: " . (keys %$tester_data)[0] ." finished")
              if keys %$tester_data;
        }
    );

    for my $tester (keys %$remotes){
        $log->_7("spinning up tester: $tester");

        my $log = $log->child($tester);

        $pm->start and next;

        my %return;

        my $socket = new IO::Socket::INET (
            PeerHost => $tester,
            PeerPort => $remotes->{$tester}{port},
            Proto => 'tcp',
        );
        if (! $socket){
            croak "can't connect to remote $tester on port " .
                "$remotes->{$tester}{port} $!\n";
        }

        $log->_7("tester $tester socket created ok");

        # syn
        $socket->send($tester);
        $log->_7("syn \"$tester\" sent");

        # ack
        my $ack;
        $socket->recv($ack, 1024);
        $log->_7("ack \"$ack\" received");

        if ($ack ne $tester){
            $log->_0("comm error: syn \"$tester\" doesn't match ack \"$ack\"");
            croak "comm discrepancy: expected $tester, got $ack\n";
        }

        if (! $cmd){
            $log->_6("no command specified, Tester default will ensue");
        }
        $socket->send($cmd);
        $log->_7("sent command: $cmd");

        my $check = '';
        $socket->recv($check, 1024);
        $log->_7("received \"$check\"");

        if ($check =~ /^error:/){
            $log->_0("received an error: $check... killing all procs");
            kill '-9', $$;
        }
        if ($check eq 'ok'){
            my $repo_link;

            if (! $repo){
                my $git = Test::BrewBuild::Git->new(debug => $self->{debug});
                $log->_5("repo not sent in, attempting to set via Git");
                $repo_link = $git->link;

                if ($repo_link){
                    $log->_5("repo set to $repo_link from Git");
                }
                else {
                    $log->_7(
                        "\$repo_link could not be set, we're about to fail..."
                    );
                }
            }
            else {
                $repo_link = $repo;
                $log->_5("repo was sent in, and set to: $repo_link");
            }

            if (! $repo_link){
                $log->_0(
                    "no repository supplied and not in a repo dir... croaking"
                );
                croak
                    "\nno repository found, and none sent in via param, " .
                    "can't continue...";
            }

            $log->_6("dispatching out to and waiting for tester: '$tester'...");

            $socket->send($repo_link);

            my $ok = eval {
                $return{$tester}{build} = Storable::fd_retrieve($socket);
                1;
            };

            $log->_7("tester work has concluded");

            if (! $ok && ! defined $self->{auto}){
                $log->_0("errors occurred... check your command line " .
                         "string for invalid args. You sent in: $cmd.\n" .
                         "The full error: $@"
                );
                exit;
            }
        }
        else {
            $log->_5(
                "deleted tester: $remotes->{$tester}... incomplete session"
            );
            delete $remotes->{$tester};
        }
        $socket->close();
        $pm->finish(0, \%return);
    }

    $pm->wait_all_children;

    return %$remotes;
}
1;

=head1 NAME

Test::BrewBuild::Dispatch - Dispatch C<Test::BrewBuild> test runs to remote test
servers.

=head1 SYNOPSIS

    use Test::BrewBuild::Dispatch;

    my $d = Test::BrewBuild::Dispatch->new;

    my $return = $d->dispatch(
        cmd => 'brewbuild -r -R',
        testers => [qw(127.0.0.1 10.1.1.1:9999)],
        repo => 'https://github.com/user/repo',
    );

    print $return;

=head1 DESCRIPTION

This is the remote dispatching system of L<Test::BrewBuild>.

It dispatches out test runs to L<Test::BrewBuild::Tester> remote test servers
to perform, then processes the results returned from those testers.

By default, we try to look up the repository information from your current
working directory. If it can't be found, you must supply it on the command line
or within the configuration file.

=head1 METHODS

=head2 new

Returns a new C<Test::BrewBuild::Dispatch> object.

=head2 dispatch(cmd => '', repo => '', testers => ['', ''], debug => 0-7)

C<cmd> is the C<brewbuild> command string that will be executed.

C<repo> is the name of the repo to test against, and is optional.
If not supplied, we'll attempt to get a repo name from the local working
directory you're working in.

C<testers> is manadory unless you've set up a config file, and contains an
array reference of IP/Port pairs for remote testers to dispatch to and follow.
eg: C<[qw(10.1.1.5 172.16.5.5:9999)]>. If the port portion of the tester is
omitted, we'll default to C<7800>.

By default, the testers run on all IPs and port C<TCP/7800>.

C<debug> optional, set to a level between 0 and 7.

See L<Test::BrewBuild::Tester> for more details on the testers that the
dispatcher dispatches to.

=head2 auto(%params)

This function will spin off a continuous run of C<dispatch()> runs, based on
whether the commit revision checksum locally is different than that from the
remote. It takes all of the same parameters as C<dispatch()>, and the
C<-r|--repo> parameter is mandatory.

There is also a configuration file directive in the C<[Dispatch]> section,
C<auto_sleep>, which dictates how many seconds to sleep in between each run. The
default is C<60>, or one minute.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
 
