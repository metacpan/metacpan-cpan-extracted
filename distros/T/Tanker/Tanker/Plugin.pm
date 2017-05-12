package Tanker::Plugin;

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
	my $pipeline = shift || warn "No pipeline was passed to this plugin : $class\n";
	

	# bless our self into a hash
        my $self  = {};
        bless ($self, $class);

	# load that with the config
	$self->{pipeline} = $pipeline;

	# and give it on back
        return $self;
}

sub handle ($$)
{
	my ($self, $request) = @_;

} 




1;
__END__
=head1 NAME

Tanker::Plugin - a base class for all Tanker plugins

=head1 SYNOPSIS

use Tanker::Plugin;

my $plugin = new Tanker::Plugin ($pipeline);

$plugin->handle($request);

this class isn't designed to be used directly but subclassed
and the handle method overridden

=head1 DESCRIPTION

If a plugin is placed in a Tanker pipeline then (almost) every 
request that comes down the pipeline will be passed to it via the
handle method.

It's then free to munge it as it wants.

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 SEE ALSO

L<Tanker>, L<Tanker::Config>, L<Tanker::RequestGenerator>, L<Tanker::ResponseHandler>, L<Tanker::Request>;

=cut
