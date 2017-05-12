package Net::Domain::Info::SEO;

use strict;
use warnings;

use WWW::Google::PageRank;
use WWW::Yandex::TIC;
use WWW::Yahoo::InboundLinks;

use Class::Easy;

our $PROVIDERS = {
	page_rank => {
		pack  => 'WWW::Google::PageRank',
		proto => 1 # require http:// prefix, 
	},
	tic => {
		pack  => 'WWW::Yandex::TIC',
		proto => 0
	},
	inbound_links => {
		pack  =>'WWW::Yahoo::InboundLinks',
		proto => 1
	} 
};

my $class = __PACKAGE__;

sub _init {
	my $class  = shift;
	my $parent = shift;
	
	make_accessor ($parent, 'page_rank', default => \&page_rank);
	make_accessor ($parent, 'tic', default => \&tic);
	make_accessor ($parent, 'inbound_links', default => \&inbound_links);
}

sub provider {
	my $self   = shift;
	my $type   = shift;
	
	return $PROVIDERS->{$type}->{pack}->new (@_);
}

sub entity {
	my $self = shift;
	my $type = shift;
	my $name = shift;
	
	return $PROVIDERS->{$type}->{proto} ? "http://$name" : $name;
}

sub rank {
	my $self   = shift;
	my $type   = shift;
	my $domain = shift;
	
	if ($domain->{$type} and $#{$domain->{$type}} > 0) { # two elements or more
		return $domain->{$type}->[0];
	}
	
	my $provider = $class->provider ($type, @_);
	my $entity   = $class->entity ($type, $domain->name);
	
	my ($rank, $resp) = $provider->get ($entity);
	
	$domain->{$type} = [$rank, $resp];
	
	return $rank;
}

sub page_rank {
	my $self = shift;
	
	my $type = 'page_rank';
	return $class->rank ($type, $self, @_);
}

sub tic {
	my $self = shift;
	return $class->rank ('tic', $self, @_);
}

sub inbound_links {
	my $self = shift;
	return $class->rank ('inbound_links', $self, @_);
}

1;

=head1 NAME

Net::Domain::Info::SEO - Net::Domain::Info plugin for requesting
search engines information for domain

=head1 SYNOPSIS

	use Net::Domain::Info qw(::SEO); # used Whois plugin

	Net::Domain::Info->new ($domain);

	$domain_info->page_rank;
	$domain_info->tic;
	$domain_info->inbound_links;

=head1 METHODS

=head2 page_rank

Google Page Rank.

=cut

=head2 tic

Yandex тИЦ

=cut

=head2 inbound_links

Yahoo inbound links count.

=cut

=head1 AUTHOR

Ivan Baktsheev, C<< <apla at the-singlers.us> >>

=head1 BUGS

Please report any bugs or feature requests to my email address,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Domain-Info>. 
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

=head1 SUPPORT



=head1 ACKNOWLEDGEMENTS



=head1 COPYRIGHT & LICENSE

Copyright 2008 Ivan Baktsheev

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
