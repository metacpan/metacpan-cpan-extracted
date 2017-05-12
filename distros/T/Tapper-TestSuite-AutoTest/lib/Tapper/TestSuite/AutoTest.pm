package Tapper::TestSuite::AutoTest;
# git description: v4.1.1-1-gdd3439b

BEGIN {
  $Tapper::TestSuite::AutoTest::AUTHORITY = 'cpan:TAPPER';
}
{
  $Tapper::TestSuite::AutoTest::VERSION = '4.1.2';
}
# ABSTRACT: Tapper - Complete OS testing in a box via autotest

use warnings;
use strict;
use 5.010;

use Cwd;
use Moose;
use Getopt::Long qw/GetOptions/;
use Sys::Hostname qw/hostname/;
use YAML::Syck;
use Archive::Tar;
use IO::Socket::INET;
use File::Slurp qw/slurp/;
use File::Spec::Functions 'tmpdir';
use Digest::MD5 'md5_hex';

with 'MooseX::Log::Log4perl';


sub makedir
{
        my ($self, $dir) = @_;
        return 0 if -d $dir;
        if (-e $dir and not -d $dir) {
                unlink $dir;
        }
        system("mkdir","-p",$dir) == 0 or return "Can't create $dir:$!";
        return 0;
}


sub log_and_system {
        my ($self, @args) = @_;
        $self->log->debug(join(" ", @args));
        system(@args);
}


sub log_and_system_shell {
        my ($self, @args) = @_;
        $self->log->debug(join(" ", @args));
        system(join(" ", @args));
}


sub copy_client
{
        my($self, $downloaddir, $target) = @_;
        my ($error, $output);
        `which rsync`;
        if ( $? == 0)  {
                ($error, $output) = $self->log_and_system_shell("rsync",
                                                                "-a",
                                                                "$downloaddir/*autotest*/",
                                                                "$target/");
        } else {
                die "Target dir '$target' does not exist\n" if not -d $target;
                ($error, $output) = $self->log_and_system_shell("cp","-r","$downloaddir/*autotest*/*","$target/");
        }
        die $output if $error;
        return;
}



sub install
{
        my ($self, $args) = @_;
        my $error;
        my $output;

        my $tmp = tmpdir;
        my $source   = $args->{source};
        my $user     = $ENV{USER} || 'unknown';
        my $checksum = substr(md5_hex($source), 0,7);
        my $target   = $args->{target} || "$tmp/tapper-testsuite-autotest-client-$user-$checksum";
        my $downloaddir = "$tmp/tapper-testsuite-autotest-mirror-$user-$checksum";

        $self->makedir($target);
        $self->makedir($downloaddir);

        my $downloadfile;
        if (! -d "$target/tests") {
                if ($source =~ m,^(http|ftp)://, ) {
                        $downloadfile = "$downloaddir/autotest-download-$checksum.tgz";
                        if (! -e $downloadfile) {
                                $self->log->debug( "Download autotest from $source to $downloadfile");
                                ($error, $output) = $self->log_and_system('wget', "--no-check-certificate",
                                                                          $source, "-O", $downloadfile);
                                die $output if $error;
                        }
                } elsif ($source =~ m,^file://,) {
                        $downloadfile = $source;
                        $downloadfile =~ s,^file://,,;
                } else {
                        $downloadfile = $source;
                }
                $self->log->debug( "Unpack autotest from file $downloadfile to subdir $downloaddir");
                ($error, $output) = $self->log_and_system("tar",
                                                          "-xzf", $downloadfile,
                                                          "-C", $downloaddir);
                die $output if $error;
                $self->copy_client($downloaddir, $target);
                die $output if $error;
        }
        $args->{target} = $target;
        return $args;
}



