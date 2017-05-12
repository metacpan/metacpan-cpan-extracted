package SOAP::Transport::HTTP::AutoInvoke::Server;
use base qw(Exporter);


BEGIN
{

	use strict;
	use vars qw ( $VERSION @EXPORT @EXPORT_OK );

	$VERSION = '0.25';

	require 5.000;

	@EXPORT = qw ( auto_invoke );

	use Data::Dumper;

}



sub auto_invoke
{
my ($request_class, $headers, $body, $envelopeMaker) = @_;
my (@ARGV, $arg);


	return unless ( exists $body->{_is_soap_autoload} );

        eval "require $request_class";
        return if ($@);

	my $method_name = $body->{soap_typename};

	#
	# Unload Arguments into an array to pass to or method
	#
	$arg = 0;
	while ( $_ = $body->{"ARG$arg"} ) {
	 	if ( /^array::/ ) {
	 		s/^array:://;
	 		$_ = eval ( $_ );
	 	}
	 	push ( @ARGV, $_ );
		delete ( $body->{"ARG$arg"} );
		$arg++;
	}


	#
	# Recycle @ARGV with result of our method call.
	#
	my $rq;
	if ( $body->{_soap_new_method} ) {
		my $new = $body->{_soap_new_method};

		return unless ( $request_class->can ( $new ) );

		if ( $body->{NewARG0} ) {
			my @NewARGV;
			$arg = 0;
			while ( $_ = $body->{"NewARG$arg"} ) {
		 		if ( /^array::/ ) {
		 			s/^array:://;
		 			$_ = eval ( $_ );
		 		}
		 		push ( @NewARGV, $_ );
				delete ( $body->{"ARG$arg"} );
				$arg++;
			}
			$rq = $request_class->$new ( @NewARGV );
		}
		else {
			$rq = $request_class->$new ();
		}
	}
	else {
		$rq = $request_class;
	}
	@ARGV = $rq->$method_name ( @ARGV );

	#
	# Reload Arguments into an array to return to our caller
	#
	$arg = 0;
	foreach (@ARGV) {
		if ( ref ($_) eq "ARRAY" ) {
			$_ = Dumper ( $_ );
			s/^\$VAR = /array::/g;
		}
		$body->{"ARG$arg"} = $_;
		$arg++;
	}

	#
	# For some reason I feel compelled to do this..
	#
	$body->{ARGC} = scalar @ARGV;


	$envelopeMaker->set_body(undef, "$method_name.response", 0, $body);
}



1;

__END__


=head1 NAME

SOAP::Transport::HTTP::AutoInvoke - Automarshall methods for Perl SOAP

=head1 SYNOPSIS

 package Apache::SoapServer;
 use strict;
 use SOAP::Transport::HTTP::Apache;      # must be the provided Apache.pm!
 use SOAP::Transport::HTTP::AutoInvoke;  # import "auto_invoke" dispatcher

 sub handler {
        my $safe_classes   ={
                ClassA     => undef,          # uses default   dispatcher
                ClassB     => undef,          # uses default   dispatcher
                Calculator => \&auto_invoke,  # uses specified dispatcher
                ClassC     => undef,          # uses default   dispatcher
                ClassD     => \&myDispatcher, # uses specified dispatcher
        };
        SOAP::Transport::HTTP::Apache->handler($safe_classes);
 }

 1;


=head1 DESCRIPTION

SOAP::Transport::HTTP::AutoInvoke provides the dispatch subroutine
"auto_invoke" to handle class instantiation and method invocation
that were called with a client created with
SOAP::Transport::ActiveWorks::AutoInvoke::Client.

=head1 DEPENDENCIES

SOAP-0.28
SOAP::AutoInvoke
Data::Dumper

=head1 AUTHOR

Daniel Yacob, L<yacob@rcn.com|mailto:yacob@rcn.com>

=head1 SEE ALSO

S<perl(1). SOAP(3). SOAP::AutoInvoke(3).>
