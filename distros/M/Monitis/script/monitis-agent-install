#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use File::Temp;
use File::Spec::Functions qw/catfile catdir rel2abs/;
use File::Path 'make_path';
use Carp;
use IPC::Open3;
use Symbol 'gensym';

use lib 'lib';
use lib '../lib';

foreach my $package ('JSON', 'Digest::SHA', 'Monitis', 'Archive::Extract') {
    eval "use $package";
    if ($@) {
        if ($@ =~ /^Can't locate/) {
            die
              "To run this script you need package '$package' installed. Try:\n\n"
              . "    cpan install $package\n";
        }

        die $@;
    }
}

my %opts;

GetOptions(
    "api-key|api=s"       => \$opts{api},
    "secret-key|secret=s" => \$opts{secret},
    "email=s"             => \$opts{email},
    "base|b=s"            => \$opts{base},
    "name=s"              => \$opts{name},
    "config=s"            => \$opts{config},
    "help|h"              => \$opts{help}
);

pod2usage if $opts{help};

check_deps();

# Read config file
$opts{mandatory_config} = !!$opts{config};
$opts{config} ||= 'monitis.conf';

if (open my $CONFIG, '<', $opts{config}) {
    while (my $line = <$CONFIG>) {
        chomp $line;
        my ($key, $value) = split /\s+/, $line, 2;
        $opts{$key} ||= $value;
    }
}
elsif ($opts{mandatory_config}) {
    die "Can not read config '$opts{config}': $!\n";
}

fill_config(\%opts);

if (my $pid = _monitis_running($opts{pidfile})) {
    die
      "\nMonitis agent already running from path '$opts{base}'\nPID: $pid\n";
}

my $file = download_agent($opts{api}, $opts{secret});

extract_agent($file, $opts{base});

write_config(%opts);

run_agent(%opts);

setup_monitors(%opts);

cleanup($opts{config});

sub _get_answer {
    my ($question, $fail, $check, @variants) = @_;

    if (ref $check eq 'ARRAY') {
        @variants = @$check;
        $check = sub { grep /^\s*\Q$_[0]\E\s*$/si, @variants };
    }
    elsif (ref $check eq 'Regexp') {
        my $regexp = $check;
        $check = sub { $_[0] =~ $regexp };
    }
    elsif (ref $check ne 'CODE') {
        croak("Wrong type of check: " . ref $check);
    }

    while (1) {
        print $question . ": ";
        print '[' . $variants[0] . '] ' if @variants;
        my $answer = <STDIN>;
        chomp $answer;

        if (!$answer && @variants) {
            $answer = $variants[0];
        }

        return $answer if $check->($answer);
        warn "$fail\n";
    }
}

sub fill_config {
    my $opts = shift;
    $opts->{api} ||= _get_answer "Monitis API KEY",
      "Wrong key format", qr/^\w+$/i;

    $opts->{secret} ||= _get_answer "Monitis SECRET KEY",
      "Wrong key format", qr/^\w+$/i;

    $opts->{'email'} ||= _get_answer "Account name (email)",
      "Wrong email format", qr/^.+\@.+\..+$/i;

    my $default_name = `uname -n`;
    chomp $default_name;
    $default_name .= '@';

    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
      localtime(time);

    $default_name .= sprintf(
        "%02d:%02d:%4d:%02d:%02d:%02d",
        $mday, $mon + 1, $year + 1900,
        $hour, $min, $sec
    );

    $opts->{'name'} ||= _get_answer "New agent name", "Wrong name", qr/.+/,
      $default_name,

      $opts->{'base'} ||= _get_answer "Path for installation", "", sub {1},
      $ENV{HOME};

    $opts->{base} = rel2abs($opts->{'base'});
    $opts->{home} = catdir($opts->{'base'}, 'monitis');

    $opts->{pidfile}    = catfile($opts->{'home'}, 'logs', 'monitis.pid');
    $opts->{executable} = catfile($opts->{'home'}, 'bin',  'monitis');
    $opts->{conf}       = catfile($opts->{'home'}, 'etc',  'monitis.conf');
    $opts->{host} ||= 'google.com';
}

sub download_agent {
    my ($key, $secret) = @_;
    my $api = Monitis->new(
        api_key    => $key,
        secret_key => $secret
    );
    my $response = $api->agents->download(platform => 'linux32');

    if (ref $response) {
        die "Unable to download Agent files: " . $response->{status} . "\n";
    }

    my ($fh, $file) =
      File::Temp::tempfile(TEMPLATE => 'MonitisXXXXX', SUFFIX => '.tar.gz');

    binmode $fh, ':raw';
    print $fh $response;
    close $fh;
    return $file;
}

