package Net::Domain::Info;

use Class::Easy;

use Net::Domain::Info::IDN;
use Encode;

use vars qw($VERSION);
$VERSION = '0.02';

has 'idn';
has 'name';

sub import {
	# this class doesn't export any functions as long as it's
	# completely object oriented, but with help of export list
	# you can configure which plug-ins to use
	# use Net::Domain::Info qw(::Whois); # used Net::Domain::Info::Whois plugin
	
	my $package = shift;
	my @plugins = @_;
	
	foreach my $plugin_tag (@plugins) {
		
		my $plugin = $plugin_tag;
		$plugin = "${package}${plugin_tag}"
			if $plugin_tag =~ /^::/;
		die "can't require package '$plugin'"
			unless try_to_use ($plugin);
		
		warn "plugin '$plugin' must contain '_init' method, skipped"
			unless $plugin->can ('_init');
		
		$plugin->_init ($package);
	}
}

sub new {
	my $class  = shift;
	my $domain = shift;
	
	# if idn prefixed with xn--, then reverse-decode must occur
	
	my $object = {idn => $domain};
	
	if (
		$domain =~ /^$Net::IDN::Encode::IDNA_prefix/
		and $domain =~ /^([0-9a-z]+[0-9a-z\-]+\.)+[0-9a-z]+[0-9a-z\-]+$/i
	) {
		$object->{name} = $domain;
		$object->{idn}  = Net::IDN::Encode::domain_to_unicode ($domain);
	} elsif ($domain !~ /^([0-9a-z]+[0-9a-z\-]+\.)+[0-9a-z]+[0-9a-z\-]+$/i) {
		unless (Encode::is_utf8 ($domain)) {
			$domain = Encode::decode_utf8 ($domain);
		}
		
		$object->{name} = Net::IDN::Encode::domain_to_ascii (
			$domain
		);
		$object->{idn}  = $domain;
	} else {
		$object->{name} = $domain;
		$object->{idn}  = $domain;
	}
	
	bless $object, $class;
}

1;

=head1 NAME

Net::Domain::Info - request for domain information like whois, dns, seo

=head1 SYNOPSIS

If you use just this module, then you receive only IDNA domain support.
The main power of this module is contained in plugins. Usage of plugins is simple:
you need provide their names in the import list.

	use Net::Domain::Info qw(::Whois ::SEO); # used Whois and SEO plugins
	use Encode;

	my $domain_raw = 'нфтвучюкг.com';
	my $domain_idn = Encode::decode_utf8 ($domain_raw);
	my $domain_asc = 'xn--b1acukzhe1a7d.com';

	my $domain_info = Net::Domain::Info->new ($domain_idn);

	ok $domain_info;
	ok $domain_info->name eq $domain_asc;
	ok $domain_info->idn  eq $domain_idn;

=head1 METHODS

=head2 new

Creates domain info object.

=cut

=head2 name

Returns ASCII representation of domain name.

=cut

=head2 idn

Returns IDNA representation of domain name.

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
