package Slackware::Slackget;

use warnings;
use strict;

require Slackware::Slackget::Base ;
require Slackware::Slackget::Network::Auth ;
require Slackware::Slackget::Config ;
require Slackware::Slackget::PkgTools ;
use Slackware::Slackget::File;

=head1 NAME

Slackware::Slackget - Main library for slack-get package manager 1.X

=head1 VERSION

Version 0.17

=cut

our $VERSION = '0.17';

=head1 SYNOPSIS

slack-get (http://slackget.infinityperl.org and now http://www.infinityperl.org/category/slack-get) is an apt-get like tool for Slackware Linux. This bundle is the core library of this program.

The name Slackware::Slackget means slack-get 1.0 because this module is complely new and is for the 1.0 release. It is entierely object oriented, and require some other modules (like XML::Simple, Net::Ftp and LWP::Simple).

This module is still beta development version and I release it on CPAN only for coder which want to see the new architecture. For more informations, have a look on subclasses.

    use Slackware::Slackget;

    my $sgo = Slackware::Slackget->new(
    	-config => '/etc/slack-get/config.xml',
	-name => 'slack-getd',
	-version => '1.0.1228'
    );

=cut

=head1 CONSTRUCTOR

The constructor ( new() ), is used to instanciate all needed class for a slack-get instance.

=head2 new

You have to pass the followings arguments to the constructor :

	-config => the name of the configuration file.
	-name => ignored : for backward compatibility
	-version => ignored : for backward compatibility

-name and -version arguments are passed to the constructor of the Slackware::Slackget::Log object.

=cut

sub new {
	my $class = 'Slackware::Slackget' ;
	my $self = {} ;
	if(scalar(@_)%2 != 0)
	{
		$class = shift(@_) ;
	}
	my %args = @_ ;
	die "FATAL: You must pass a configuration file as -config parameter.\n" if(!defined($args{'-config'}) || ! -e $args{'-config'}) ;
	$self->{'config'} = new Slackware::Slackget::Config ( $args{'-config'} )  or die "FATAL: error during configuration file parsing\n$!\n" ;
	$self->{'base'} = new Slackware::Slackget::Base ( $self->{'config'} );
	$self->{'pkgtools'} = new Slackware::Slackget::PkgTools ( $self->{'config'} );
	$self->{'auth'} = Slackware::Slackget::Network::Auth->new( $self->{'config'} );
	$self->{'slackware_version'}=undef;
	bless($self,$class) ;
	return $self;
}

=head2 slackware_version

Return the host's Slackware version as written in the /etc/slackware-version file.

	if ( $sgo->slackware_version >= 12.0.0 ){
		print "Slackware distribution is ok, let's continue.\n";
	}

=cut

sub slackware_version {
	my $self = shift;
	unless( defined($self->{'slackware_version'}) ){
		my $file = Slackware::Slackget::File->new('/etc/slackware-version');
		my $line = $file->get_line(0);
		chomp $line;
		if( $line =~ /^Slackware\s*([\d\.]+)$/ ){
			$self->{'slackware_version'}=$1;
		}
	}
	return $self->{'slackware_version'};
}

=head1 FUNCTIONS

=head2 load_plugins

Search for all plugins in the followings directories : <all @INC directories>/lib/Slackware/Slackget/Plugin/, <INSTALLDIR>/lib/Slackware/Slackget/Plugin/, <HOME DIRECTORY>/lib/Slackware/Slackget/Plugin/.

When you call this method, she scan in thoses directory and try to load all files ending by .pm. The loading is in 4 times :

1) scan for plug-in

2) try to "require" all the finded modules.

3) Try to instanciate all modules successfully "require"-ed. To do that, this method call the new() method of the plug-in and passed the current Slackware::Slackget object reference. The internal code is like that :

	# Slackware::Slackget::Plugin::MyPlugin is the name of the plug-in
	# $self is the reference to the current Slackware::Slackget object.
	
	my $plugin = Slackware::Slackget::Plugin::MyPlugin->new( $self ) ;

