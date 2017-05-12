package Tanker::Request;

use strict;
use warnings;


sub new  ($$)
{
	# standard stuff for creating a new object
	# I'm not sure if this *should* be an object 
	# but I think it'll probably be useful in the end
	my $proto  = shift;
        my $class  = ref($proto) || $proto;
	
	# yes, we must have a variable hash
	my $self = shift || warn "No variable hash was passed to this Request\n";

	# bless our self into a hash
        bless ($self, $class);

	# and give it on back
        return $self;
}

sub get_data ($)
{
	my ($self) = @_;

	return $self->{data};
}



1;
__END__
=head1 NAME

Tanker::Request - a blessed hash full of variables

=head1 SYNOPSIS

use Tanker::Request;

my $request = new Tanker::Request (%vars);
print $request->get_data();


=head1 DESCRIPTION

This class gets instantiated by a Tanker::RequestGenerator and 
passed to a pipeline where it is handed off to the handle method 
of all the plugins in the pipeline and then, finally, handed to a 
Tanker::ResponseHandler;

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 SEE ALSO

L<Tanker>, L<Tanker::Config>, L<Tanker::RequestGenerator>, L<Tanker::ResponseHandler>, L<Tanker::Plugin>;

=cut
