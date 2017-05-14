package Patterns::ChainOfResponsibility::Role::Handler;

use MooseX::Role::Parameterized;

parameter 'handler_method' => (
    isa => 'Str',
    required => 1,
    default => 'handle',
);

parameter 'dispatcher' => (
    isa => 'Str',
    required => 1,
    default => '::Provider',
);

role {
    my $dispatcher = $_[0]->dispatcher;
    if($dispatcher =~m/^::/) {
        $dispatcher = "Patterns::ChainOfResponsibility".$dispatcher;
    }
    Class::MOP::load_class($dispatcher);

    has 'dispatcher' => (
        is => 'bare',
        does => 'Patterns::ChainOfResponsibility::Role::Dispatcher',
        lazy_build => 1,
        handles => ['dispatch'],
    );

    method '_build_dispatcher', sub {
        return $dispatcher->new;
    };

    requires 'handle';

    has 'handlers' => (
        traits => [qw(Array)],
        is => 'rw',
        isa => 'ArrayRef[Object]', 
        handles => {
            all_handlers => 'elements',
            no_handlers => 'is_empty',
        },
        default => sub {+[]},
    );

    sub next_handlers {
        my ($self, @handlers) = @_;
        $self->handlers(\@handlers);
        return $self;
    }

    my $handler_method = $_[0]->handler_method;

    method 'process', sub {
        my ($self, @args) = @_;
        my @return = $self->$handler_method(@args);
        return $self->dispatch($self,\@return,\@args);

    };
}; 

=head1 NAME
 
Patterns::ChainOfResponsibility::Role::Handler - A Link in a Chain of Responsibility

=head1 SYNOPSIS

    package Loader::Filesystem;

    use Moose;
    with 'MyApp::Loader';
    with 'Patterns::ChainOfResponsibility::Role::Handler', {dispatcher => '::Provider'};

    sub handle {
        my ($self, @args) = @_;
        if($something_works) {
            return @returned_info;
        } else {
            return;
        }
    }

    ...

    my $io_handle = Loader::Filesystem
        ->new(%options)
        ->next_handlers(@handlers)
        ->process(@args);

    
=head1 DESCRIPTION

This is a role to be consumed by any class whose instances are links in a chain
of responsibility.  Classes must define a L</handle> method.

=head1 PARAMETERS

This role defines the following parameters

=head2 handler_method

This is the name of the method in the target class which is handling args sent
to L</process>.  By default its 'handle' but you can override as follows:

    with 'Patterns::ChainOfResponsibility::Role::Handler', {
        handler_method => 'execute',
    };

This method should return processed args or nothing in the case of an error.

=head2 dispatcher

This is the dispatcher strategy to be used.  This must be a class that consumes
the role L<Patterns::ChainOfResponsibility::Role::Dispatcher>.  This distribution
includes three dispatchers which should cover the standard uses, but you can
write your own.

=over 4

=item ::Provider

This is probably the most 'classic' dispatcher.  Processes each handler until
one of them returns true.  The first handler to 'handle' the job wins.

    with 'Patterns::ChainOfResponsibility::Role::Handler', {
        dispatcher => '::Provider',
    };


See L<Patterns::ChainOfResponsibility::Provider>

=item ::Filter

Similar to a UNIX commandline pipe.  Each hander gets the return of the previous
until all have been handled (and the final filtered results are returned) or
when one handler returns nothing.

    with 'Patterns::ChainOfResponsibility::Role::Handler', {
        dispatcher => '::Filter',
    };

See L<Patterns::ChainOfResponsibility::Filter>

=item ::Broadcast

Each handler gets the original args.  All handers are processed in order until
the last handler is finished or one handler returns null.  Good for something
like a logger where you have multiply and independent loggers

    with 'Patterns::ChainOfResponsibility::Role::Handler', {
        dispatcher => '::Broadcast',
    };

See L<Patterns::ChainOfResponsibility::Broadcast>

=back

If you write a custom dispatcher, you should include the full namespace name in
the parameter, as in:

    with 'Patterns::ChainOfResponsibility::Role::Handler', {
        dispatcher => 'MyApp::Dispatcher::MyCustomDispatcher',
    };

=head1 METHODS

This role defines the following methods

=head2 process ( @args)
 
The arguments you want one or more handler to process

=head2 next_handlers (@handlers)

Add more handlers to the end of the chain

=head2 handle (@args)

Gets @args sent to L</process>.  Should return either processed arguments or a null
terminated 'return' (see L</SYNOPSIS>.

=head1 AUTHOR

John Napiorkowski C<< <jjnapiork@cpan.org> >> 
 
=head1 LICENSE & COPYRIGHT
 
Copyright 2011, John Napiorkowski C<< <jjnapiork@cpan.org> >>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
 
=cut

1;
