package Net::PortTest;

use 5.014002;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::PortTest ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	ok alias run_tests	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	ok alias run_tests	
);

our $VERSION = '0.010001';

use IO::Socket::INET;
use Carp;

my $portmap = {};

sub on {
	my $port = shift;
	my $sub = shift;

	carp 'Not a valid port'
		unless( $port =~ /^\d+$/ and ( $port < 56000 and $port > 0 ) );

	carp 'You must provide a function reference'
		unless( ref( $sub ) eq 'CODE' );

	# Register the handler with the port
	$portmap->{$port} = $sub;
}

sub alias {
	my @vars = reverse @_;

	my $port = shift @vars;
	my @aliases = reverse @vars;

	if( ref \@aliases eq 'ARRAY' ){
		for my $a ( @aliases ){
			if( defined $portmap->{$port} ){
				on $a => $portmap->{$port};
			} else {
				carp "Can't create alias: target port $port not defined\n";
			}
		}
	}
}

sub run_tests {
	my $hostname = shift;
	my @ports = @_;

	my $result_map = {};

	use Time::HiRes qw/ time sleep /;

	for my $port ( @ports ){
		if( defined $portmap->{$port} ){
			my $fnref = $portmap->{$port};

			my $sock = IO::Socket::INET->new(
				PeerAddr => $hostname,
                                PeerPort => $port,
                                Proto    => 'tcp'
			);

			carp 'Could not create socket'
				unless $sock;

			my $start = time;
			my ($rc,$res) = &$fnref( $sock );
			my $end   = time;

			# Return the time deltas, plus whatever is returned
			# by the handler
			$result_map->{$port} = {
				delta => ( $end - $start ),
				res   => $res,
				rc    => $rc,
			};

		} else {
			warn "No handler for port $port defined\n";
		}
	}
	return $result_map;
}

sub import {
	no strict 'refs';
	my ( $package, $file, $line ) = caller;

	for( qw(on alias run_tests)){
		*{$package . "::$_"} = \&$_;
	}
}

1;
__END__

=head1 NAME

Net::PortTest - Perl extension for running banner tests against INET services

=head1 SYNOPSIS

  use Net::PortTest;

  on 143 => sub {
      my $sock = shift;
      my $results = {};
      my $rc = -1;
    
      $results->{banner} = $sock->getline;
    
      $rc = 0
              if $results->{banner} =~ '^\* OK';
    
      return $rc, $results;
  };

  # alias some non standard ports to use the same
  # test function

  alias qw/ 10143 20143 / => 143;

  my $results = run_tests '1.2.3.4' => 143;

  # or, pass in an array of ports
  $results = run_tests '1.2.3.4' => qw/ 143 10143 20143 /;


=head1 DESCRIPTION

This module is used as a framework for quickly and easily defining functions
used to check internet services.  The simplest examples are in the code,
and they show how to execute a naiive IMAP banner check against an IP
address.

=head2 EXPORT

This module will export the following functions into the main namespace:

C<run_tests>, C<on> and C<alias> 

when the module is loaded with:

  use Net::PortTest ':all';

=head1 SEE ALSO

This module makes use of L<Net::Socket::INET> for the communications
with the external services.

Please submit all bugs via L<< https://github.com/petermblair/Perl-CPAN/issues >>

=head1 AUTHOR

Peter Blair, E<lt>cpan@petermblair.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Peter Blair

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
