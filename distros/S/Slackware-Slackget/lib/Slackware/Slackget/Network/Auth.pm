package Slackware::Slackget::Network::Auth;

use warnings;
use strict;

=head1 NAME

Slackware::Slackget::Network::Auth - The authentification/authorization class for slack-getd network deamons.

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 SYNOPSIS

This class is used by slack-get daemon's to verify the permission of an host.

    use Slackware::Slackget::Network::Auth;

    my $auth = Slackware::Slackget::Network::Auth->new($config);
    if(!$auth->can_connect($client->peerhost()))
    {
    	$client->close ;
    }
    

=cut

sub new
{
	my ($class,$config) = @_ ;
	return undef if(!defined($config) && ref($config) ne 'Slackware::Slackget::Config') ;
	my $self={};
	$self->{CONF} = $config ;
	bless($self,$class);
	
	return $self;
}

=head1 CONSTRUCTOR

=head2 new

The constructor just take one argument: a Slackware::Slackget::Config object :

	my $auth = new Slackware::Slackget::Network::Auth ($config);

=head1 FUNCTIONS

All methods name are the same as configuration file directives, but you need to change '-' to '_'. 

=head2 RETURNED VALUES

All methods return TRUE (1) if directive is set to 'yes', FALSE (0) if set to 'no' and undef if the directive cannot be found in the Slackware::Slackget::Config. For some secure reasons, all directives are in read-only access.
But in the real use the undef value must never been returned, because all method fall back to the <all> section on undefined value. So if a method return undef, this is because the <daemon> -> <connection-policy> -> <all> section is not complete, and that's really a very very bad idea !

=head2 can_connect

Take an host address and return the appropriate value.

	$auth->can_connect($client->peerhost) or die "client is not allow to connect\n";

=cut

sub can_connect {
	my ($self,$host) = @_ ;
	if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}))
	{
		if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-connect'}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-connect'}))
		{
			if($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-connect'}=~ /yes/i)
			{
				return 1;
			}
			else
			{
				return 0;
			}
		}
	}
	if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-connect'}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-connect'}))
	{
		if($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-connect'}=~ /yes/i)
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}
	else
	{
		return undef;
	}
}

=head2 can_build_packages_list

=cut

sub can_build_packages_list {
	my ($self,$host) = @_ ;
	if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}))
	{
		if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-build-packages-list'}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-build-packages-list'}))
		{
			if($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-build-packages-list'}=~ /yes/i)
			{
				return 1;
			}
			else
			{
				return 0;
			}
		}
	}
	if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-build-packages-list'}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-build-packages-list'}))
	{
		if($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-build-packages-list'}=~ /yes/i)
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}
	else
	{
		return undef;
	}
}

=head2 can_build_installed_list

=cut

sub can_build_installed_list {
	my ($self,$host) = @_ ;
	if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}))
	{
		if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-build-installed-list'}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-build-installed-list'}))
		{
			if($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-build-installed-list'}=~ /yes/i)
			{
				return 1;
			}
			else
			{
				return 0;
			}
		}
	}
	if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-build-installed-list'}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-build-installed-list'}))
	{
		if($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-build-installed-list'}=~ /yes/i)
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}
	else
	{
		return undef;
	}
}

=head2 can_install_packages

=cut

sub can_install_packages {
	my ($self,$host) = @_ ;
	if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}))
	{
		if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-install-packages'}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-install-packages'}))
		{
			if($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-install-packages'}=~ /yes/i)
			{
				return 1;
			}
			else
			{
				return 0;
			}
		}
	}
	if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-install-packages'}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-install-packages'}))
	{
		if($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-install-packages'}=~ /yes/i)
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}
	else
	{
		return undef;
	}
}

=head2 can_upgrade_packages

=cut

sub can_upgrade_packages {
	my ($self,$host) = @_ ;
	if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}))
	{
		if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-upgrade-packages'}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-upgrade-packages'}))
		{
			if($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-upgrade-packages'}=~ /yes/i)
			{
				return 1;
			}
			else
			{
				return 0;
			}
		}
	}
	if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-upgrade-packages'}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-upgrade-packages'}))
	{
		if($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-upgrade-packages'}=~ /yes/i)
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}
	else
	{
		return undef;
	}
}

=head2 can_remove_packages

=cut

sub can_remove_packages {
	my ($self,$host) = @_ ;
	if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}))
	{
		if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-remove-packages'}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-remove-packages'}))
		{
			if($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-remove-packages'}=~ /yes/i)
			{
				return 1;
			}
			else
			{
				return 0;
			}
		}
	}
	if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-remove-packages'}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-remove-packages'}))
	{
		if($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-remove-packages'}=~ /yes/i)
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}
	else
	{
		return undef;
	}
}

=head2 can_require_installed_list

=cut

sub can_require_installed_list {
	my ($self,$host) = @_ ;
	if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}))
	{
		if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-require-installed-list'}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-require-installed-list'}))
		{
			if($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-require-installed-list'}=~ /yes/i)
			{
				return 1;
			}
			else
			{
				return 0;
			}
		}
	}
	if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-require-installed-list'}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-require-installed-list'}))
	{
		if($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-require-installed-list'}=~ /yes/i)
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}
	else
	{
		return undef;
	}
}

=head2 can_require_servers_list

=cut

sub can_require_servers_list {
	my ($self,$host) = @_ ;
	if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}))
	{
		if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-require-servers-list'}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-require-servers-list'}))
		{
			if($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-require-servers-list'}=~ /yes/i)
			{
				return 1;
			}
			else
			{
				return 0;
			}
		}
	}
	if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-require-servers-list'}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-require-servers-list'}))
	{
		if($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-require-servers-list'}=~ /yes/i)
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}
	else
	{
		return undef;
	}
}

=head2 can_require_packages_list

=cut

sub can_require_packages_list {
	my ($self,$host) = @_ ;
	if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}))
	{
		if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-require-packages-list'}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-require-packages-list'}))
		{
			if($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-require-packages-list'}=~ /yes/i)
			{
				return 1;
			}
			else
			{
				return 0;
			}
		}
	}
	if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-require-packages-list'}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-require-packages-list'}))
	{
		if($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-require-packages-list'}=~ /yes/i)
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}
	else
	{
		return undef;
	}
}


=head2 can_search

=cut

sub can_search {
	my ($self,$host) = @_ ;
	if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}))
	{
		if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-search'}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-search'}))
		{
			if($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{'can-search'}=~ /yes/i)
			{
				return 1;
			}
			else
			{
				return 0;
			}
		}
	}
	if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-search'}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-search'}))
	{
		if($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{'can-search'}=~ /yes/i)
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}
	else
	{
		return undef;
	}
}

=head2 is_allowed_to

=cut

sub is_allowed_to {
	my ($self,$rule,$host) = @_ ;
	if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}))
	{
		if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{$rule}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{$rule}))
		{
			if($self->{CONF}->{daemon}->{'connection-policy'}->{host}->{"$host"}->{$rule}=~ /yes/i)
			{
				return 1;
			}
			else
			{
				return 0;
			}
		}
	}
	if(exists($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{$rule}) && defined($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{$rule}))
	{
		if($self->{CONF}->{daemon}->{'connection-policy'}->{all}->{$rule}=~ /yes/i)
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}
	else
	{
		return undef;
	}
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

L<http://www.infinityperl.org>

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

1; # End of Slackware::Slackget::Network::Auth
