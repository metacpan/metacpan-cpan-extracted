use strict;
use warnings;
package MooseX::Role::LogHandler;


BEGIN {
  $MooseX::Role::LogHandler::VERSION = '0.008';
}
# ABSTRACT: Role for those who prefer LogHandler

use MooseX::Role::Parameterized;
use Log::Handler;
use namespace::autoclean;
 
parameter 'logfile' => ( isa => 'Str | Undef');
parameter 'logconf' => ( isa => 'HashRef | Undef');
role {
    my $p = shift;
    has 'logger' => (
          is      => 'rw',
          isa     => 'Log::Handler',
          lazy_build    => 1,
    );
    has 'logfile' => (
        is => 'rw',
        isa => 'Str | Undef',
        default => sub {$p->logfile}
    );
    has 'logconf' => (
        is => 'rw',
        isa => 'HashRef | Undef',
        default => sub {$p->logconf}
    );
  
  sub _build_logger {
      my $self   = shift;      
      my $logger;
      
      if( defined $self->logconf ) { 
        $logger = Log::Handler->new( %{ $self->logconf } );
        return $logger;      
      }
       
      $logger = Log::Handler->new( 
            file => {
              filename => defined($self->logfile) ? $self->logfile : "/tmp/".__PACKAGE__.".log",
              maxlevel => "debug",
              minlevel => "warning",
              message_layout => "%T [%L] [%p] line %l: %m",
            }        
      );
      return $logger;
  };
};
1;
__END__

=head1 NAME

MooseX::Role::LogHandler - A Logging Role for Moose based on Log::Handler

=head1 SYNOPSIS

 package MyApp;
 use Moose;

 # customise log file destination from /tmp/__PACKAGE__.log  
 has logfile => ( isa => 'Str', is => 'ro', default => sub { '/tmp/my.log'} ); 
 # or more full config
 has logconf => ( isa => 'HashRef', is => 'ro', default => sub {{file => {filename => '/tmp/my.log', maxlevel => 'debug'}}});
 
 with 'MooseX::Role::LogHandler';

 sub foo {
   my ($self) = @_;
   $self->logger->debug("started bar");    ### logs with default class catergory "MyApp"

 }

=head1 DESCRIPTION

A logging role building a very lightweight wrapper to L<Log::Handler> for use with your L<Moose> classes.

For compatibility the C<logger> attribute can be accessed to use a common interface for application logging.

=head1 ACCESSORS

=head2 logger

The C<logger> attribute holds the L<Log::Handler> object that implements all logging methods for the
defined log levels, such as C<debug> or C<error>. As this method is defined also in other logging
roles/systems like L<MooseX::Log::LogDispatch> this can be thought of as a common logging interface.

  package MyApp::View::JSON;
  extends 'MyApp::View';
  
  with 'MooseX::Role::LogHandler';

  sub bar {
    $self->logger->debug("Something could be crappy here");	     # logs a debug message
    $self->logger->debug("Something else could be crappy here"); # logs a debug message
  }

=head1 SEE ALSO

L<Log::Handler>, L<Moose>, L<MooseX::Log::Log4perl>, L<MooseX::LogDispatch>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-moosex-loghandler@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

Or come bother us in C<#moose> on C<irc.perl.org>.

=head1 AUTHOR

NJ Walker C<< <njwalker@cpan.org> >>

All (inc. most documentation) based on the work by Roland Lammel C<< <lammel@cpan.org> >> who was in turn inspired by Chris Prather C<< <perigrin@cpan.org> >> and Ash
Berlin C<< <ash@cpan.org> >> on L<MooseX::LogDispatch>

=head1 CONTRIBUTORS

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011-2013, NJ Walker C<< <njwalker@cpan.org> >>, Some rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
