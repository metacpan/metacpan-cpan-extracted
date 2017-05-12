package Net::SolarWinds::LogMethods;

use strict;
use warnings;

=pod

=head1 NAME

Net::SolarWinds::LogMethods - Passive logging interfcaes

=head1 SYNOPSIS

  package MyClass;
  
  use base qw(Net::SolarWinds::ConstructorHash  Net::SolarWinds::LogMethods);
  
  1;
  
  my $pkg=new MyClass(key=>'value');

=head1 DESCRIPTION

This library provides a common logging interfcaes that expect Net::SolarWinds::Log or something that implements its features. It also assumes object instance is a hash with $self->{log} contains the logging object.


=head1 OO Methods provided

=over 4

=item * my $log=$self->get_log;

Returns the logging object if any

=cut

sub get_log { $_[0]->{log} }

=item * $self->set_log(Net::SolarWinds::Log->new);

Sets the Chater::Log object, you can also set this in the constructor at object creation time.

=cut

sub set_log { $_[0]->{log} = $_[1] }

=item * $self->log_error("Some error");

This is a lazy man's wrapper function for 

  my $log=$self->get_log;
  $log->log_error("Some error") if $log; 

=cut

sub log_error {
    my ( $self, @args ) = @_;

    my $log = $self->get_log;

    return 0 unless $log;

    return 1 unless $log->get_loglevel >= $log->LOG_ERROR;

    my @list = ('ERROR');
    push @list, $self->log_header if $self->can('log_header');

    return $log->write_to_log( @list, @args );
}

=item * $log->log_die("Log this and die");

Logs the given message then dies.

=cut 

sub log_die {
    my ( $self, @args ) = @_;

    my $log = $self->get_log;
    my @list = ('DIE');
    push @list, $self->log_header if $self->can('log_header');

    my $string=$self->format_log(@list,@args);

    return die $string  unless $log;

    return 1 unless $log->get_loglevel >= $log->LOG_ALWAYS;


    $log->write_to_log( @list, @args );
    die $string;

}

sub format_log {
  my ($self,@args)=@_;

  return join(' ',@args)."\n" unless $self->get_log;
  return $self->get_log->format_log(@args);

}

=item * $self->log_always("Some msg");

This is a lazy man's wrapper function for 

  my $log=$self->get_log;
  $log->log_always("Some msg") if $log; 

=cut

sub log_always {
    my ( $self, @args ) = @_;

    my $log = $self->get_log;

    return 0 unless $log;

    return 1 unless $log->get_loglevel >= $log->LOG_ALWAYS;

    my @list = ('ALWAYS');
    push @list, $self->log_header if $self->can('log_header');

    return $log->write_to_log( @list, @args );
}

=item * my $string=$self->log_header;

This is a stub function that allows a quick addin for logging, the string returned will be inserted after the log_level in the log file if this function is created.

=cut

=item * $self->log_warn("Some msg");

This is a lazy man's wrapper function for: 

  my $log=$self->get_log;
  $log->log_warn("Some msg") if $log; 

=cut

sub log_warn {
    my ( $self, @args ) = @_;

    my $log = $self->get_log;

    return 0 unless $log;

    return 1 unless $log->get_loglevel >= $log->LOG_WARN;
    my @list = ('WARN');
    push @list, $self->log_header if $self->can('log_header');

    return $log->write_to_log( @list, @args );
}

=item * $self->log_info("Some msg");

This is a lazy man's wrapper function for: 

  my $log=$self->get_log;
  $log->log_info("Some msg") if $log; 

=cut

sub log_info {
    my ( $self, @args ) = @_;

    my $log = $self->get_log;

    return 0 unless $log;

    return 1 unless $log->get_loglevel >= $log->LOG_INFO;
    my @list = ('INFO');
    push @list, $self->log_header if $self->can('log_header');

    return $log->write_to_log( @list, @args );
}

=item * $self->log_debug("Some msg");

This is a lazy man's wrapper function for: 

  my $log=$self->get_log;
  $log->log_debug("Some msg") if $log; 

=cut

sub log_debug {
    my ( $self, @args ) = @_;

    my $log = $self->get_log;

    return 0 unless $log;

    return 1 unless $log->get_loglevel >= $log->LOG_DEBUG;

    my @list = ('DEBUG');
    push @list, $self->log_header if $self->can('log_header');

    return $log->write_to_log( @list, @args );
}

=back

=head1 AUTHOR

Michael Shipper

=cut

1;