sub report_away
{
        my ($self, $args) = @_;
        my $result_dir   = $args->{result_dir};
        my $gzipped_content = slurp("$result_dir/tap.tar.gz");

        my $sock = IO::Socket::INET->new(PeerAddr => $args->{report_server},
                                         PeerPort => $args->{report_port},
                                         Proto    => 'tcp');
        $self->log->debug("Report to ".($args->{report_server} // "report_server=UNDEF").":".($args->{report_port} // "report_port=UNDEF"));
        unless ($sock) {
                $self->log->error( "Result TAP in $result_dir/tap.tar.gz can not be sent to Tapper server.");
                die "Can't open connection to ", ($args->{report_server} // "report_server=UNDEF"), ":", ($args->{report_port} // "report_port=UNDEF"), ":$!"
        }

        my $report_id = <$sock>;
        ($report_id) = $report_id =~ /(\d+)$/;
        $sock->print($gzipped_content);
        $sock->close();
        $self->log->debug( "Report $report_id (http://".$args->{report_server}."/tapper/reports/id/$report_id)");
        return $report_id;
}


sub upload_files
{
        my ($self, $report_id, $test, $args) = @_;

        my $host       = $args->{reportserver};
        my $port       = $args->{reportport};
        my $result_dir = $args->{result_dir};

        # Currently no upload for these (personal taste, privacy, too big):
        #
        #   sysinfo/installed_packages
        #
        my @files = ();
        push @files, (qw( status
                          control
                          sysinfo/cmdline
                          sysinfo/cpuinfo
                          sysinfo/df
                          sysinfo/dmesg.gz
                          sysinfo/gcc_--version
                          sysinfo/hostname
                          sysinfo/interrupts
                          sysinfo/ld_--version
                          sysinfo/lspci_-vvn
                          sysinfo/meminfo
                          sysinfo/modules
                          sysinfo/mount
                          sysinfo/partitions
                          sysinfo/proc_mounts
                          sysinfo/slabinfo
                          sysinfo/uname
                          sysinfo/uptime
                          sysinfo/version
                       ));
        my @iterations = map { chomp; $_ } `cd  $result_dir ; find $test/sysinfo -name 'iteration.*'`;
        foreach my $iteration (@iterations) {
                push @files, map { "$iteration/$_" } (qw( interrupts.before
                                                          interrupts.after
                                                          meminfo.before
                                                          meminfo.after
                                                          schedstat.before
                                                          schedstat.after
                                                          slabinfo.before
                                                          slabinfo.after
                                                       ));
        }
        foreach my $shortfile (@files) {
                my $file = "$result_dir/$shortfile";
                next unless -e $file;

                # upload uncompressed dmesg for easier inline reading
                if ($file =~ m/dmesg.gz$/) {
                        system("gunzip $file") or do {
                                $file      =~ s/\.gz$//;
                                $shortfile =~ s/\.gz$//;
                        }
                }

                my $cmdline    = "#! upload $report_id $shortfile plain\n";
                my $content = slurp($file);
                my $sock = IO::Socket::INET->new(PeerAddr => $args->{report_server},
                                                 PeerPort => $args->{report_api_port},
                                                 Proto    => 'tcp');
                $self->log->debug("Upload '$shortfile' to ".($args->{report_server} // "report_server=UNDEF").":".($args->{report_api_port} // "report_api_port=UNDEF"));
                unless ($sock) {
                        $self->log->error( "Result file '$file' can not be sent to Tapper server.");
                        die "Can't open connection to ", ($args->{report_server} // "report_server=UNDEF"), ":", ($args->{report_api_port} // "report_api_port=UNDEF"), ":$!"
                }
                $sock->print($cmdline);
                $sock->print($content);
                $sock->close();
        }
        return;
}


sub get_machine_name
{
        my $etc_tapper = "/etc/tapper";

        my $hostname = hostname();
        $hostname =~ s/\..*$//; # no FQDN
        # combined machine name in Tapper automation guest environment
        if ($ENV{TAPPER_HOSTNAME}) {
                $hostname = "$ENV{TAPPER_HOSTNAME}:$hostname"
        } elsif ( -r $etc_tapper ) {
                my @tapper_config = ();
                my $TAPPERCFG;
                open $TAPPERCFG, "<", $etc_tapper and do {
                        local $/;
                        @tapper_config = <$TAPPERCFG>;
                        close $TAPPERCFG;
                };
                my ($machinename) =
                 map {
                      my $m = $_ ; $m =~ s/^[^:]*:// ; $m
                     }
                  grep {
                          /hostname:/
                  } @tapper_config;
                $hostname = "${machinename}:$hostname";
        }
        return $hostname;
}


sub send_results
{
        my ($self, $test, $args) = @_;
        my $report;

        my $tar             = Archive::Tar->new;
        $args->{result_dir} = $args->{target}."/client/results/default";
        my $result_dir      = $args->{result_dir};
        my $hostname        = get_machine_name;
        my $testrun_id      = $args->{testrun_id};
        my $report_group    = $args->{report_group};

        my $report_meta = "Version 13
1..1
# Tapper-Suite-Name: Autotest-$test
# Tapper-Machine-Name: $hostname
# Tapper-Suite-Version: ".$Tapper::TestSuite::AutoTest::VERSION."
ok 1 - Tapper metainfo
";
        $report_meta .= $testrun_id   ? "# Tapper-Reportgroup-Testrun: $testrun_id\n"     : '';
        $report_meta .= $report_group ? "# Tapper-Reportgroup-Arbitrary: $report_group\n" : '';
        $report_meta .= $self->autotest_meta($test, $args);

        my $meta;
        eval { $meta = YAML::Syck::LoadFile("$result_dir/meta.yml") };
        if ($@) {
                $meta = {};
                $report_meta .= "# Error loading $result_dir/meta.yml: $@\n";
                $report_meta .= "# Files in $result_dir\n";
                $report_meta .= $_ foreach map { "#   ".$_ } `find $result_dir`;
        }
        push @{$meta->{file_order}}, 'tapper-suite-meta.tap';
        $tar->read("$result_dir/tap.tar.gz");
        $tar->replace_content( 'meta.yml', YAML::Syck::Dump($meta) );
        $tar->add_data('tapper-suite-meta.tap',$report_meta);
        $tar->write("$result_dir/tap.tar.gz", COMPRESS_GZIP);

        my $report_id = $self->report_away($args);
        $self->upload_files($report_id, $test, $args) if $args->{uploadfiles};
        return $args;
}


sub autotest_meta
{
        my ($self, $test, $args) = @_;

        my $result_dir      = $args->{result_dir};
        my $meta = '';

        # --- generic entries ---
        my %metamapping = ( "uname"        => "uname",
                            "flags"        => "cmdline",
                            "machine-name" => "hostname",
                          );
        foreach my $header (keys %metamapping) {
                my $file = "$result_dir/sysinfo/".$metamapping{$header};
                next unless -e $file;
                my ($value) = slurp($file);
                chomp $value;
                $meta .= "# Tapper-$header: $value\n";
        }

        # --- cpu info ---
        my $cpuinfofile    = "$result_dir/sysinfo/cpuinfo";
        if (-e $cpuinfofile) {
                my @lines      = slurp($cpuinfofile);
                my $is_arm_cpu = grep { /Processor.*:.*ARM/ } @lines;
                my $entry      = $is_arm_cpu ? "Processor" : "model name";
                my @cpuinfo    = map { chomp ; s/^$entry.*: *//; $_ } grep { /$entry.*:/ } @lines;
                $meta         .= "# Tapper-cpuinfo: ".@cpuinfo." cores [".$cpuinfo[0]."]\n" if @cpuinfo;
        }
        return $meta;
}


sub print_help
{
        my ($self) = @_;
        say "$0 --test=s@ [ --directory=s ] [--remote-name]";
        say "\t--test|t\t\tName of a subtest, REQUIRED, may be given multple times";
        say "\t--directory|d\t\tDirectory to copy autotest to";
        say "\t--source_url|s\t\tURL to get autotest from";
        say "\t--remote-name|O\t\tPrint out the name of result files";
        say "\t--help|h\t\tPrint this help text and exit";


        exit;
}


sub parse_args
{
        my ($self) = @_;
        my @tests;
        my ($dir, $remote_name, $help, $source, $uploadfiles);

        $uploadfiles = 1;
        GetOptions ("test|t=s"  => \@tests,
                    "directory|d=s" => \$dir,
                    "remote-name|O" => \$remote_name,
                    "source_url|s=s"  => \$source,
                    "help|h"        => \$help,
                    "uploadfiles!" => \$uploadfiles,
                   );
        $self->print_help() if $help;
        if (not @tests) {
                print "Please name at least one subtest you want to run (--test=...).\n\n.";
                $self->print_help();
        }

        my $args = {subtests        => \@tests,
                    target          => $dir,
                    source          => $source || 'http://github.com/autotest/autotest/tarball/0.14.3',
                    report_server   => $ENV{TAPPER_REPORT_SERVER},
                    report_api_port => $ENV{TAPPER_REPORT_API_PORT} || '7358',
                    report_port     => $ENV{TAPPER_REPORT_PORT}     || '7357',
                    testrun_id      => $ENV{TAPPER_TESTRUN}         || '',
                    report_group    => $ENV{TAPPER_REPORT_GROUP}    || '',
                    remote_name     => $remote_name,
                    uploadfiles     => $uploadfiles,
                   };

        return $args;

}



sub run
{
        my ($self, $args) = @_;
        my $target = $args->{target};
        my $autotest = "./autotest-local";

        my $olddir = cwd();
        foreach my $test (@{$args->{subtests} || [] }) {
                $self->log->debug("chdir $target/client");
                chdir "$target/client";
                $self->log_and_system($autotest, "run", "--tap", $test);
                $self->send_results($test, $args);
        }
        chdir $olddir;
        return $args;
}

1; # End of Tapper::TestSuite::AutoTest

__END__
=pod

=encoding utf-8

=head1 NAME

Tapper::TestSuite::AutoTest - Tapper - Complete OS testing in a box via autotest

=head1 SYNOPSIS

You most likely want to run the frontend cmdline tool like this

=over 4

=item * Run an autotest subtest and report results to Tapper:

  $ tapper-testsuite-autotest -t hackbench

=item * Run multiple autotest subtests and report results to Tapper:

  $ tapper-testsuite-autotest -t hackbench -t hwclock

=back

=head1 DESCRIPTION

This module wraps autotest to make its (sub) tests available for Tapper.

The commandline tool simply calls the single steps like this:

    use Tapper::TestSuite::AutoTest;

    my $wrapper = Tapper::TestSuite::AutoTest->new();
    my $args    = $wrapper->parse_args();
    $args       = $wrapper->install($args);
    $args       = $wrapper->run($args);

The reporting evaluates several environment variables:

  TAPPER_REPORT_SERVER
  TAPPER_REPORT_API_PORT
  TAPPER_REPORT_PORT
  TAPPER_TESTRUN
  TAPPER_REPORT_GROUP

with some sensible defaults. They are automatically provided when
using Tapper automation.

In case you run it manually the most important variable is
C<TAPPER_REPORT_SERVER> pointing to your central Tapper server.

See the Tapper manual for more details.

=head1 FUNCTIONS

=head2 makedir

Checks whether a given directory exists and creates it if not.

@param string - directory to create

@return success - 0
@return error   - error string

=head2 $self->log_and_system(@args)

Log and do a multi arg C<system()>.

=head2 $self->log_and_system_shell(@args)

Log and do a single arg C<system()>.

=head2 copy_client

Move the client to where it belongs.

@param string - download directory
@param string - target directory

@return die() in case of error

=head2 install

Install the autotest framework from a given source into a given target

@param hash ref - args

@return hash ref - args

=head2 report_away

Send the actual report to reports receiver framework.

@param hash ref - args

@return success - int - report id
@return error   - die()

=head2 upload_files

Upload the stats file to reports framework.

@param int       - report id
@param hash ref - args

=head2 get_machine_name

Return hostname for metainfo in typical Tapper notation, i.e., just
the hostname (without FQDN) in host context or C<host:guest> (colon
separated) in guest context.

=head2 send_results

Send the test results to Tapper.

@param hash ref - args

@return hash ref - args

=head2 autotest_meta

Add meta information from files generated by autotest.

@param hash ref - args

@return string - Tapper TAP metainfo headers

=head2 print_help

Print help and die.

=head2 parse_args

Parse command line arguments and Tapper ENV variables.

@return hash ref - args

=head2 run

Run the requested autotest test(s), collect their results and report
them.

@param hash ref - args

@return hash ref - args

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

