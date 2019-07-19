package Net::Stomp::StupidLogger;
use strict;
use warnings;
use Carp;

our $VERSION = '0.60';

sub new {
    my ($class,$levels) = @_;
    $levels||={};
    for my $l (qw(warn error fatal)) {
        $levels->{$l}=1 unless defined $levels->{$l};
    }
    return bless $levels,$class;
}

sub _log {
    my ($self,$level,@etc) = @_;
    return unless $self->{$level};
    carp join '',@etc;
}

sub debug { my $self=shift;$self->_log(debug=>@_) }
sub info  { my $self=shift;$self->_log(info =>@_) }
sub warn  { my $self=shift;$self->_log(warn =>@_) }
sub error { my $self=shift;$self->_log(error=>@_) }
sub fatal { my $self=shift;$self->_log(fatal=>@_) }

1;

__END__

=head1 NAME

Net::Stomp::StupidLogger - stub logger

=head1 DESCRIPTION

This class implements a very simple logger-like object, that just
delegates to L<carp|Carp/carp>.

By default, it logs at C<warn> and above.

L<Net::Stomp> used to use this, but now it just uses L<Log::Any>, so
this package is here just in case someone else was using it.

=head1 METHODS

=head2 new

Constructor. You can pass a hashref with the log levels to enable /
disable, like:

  Net::Stomp::StupidLogger->new({debug=>1}); # logs debug, warn,
                                             # error, fatal

  Net::Stomp::StupidLogger->new({warn=>0}); # logs error, fatal

=head2 debug

=head2 info

=head2 warn

=head2 error

=head2 fatal

  $logger->warn('some',$message);

If the corresponding level is enabled, joins the arguments in a single
string (no spaces added) and calls L<carp|Carp/carp>.

=head1 AUTHORS

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
