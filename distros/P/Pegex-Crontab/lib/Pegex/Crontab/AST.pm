package Pegex::Crontab::AST;
use Pegex::Base;
extends 'Pegex::Tree';

use lexicals;

sub cron_hash {
    my ($min, $hour, $dom, $mon, $dow, $cmd) = @{(shift)};
    lexicals;
}

sub env_hash {
    my ($var, $val) = @{(shift)};
    lexicals;
}

sub got_cron_line {
    my ($self, $node) = @_;
    cron_hash($node);
}

sub got_env_line {
    my ($self, $node) = @_;
    env_hash($node);
}

1;
