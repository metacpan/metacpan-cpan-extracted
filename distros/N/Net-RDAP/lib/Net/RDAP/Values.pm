package Net::RDAP::Values;
use Carp;
use File::Basename qw(dirname basename);
use File::Slurp;
use File::Spec;
use File::Temp;
use File::stat;
use HTTP::Request::Common;
use List::MoreUtils qw(any);
use Net::RDAP::UA;
use XML::LibXML;
use vars qw($UA $REGISTRY @EXPORT);
use constant {
	RDAP_TYPE_NOTICE_OR_REMARK_TYPE		=> 'notice or remark type',	# 
	RDAP_TYPE_STATUS			=> 'status',			# these values are defined in
	RDAP_TYPE_ROLE				=> 'role',			# RFC 7483, section 10.2.
	RDAP_TYPE_EVENT_ACTION			=> 'event action',		# 
	RDAP_TYPE_DOMAIN_VARIANT_RELATION	=> 'domain variant relation',	# 
};
use base qw(Exporter);
use strict;

#
# export these symbols
#
our @EXPORT = qw(
	RDAP_TYPE_NOTICE_OR_REMARK_TYPE
	RDAP_TYPE_STATUS
	RDAP_TYPE_ROLE
	RDAP_TYPE_EVENT_ACTION
	RDAP_TYPE_DOMAIN_VARIANT_RELATION
);

#
# in case we need to download something
#
$UA = Net::RDAP::UA->new;

#
# where we store the registry data
#
$REGISTRY = load_registry();

=pod

=head1 NAME

L<Net::RDAP::Values> - interface to the RDAP values registry.

=head1 DESCRIPTION

The RDAP JSON Values Registry was defined in RFC 7483 and lists the
permitted values of certain RDAP object properties. This class implements
an interface to that registry.

Ironically, since the registry is only available in CSV and XML formats,
this module has to use L<XML::LibXML> in order to access the registry data
that it retrieves from the IANA web server.

=head1 METHODS

=head2 check()

	Net::RDAP::Values->check($value, $type);

	Net::RDAP::Values->check('add period', RDAP_TYPE_STATUS);

	Net::RDAP::Values->check('registration', RDAP_TYPE_EVENT_ACTION);

The C<check()> function allows you to determine if a given value is present
in the registry. You must also specify the type of the value using one of
the C<RDAP_TYPE_*> constants.

If the value is registered in the registry, this method returns a true
value, otherwise it returns C<undef>.

=cut

sub check {
	my ($self, $value, $type) = @_;

	foreach my $registered ($self->values($type)) {
		return 1 if ($registered eq $value);
	}

	return undef;
}

=pod

=head2 values()

	@values = Net::RDAP::Values->values($type);

	@values = Net::RDAP::Values->values(RDAP_TYPE_ROLE);

The C<values()> function returns a list of the permitted values for the
given value type. If you specify an invalid type, an exception is raised.

=cut

sub values {
	my ($self, $type) = @_;

	if (!defined($REGISTRY->{'values_by_type'}->{$type})) {
		croak(sprintf("'%s' is not a permitted value type", $type));

	} else {
		return sort @{$REGISTRY->{'values_by_type'}->{$type}};

	}
}

=pod

=head2 types()

	@types = Net::RDAP::Values->types;

The C<types()> function returns a list of all possible RDAP value types.

=cut

sub types {
	return (
		RDAP_TYPE_NOTICE_OR_REMARK_TYPE,
		RDAP_TYPE_STATUS,
		RDAP_TYPE_ROLE,
		RDAP_TYPE_EVENT_ACTION,
		RDAP_TYPE_DOMAIN_VARIANT_RELATION,
	);
}

=pod

=head2 description()

	$description = Net::RDAP::Values->description($value, $type);

	$description = Net::RDAP::Values->description('registration', RDAP_TYPE_EVENT_ACTION);

	use Net::RDAP::EPPStatusMap;
	$description = Net::RDAP::Values->description(epp2rdap('serverHold'), RDAP_TYPE_STATUS);

The C<description()> function returns a textual description (in English) of the value
in the registry, suitable for display to the user.

=cut

sub description {
	my ($self, $value, $type) = @_;

	return $REGISTRY->{'descriptions'}->{$type}->{$value};
}

sub load_registry {
	my $package = shift;

	my $url = 'https://www.iana.org/assignments/rdap-json-values/rdap-json-values.xml';

	my $file = sprintf('%s/%s-%s', File::Spec->tmpdir, $package, basename($url));

	my ($mirror, $stat);
	if (-e $file) {
		$stat = stat($file);
		$mirror = (time() - $stat->mtime > 86400);

	} else {
		$mirror = 1;

	}

	if ($mirror) {
		my $request = GET($url);
		$request->header('Accept' => '*/*');
		$request->header('If-Modified-Since' => HTTP::Date::time2str($stat->mtime)) if ($stat);

		my $response = $UA->request($request);

		if (304 == $response->code) {
			utime(undef, undef, $file);

		} elsif ($response->is_success) {
			my $tmpfile = File::Temp::tempnam(dirname($file), basename($file));
			carp("Unable to write response data to $tmpfile: $!") if (!write_file($tmpfile, $response->content));
			carp("Unable to move $tmpfile to $file: $!") if (!rename($tmpfile, $file));

		} else {
			carp($response->status_line);

		}
	}

	if (-e $file) {
		my $doc = XML::LibXML->load_xml('location' => $file, 'no_blanks' => 1);

		my $registry = {};

		foreach my $record ($doc->getElementsByTagName('record')) {
			my $value = $record->getElementsByTagName('value')->shift->textContent;
			my $type = $record->getElementsByTagName('type')->shift->textContent;
			my $description = $record->getElementsByTagName('description')->shift->textContent;

			push(@{$registry->{'value_types'}->{$value}}, $type);
			push(@{$registry->{'values_by_type'}->{$type}}, $value);
			$registry->{'descriptions'}->{$type}->{$value} = $description;
		}

		return $registry;

	} else {
		return undef;

	}
}

=pod

=head1 EXPORTED CONSTANTS

L<Net::RDAP::Values> exports the following constants, which correspond
to the permitted types of RDAP values:

=over

=item * C<RDAP_TYPE_NOTICE_OR_REMARK_TYPE>

=item * C<RDAP_TYPE_STATUS>

=item * C<RDAP_TYPE_ROLE>

=item * C<RDAP_TYPE_EVENT_ACTION>

=item * C<RDAP_TYPE_DOMAIN_VARIANT_RELATION>

=back

=head1 COPYRIGHT

Copyright 2019 CentralNic Ltd. All rights reserved.

=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the name of the author not be used
in advertising or publicity pertaining to distribution of the software
without specific prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

1;
