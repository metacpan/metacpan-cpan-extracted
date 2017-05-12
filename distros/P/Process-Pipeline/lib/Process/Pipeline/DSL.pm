package Process::Pipeline::DSL;
use 5.008001;
use strict;
use warnings;
use Process::Pipeline;

use Exporter qw/ import /;
our @EXPORT = qw/ proc set /;

our $PIPELINE;
our $PROCESS;

sub set {
    die "Cannot call outside proc()\n" unless $PROCESS;
    my ($key, $value) = @_;
    $PROCESS->set($key, $value);
}

sub proc (&;@) {
    my ($code, @process) = @_;
    if (!$PIPELINE) {
        local $PIPELINE = Process::Pipeline->new;
        local $PROCESS  = Process::Pipeline::Process->new;
        $PROCESS->cmd($code->());
        $PIPELINE->_push($PROCESS);
        $PIPELINE->_push($_) for map { @{$_->{process}} } @process;
        return $PIPELINE;
    } else {
        local $PROCESS = Process::Pipeline::Process->new;
        $PROCESS->cmd($code->());
        return $PROCESS;
    }
}

1;
