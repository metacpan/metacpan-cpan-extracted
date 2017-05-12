package Tanker::Plugin::Log;

use strict;
use warnings;
use Tanker::Request;
use Tanker::Plugin;
use Data::Dumper;
use vars qw(@ISA);

@ISA = qw (Tanker::Plugin);


sub handle ($$)
{
	my ($self, $request) = @_;
	
	sleep (rand(10));
	print STDERR Dumper $request;
	print STDERR "\n\n";

} 




1;
__END__
=head1 NAME

Tanker::Plugin::Log - a logs all request coming down a 

=head1 SYNOPSIS

use Tanker::Plugin::Log;

my $plugin = new Tanker::Plugin::Log ($pipeline);

$plugin->handle($request);


=head1 DESCRIPTION

This is a test plugin that just prints everything it sees
to STDERR using Data::Dumper.


=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 SEE ALSO

L<Tanker>, L<Tanker::Config>, L<Tanker::RequestGenerator>, L<Tanker::ResponseHandler>, L<Tanker::Request>, L<Tanker::Plugin>, L<Data::Dumper>


=cut
