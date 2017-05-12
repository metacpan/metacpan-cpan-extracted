package MojoX::Log::Dispatch;
use warnings;
use strict;
use base 'Mojo::Log';
use Carp 'croak';
use Log::Dispatch;
use Log::Dispatch::File;
use Log::Dispatch::Screen;

=head1 NAME


MojoX::Log::Dispatch - Log::Dispatch For Mojo

=head1 VERSION

Version 0.06

=cut


our $VERSION = '0.1';


__PACKAGE__->attr(
    'handle' => sub {
        my $self = shift;
		my $dispatcher;
		if ($self->callbacks)
		{
			 $dispatcher = Log::Dispatch->new(callbacks => $self->callbacks);	
		}
		else 
		{
			$dispatcher = Log::Dispatch->new(@_);
		}
		
		if ($self->path)
		{
			 $dispatcher->add(Log::Dispatch::File->new( 'name'      => '_default_log_obj',
					                                    'min_level' => $self->level,
					                                    'filename'  => $self->path,
					                                    'mode'      => 'append' )
              											);                         
			
		}
		else 
		{
			# Create a logging object that will log to STDERR by default
			$dispatcher->add(Log::Dispatch::Screen->new( 	'name'      => '_default_log_obj',
                                           					'min_level' => $self->level,
                                           					'stderr'    => 1 )
    													);            	
		}
		return $dispatcher;
    }
);

__PACKAGE__->attr('callbacks');
__PACKAGE__->attr('remove_default_log_obj' => 1);


sub dispatcher { return shift->handle }

#some methods from Log::Dispatch
sub add { 
	my $self = shift;
	my $l = $self->handle->add(@_);
	#remove default log object that log to STDERR?
	$self->remove('_default_log_obj') if $self->remove_default_log_obj;
	return $l; 
}

sub remove { return shift->handle->remove(@_) }
sub output { return shift->handle->output(@_)}
sub would_log {return shift->handle->would_log(@_)}
sub log_to {return shift->handle->log_to(@_) }
sub level_is_valid { return shift->handle->level_is_valid(@_) }
sub log_and_die {  return shift->handle->log_and_die(@_) }
sub log_and_croak {  return shift->handle->log_and_croak(@_) }


sub log 
{
	my ($self, $level, @msgs) = @_;
    
    # Check log level
    $level = lc $level;
    return $self unless $level && $self->is_level($level);
    
    $self->handle->log('level' => $level,  'message' => @msgs);
    return $self;
}



sub fatal { shift->log('emergency', @_) }
sub emergency { shift->log('emergency', @_) }
sub alert { shift->log('alert', @_) }
sub critical { shift->log('critical', @_) }
sub warning  { shift->log('warning',  @_) }
sub warn  { shift->log('warning',  @_) }
sub notice  { shift->log('notice', @_) }
#short alias syslog style
sub err  { shift->log('error', @_) }
sub crit  { shift->log('critical', @_) }
sub emerg  { shift->log('emergency', @_) }



sub is_level {
    my ($self, $level) = @_;
    return 0 unless $level;
    $level = lc $level;
   	return $self->would_log($level);
}
sub is_fatal { shift->is_level('emergency') }
sub is_emergency { shift->is_level('emergency') }
sub is_alert { shift->is_level('alert') }
sub is_critical { shift->is_level('critical') }
sub is_warning { shift->is_level('warning') }
sub is_warn { shift->is_level('warning') }
sub is_notice { shift->is_level('notice') }
sub is_err { shift->is_level('error') }
sub is_crit { shift->is_level('critical') }
sub is_emerg { shift->is_level('emergency') }

1; # End of MojoX::Log::Dispatch

__END__

=head1 SYNOPSIS

    use MojoX::Log::Dispatch;

    # Create a Log::Dispatch whith logging object that will log to STDERR by default
    # or to file if exists attribute path
    
    my $log = MojoX::Log::Dispatch->new();

    $log->add(Log::Dispatch::File->new(name => 'file1',
                                       min_level => $self->level,
                                       filename => 'logfile' 
                                       ));
                                              
    #Add some exotic loggers
    $log->add(Log::Dispatch::Twitter->new(  username  => "foo",
                                            password  => "bar",
                                            min_level => "critical",
                                            name      => "twitter",
                                           ));
                                              
	#and now as in Mojo::Log

    $log->debug("Why isn't this working?");
    $log->info("FYI: it happened again");
    $log->warn("This might be a problem");
    $log->error("Garden variety error");
    $log->fatal("Boom!");
    $log->emergency("Boom! Boom!");
    $log->alert("Hello!");
    $log->critical("This might be a BIG problem");
    $log->warning("This might be a problem");#=warn
    $log->notice("it happened again");
    
    #OR:
    $log->log('debug' => 'This should work');
    
    
    #In your Mojo App
    # create a custom logger object for Mojo/Mojolicious to use
    # (this is usually done inside the "startup" sub on Mojolicious).
    
    use MojoX::Log::Dispatch;
    use Log::Dispatch::Syslog;
    
    my $dispatch = MojoX::Log::Dispatch->new('path' => '/home/green/tmp/mySupEr.log',
                                             'remove_default_log_obj' => 0);
	
	$dispatch->add(Log::Dispatch::Syslog->new( name      => 'logsys',
                                               min_level => 'debug',
                                               ident     => 'MyMojo::App',
                                               facility  => 'local0' 
                                               ));
	$self->log($dispatch);
	
	#and then
	$self->log->debug("Why isn't this working?");										
    
    

