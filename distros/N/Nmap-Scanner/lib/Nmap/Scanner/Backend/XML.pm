package Nmap::Scanner::Backend::XML;

use strict;

use vars qw(@ISA);
@ISA = qw(Nmap::Scanner::Backend::Processor);

use XML::SAX::ParserFactory; 

use Nmap::Scanner;
use Nmap::Scanner::Backend::Results;
use Nmap::Scanner::Backend::Processor;

sub new {
    my $class = shift;
    my $you = $class->SUPER::new();
    return bless $you, $class;
}

#  Process results from "-oX -"

sub process {
    
    my $self = shift;
    my $pid = shift;
    my $read = shift;
    my $cmdline = shift;
    my $error = shift;

    #  Suppress warnings about reading unopened handle
    $^W = 0;
    my $err = join('', (<$error>));
    $^W = 1;

    if ($err ne '') {

        close($read);
        close($error);

        warn <<EOF;
<nmap-error>
  <pid="$pid"/>
  <cmdline="$cmdline"/>
  <nmap-err>$err</nmap-msg>
</nmap-error>
EOF
        exit 1;
    }

    my $handler = NmapHandler->new($self);
    my $parser = XML::SAX::ParserFactory->parser(Handler => $handler);

    eval { $parser->parse_file($read) }; 


    if (defined($@) && ($@ ne '')) {

        my $msg = join('', <$read>);

        Nmap::Scanner::debug("bytes in input stream: " .  tell($read));
        Nmap::Scanner::debug("bytes in error stream: " .  tell($error));

        warn <<EOF;
<nmap-error>
  <pid="$pid"/>
  <cmdline="$cmdline"/>
  <perl-msg>$@</perl-msg>
  <nmap-msg>$msg</nmap-msg>
  <nmap-err>$err</nmap-msg>
</nmap-error>
EOF
        close($read);
        exit 1;

    }

    close($read);

    return $handler->results();

}

1;

#
#  SAX listener to process XML output from nmap.
#