The plug-in can internally store this reference, and by the way acces to the instance of this objects : Slackware::Slackget, Slackware::Slackget::Base, Slackware::Slackget::Config, Slackware::Slackget::Network::Auth and Slackware::Slackget::PkgTools.

IN ALL CASE, PLUG-INS ARE NOT ALLOWED TO MODIFY THE Slackware::Slackget OBJECT !

For performance consideration we don't want to clone all accesible objects, so all plug-in developper will have to respect this rule : you never modify object accessible from this object ! At the very least if you have a good idea send me an e-mail to discuss it.

4) dispatch plug-ins' instance by supported HOOK.

Parameters :

1) An ARRAY reference on supported Hooks.

2) the type of plug-in you want to load.

Ex:

	$sgo->load_plugins( ['HOOK_COMMAND_LINE_OPTIONS','HOOK_COMMAND_LINE_HELP','HOOK_START_DAEMON','HOOK_RESTART_DAEMON','HOOK_STOP_DAEMON'], 'daemon');

=cut

sub load_plugins {
	my $self = shift;
	my $HOOKS = shift;
	my $plugin_type = shift; # TODO: impl�enter la s��tion des types de plug-in
	my $extra_ref = shift;
# 	print "[SG10] needed type : $plugin_type\n";
	#NOTE : searching for install plug-in
	$self->log()->Log(2,"searching for plug-in\n") ;
	my %tmp_pg;
	foreach my $dir (@INC)
	{
		if( -e "$dir/Slackware/Slackget/Plugin" && -d "$dir/Slackware/Slackget/Plugin")
		{
			foreach my $name (`ls -1 $dir/Slackware/Slackget/Plugin/*.pm`)
			{
				chomp $name ;
				$name =~ s/.+\/([^\/]+)\.pm$/$1/;
				$self->log()->Log(2,"found plug-in: $name\n") ;
 				print "[SG10] found plug-in: $name in $dir/Slackware/Slackget/Plugin/\n" ;
# 				push @plugins_name, $name;
				$tmp_pg{$name} = 1;
			}
		}
	}
	#NOTE : loading plug-in
	$self->log()->Log(2,"loading plug-in\n") ;
	my @loaded_plugins;
# 	foreach my $plg (@plugins_name)
	foreach my $plg (keys(%tmp_pg))
	{
		my $ret = eval qq{require Slackware::Slackget::Plugin::$plg} ;
		unless($ret)
		{
			if($@)
			{
				warn "Fatal Error while parsing plugin $plg : $@\n";
				$self->log()->Log(1,"Fatal Error while parsing plugin $plg (this is a programming error) : $@\n") ;
			}
			elsif($!)
			{
				warn "Fatal Error while loading plugin $plg : $!\n";
				$self->log()->Log(1,"Fatal Error while parsing plugin $plg : $!\n") ;
			}
		}
		else
		{
			my $package = "Slackware::Slackget::Plugin::$plg";
# 			print "[SG10] \$package:$package\n";
			my $type = '$'.$package.'::PLUGIN_TYPE';
# 			print "[SG10] \$type:$type\n";
			my $pg_type = eval qq{ $type };
			if(defined($pg_type) && ($pg_type eq $plugin_type or $pg_type eq 'ALL'))
			{
				print "[SG10] loaded success for plug-in $plg\n" ;
				$self->log()->Log(3,"loaded success for plug-in $plg\n") ;
				push @loaded_plugins, $plg;
				$self->{'plugin'}->{'types'}->{$ret} = $pg_type ;
			}
		}
	}
	#NOTE : creating new instances
	$self->log()->Log(2,"creating new plug-in instance\n") ;
	my @plugins;
	foreach my $plugin (@loaded_plugins)
	{
		my $package = "Slackware::Slackget::Plugin::$plugin";
		my $ret;
		if($plugin_type=~ /gui/i)
		{
			# TODO: tester le code de chargement d'un plug-in graphique, la ligne suivante n'a pas encore ��test�
			print "[DEBUG Slackware::Slackget.pm::load_plugins()] loading package \"$package\" call is \"use $package; $package( $extra_ref ) ;\" }\"\n";
			$ret = eval "use $package; $package( $extra_ref ) ;" ;
		}
		else
		{
			$ret = eval{ $package->new($self) ; } ;
		}
		
		if($@ or !$ret)
		{
			$self->{'plugin'}->{'types'}->{$ret} = undef;
			delete $self->{'plugin'}->{'types'}->{$ret} ;
			warn "Fatal Error while creating new instance of plugin $package: $@\n";
			$self->log()->Log(1,"Fatal Error while creating new instance of plugin $package: $@\n") ;
		}
		else
		{
			
# 			print "[SG10] $plugin instanciates\n" ;
			$self->log()->Log(3,"$plugin instanciates\n") ;
# 			if($plugin_type=~ /gui/i)
# 			{
# 				$ret->show();
# 			}
			print "[DEBUG Slackware::Slackget.pm::load_plugins()] print pushing reference \"$ret\" on the plugin stack\n";
			push @plugins, $ret;
		}
	}
	%tmp_pg = ();
	@loaded_plugins = ();
	$self->register_plugins(\@plugins,$HOOKS);
}

