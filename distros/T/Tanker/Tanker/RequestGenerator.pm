package Tanker::RequestGenerator;

use strict;
use warnings;
use Tanker::Request;

sub new  ($$)
{
	# standard stuff for creating a new object
	# I'm not sure if this *should* be an object 
	# but I think it'll probably be useful in the end
	my $proto  = shift;
        my $class  = ref($proto) || $proto;
	
	# yes, we must have a pipeline
	my $pipeline = shift || die "You must pass a pipeline file to $class\n";

	# bless our self into a hash
        my $self  = {};
        bless ($self, $class);

	$self->{pipeline} = $pipeline;

	# and give it on back
        return $self;
}

sub run($)
{
	# do nothing
}

1;
__END__

=head1 NAME

Tanker::RequestGenerator - a module to inject requests down a pipeline

=head1 SYNOPSIS

use Tanker::RequestGenerator;


my $rg = new Tanker::RequestGenerator ($request)
$rg->run()

This is a base class and is suppsoed to be overridden.

=head1 DESCRIPTION

A request generator sits and generates requests which it pumps down 
the pipeline passed to its constructor.



=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 SEE ALSO

L<Tanker::Config>, L<Tanker>, L<Tanker::Plugin>, L<Tanker::ResponseHandler>, L<Tanker::Request>;

=cut
