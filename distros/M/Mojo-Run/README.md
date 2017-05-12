# Mojo::Run
Mojo::Run - asynchronous external command execution for Mojo

# Installation

```sh
cpan -i Mojo::Run
```

# Getting Started

```sh
use Mojo::Run;
use Mojo::Log;

my $run = Mojo::Run->new;
$run->max_forks(10);
$run->log(Mojo::Log->new(
    level => 'error',
    path  => 'log/mojo_run.log',
));

$run->spawn(
    cmd => sub {
        my $pid   = shift;
        my $param = shift; # {a => 1, b => 2}
        
        my $data = {};
        ... do something
        return $data;
    },
    param => {a => 1, b => 2},
    exec_timeout => 120, # sec
    stdout_cb => sub {
        my ($pid, $chunk) = @_;
    },
    stderr_cb => sub {
        my ($pid, $chunk) = @_;
    },
    exit_cb => sub {
        my $pid = shift;
        my $res = shift;
        warn $res->{result}->[0];
    },
);
$run->spawn(
    cmd => 'ps aux',
    exit_cb => sub {
        my $pid = shift;
        my $res = shift;
    },
);
$run->spawn(
    cmd => ['perl', '-v'],
    exit_cb => sub {
        my $pid = shift;
        my $res = shift;
    },
);

$run->start;
```

# Result
Result in **exit_cb** is a HASH with following keys:

* **cmd**
* **param**
* **exit_status**
* **exit_signal**
* **exit_core**
* **stdout**
* **stderr**
* **result**
* **time_started**
* **time_stopped**
* **time_duration_exec**
* **time_duration_total**

# SOURCE REPOSITORY

L<https://github.com/likhatskiy/Mojo-Run> 

# AUTHOR

Alexey Likhatskiy, <likhatskiy@gmail.com>

# LICENSE AND COPYRIGHT
Copyright (C) 2012-2013 "Alexey Likhatskiy"

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.