=head2 register_plugins

Register all plug-ins by supported calls.

Take a plug-in array reference and a hooks array reference in arguments.

	$sgo->register_plugins(\@plugins, \@HOOKS) ;

Please read the code of the load_plugins() method to see how to set the object internal state.

=cut

sub register_plugins
{
	my ($self,$plugins,$HOOKS) = @_ ;
	$self->{'plugin'}->{'raw_table'} = $plugins ;
	$self->{'plugin'}->{'sorted'} = {} ;
	# NOTE: dispatching plug-ins by hooks.
	$self->log()->Log(2,"dispatching plug-in by supported HOOKS\n") ;
	foreach my $hook (@{ $HOOKS })
	{
		my $hk = lc($hook) ;
# 		print "[DEBUG Slackware::Slackget.pm::register_plugins()] examining if plug-in support hook $hk\n";
		$self->{'plugin'}->{'sorted'}->{$hook} = [] ;
		foreach my $plugin (@{ $plugins })
		{
			if($self->{'plugin'}->{'types'}->{$plugin}=~ /gui/i)
			{
				
				eval{ $plugin->$hk('test') ;};
				if($@)
				{
					print "[SG10] plug-in $plugin do not support hook $hook\n" ;
#  					warn "$@\n";
				}
				else
				{
					print "[SG10] registered plug-in $plugin for hook $hook\n" ;
					$self->log()->Log(3,"registered plug-in $plugin for hook $hook\n") ;
					push @{ $self->{'plugin'}->{'sorted'}->{$hook} },$plugin ;
				}
			}
			else
			{
				if($plugin->can($hk))
				{
					print "[SG10] registered plug-in $plugin for hook $hook\n" ;
					$self->log()->Log(3,"registered plug-in $plugin for hook $hook\n") ;
					push @{ $self->{'plugin'}->{'sorted'}->{$hook} },$plugin ;
				}
			}
		}
	}
}

=head2 call_plugins

Main method for calling back differents plug-in. This method is quite easy to use : just call it with a hook name in parameter.

call_plugins() will iterate on all plug-ins wich implements the given HOOK.

	$sgo->call_plugins( 'HOOK_START_DAEMON' ) ;

Additionaly you can pass all arguments you need to pass to the callback which take care of the HOOK. All extra arguments are passed to the callback.

Since all plug-ins have access to many objects which allow them to perform all needed operations (like logging etc), they have to care about output and user information.

So all call will be eval-ed and juste a little log message will be done on error.

=cut

sub call_plugins
{
	my $self = shift;
	my $HOOK = shift ;
	my @returned;
	foreach my $pg ( @{ $self->{'plugin'}->{'sorted'}->{$HOOK} })
	{
		my $callback = lc($HOOK);
		push @returned, eval{ $pg->$callback(@_) ;} ;
		if($@)
		{
			$self->{'log'}->Log(1,"An error occured while attempting to call plug-in ".ref($pg)." for hook $HOOK. The error occured in method $callback. The evaluation return the following error : $@\n");
		}
	}
	return @returned ;
}

