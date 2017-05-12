package Snapforce::API;

use 5.018002;
use strict;
use warnings;
use Carp;
use XML::Parser;
use HTTP::Request::Common qw/GET POST/;
use LWP::UserAgent;

require Exporter;

our $VERSION = '0.02';
our $SNAPURL = 'https://crm2.snapforce.com/sf_receive_request.inc.php';

sub new {
	my ($class, $authuser, $authkey) = @_;
	croak "Authentication user and/or key are missing" unless $authkey;
	my $self = bless {
		authuser => $authuser,
		authkey => $authkey
	}, $class;
	return $self;
}

sub fetchRecords {
	my $self = shift;
	return runAPI($self, 'method' => "fetchRecords", @_);
}

sub runAPI {
	my ($self, %args) = @_;
	carp "No method specified for explicit call of runAPI.  Defaulting to fetchRecords" if not $args{'method'}; 
	my %params = (
		format		=> "xml",
		module		=> "Accounts",
		api_user	=> $self->{authuser},
		api_key		=> $self->{authkey},
		status		=> "Active",
		method 		=> "fetchRecords"
	);
	@params{keys %args} = values %args;
	my $ua = new LWP::UserAgent;
	my $resp = $ua->request(POST $SNAPURL, [%params]);
	return $resp->content;
}

sub parseXML {
	my ($self, $info) = @_;
	my %data = ();
	my @tree = ();
	my $spot = "";
	my $word = "";

	my $sthdl = sub {
		my ($prsr, $elem, %atts) = @_;
		my $obj = \%data;
		$obj = ${$obj}{$_} foreach (@tree);
		$spot = $elem.(%atts ? "-".$atts{(keys %atts)[0]} : "");
		push @tree, $spot;
		${$obj}{$spot} = {};
		$word = "";
	};
	my $edhdl = sub {
		my ($prsr, $elem) = @_;
		pop @tree;
		my $obj = \%data;
		$obj = ${$obj}{$_} foreach @tree;
		${$obj}{$spot} = $word;
		$spot = "";
	};
	my $chhdl = sub {
		$word .= $_[1];
	};

	my $parser = XML::Parser->new(Handlers => {
		Start 	=> \&$sthdl,
		End 	=> \&$edhdl,
		Char	=> \&$chhdl
	});
	
	$parser->parse($info);
	delete $data{""};
	delete $data{(keys %data)[0]}{''};
	return %data;
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Snapforce::API - Perl module for simple use of the Snapforce API.

=head1 SYNOPSIS

  use Snapforce::API;
  blah blah blah

=head1 Description

This module acts as a simple in-between between a Perl user and the Snapforce API.  All of this can be reasonably done by the end-user; this module is meant to simplify the process.  Each call of fetchRecords performs an API call to Snapforce according to their API: https://www.snapforce.com/crm/resources/developers/api/

At the moment, only the L</fetchRecords()> API function is implemented, but explicit calls to other methods are allowed with the L</runAPI> function, as long as the appropriate parameters are passed.  See C</runAPI> for more details.

=head1 Methods

=over 4

=item new(Authuser, Authkey)

This is the constructor method for Snapforce::API.  This method has two required parameters: the authentication username and authentication key provided by your Snapforce account.

=item fetchRecords([OPT => OPT_VALUE [...]])

Primary read-only function of the API.  The options that are available for this method are available for all API call methods:

=over 4

=item * module

The module the API call will be using.  This value can be C<Leads>, C<Accounts>, C<Contacts>, C<Opportunities>, or C<Events>.

=item * status

Can be set to either C<Active> or C<Inactive>

=item * format

This is the output format from the API call.  At the moment, the Snapforce API itself only allows C<xml> and C<txt> as values..  When that changes, this module will be updated to support the additional types.

=back

=item runAPI([OPT => OPT_VALUE [...]])

All of the other API functions prepare their data to be passed to this function, which is where the actual API call is made.  The options that this accepts are the same as fetchRecords, but also includes a few others.
runAPI should always be called with a C<method> parameter, but if not, a warning will be thrown that it will default to fetchRecords.  Methods such as inputRecords will also take other key=>value pairs in the form of C<$fieldname => $fieldvalue> as passed parameters.

=item parseXML(XML_DOC)

Not strictly required by this module, as you are free to deal with the returned xml from other methods yourself, but parseXML will turn the returned XML document (if C<format => 'xml'> is specified or no format is given) into a hash tree.  For example:
	my %tree = parseXML($response);
	print $tree{'accounts'}{'account-12345'}{'account_name'};

This will output the account name of account 12345 from the returned xml document.


=head1 SEE ALSO

Please check the official Snapforce API documentation, located at https://www.snapforce.com/crm/resources/developers/api/ to get a list of all functions and parameters. Anything that this module doesn't specifically cover can still be explicitly called using the runAPI function.

=head1 AUTHOR

Gabriel Benamy, E<lt>gabrielbenamy@snapforce.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Snapforce

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
