package POE::Component::Log4perl;

use 5.008;
use strict;
use warnings;

use POE;
use Log::Log4perl;
use Log::Log4perl::Level;

# ------------------------------------------------------------------------

our $VERSION = '0.03';
our $level = $INFO;

# ------------------------------------------------------------------------

sub spawn {
    my $class = shift;

    POE::Session->create(
        inline_states => {
            _start => \&start_logger,
            _stop  => \&stop_logger,
            info   => sub { local $level = $INFO;  poe_logger(@_) },
            debug  => sub { local $level = $DEBUG; poe_logger(@_) },
            warn   => sub { local $level = $WARN;  poe_logger(@_) },
            error  => sub { local $level = $ERROR; poe_logger(@_) },
            fatal  => sub { local $level = $FATAL; poe_logger(@_) },
            trace  => sub { local $level = $TRACE; poe_logger(@_) },
            category => sub { 
                my ($heap, $arg0) = @_[HEAP,ARG0];
                $heap->{_category} = $arg0;
            },
        },
        args => [@_ ],
    );

}

sub start_logger {
    my ($kernel, $heap, %args) = @_[KERNEL, HEAP, ARG0 .. $#_];

    Log::Log4perl::init_once($args{ConfigFile});
    $Log::Log4perl::caller_depth = 1;
    *{main::get_logfile} = $args{GetLogfile} if (defined($args{GetLogfile}));

    $heap->{_alias} = $args{Alias} || 'logger';
    $heap->{_category} = $args{Category};

    $kernel->alias_set($args{Alias});
      
}

sub stop_logger {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    $kernel->alias_remove($heap->{_alias});
    delete $heap->{_alias};

}

sub poe_logger {
    my ($heap, $arg0, @args) = @_[HEAP, ARG0, ARG1 .. $#_];

    my $message;
    my $log = Log::Log4perl->get_logger($heap->{_category});

    if (ref($arg0)) {

        $log->log(%$arg0);

    } else {

        $message = join("", $arg0, @args);
        $log->log($level, $message);

    }

}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

POE::Component::Log4perl - Perl extension for the POE Environemt

=head1 SYNOPSIS

  use POE::Component::Log4perl;

  POE::Component::Log4perl->spawn(
     Alias => 'logger',
     Category => 'default',
     ConfigFile => 'logging.conf',
     GetLogfile => \&get_logfile,
  );

=head1 DESCRIPTION

Well, just what everybody needs, another logging module for the POE 
environment. This one will encapsulate the Log4perl modules to do the
logging.

This modules understands the following parameters:

 Alias      - The alias for the session
 Category   - The category to use from the configuration file
 ConfigFile - The name of the configuration file
 GetLogfile - This points to a function to return the logfile name

A word about the "GetLogfile" parameter. In my environment, I use a single 
centralized configuration file to handle the logging environment. This makes 
management a bit easier. Log4perl allows this to happen by using a callback 
to your main routine to retrieve the filename. The GetLogfile allows you to 
name the function to handle that task. The function name should match the 
one in the configuration file. If you don't use this ability then you can 
safely ignore this parameter.

=head1 EVENTS

=over 4

=item info

This event will insert an "INFO" line into your logfile.

=over 4

=item Example

 $poe_kernel->post('logger' => info => 'my cool message');

=back

=item warn

This event will insert a "WARN" line into your logfile.

=item error

This event will insert an "ERROR" line into your logfile.

=item fatal

This event will insert a "FATAL" line into your logfile.

=over 4

=item Example

 $poe_kernel->post('logger' => fatal => 'bad mojo');
 $poe_kernel->yield('shutdown');

=back

=item debug

This event will insert a "DEBUG" line into your logfile.

=back

=head1 SEE ALSO

 Log::Log4perl
 POE::Component::Logger
 POE::Component::SimpleLogger

=head1 AUTHOR

Kevin L. Esteb, E<lt>kesteb@wsipc.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