package NmapHandler;

    use strict;
    use base qw(XML::SAX::Base);

    use XML::SAX::Base;

    use Nmap::Scanner::Host;
    use Nmap::Scanner::Hostname;
    use Nmap::Scanner::Port;
    use Nmap::Scanner::Service;
    use Nmap::Scanner::Address;
    use Nmap::Scanner::Hosts;
    use Nmap::Scanner::ExtraPorts;
    use Nmap::Scanner::RunStats;
    use Nmap::Scanner::RunStats::Finished;
    use Nmap::Scanner::NmapRun;
    use Nmap::Scanner::ScanInfo;
    use Nmap::Scanner::Task;
    use Nmap::Scanner::TaskProgress;
    use Nmap::Scanner::Distance;
    use Nmap::Scanner::Backend::Results;

    use Nmap::Scanner::OS;
    use Nmap::Scanner::OS::PortUsed;
    use Nmap::Scanner::OS::Uptime;
    use Nmap::Scanner::OS::Class;
    use Nmap::Scanner::OS::Match;
    use Nmap::Scanner::OS::TCPSequence;
    use Nmap::Scanner::OS::TCPTSSequence;
    use Nmap::Scanner::OS::IPIdSequence;
    use Nmap::Scanner::OS::Fingerprint;

    #  One function per element .. fun! ;)

    my %HANDLERS = (
        host          => \&host,
        hosts         => \&hosts,
        status        => \&hoststatus,
        hostname      => \&hostname,
        smurf         => \&smurf,
        address       => \&hostaddress,
        hostnames     => \&hostnames,
        port          => \&port,
        ports         => \&ports,
        state         => \&state,
        service       => \&service,
        owner         => \&owner,
        addport       => \&addport,
        extraports    => \&extraports,
        os            => \&os,
        portused      => \&portused,
        osclass       => \&osclass,
        osfingerprint => \&osfingerprint,
        osmatch       => \&osmatch,
        uptime        => \&uptime,
        tcpsequence   => \&tcpsequence,
        tcptssequence => \&tcptssequence,
        ipidsequence  => \&ipidsequence,
        nmaprun       => \&nmaprun,
        scaninfo      => \&scaninfo,
        taskbegin     => \&taskbegin,
        taskend       => \&taskend,
        taskprogress  => \&taskprogress,
        verbose       => \&verbose,
        debugging     => \&debugging,
        runstats      => \&runstats, 
        finished      => \&finished,
        distance      => \&distance,
    );

    sub new {
        my $class = shift;
        my $backend = shift;
        my $self = $class->SUPER::new();
        $self->{NMAP_BACKEND} = $backend;
        $self->{NMAP_PORT} = undef;
        $self->{NMAP_HOST} = undef;
        $self->{NMAP_RUNSTATS} = undef;
        $self->{NMAP_NMAPRUN} = undef;
        $self->{PORT_COUNT} = 0;
        $self->{NMAP_OSGUESS} = undef;
        $self->{NMAP_RESULTS} = Nmap::Scanner::Backend::Results->new();
        $self->{NMAP_TASK} = undef;
        $self->{NMAP_TASK_PROGRESS} = undef;
        return bless $self, $class;
    }

    #  Controller for start element handlers

    sub start_element {
       my ($self, $el) = @_;
       my $name  = $el->{Name};

       if (exists $HANDLERS{$name}) {
           Nmap::Scanner::debug("About to handle $name");
           &{$HANDLERS{$name}}($self, $el->{Attributes});
           Nmap::Scanner::debug("Handled $name");
       } else {

            my %attrs = %{$el->{Attributes}};

            return unless Nmap::Scanner::debug("Received unhandled XML: $name");

            for my $key (keys %attrs) {
                Nmap::Scanner::debug("Unhandled[$name]: $key = $attrs{$key}");
            }
       }
    }

    #  Controller for end element handlers

    sub end_element {

        my ($self, $el) = @_;

        if ($el->{Name} eq 'host') {
            my $host = $self->{NMAP_HOST};
            $self->{NMAP_HOST}->os($self->{NMAP_OSGUESS})
                if $self->{NMAP_OSGUESS};
            $self->{NMAP_RESULTS}->add_host($host);
            $self->{NMAP_BACKEND}->notify_scan_complete($self->{NMAP_HOST});
            undef $self->{NMAP_OSGUESS};
        } elsif ($el->{Name} eq 'hosts') {
            $self->{NMAP_NMAPRUN}->run_stats($self->{NMAP_RUNSTATS});
        } elsif ($el->{Name} eq 'port') {
            my $port = $self->{NMAP_PORT};
            Nmap::Scanner::debug("Adding port: " . $port->portid());
            $self->{NMAP_HOST}->add_port($port);
            $self->{PORT_COUNT}++;
            $self->{NMAP_BACKEND}->notify_port_found(
                $self->{NMAP_HOST}, $self->{NMAP_PORT}
            );
            undef $self->{NMAP_PORT};
        } elsif ($el->{Name} eq 'ports') {
            unless ($self->{PORT_COUNT} > 0) {
                $self->{NMAP_BACKEND}->notify_no_ports_open(
                    $self->{NMAP_HOST}, $self->{NMAP_HOST}->extra_ports()
                );
            }
            $self->{PORT_COUNT} = 0;
        } elsif ($el->{Name} eq 'hostnames') {
             $self->{NMAP_BACKEND}->notify_scan_started($self->{NMAP_HOST});
        } elsif ($el->{Name} eq 'taskbegin') {
            $self->{NMAP_BACKEND}->notify_task_started($self->{NMAP_TASK});
        } elsif ($el->{Name} eq 'taskend') {
            $self->{NMAP_BACKEND}->notify_task_ended($self->{NMAP_TASK});
        } elsif ($el->{Name} eq 'taskprogress') {
            $self->{NMAP_BACKEND}->notify_task_progress(
                $self->{NMAP_TASK_PROGRESS});
        } elsif ($el->{Name} eq 'nmaprun') {
            $self->{NMAP_RESULTS}->nmap_run($self->{NMAP_NMAPRUN});
        }
    }

    sub host {
        my ($self, $ref) = @_;
        $self->{NMAP_HOST} = Nmap::Scanner::Host->new();
    }

    sub hoststatus {
        my ($self, $ref) = @_;
        my $state = $ref->{'{}state'}->{Value};
        $self->{NMAP_HOST}->status($state);
    }

    sub hostname {
        my ($self, $ref) = @_;
        my $host = $self->{NMAP_HOST};
        my $hostname = Nmap::Scanner::Hostname->new();
        $hostname->name($ref->{'{}name'}->{Value});
        $hostname->type($ref->{'{}type'}->{Value});
        $host->add_hostname($hostname);
    }

    sub hostnames {
        my $self = shift;
        #  Do nothing, as this is just an array of hostnames, held in Host object.
    }

    sub ports {
        my $self = shift;
        #  Do nothing, as this is just an array of ports, held in Host object.
    }

    sub smurf {
        my ($self, $ref) = @_;
        my $smurf = $ref->{'{}responses'}->{Value};
        $self->{NMAP_HOST}->smurf($smurf);
    }                                    

    sub hostaddress {
        my ($self, $ref) = @_;
        my $addr = Nmap::Scanner::Address->new();
        $addr->addr($ref->{'{}addr'}->{Value});
        $addr->addrtype($ref->{'{}addrtype'}->{Value});
        $addr->vendor($ref->{'{}vendor'}->{Value}) 
            if $ref->{'{}vendor'}->{Value};
        $self->{NMAP_HOST}->add_address($addr);
    }

    sub port {
        my ($self, $ref) = @_;
        my $port = Nmap::Scanner::Port->new();
        $port->protocol($ref->{'{}protocol'}->{Value});
        $port->portid($ref->{'{}portid'}->{Value});
        $self->{NMAP_PORT} = $port;
    }

    sub state {
        my ($self, $ref) = @_;
        $self->{NMAP_PORT}->state($ref->{'{}state'}->{Value});
    }

    sub owner {
        my ($self, $ref) = @_;
        my $owner = $ref->{'{}name'}->{Value};
        $self->{NMAP_PORT}->owner($owner);
    }

    sub service {

        my ($self, $ref) = @_;
        my $port = $self->{NMAP_PORT};
        my $svc = Nmap::Scanner::Service->new();
        $svc->name($ref->{'{}name'}->{Value});
        $svc->proto($ref->{'{}proto'}->{Value});
        $svc->rpcnum($ref->{'{}rpcnum'}->{Value});
        $svc->lowver($ref->{'{}lowver'}->{Value});
        $svc->highver($ref->{'{}highver'}->{Value});
        $svc->method($ref->{'{}method'}->{Value});
        $svc->conf($ref->{'{}conf'}->{Value});
        $svc->tunnel($ref->{'{}tunnel'}->{Value});
        $svc->product($ref->{'{}product'}->{Value});
        $svc->version($ref->{'{}version'}->{Value});
        $svc->extrainfo($ref->{'{}extrainfo'}->{Value});
        $port->service($svc);
    }

    sub addport {
        my ($self, $ref) = @_;

        my $port = Nmap::Scanner::Port->new();
        $port->state($ref->{'{}state'}->{Value});
        $port->protocol($ref->{'{}protocol'}->{Value});
        $port->portid($ref->{'{}portid'}->{Value});
        $port->owner($ref->{'{}owner'}->{Value})
            if $ref->{'{}owner'};
        $self->{NMAP_BACKEND}->notify_port_found(
            $self->{NMAP_HOST}, $port
        );
    }

    sub extraports {
        my ($self, $ref) = @_;
        my $extras = Nmap::Scanner::ExtraPorts->new();
        $extras->state($ref->{'{}state'}->{Value});
        $extras->count($ref->{'{}count'}->{Value});
        $self->{NMAP_HOST}->extra_ports($extras);
    }

    sub os {
        my ($self, $ref) = @_;
        $self->{NMAP_OSGUESS} = Nmap::Scanner::OS->new();
    }

    sub osclass {
        my ($self, $ref) = @_;
        my $os = $self->{NMAP_OSGUESS};
        my $class = Nmap::Scanner::OS::Class->new();
        $class->type($ref->{'{}type'}->{Value});
        $class->vendor($ref->{'{}vendor'}->{Value});
        $class->osfamily($ref->{'{}osfamily'}->{Value});
        $class->osgen($ref->{'{}osgen'}->{Value});
        $class->accuracy($ref->{'{}accuracy'}->{Value});
        $os->add_os_class($class);
    }

    sub osfingerprint {
        my ($self, $ref) = @_;
        my $os = $self->{NMAP_OSGUESS};
        my $fingerprint = Nmap::Scanner::OS::Fingerprint->new();
        $fingerprint->fingerprint($ref->{'{}fingerprint'}->{Value});
        $os->osfingerprint($fingerprint);
    }
    
    sub osmatch {
        my ($self, $ref) = @_;
        my $os = $self->{NMAP_OSGUESS};
        my $match = Nmap::Scanner::OS::Match->new();
        $match->name($ref->{'{}name'}->{Value});
        $match->accuracy($ref->{'{}accuracy'}->{Value});
        $os->add_os_match($match);
    }

    sub portused {
        my ($self, $ref) = @_;
        my $os = $self->{NMAP_OSGUESS};
        my $port = Nmap::Scanner::OS::PortUsed->new();
        $port->state($ref->{'{}state'}->{Value});
        $port->proto($ref->{'{}proto'}->{Value});
        $port->portid($ref->{'{}portid'}->{Value});
        $os->add_port_used($port);
    }

    sub uptime {
        my ($self, $ref) = @_;
        my $os = $self->{NMAP_OSGUESS};
        my $u = Nmap::Scanner::OS::Uptime->new();
        $u->seconds($ref->{'{}seconds'}->{Value});
        $u->lastboot($ref->{'{}lastboot'}->{Value});
        $os->uptime($u);
    }

    sub tcpsequence {
        my ($self, $ref) = @_;
        my $os = $self->{NMAP_OSGUESS};
        my $t = Nmap::Scanner::OS::TCPSequence->new();
        $t->index($ref->{'{}index'}->{Value});
        $t->class($ref->{'{}class'}->{Value});
        $t->difficulty($ref->{'{}difficulty'}->{Value});
        $t->values($ref->{'{}values'}->{Value});
        $os->tcpsequence($t);
    }

    sub tcptssequence {
        my ($self, $ref) = @_;
        my $os = $self->{NMAP_OSGUESS};
        my $t = Nmap::Scanner::OS::TCPTSSequence->new();
        $t->class($ref->{'{}class'}->{Value});
        $t->values($ref->{'{}values'}->{Value});
        $os->tcptssequence($t);
    }

    sub ipidsequence {
        my ($self, $ref) = @_;
        my $os = $self->{NMAP_OSGUESS};
        my $t = Nmap::Scanner::OS::IPIdSequence->new();
        $t->class($ref->{'{}class'}->{Value});
        $t->values($ref->{'{}values'}->{Value});
        $os->ipidsequence($t);
    }

    sub nmaprun {
        my ($self, $ref) = @_;
        my $run = Nmap::Scanner::NmapRun->new();
        $run->scanner($ref->{'{}scanner'}->{Value});
        $run->args($ref->{'{}args'}->{Value});
        $run->start($ref->{'{}start'}->{Value});
        $run->startstr($ref->{'{}startstr'}->{Value});
        $run->version($ref->{'{}version'}->{Value});
        $run->xmloutputversion($ref->{'{}xmloutputversion'}->{Value});
        $self->{NMAP_NMAPRUN} = $run;
    }

    sub scaninfo {
        my ($self, $ref) = @_;
        my $info = Nmap::Scanner::ScanInfo->new();
        $info->type($ref->{'{}type'}->{Value});
        $info->protocol($ref->{'{}protocol'}->{Value});
        $info->numservices($ref->{'{}numservices'}->{Value});
        $info->services($ref->{'{}services'}->{Value});
        $self->{NMAP_NMAPRUN}->add_scan_info($info);
    }

    sub taskbegin {
        my ($self, $ref) = @_;
        my $name = $ref->{'{}task'}->{'Value'};
        my $time = $ref->{'{}time'}->{'Value'};
        my $task = Nmap::Scanner::Task->new();
        $task->name($name);
        $task->begin_time($time);
        $self->{NMAP_TASK} = $task;
    }

    sub taskprogress {

        my ($self, $ref) = @_;

        my $time = $ref->{'{}time'}->{'Value'};
        my $percent = $ref->{'{}percent'}->{'Value'};
        my $remaining = $ref->{'{}remaining'}->{'Value'};
        my $etc = $ref->{'{}etc'}->{'Value'};
        my $tp = Nmap::Scanner::TaskProgress->new();

        $tp->task($self->{NMAP_TASK});
        $tp->time($time);
        $tp->percent($percent);
        $tp->remaining($remaining);
        $tp->etc($etc);

        $self->{NMAP_TASK_PROGRESS} = $tp;

    }

    sub taskend {

        my ($self, $ref) = @_;
        my $name = $ref->{'{}task'}->{'Value'};
        my $time = $ref->{'{}time'}->{'Value'};
        my $task = $self->{NMAP_TASK};

        $task->end_time($time);

        $self->{NMAP_NMAPRUN}->add_task($task);

    }

    sub distance {
        my ($self, $ref) = @_;
        my $distance = Nmap::Scanner::Distance->new();
        my $value = $ref->{'{}value'}->{Value};
        $distance->value($value);
        $self->{NMAP_HOST}->distance($distance);
    }

    sub verbose {
        my ($self, $ref) = @_;
        $self->{NMAP_NMAPRUN}->verbose($ref->{'{}level'}->{Value});
    }

    sub debugging {
        my ($self, $ref) = @_;
        $self->{NMAP_NMAPRUN}->debugging($ref->{'{}level'}->{Value});
    }

    sub runstats {
        my ($self, $ref) = @_;
        my $stats = Nmap::Scanner::RunStats->new();
        $self->{NMAP_RUNSTATS} = $stats;
    }

    sub hosts {
        my ($self, $ref) = @_;
        my $hosts = Nmap::Scanner::Hosts->new();
        $hosts->up($ref->{'{}up'}->{Value});
        $hosts->down($ref->{'{}down'}->{Value});
        $hosts->total($ref->{'{}total'}->{Value});
        $self->{NMAP_RUNSTATS}->hosts($hosts);
    }

    sub finished {
        my ($self, $ref) = @_;
        my $f = Nmap::Scanner::RunStats::Finished->new();
        $f->time($ref->{'{}time'}->{Value});
        $f->timestr($ref->{'{}timestr'}->{Value});
        $self->{NMAP_RUNSTATS}->finished($f);
    }

    sub results {
        my $self = shift;
        return $self->{NMAP_RESULTS};
    }

1;

