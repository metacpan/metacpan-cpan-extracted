package Nagios::Plugin::WWW::Mechanize;
use 5.006;
use warnings;
use strict;
use Nagios::Plugin::Functions qw(:codes %ERRORS %STATUS_TEXT @STATUS_CODES);
use Nagios::Plugin;
use WWW::Mechanize;
use Time::HiRes qw(gettimeofday tv_interval);
use Exporter;
use base qw(Exporter Nagios::Plugin);

our @EXPORT = (@STATUS_CODES);

our $VERSION = "0.13";

=head1 NAME

Nagios::Plugin::WWW::Mechanize - Login to a web page as a user and get data as a Nagios plugin

=head1 SYNOPSIS

  use Nagios::Plugin::WWW::Mechanize;
  $np = Nagios::Plugin::WWW::Mechanize->new( 
    usage => "Checks number of mailing list users"
  );
  $np->getopts;

  $np->get( "http://lists.opsview.org/lists/admin/opsview-users/members" );
  $np->submit_form( form_name => "f", fields => { adminpw => "****" } );
  $content = $np->content;
  ($number_of_users) = ($content =~ /(\d+) members total/);
  $np->nagios_exit( CRITICAL, "Cannot get number of users" ) unless defined $number_of_users;

  $np->add_perfdata(
    label => "users",
    value => $number_of_users,
  );
  $np->nagios_exit(
    OK,
    "Number of mailing list users: $number_of_users"
  );

=head1 DESCRIPTION

This module ties Nagios::Plugin with WWW::Mechanize so that there's less
code in your perl script and the most common work is done for you.

For example, the plugin will automatically call nagios_exit(CRITICAL, ...) if
a page is unavailable or a submit_form fails. The plugin will also keep a track
of the time for responses from the remote web server and output that as
performance data.

=head1 INITIALISE

=over 4

=item Nagios::Plugin::WWW::Mechanize->new( %opts )

Takes %opts. If $opts{mech} is specified and is an object, will check if it is a WWW::Mechanize object and die if not.
If $opts{mech} is a hash ref, will pass those to a WWW::Mechanize->new() call. Will create a WWW::Mechanize object 
with autocheck => 0, otherwise any failures are exited immediately.

Also looks for $opts{include_time}. Defaults to 1 which means that performance data for time will be returned.

All other options are passed to Nagios::Plugin.

=cut

sub new {
	my ($class, %opts) = @_;
	my $include_time = 1;
	my $mech;
	if ($_ = delete $opts{mech}) {
		if (ref $_ eq "HASH") {
			$mech = WWW::Mechanize->new(%$_);
		} elsif ( $_->isa("WWW::Mechanize") ) {
			$mech = $_;
		} else {
			die "Invalid object passed into mech option";
		}
	}
	unless ($mech) {
		$mech = WWW::Mechanize->new( autocheck => 0 );
	}
	if (exists $opts{include_time}) {
		$include_time = delete $opts{include_time};
	}
	my $np = $class->SUPER::new( %opts );
	$np->include_time($include_time);
	$np->mech($mech);
	$np->total_time(0);
	$np;
}

sub include_time {
	my $self = shift;
	if (@_) { $self->{include_time} = shift } else { $self->{include_time} } 
}

sub total_time {
	my $self = shift; if (@_) { $self->{total_time} = shift } else { $self->{total_time} };
}

sub add_to_total_time {
	my $self = shift; $self->total_time( $self->total_time + (shift || 0) );
}

sub timer_start {
	my $self = shift; $self->{timer_start} = [gettimeofday()];
}

sub timer_end {
	my $self = shift; $self->add_to_total_time( tv_interval( $self->{timer_start} ) );
}

=head1 METHODS

=over 4

=item mech

Returns the WWW::Mechanize object

=cut

sub mech {
	my $self = shift;
	if (@_) { $self->{mech} = shift } else { $self->{mech} } 
}

=item get( @args )

Calls $self->mech->get( @args ). If $self->include_time is set, will start a timer before the get, calculate the duration, and adds
it to a total timer.

If the mech->get call failed, will call nagios_exit with a CRITICAL error.

Returns the value from mech->get.

=item submit_form( @args )

Similar to get.

=cut

sub wrap_mech_call {
	my ($self, $method, @args ) = @_;
	$self->timer_start;
	my $res = $self->mech->$method( @args );
	unless ($self->mech->success) {
		$self->nagios_exit( CRITICAL, $self->mech->content );
	}
	$self->timer_end;
	$res;
}

sub submit_form { shift->wrap_mech_call("submit_form", @_); }
sub get { shift->wrap_mech_call("get", @_); }

=item content

Shortcut for $self->mech->content.

=cut

sub content { shift->mech->content }

=item nagios_exit

Override to add performance data for time if required

=cut

sub nagios_exit {
	my ($self, @args) = @_;
	# Only add the performance data if the last mech call was successful
	# IE, only print time if everything was okay
	if ($self->include_time && $self->mech->success) {
		$self->add_perfdata(
			label => "time",
			value => sprintf("%0.3f", $self->total_time),
			uom => "s",
		);
	}
	$self->SUPER::nagios_exit( @args );
}

=head1 AUTHOR

Ton Voon, E<lt>ton.voon@opsera.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2009 Opsera Limited. All rights reserved

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