=head1 DESCRIPTION


L<MojoX::Log::Dispatch>  wrapper around Log::Dispatch module. Log::Dispatch manages a set of Log::Dispatch::* objects, allowing you to add and remove output objects as desired.

Include log statements at various levels throughout your code.
Then when you create the new logging object, set the minimum log level you
want to keep track off.
Set it low, to 'debug' for development, then higher in production.

=head1 ATTRIBUTES

=head2 C<handle>

    my $handle = $log->handle;
   
Returns a Log::Dispatch object for logging if called without arguments.
Returns the invocant if called with arguments.


=head2 C<level>

    my $level = $log->level;
    $log      = $log->level('debug');

Returns the minimum logging level if called without arguments.
Returns the invocant if called with arguments.
Valid value are: debug, info, warn, error and fatal.


=head2 C<callbacks>

    $log->callbacks( callbacks( \& or [ \&, \&, ... ] ) );
	See  Log::Dispatch->new for details
	

=head2 C<remove_default_log_obj>

	default 1	
	
    $log->remove_default_log_obj;
	
	If true remove default log objects when C<add> new Log::Dispatch::* object	

=head1 METHODS


=head2 C<new>

Returns a new MojoX::Log::Dispatch object.  This method takes one optional
parameter (for Log::Dispatch->new):


=head2 C<add>

add( Log::Dispatch::* OBJECT )

example:

$log->add(Log::Dispatch::Syslog->new( name      => 'mysyslog1',
                                      min_level => 'info',
                                      facility => 'local0' ));

Adds a new a Log::Dispatch::* object to the dispatcher.  If an object
of the same name already exists, then that object is replaced.  A
warning will be issued if the C<$^W> is true.

NOTE: This method can really take any object that has methods called
'name' and 'log'. 

=head2 C<log>

    Like in C<Mojo::Log> (not as Log::Dispatch)
    
    $log = $log->log(log_level_name => $ or & )
    
    EXAMPLE
    
    $log = $log->log('debug' => 'This should work');
    $log = $log->log('alert' => 'hello');
    
    OR
    
    $log = $log->log('critical' => \&);

Sends the message (at the appropriate level) to all the
Log::Dispatch::* objects that the dispatcher contains (by calling the
C<log_to> method repeatedly).

This method also accepts a subroutine reference as the message
argument. This reference will be called only if there is an output
that will accept a message of the specified level.

=head2 C<log_to>

log_to( name => $, level => $, message => $ )

Sends the message only to the named object.

=head2 C<would_log>

would_log( $string )

Given a log level, returns true or false to indicate whether or not
anything would be logged for that log level.


=head2 C<level_is_valid>

level_is_valid( $string )

Returns true or false to indicate whether or not the given string is a
valid log level.  Can be called as either a class or object method.


=head2 C<remove>

remove('logname')

Removes the object that matches the name given to the remove method.
The return value is the object being removed or undef if no object
matched this.


=head2 C<log_and_die>

log_and_die( level => $, message => $ or \& )
Has the same behavior as calling C<log()> but calls
C<_die_with_message()> at the end.

=head2 C<log_and_croak>

log_and_croak( level => $, message => $ or \& )

This method adjusts the C<$Carp::CarpLevel> scalar so that the croak
comes from the context in which it is called.

=head2 C<_die_with_message>

_die_with_message( message => $, carp_level => $ )

This method is used by C<log_and_die> and will either die() or croak()
depending on the value of C<message>: if it's a reference or it ends
with a new line then a plain die will be used, otherwise it will
croak.

You can throw exception objects by subclassing this method.

If the C<carp_level> parameter is present its value will be added to
the current value of C<$Carp::CarpLevel>.

=head2 C<output>

output( $name )

