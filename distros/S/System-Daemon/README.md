# System::Daemon

## NAME

System::Daemon

## DESCRIPTION

Swiss-knife for daemonization

## SYNOPSIS

See liittle example:

    use System::Daemon;

    $0 = 'my_daemon_process_name';

    my $daemon = System::Daemon->new(
    user            =>  'username',
    group           =>  'groupname',
    pidfile         =>  'path/to/pidfile',
    name_pattern    =>  'my_daemon_process_name'
    );
    $daemon->daemonize();

    your_cool_code();

    $daemon->exit(0);

## METHODS

### new(%params)

Constructor, returns System::Daemon object. Available parameters:

 * user            =>   desired username
 * group           =>   desired groupname
 * pidfile         =>   '/path/to/pidfile'
 * name_pattern    =>  name pattern to look if ps output,
 * new             =>  tool for grace restart.

### daemonize
    
Call it to become a daemon.

### exit($exit_code)

An exit wrapper, also, it performing cleanup before exit.

### finish

Performing cleanup. At now cleanup is just pid file removing.

### cleanup

Same as finish.

### process_object

Returns System::Process object of daemon instance.
