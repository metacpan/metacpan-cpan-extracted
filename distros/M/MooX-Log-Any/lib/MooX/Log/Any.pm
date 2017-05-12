# ABSTRACT: Role to add Log::Any
package MooX::Log::Any;
our $VERSION = '0.004004'; #VERSION 
use Moo::Role;
use Log::Any;
local $| = 1;
has 'log' => (
    is      => 'ro',
    lazy    => 1,
    default => sub { Log::Any->get_logger(category=>ref shift); },
);
sub logger {
	my $self=shift;
	my $category=shift; 
	if (defined $category)
	{
		return Log::Any->get_logger(category=>$category);
	}
	return $self->log;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooX::Log::Any - Role to add Log::Any

=head1 VERSION

version 0.004004

=head1 DESCRIPTION

A logging role building a very lightweight wrapper to L<Log::Any> for use with your L<Moo> or L<Moose> classes.
Connecting a Log::Any::Adapter should be performed prior to logging the first log message, otherwise nothing will happen, just like with Log::Any

Using the logger within a class is as simple as consuming a role:

    package MyClass;
    use Moo;
    with 'MooX::Log::Any';
    
    sub dummy {
        my $self = shift;
        $self->log->info("Dummy log entry");
    }

The logger needs to be setup before using the logger, which could happen in the main application:

    package main;
    use Log::Any::Adapter;
    # Send all logs to Log::Log4perl
    Log::Any::Adapter->set('Log4perl')
    
    use MyClass;
    my $myclass = MyClass->new();
    $myclass->log->info("In my class"); # Access the log of the object
    $myclass->dummy;                    # Will log "Dummy log entry"

=head1 SYNOPSIS;

    package MyApp;
    use Moo;
    
    with 'MooX::Log::Any';
    
    sub something {
        my ($self) = @_;
        $self->log->debug("started bar");    ### logs with default class catergory "MyApp"
        $self->log->error("started bar");    ### logs with default class catergory "MyApp"
    }

=head1 ACCESSORS

=head2 log

The C<log> attribute holds the L<Log::Any::Adapter> object that implements all logging methods for the
defined log levels, such as C<debug> or C<error>. As this method is defined also in other logging
roles/systems like L<MooseX::Log::LogDispatch> this can be thought of as a common logging interface.

  package MyApp::View::JSON;

  extends 'MyApp::View';
  with 'MooseX:Log::Log4perl';

  sub bar {
    $self->logger->info("Everything fine so far");    # logs a info message
    $self->logger->debug("Something is fishy here");  # logs a debug message
  }

=head2 logger([$category])

This is an alias for log.

=head1 SEE ALSO

L<Log::Any>, L<Moose>, L<Moo>

=head2 Inspired by

Inspired by the work by Chris Prather C<< <perigrin@cpan.org> >> and Ash
Berlin C<< <ash@cpan.org> >> on L<MooseX::LogDispatch> and Roland Lammel C<< <lammel@cpan.org> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests through github 
L<https://github.com/cazador481/MooX-Log-Any>.

=head1 CONTRIBUTORS

In alphabetical order:

Jens Rehsack C<< rehsack@gmail.com> >>

=over 2

=back 
;

=head1 AUTHOR

Edward Ash <eddie+cpan@ashfamily.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Edward Ash.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