sub extract_agent {
    my ($file, $monitisdir) = @_;

    die "No such file: '$file'\n" unless -f $file;

    my $ae = Archive::Extract->new(archive => $file);

    unless (-d $monitisdir) {
        make_path $monitisdir
          or die "Failed to create base dir '$monitisdir': $!";
    }

    $ae->extract(to => $monitisdir);
}

sub write_config {
    my %opts = @_;

    my $conf_dir = catdir($opts{base}, 'monitis', 'etc');
    my $log_dir  = catdir($opts{base}, 'monitis', 'logs');

    for ($conf_dir, $log_dir) {
        unless (-d $_) {
            make_path($_)
              or die "Failed to create config dir '$_': $!";
        }
    }

    open my $CFG, ">", $opts{conf}
      or die "Failed to create config file '$opts{conf}': $!";

    print $CFG "MONITISHOME $opts{home}\n";
    print $CFG "LOGFILE "
      . catfile($opts{home}, 'logs', 'monitis.log') . "\n";
    print $CFG "PIDFILE $opts{pidfile}\n";
    print $CFG "USEREMAIL $opts{email}\n";
    print $CFG "AGENTNAME $opts{name}\n";
    close $CFG;
}

sub run_agent {
    my %opts = @_;

    my ($wtr, $rdr);
    my $err = gensym;

    my $home = catdir($opts{base}, 'monitis');

    unless (-f $opts{executable}) {
        die "Monitis executable '$opts{executable}' not found\n";
    }

    unless (-e $opts{executable}) {
        die
          "Monitis executable '$opts{executable}' has no 'executable' flag\n";
    }

    if (my $pid = _monitis_running($opts{pidfile})) {
        die "Monitis agent already running! PID: $pid\n";
    }

    open my $PID, '>', $opts{pidfile}
      or die "Unable to create pid file '$opts{pidfile}': $!";

    close $PID;

    print "Starting Monitis agent:\n";

    my $openpid =
      open3($wtr, $rdr, $err, $opts{executable}, '-C', $opts{conf});

    local $| = 1;

    for (1 .. 10) {
        sleep 1;

        last unless kill 0, $openpid;

        my $pid = do { open my $PID, '<', $opts{pidfile}; <$PID> };

        if (my $pid = _monitis_running($opts{pidfile})) {
            print "\rMonitis agent '$opts{name}' started. PID: $pid\n";
            return $pid;
        }

        print "$_ ";
    }

    die "\rFailed to start Monitis agent:\n"
      . join("", <$err>)
      . join("", <$rdr>)
      . "\nCheck logfile for additional info\n";
}

sub _monitis_running {
    my $pidfile = shift;
    my $PID;
    open $PID, '<', $pidfile or return;

    chomp(my $pid = <$PID>);

    return unless $pid;

    return $pid if kill 0, $pid;

    undef;
}

