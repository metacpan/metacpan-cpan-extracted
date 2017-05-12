package OpenPlugin::Log::Log4perl;

# $Id: Log4perl.pm,v 1.15 2003/04/12 03:17:42 andreychek Exp $

use strict;
use OpenPlugin::Log();
use base          qw( OpenPlugin::Log );
use Log::Log4perl 0.25 qw( get_logger );

$OpenPlugin::Log::Log4perl::VERSION = sprintf("%d.%02d", q$Revision: 1.15 $ =~ /(\d+)\.(\d+)/);

sub init {
    my ( $self, $args ) = @_;

    $Log::Log4perl::caller_depth = 1;
    my $params = $self->OP->get_plugin_info( "log" )->{'driver'}{'Log4perl'};

    # Each line from the config needs to start with "log4perl."
    foreach my $string ( keys %{ $params } ) {
        unless( $string =~ m/^log4perl\./ ) {
            $string = "log4perl." . $string;
        }
    }
    Log::Log4perl::init( $params );

    return $self;
}

# Here, we're just trying to mimic Log4perl's interface.  Since Log4perl wasn't
# designed to be subclassed, we need to create all the methods we want to use,
# and pass parameters sent from them to Log4perl's functions

# TODO: Is there a better way to do this?  Is there a way we can have init()
# return a Log::Log4perl object instead of a OpenPlugin::Plugin::Log object?
# Are there any drawbacks with this?

#################
# Logging Methods
sub debug { shift; get_logger((caller(0))[0])->debug( @_ ); }
sub info  { shift; get_logger((caller(0))[0])->info( @_ );  }
sub warn  { shift; get_logger((caller(0))[0])->warn( @_ );  }
sub error { shift; get_logger((caller(0))[0])->error( @_ ); }
sub fatal { shift; get_logger((caller(0))[0])->fatal( @_ ); }

#############################
# Debug level testing methods
sub is_debug { return get_logger((caller(0))[0])->is_debug }
sub is_info  { return get_logger((caller(0))[0])->is_info  }
sub is_warn  { return get_logger((caller(0))[0])->is_warn  }
sub is_error { return get_logger((caller(0))[0])->is_error }
sub is_fatal { return get_logger((caller(0))[0])->is_fatal }

#############################
# Alter logging levels
sub more_logging { shift; return get_logger((caller(0))[0])->more_logging( @_ ) }
sub less_logging { shift; return get_logger((caller(0))[0])->less_logging( @_ ) }
sub inc_level    { shift; return get_logger((caller(0))[0])->inc_level( @_ ) }
sub dec_level    { shift; return get_logger((caller(0))[0])->dec_level( @_ ) }


1;

__END__

=pod

=head1 NAME

OpenPlugin::Log::Log4perl - Log4perl driver for the OpenPlugin::Log plugin

=head1 PARAMETERS

None.

=head1 CONFIG OPTIONS

=over 4

=item * driver

Log4perl

=item * driver options

 <driver Log4perl>
    [Log:::Log4perl options go here, see L<Log::Log4perl>]
 </log4perl>

 Example using a conf style config:
 <driver Log4perl>
    category.OpenPlugin.Application.MyApp          = WARN, myloghandler
    category.OpenPlugin.Application.MyApp.SubClass = DEBUG, myloghandler

    appender.myloghandler              = Log::Dispatch::Screen
    appender.myloghandler.layout       = org.apache.log4j.PatternLayout
    appender.myloghandler.layout.ConversionPattern = %F (%L) %m%n
 </driver>

The above example enables logging at the WARN level and above for MyApp.  But
for MyApp::SubClass, the level is DEBUG, which enables all logging.  Since
MyApp::SubClass does not define a seperate appendar (a logging handler),
MyApp::SubClass uses the handler defined by MyApp -- which prints to STDERR.

=back

Log handlers (appenders), such as Syslog, STDERR, and Files, are defined using
Log::Dispatch:: drivers.

=head1 TO DO

Nothing known.

=head1 BUGS

None known.

=head1 SEE ALSO

L<OpenPlugin>
L<OpenPlugin::Log>
L<Log::Log4perl>

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
