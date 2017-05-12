package RHP::Timer;

use strict;
use warnings;

=head1 NAME

 RHP::Timer - A high resolution timer abstraction

=head1 SYNOPSIS

 use RHP::Timer ();
 use My::Logger ();

 $logger = My::Logger->new;
 $timer  = RHP::Timer->new();

 # timing data from the point of the caller
 $timer->start('fizzbin');
 fizzbin(); # how fast is fizzbin?
 $logger->info(
     sprintf("Timing caller: %s %s %d, timer_name: %s, time: %s",
     @{$timer->checkpoint}));

 # or simpler
 $timer->start('foobin');
 foobin();
 $logger->info("pid $$ timer " . $timer->current . 
     " took " . $timer->stop . " seconds");

 # what was the last timing block?
 $logger->info("Last timing block " . $timer->current . 
     " took " . $timer->last_interval . " seconds");

=head1 DESCRIPTION

RHP::Timer is a wrapper around Time::HiRes.  I wrote it because I 
needed some simple abstractions for timing programs to 
determine bottlenecks in running programs.

The goals of RHP::Timer is to be easy to use, accurate, and simple.

=cut

use Time::HiRes ();

our $VERSION = 0.1;

=head1 METHODS

=over 4

=item new()

 $timer = RHP::Timer->new();

Constructor which takes no arguments and returns a timer object

=cut

sub new {
    my ($class) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
}

=item start()

 $timer->start('fizzbin');

Starts the timer for 'fizzbin'

=cut

sub start {
    my ($self, $name) = @_;
    $self->{$name}->{_start} = [Time::HiRes::gettimeofday];
    $self->{_current} = $name;
    return 1;
}

=item stop()

 $interval = $timer->stop;

Stops the last timer started, and returns the number of seconds between
start and stop.

=cut

sub stop {
    my ($self) = @_;
    no strict 'refs';
    $self->{$self->{_current}}->{_stop} = [Time::HiRes::gettimeofday];
    $self->{$self->{_current}}->{interval} =
      Time::HiRes::tv_interval($self->{$self->{_current}}->{_start},
                               $self->{$self->{_current}}->{_stop});
    return $self->{$self->{_current}}->{interval};
}

=item current()

 $timer_name = $timer->current();
 # $timer_name is 'fizzbin' from previous pod

Returns the name of the most recent timer started.

=cut

sub current {
    my $self = shift;
    return $self->{_current};
}

=item checkpoint()

 [ caller(), $timer_name, $interval ] = $timer->checkpoint();

Stops the current timer and returns an array reference containing caller()
information, the name of the timer stopped, and the interval of the last
timing run.  Useful for passing to a logfile in sprintf or other format.

=cut

sub checkpoint {
    my $self = shift;
    my $stop = $self->stop;
    my @summary = ( caller, $self->current, $self->stop);
    return \@summary;
}

=item last_interval()

 $last_interval = $timer->last_interval;

Returns the last timing interval recorded by the timer object.

=cut

sub last_interval {
    my $self = shift;
    return $self->{$self->{_current}}->{interval};
}

=pod

=back

=cut

1;

__END__

=head1 BUGS

None known yet.  If you find any, or want a feature, email the author.

=head1 SEE ALSO

Time::HiRes(3)

=head1 AUTHOR

Fred Moyer <fred@redhotpenguin.com>

=head1 COPYRIGHT

Copyright 2007 Red Hot Penguin Consulting LLC

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
