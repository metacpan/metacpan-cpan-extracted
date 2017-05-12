package Tanker;

use strict;
use warnings;
use vars qw($VERSION);
use Data::Dumper;

$VERSION = 0.021;


sub new  ($$)
{
	# standard stuff for creating a new object
	# I'm not sure if this *should* be an object 
	# but I think it'll probably be useful in the end
	my $proto  = shift;
        my $class  = ref($proto) || $proto;
	
	# yes, we must have a config file
	my $config = shift || die "You must pass a config file to $class\n";

	# bless our self into a hash
        my $self  = {};
        bless ($self, $class);

	# load that with the config
	$self->{config_file} = $config;
	$self->parse_config();

	# and give it on back
        return $self;
}

# read the config file somehow and load all the plugins
# RequestHandlers and ResponseHandlers and stick them global
# thinking about it, this shouldn't be in the module but we'll 
# fix that it a bit
sub parse_config ($)
{
	my $self = shift;

	## todo make this proper
	use Tanker::Plugin::Log;

	my $logger = new Tanker::Plugin::Log ($self);
	$self->add_plugin($logger);

	use Tanker::RequestGenerator::IRC;
	my $irc    = new Tanker::RequestGenerator::IRC ($self);
	$irc->run();

}

sub add_plugin ($$)
{
	my ($self, $plugin) = @_;

	# so that the plugin will be able to get hold 
	# of us if it needs to

	push @{$self->{plugins}}, $plugin;

}


# this gets called by the Request Generator
# it forks and sends off the request
sub inject ($$)
{
	my ($self, $request) = @_;


	# send the request down the pipeline asynchronously
	# this should be handled more defensively
	unless (fork())
	{

		$self->inject_aux($request);
		exit;
	}

}

sub inject_aux ($$)
{
	my ($self, $request) = @_;

	foreach my $plugin (@{$self->{plugins}})
	{
		
		$plugin->handle($request);
	}

} 




1;
__END__
=head1 NAME

Tanker - a module to allow you to construct pipelines

=head1 SYNOPSIS

use Tanker;

my $tanker = new Tanker ($path_to_configfile)

# but you really ought to read the cookbook below


=head1 DESCRIPTION

Tanker allows you to construct asynchronous pipelines such that

        another client
              |
client ----.  |  .----- yet another
           |  |  |   
        .----------.
        | Generate | 
        |  Request |
        '----------'
             |
             | <- pipeline plugin
             | <- pipeline plugin
             | <- pipeline plugin
             | 
        .----------.
        | Generate |
        | Response |
        '----------'
             |
            \'/
             '                                   

and requests can travel down the pipeline asynchronously.

i.e if one requests enters the pipeline and a plugin takes 
a long time to complete then other requests can be passing 
down the pipeline at the same time.

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 SEE ALSO

L<Tanker::Config>, L<Tanker::RequestGenerator>, L<Tanker::Plugin>, L<Tanker::ResponseHandler>, L<Tanker::Request>;

=cut