=head1 ACCESSORS

=head2 base

Return the Slackware::Slackget::Base object of the current instance of the Slackware::Slackget object.

	$sgo->base()->compil_package_directory('/var/log/packages/');

=cut

sub base
{
	my $self = shift;
	return $self->{'base'} ;
}

=head2 pkgtools

Return the Slackware::Slackget::PkgTools object of the current instance of the Slackware::Slackget object.

	$sgo->pkgtools()->install( $package_list ) ;

=cut

sub pkgtools
{
	my $self = shift;
	return $self->{'pkgtools'} ;
}

=head2 removepkg(<some package>)

Alias for :

	$sgo->pkgtools()->remove(<some package>);

=cut

sub removepkg {
	my ($self,@params) = @_;
	return $self->{'pkgtools'}->remove(@params) ;
}

=head2 installpkg(<some package>)

Alias for :

	$sgo->pkgtools()->install(<some package>);

=cut

sub installpkg {
	my ($self,@params) = @_;
	return $self->{'pkgtools'}->install(@params) ;
}

=head2 upgradepkg(<some package>)

Alias for :

	$sgo->pkgtools()->upgrade(<some package>);

=cut

sub upgradepkg {
	my ($self,@params) = @_;
	print "Slackware::slackget::upgradepkg: pass \@params to pkgtools->upgrade(@params).\n";
	return $self->{'pkgtools'}->upgrade(@params) ;
}

=head2 config

Return the Slackware::Slackget::Config object of the current instance of the Slackware::Slackget object.

	print $sgo->config()->{common}->{'file-encoding'} ;

=cut

sub config
{
	my $self = shift;
	my $cfg_name = shift;
	if($cfg_name)
	{
		return undef if(!defined($cfg_name) || ! -e $cfg_name) ;
		$self->{'config'} = new Slackware::Slackget::Config ( $cfg_name )  or die "FATAL: error during configuration file parsing\n$!\n" ;
		return 1;
	}
	else
	{
		return $self->{'config'} ;
	}
}

=head2 get_config_token

A wrapper method to get a configuration key. This method call the Slackware::Slackget::Config->get_token() method.

SO YOU HAVE TO COMPLY WITH THIS SYNTAX !

	print "Official media is: ",$sgo->get_config_token('/daemon/official-media'),"\n";

=cut

sub get_config_token {
	my ($self, $query) = @_;
	return $self->{'config'}->get_token($query);
}

=head2 set_config_token

A wrapper method to set a configuration key. This method call the Slackware::Slackget::Config->set_token() method.

SO YOU HAVE TO COMPLY WITH THIS SYNTAX !

	$sgo->set_config_token('/daemon/official-media','slackware-12.0');

=cut

sub set_config_token {
	my ($self, $query,$value) = @_;
	return $self->{'config'}->set_token($query,$value);
}

=head2 auth

Return the Slackware::Slackget::Network::Auth object of the current instance of the Slackware::Slackget object.

	$sgo->auth()->can_connect($client) or die "Client not allowed to connect here\n";

=cut

sub auth
{
	my $self = shift;
	return $self->{'auth'} ;
}

=head1 AUTHOR

DUPUIS Arnaud, C<< <a.dupuis@infinityperl.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-Slackware-Slackget@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Slackware-Slackget>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Slackware::Slackget


You can also look for information at:

=over 4

=item * Infinity Perl website

L<http://www.infinityperl.org/category/slack-get>

=item * slack-get specific website

L<http://slackget.infinityperl.org>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Slackware-Slackget>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Slackware-Slackget>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Slackware-Slackget>

=item * Search CPAN

L<http://search.cpan.org/dist/Slackware-Slackget>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Bertrand Dupuis (yes my brother) for his contribution to the documentation.

=head1 COPYRIGHT & LICENSE

Copyright 2005 DUPUIS Arnaud, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Slackware::Slackget
