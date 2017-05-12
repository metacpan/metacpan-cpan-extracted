package MooseX::Types::Log::Dispatch;

use MooseX::Types -declare => [ 'LogLevel', 'Logger' ];

use MooseX::Types::Moose qw/Str HashRef ArrayRef/;
use Log::Dispatch;

our $VERSION = '0.002000';

subtype LogLevel,
  as Str,
  where { Log::Dispatch->level_is_valid( $_ ) },
  message { "'$_' is not a valid Log::Dispatch log level." };

class_type Logger, { class => 'Log::Dispatch' };

coerce Logger,
  from HashRef,
  via { Log::Dispatch->new( %$_ ) };

coerce Logger,
  from ArrayRef,
  via { Log::Dispatch->new( outputs => $_ ) };

1;

__END__;

=head1 NAME

MooseX::Types::Log::Dispatch - L<Log::Dispatch> related constraints and coercions for
Moose

=head1 SYNOPSIS

    package MyFoo;
    use MooseX::Types::Log::Dispatch qw(Logger LogLevel);

    has logger => (
        isa => Logger,
        is => 'ro',
        coerce => 1,
    );

    has event_log_level => (
        isa => LogLevel,
        is => 'ro',
    );

    sub some_event_happened {
      my ($self, $event) = @_;
      $self->logger->log( level => $self->event_log_level, message => "$event happened");
    }

    my $obj1 = MyFoos->new(
      event_log_level => 'debug',
      logger => [ ['Screen', min_level => 'notice' ] ]
    );

    ## or

    my $obj2 = MyFoos->new(
      event_log_level => 'warning',
      logger => { outputs => [ ['Screen', min_level => 'debug' ] ] }
    );

    $obj1->some_event_happened('zoom'); #nothing prints
    $obj2->some_event_happened('zoom'); # 'zoom happened' prints

=head1 DESCRIPTION

This module provides Moose TypeConstraints that are believed to be useful when
working with Log::Dispatch;

=head1 AVAILABLE CONSTRAINTS

=head2 Logger

Class type for 'Log::Dispatch' optional coercion will turn dereference a
hash reference and pass it to 'new' or treat an array reference as a list
of C<outputs>.

=head2 LogLevel

A subtype of 'Str', this should be a string that is a valid L<Log::Dispatch>
log level like: 0, 1, 2 ,3 ,4 ,5 ,6 ,7, info, debug, notice, warn, warning,
err, error, crit, critical, alert, emerg, and emergency

=head1 AUTHOR

Guillermo Roditi (groditi) E<lt>groditi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 Guillermo Roditi. This program is free software; you can 
redistribute it and/or modify it under the same terms as Perl itself.

=cut

