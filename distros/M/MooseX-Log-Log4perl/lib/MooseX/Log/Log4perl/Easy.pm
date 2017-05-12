package MooseX::Log::Log4perl::Easy;

use Moo::Role;

with 'MooseX::Log::Log4perl';

our $VERSION = '0.47';

sub log_fatal { local $Log::Log4perl::caller_depth += 1; return shift->logger->fatal(@_); }
sub log_error { local $Log::Log4perl::caller_depth += 1; return shift->logger->error(@_); }
sub log_warn  { local $Log::Log4perl::caller_depth += 1; return shift->logger->warn(@_); }
sub log_info  { local $Log::Log4perl::caller_depth += 1; return shift->logger->info(@_); }
sub log_debug { local $Log::Log4perl::caller_depth += 1; return shift->logger->debug(@_); }
sub log_trace { local $Log::Log4perl::caller_depth += 1; return shift->logger->trace(@_); }

1;

__END__

=head1 NAME

MooseX::Log::Log4perl::Easy - A role for easy usage of logging in your Moose based modules based on L<MooseX::Log::Log4perl>

=head1 SYNOPSIS

 package MyApp;
 use Moose;
 use Log::Log4perl qw(:easy);

 with 'MooseX::Log::Log4perl::Easy';

 BEGIN {
 	 Log::Log4perl->easy_init();
 }

 sub foo {
   my ($self) = @_;
   $self->log_debug("started bar");            ### logs with default class catergory "MyApp"
   $self->log_info('bar');                     ### logs an info message
   $self->log('AlsoPossible')->fatal("croak"); ### log
 }

=head1 DESCRIPTION

The "Easy" logging role based on the L<MooseX::Log::Log4perl> logging role for
Moose directly adds the log methods for all available levels to your class
instance. Hence it is possible to use

  $self->log_info("blabla");

without having to access a separate log attribute as in MooseX::Log::Log4perl;

In case your app grows and you need more of the super-cow powers of Log4perl or
simply don't want the additional methods to clutter up your class you can simply
replace all code C<< $self->log_LEVEL >> with C<< $self->log->LEVEL >>.

You can use the following regex substitution to accomplish that:

  s/log(_(trace|debug|info|warn|error|fatal))/log->$2/g

=head1 ACCESSORS

=head2 logger

See L<MooseX::Log::Log4perl>

=head2 log

See L<MooseX::Log::Log4perl>

=head2 log_fatal ($msg)

Logs a fatal message $msg using the logger attribute. Same as calling

  $self->logger->fatal($msg)

=head2 log_error ($msg)

Logs an error message using the logger attribute. Same as calling

  $self->logger->error($msg)

=head2 log_warn ($msg)

Logs a warn message using the logger attribute. Same as calling

  $self->logger->warn($msg)

=head2 log_info ($msg)

Logs an info message using the logger attribute. Same as calling

  $self->logger->info($msg)

=head2 log_debug ($msg)

Logs a debug message using the logger attribute. Same as calling

  $self->logger->debug($msg)

=head2 log_trace ($msg)

Logs a trace message using the logger attribute. Same as calling

  $self->logger->trace($msg)

=head1 SEE ALSO

L<MooseX::Log::Log4perl>

=head1 AUTHOR

Roland Lammel C<< <lammel@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2016, Roland Lammel L<< <lammel@cpan.org> >>, http://www.quikit.at

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
