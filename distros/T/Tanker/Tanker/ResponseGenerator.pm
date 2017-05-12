package Tanker::ResponseHandler;

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
	
	# bless our self into a hash
        my $self  = {};
        bless ($self, $class);


	# and give it on back
        return $self;
}

sub handle ($$)
{
	my ($self, $request) = @_;
	
	# do something
} 




1;
__END__
=head1 NAME

Tanker::ResponseHandler - a base class for all Tanker Response Handlers

=head1 SYNOPSIS

use Tanker::ResponseHandler;

my $handler = new Tanker::Handler($pipeline);

$handler->handle($request);

this class isn't designed to be used directly but subclassed
and the handle method overridden

=head1 DESCRIPTION

When a Request has travelled down a pipeline it will be passed to
each ResponseHandler one after another and then they can deal with it
however they want.


=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 SEE ALSO

L<Tanker>, L<Tanker::Config>, L<Tanker::RequestGenerator>, L<Tanker::Plugin>, L<Tanker::Request>;

=cut