Returns an output of the given name.  Returns undef or an empty list,
depending on context, if the given output does not exist.

=head2 C<dispatcher>

Returns a Log::Dispatch object

L<MojoX::Log::Dispatch> inherits all methods from L<Mojo::Log> and implements the
following new ones.

=head1 LOG LEVELS

The log levels that Log::Dispatch (and MojoX::Log::Dispatch) uses are taken directly from the
syslog man pages (except that I expanded them to full words).  Valid
levels are:

=over 4

=item debug

=item info

=item notice

=item warning (=warn for Mojo::Log compatibility )

=item error

=item critical

=item alert

=item emergency (=fatal for Mojo::Log compatibility )

=back

The syslog standard of 'err', 'crit', and 'emerg'
is also acceptable.


=head2 C<debug>

    $log = $log->debug('You screwed up, but thats ok');


=head2 C<info>

    $log = $log->info('You are bad, but you prolly know already');
    

=head2 C<notice>

    $log = $log->notice('it happened again');
 
=head2 C<warning>

    $log = $log->warning("This might be a problem");
 
=head2 C<warn>

    $log = $log->warn("This might be a problem");
 

=head2 C<error>

    $log = $log->error('You really screwed up this time');

=head2 C<err>

    $log = $log->err('You really screwed up this time');


=head2 C<critical>

    $log = $log->critical("This might be a BIG problem");
 

=head2 C<crit>

    $log = $log->crit("This might be a BIG problem");
 
=head2 C<alert>

    $log = $log->alert("Hello!");;
 


=head2 C<fatal>

    $log = $log->fatal('Its over...');


=head2 C<emergency>

    $log = $log->emergency("Boom! Boom!");;
 
=head2 C<emerg>

    $log = $log->emerg("Boom! Boom!");;
 

=head1 CHEKING LOG LEVELS 

=head2 C<is_level>

    my $is = $log->is_level('debug');

Returns true if the current logging level is at or above this level. 

=head2 C<is_debug>

    my $is = $log->is_debug;
    
Returns true if the current logging level is at or above this level.     


=head2 C<is_info>

    my $is = $log->is_info;
    
Returns true if the current logging level is at or above this level.     


=head2 C<is_notice>

    my $is = $log->is_notice;
    
Returns true if the current logging level is at or above this level.     


=head2 C<is_warn>

    my $is = $log->is_warn;
    
Returns true if the current logging level is at or above this level.     
    

=head2 C<is_warning>

    my $is = $log->is_warning;

Returns true if the current logging level is at or above this level.    
    

=head2 C<is_error>

    my $is = $log->is_error;
    
Returns true if the current logging level is at or above this level.     


=head2 C<is_err>

    my $is = $log->is_err;

Returns true if the current logging level is at or above this level.    


=head2 C<is_critical>

    my $is = $log->is_critical;

Returns true if the current logging level is at or above this level. 


=head2 C<is_crit>

    my $is = $log->is_crit;

Returns true if the current logging level is at or above this level.    


=head2 C<is_alert>

    my $is = $log->is_alert;

Returns true if the current logging level is at or above this level. 


=head2 C<is_fatal>

    my $is = $log->is_fatal;
    
Returns true if the current logging level is at or above this level.     

=head2 C<is_emergency>

    my $is = $log->is_emergency;

Returns true if the current logging level is at or above this level. 

=head2 C<is_emerg>

    my $is = $log->is_emerg;

Returns true if the current logging level is at or above this level. 


=head1 See Also

Log::Dispatch
Log::Dispatch::ApacheLog,
Log::Dispatch::Email,
Log::Dispatch::Email::MailSend,
Log::Dispatch::Email::MailSender,
Log::Dispatch::Email::MailSendmail,
Log::Dispatch::Email::MIMELite,
Log::Dispatch::File,
Log::Dispatch::File::Locked,
Log::Dispatch::Handle,
Log::Dispatch::Output,
Log::Dispatch::Screen,
Log::Dispatch::Syslog

and more others Log::Dispatch::* modules L<http://search.cpan.org/search?m=dist&q=Log%3A%3ADispatch>


=head2 Other Mojo loggers

MojoX::Log::Log4perl, Mojo::Log 


=head1 AUTHOR

Konstantin Kapitanov, C<< <perlovik at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojox-log-dispatch at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MojoX-Log-Dispatch>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MojoX::Log::Dispatch


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MojoX-Log-Dispatch>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MojoX-Log-Dispatch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MojoX-Log-Dispatch>

=item * Search CPAN

L<http://search.cpan.org/dist/MojoX-Log-Dispatch/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Konstantin Kapitanov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut


