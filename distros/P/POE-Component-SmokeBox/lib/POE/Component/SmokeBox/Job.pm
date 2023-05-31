package POE::Component::SmokeBox::Job;
$POE::Component::SmokeBox::Job::VERSION = '0.58';
#ABSTRACT: Object defining a SmokeBox job.

use strict;
use warnings;
use Params::Check qw(check);
use base qw(Object::Accessor);
use vars qw($VERBOSE);

sub new {
  my $package = shift;

  my $tmpl = {
	idle    => { allow => qr/^\d+$/, default => 600, },
	timeout => { allow => qr/^\d+$/, default => 3600, },
	type    => { defined => 1, default => 'CPANPLUS::YACSmoke', },
	command => { allow => [ qw(check index smoke) ], default => 'check', },
	module  => { defined => 1 },
	no_log	=> { defined => 1, allow => qr/^(?:0|1)$/, default => 0, },
	delay	=> { defined => 1, allow => qr/^\d+$/, default => 0, },
	check_warnings => { defined => 1, allow => qr/^(?:0|1)$/, default => 1, },
  };

  my $args = check( $tmpl, { @_ }, 1 ) or return;
  if ( $args->{command} eq 'smoke' and !$args->{module} ) {
     warn "${package}::new expects 'module' to be set when command is 'smoke'";
     return;
  }
  my $self = bless { }, $package;
  my $accessor_map = {
	idle    => qr/^\d+$/,
	timeout => qr/^\d+$/,
	type    => sub { defined $_[0]; },
	command => [ qw(check index smoke) ],
	module  => sub { defined $_[0]; },
	id	=> sub { defined $_[0]; },
	no_log	=> qr/^(?:0|1)$/,
	delay	=> qr/^\d+$/,
	check_warnings => qr/^(?:0|1)$/,
  };
  $self->mk_accessors( $accessor_map );
  $self->$_( $args->{$_} ) for keys %{ $args };
  return $self;
}

sub dump_data {
  my $self = shift;
  my @returns = qw(idle timeout type command no_log check_warnings);
  push @returns, 'module' if $self->command() eq 'smoke';
  return map { ( $_ => $self->$_ ) } @returns;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::SmokeBox::Job - Object defining a SmokeBox job.

=head1 VERSION

version 0.58

=head1 SYNOPSIS

  use POE::Component::SmokeBox::Job;

  my $job = POE::Component::SmokeBox::Job->new(
	type    => 'CPANPLUS::YACSmoke',
	command => 'smoke',
	module  => 'B/BI/BINGOS/Acme-POE-Acronym-Generator-1.14.tar.gz',
  );

=head1 DESCRIPTION

POE::Component::SmokeBox::Job is a class encapsulating L<POE::Component::SmokeBox> jobs.

=head1 CONSTRUCTOR

=over

=item C<new>

Creates a new POE::Component::SmokeBox::Job object. Takes a number of parameters:

  'idle', number of seconds before jobs are killed for idling, default 600;
  'timeout', number of seconds before jobs are killed for excess runtime, default 3600;
  'type', the type of backend to use, default is 'CPANPLUS::YACSmoke';
  'command', the command to run, 'check', 'index' or 'smoke', default is 'check';
  'module', the distribution to smoke, mandatory if command is 'smoke';
  'no_log', enable to not store the job output log, default is false;
  'delay', the time in seconds to wait between smoker runs, default is 0;
  'check_warnings', enable to check job output for common perl warning strings, default is 1;

=back

=head1 METHODS

Accessor methods are provided via L<Object::Accessor>.

=over

=item C<idle>

Number of seconds before jobs are killed for idling, default 600.

=item C<timeout>

Number of seconds before jobs are killed for excess runtime, default 3600

=item C<type>

The type of backend to use, default is C<'CPANPLUS::YACSmoke'>.

=item C<command>

The command to run, C<'check'>, C<'index'> or C<'smoke'>, default is C<'check'>.

=item C<module>

The distribution to smoke, mandatory if command is C<'smoke'>.

=item C<no_log>

Boolean value determining whether the job will store it's STDERR/STDOUT log, default 0.

=item C<delay>

Number of seconds to pause between smokers for this job. Useful to "throttle" your smokers! The default is 0.

WARNING: This option is ineffective if you have multiplicity set in SmokeBox.

=item C<check_warnings>

Boolean value determining whether SmokeBox will use L<String::Perl::Warnings> to check job output for common perl warnings.

If enabled, SmokeBox will not kill a job prematurely if it prints a lot of warnings to STDERR. It will run the additional check
for the warnings and give the process more time to reach the limit. ( look at L<POE::Component::SmokeBox::Backend> for 'excess_kill' )

=item C<dump_data>

Returns all the data contained in the object as a list.

=back

=head1 SEE ALSO

L<POE::Component::SmokeBox>

L<POE::Component::SmokeBox::JobQueue>

L<Object::Accessor>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
