package Mnet;

# version number used by Makefile.PL
#   these should be set to "dev", expect when creating a new release
#   refer to developer build notes in Makefile.PL for more info
our $VERSION = "5.21";

=head1 NAME

Mnet - Testable network automation and reporting

=head1 SYNOPSIS

    # sample script to report Loopback0 ip on cisco devices
    #
    #   demonstrates typical use of all major Mnet modules
    #
    #   --help to list all options, or --help <option>
    #   --device <address> to connect to device with logging
    #   --username and --password should be set if necessary
    #   --batch <file.batch> to process multiple --device lines
    #   --report csv:<file.csv> to create an output csv file
    #   --record <file.test> to create replayable test file
    #   --test --replay <file.test> for regression test output
    #
    #   refer to various Mnet modules' perldoc for more info

    # load modules
    use warnings;
    use strict;
    use Mnet::Batch;
    use Mnet::Expect::Cli::Ios;
    use Mnet::Log qw(DEBUG INFO WARN FATAL);
    use Mnet::Opts::Cli;
    use Mnet::Report::Table;
    use Mnet::Stanza;
    use Mnet::Test;

    # define --device, --username, --password, and --report cli options
    #   record, redact, default, and help option attributes are shown
    Mnet::Opts::Cli::define({ getopt => "device=s", record => 1 });
    Mnet::Opts::Cli::define({ getopt => "username=s" });
    Mnet::Opts::Cli::define({ getopt => "password=s", redact  => 1 });
    Mnet::Opts::Cli::define({ getopt => "report=s", default => undef,
        help_tip    => "specify report output, csv, json, sql, etc",
        help_text   => "perldoc Mnet::Report::Table for more info",
    });

    # create object to access command line options and Mnet env variable
    #   export Mnet="--password '<secret>'" env var from secure file
    my $cli = Mnet::Opts::Cli->new("Mnet");

    # define output --report table, will include first of any errors
    #   use --report cli opt to output data as csv, json, or sql, etc
    my $report = Mnet::Report::Table->new({
        columns => [
            device  => "string",
            error   => "error",
            ip      => "string",
        ],
        output  => $cli->report,
    });

    # recreate cli option object, forking children if in --batch mode
    #   process one device or ten thousand devices with the same script
    #   exit --batch parent process here when finished forking children
    $cli = Mnet::Batch::fork($cli);
    exit if not $cli;

    # output report row for device error if script dies before finishing
    $report->row_on_error({ device => $cli->device });

    # call logging function, also create log object for current --device
    FATAL("missing --device") if not $cli->device;
    my $log = Mnet::Log->new({ log_id => $cli->device });
    $log->info("processing device");

    # create an expect ssh session to current --device
    #   log ssh login/auth prompts as info, instead of default debug
    #   password_in set to prompt for password if --password opt not set
    #   ssh host/key checks can be skipped, refer to Mnet::Expect::Cli
    my $ssh = Mnet::Expect::Cli::Ios->new({
        spawn       => [ "ssh", "$cli->{username}\@$cli->{device}" ],
        log_id      => $cli->{device},
        log_login   => "info",
        password    => $cli->password,
        password_in => 1,
    });

    # retrieve ios config using ssh command, warn otherwise
    my $config = $ssh->command("show running-config");
    WARN("unable to read config") if not $config;

    # parse interface loopack0 stanza from device config
    #   returns int loop0 line and lines indented under int loop0
    my $loop = Mnet::Stanza::parse($config, qr/^interface Loopback0$/);

    # parse primary ip address from loopback config stanza
    my $ip = undef;
    $ip = $1 if $loop and $loop =~ /^ ip address (\S+) \S+$/m;

    # report on parsed loopback0 interface ip addres
    $report->row({ device => $cli->device, ip => $ip });

    # finished
    exit;

=head1 DESCRIPTION

The L<Mnet> modules are for perl programmers who want to create testable
network automation and/or reporting scripts as simply as possible.

The main features are:

=over

=item *

Record and replay connected command line sessions, speeding development
and allow for regression testing of complex automation scripts.

=item *

Reliable automation of cisco ios and other command line sessions, including
authentication and command prompt handling.

=item *

Automation scripts can run in batch mode to concurrently process a list of
devices, using a simple command line argument and a device list file.

=item *

Facilitate easy log, debug, alert and error output from automation scripts,
outputs can be redirected to per-device files

=item *

Flexible config settings via command line, environment variable, and/or batch
device list files.

=item *

Report data from scripts can be output as csv, json, or sql.

=back

Most of the L<Mnet> sub-modules can be used independently of each other,
unless otherwise noted.

Refer to the individual modules listed in the SEE ALSO section below
for more detail.

=head1 INSTALLATION

The L<Mnet> perl modules should work in just about any unix perl environment.

The latest release can be installed from CPAN

    cpan install Mnet

Or download and install from L<https://github.com/menzascripting/Mnet>

    tar -xzf Mnet-X.y.tar.gz
    cd Mnet-X.y
    perl Makefile.PL  # INSTALL_BASE=/specify/path
    make test
    make install

Check your PERL5LIB environment variable if INSTALL_BASE was used, or if you
copied the lib/Mnet directory somewhere instead of using Makefile.PL. Refer
to L<ExtUtils::MakeMaker> for more information

=head1 AUTHOR

The L<Mnet> perl distribution has been created and is maintained by Mike Menza.
Feedback and bug reports are welcome, feel free to contact Mike via email
at <mmenza@cpan.org> with any comments or questions.

=head1 COPYRIGHT AND LICENSE

Copyright 2006, 2013-2020 Michael J. Menza Jr.

L<Mnet> is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see L<http://www.gnu.org/licenses/>

=head1 SEE ALSO

L<Mnet::Batch>

L<Mnet::Expect::Cli>

L<Mnet::Expect::Cli::Ios>

L<Mnet::Log>

L<Mnet::Opts::Cli>

L<Mnet::Report::Table>

L<Mnet::Stanza>

L<Mnet::Test>

=cut

# required modules
#   cpan complians if use strict is missing
use warnings;
use strict;

# normal end of package
1;

