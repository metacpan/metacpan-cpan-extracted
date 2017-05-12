package Synapse::Monitor::Listener::Action;
use base qw /Synapse::CLI::Config::Object/;
use Synapse::Logger;
use YAML::XS;
use File::Spec;
use Time::HiRes;
use warnings;
use strict;


sub process {
    my $self  = shift;
    my $event = shift;
    my $tmp   = File::Spec->tmpdir() . '/' . Time::HiRes::time() . '.tmp.yml';
    open TEMP, ">$tmp" or do {
        logger ("cannot write-open $tmp");
        return;
    };
    print TEMP Dump ($event);
    close(TEMP);
    
    my $exec  = $self->label();
    logger ("exec YAML_FILE=$tmp $exec");
    system_execute ("YAML_FILE=$tmp $exec");

    unlink $tmp;
}


sub system_execute {
    my $msg = shift;
    system ($msg);
}


1;


__END__
