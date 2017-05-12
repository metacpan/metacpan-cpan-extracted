package Net::DNS_A;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::DNS_A ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Net::DNS_A', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::DNS_A - First attempt at asynchronous dns resoloving with gettaddrinfo_a

=head1 SYNOPSIS

  use Net::DNS_A;

  Net::DNS_A::lookup("google.com");
  sleep(1);

  my @output = Net::DNS_A::retrieve();
  print("output[0]: $output[0]\n");
  print("output[1]: $output[1]\n");

=head1 DESCRIPTION

L<Net::DNS_A> is a first attempt at asynchronous dns resolving with gettaddrinfo_a.

=head2 EXPORT

None by default.

=head1 AUTHOR

Brian Medley, E<lt>bpmedley@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Brian Medley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