sub setup_monitors {
    my %opts = @_;

    local $| = 1;
    my $tag = $opts{tag} || 'default_monitor';

    my $api = Monitis->new(
        api_key    => $opts{api},
        secret_key => $opts{secret}
    );

    print "Check if Monitis API found agent '$opts{name}'\n";
    my $agent_id;

    for (1 .. 10) {
        sleep 1;
        my $info = $api->agents->get;
        my ($agent) = grep { $_->{key} eq $opts{name} } @$info;

        if ($agent && $agent->{status} eq 'running') {
            print "\rOK\n";
            $agent_id = $agent->{id};
            last;
        }
        print "$_ ";
        if ($_ >= 10) {
            die "\rAgent '$opts{name}' not found at Monitis API.\n"
              . "Please check agent's log\n";
        }
    }

    print "Add default monitors:\n";

    print "CPU monitor... ";
    my $status = $api->cpu->add(
        agentkey  => $opts{name},
        idleMin   => 0,
        ioWaitMax => 100,
        kernelMax => 100,
        usedMax   => 100,
        name      => $opts{name} . "_CPU_monitor",
        tag       => $tag
    );
    print $status->{status} . "\n";

    print "Memory monitor... ";
    $status = $api->memory->add(
        agentkey      => $opts{name},
        platform      => 'LINUX',
        freeLimit     => 2000,
        freeSwapLimit => 1000,
        bufferedLimit => 1000,
        cachedLimit   => 1000,
        name          => $opts{name} . "_Memory_monitor",
        tag           => $tag,
    );
    print $status->{status} . "\n";

    print "Drive monitor... ";
    $status = $api->drive->add(
        agentkey    => $opts{name},
        driveLetter => 'C',                              #Generic
        freeLimit   => 10,
        name        => $opts{name} . "_Drive_monitor",
        tag         => $tag,
    );
    print $status->{status} . "\n";

    print "Process monitor... ";
    $status = $api->process->add(
        agentkey           => $opts{name},
        processName        => 'monitis',
        cpuLimit           => 15,
        memoryLimit        => 200,
        virtualMemoryLimit => 200,
        name               => $opts{name} . "_Memory_monitor",
        tag                => $tag,
    );
    print $status->{status} . "\n";

    print "Load Average monitor... ";
    $status = $api->load_average->add(
        agentkey => $opts{name},
        limit1   => 90,
        limit5   => 80,
        limit15  => 70,
        name     => $opts{name} . "_Load_Average_monitor",
        tag      => $tag,
    );
    print $status->{status} . "\n";

    print "HTTP monitor... ";
    $status = $api->http->add(
        userAgentId        => $agent_id,
        contentMatchFlag   => 1,
        contentMatchString => 'Monitis',
        httpMethod         => 0,
        postData           => 'q=monitis',
        userAuth           => '',
        passAuth           => '',
        timeout            => 3000,
        redirect           => 1,
        url                => $opts{host},
        name               => $opts{name} . "_HTTP_monitor",
        tag                => $tag,
    );
    print $status->{status} . "\n";

    print "Ping monitor... ";
    my $response = $api->ping->add(
        userAgentId  => $agent_id,
        maxLost      => 2,
        packetsCount => 5,
        packetsSize  => 32,
        timeout      => 20000,
        url          => $opts{host},
        name         => $opts{name} . "_Ping_monitor",
        tag          => $tag,
    );
    print $status->{status} . "\n";
}

sub cleanup {
    my $file = shift;
    return unless $file && -f $file;

    local $| = 1;

    print
      "\nInstallation config file '$file' can contain private information\n"
      . "like yout API key, your email, etc.\n"
      . "Remove it? [Y] ";

    my $answer = <STDIN>;
    chomp $answer;

    if ('yes' =~ /^\Q$answer\E/i) {
        unlink $file or die "\nUnable to remove config file '$file': $!\n";
        print "\nConfig '$file' was successfully removed\n";
    }
}

sub check_deps {

    my @files = (
        "libssl.so",        "libssl.so.0.9.8",
        "libssl.so.0.9.7",  "libssl.so.0.9.7a",
        "libssl.so.0.9.7b", "libssl.so.0.9.7c",
        "libssl.so.0.9.8a", "libssl.so.0.9.8b",
        "libssl.so.0.9.8c", "libssl.so.0.9.8e"
    );

    my $libssl;

  DIR: foreach my $dir ('/usr/lib', '/lib') {
        foreach my $file (@files) {
            if (-f "$dir/$file") {
                $libssl = "$dir/$file";
                last DIR;
            }
        }
    }

    warn <<END unless $libssl;

   ATTENTION

   Looks like libssl is not installed.
   You need to install it.
   Or yo may need to create a symbolic link to your libssl.so:

        ln -s /lib/libssl.so.0.9.7 /usr/lib/libssl.so

   See agents's doc/README for details

END
}

__END__

=head1 NAME

install.pl - install Monitis API Agent on Linux servers

=head1 SYNOPSIS

install.pl [OPTIONS]

    Options:
    --api-key           Your API key
    --secret-key        Your secret key
    --email             Your account name (email)
    --base              Base path where Monitis API agent should be installed
    --name              Agent name
    --help              Display this message
    --config            Path to installation config file

=head1 OPTIONS

=over 4

=item B<--api-key>

Your API key.
You can get it at L<http://monitis.com/> under Tools -> API -> API key

=item B<--api-secret>

Your API secret.
You can get it at L<http://monitis.com/> under Tools -> API -> API key

=back

=head1 DESCRIPTION

This script downloads Monitis API agent from monitis.com and installs it on your server.
After successfull install, script enables default monitors for newly installed agent.

=head1 AUTHOR

Yaroslav Korshak  C<< <ykorshak@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (C) 2006-2011, Monitis Inc.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
