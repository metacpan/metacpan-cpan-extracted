package Net::Rest::Generic;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Want;
use URI;
use Storable qw(dclone);
use Net::Rest::Generic::Error;
use Net::Rest::Generic::Utility;

=head1 NAME

Net::Rest::Generic - A tool for generically interacting with restfull (or restlike) APIs.

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

Net::Rest::Generic is a module for interacting with arbitrary HTTP/S APIs.
It attempts to do this by providing an easy to read syntax for generating the request
URLs on the fly, and generally Doing The Right Thing.

A basic example:

    use Net::Rest::Generic;

    my $api = Net::Rest::Generic->new(
		host => "api.foo.com",
		scheme => "https",
		base => "api/v1",
		authorization_basic => {
			username => "user",
			password => "password",
		}
	);
    my $result = $api->setRequestMethod("POST")->this->is->the->url("parameterized")->addLabel("new");

    my $details = $api->setRequestMethod("GET")->user("superUser")->details->color->favorite;
    ...

=head1 SUBROUTINES/METHODS

=head2 new()

The new method is used to create a new() Net::Rest::Generic object.

=cut

sub new {
	my $class = shift;
	my %defaults = (
		mode   => 'get',
		scheme => 'https',
		string => 0,
	);
	my $param_ref = ref($_[0]) ? $_[0] : {@_};
	my $self = {
		chain   => [],
		_params => dclone($param_ref),
	};
	map { $self->{$_}  = delete $self->{_params}{$_} } grep { defined($self->{_params}{$_}) } qw(mode scheme host port base string authorization_basic);
	while (my ($k, $v) = each %defaults) {
		$self->{$k} ||= $v;
	}

	my $input;
	my @modes = qw(delete get post put head);
	if (! grep (/$self->{mode}/i, @modes)) {
		$input = Net::Rest::Generic::Error->throw(
			category => 'input',
			message => 'mode must be one of the following: ' . join(', ', @modes) . '. You supplied: ' . $self->{mode},
		);
	}
	my @schemes = qw(http https);
	if (! grep (/$self->{scheme}/i, @schemes)) {
		$input = Net::Rest::Generic::Error->throw(
			category => 'input',
			message  => 'scheme must be one of the following: ' . join(', ', @schemes) . '. You supplied: ' . $self->{scheme},
		);
	}
	return $input if (ref($input) eq 'Net::Rest::Generic::Error');

	$self->{uri} = URI->new();
	$self->{uri}->scheme($self->{scheme});
	$self->{uri}->host($self->{host});
	$self->{uri}->port($self->{port}) if exists $self->{port};
	return bless $self, $class;
}

sub AUTOLOAD {
	my $self = shift;

	our $AUTOLOAD;
	my ($key) = $AUTOLOAD =~ /.*::([\w_]+)/o;
	return if ($key eq 'DESTROY');

	push @{ $self->{chain} }, $key;
	my $args;
	if (ref($_[0])) {
		$args = $_[0];
	}
	else {
		push @{ $self->{chain} }, @_;
	}
	if (want('OBJECT') || want('VOID')) {
		return $self;
	}

	unshift(@{ $self->{chain} }, $self->{base}) if exists $self->{base};
	my $url = join('/', @{ $self->{chain} });
	$self->{chain} = [];
	$self->{uri}->path($url);

	if ($self->{string}) {
		if (want('LIST')) {
			return ($self->{mode}, $self->{uri}->as_string);
		}
		else {
			return $self->{uri}->as_string;
		}
	}

	return Net::Rest::Generic::Utility::_doRestCall($self, $self->{mode}, $self->{uri}, $args);
}

=head2 addLabel()

The addLabel method exists in case the rest url that you're using
has a portion of it's path that has the same name as a method that isn't
handled by the AUTOLOAD method in this module.

usage: $api->addLabel("new");

=cut

sub addLabel {
	my ($self, @labels) = @_;
	push @{$self->{chain}}, @labels;
	return $self;
}

=head2 cloneApi

The cloneApi function is used to make a hard copy of whatever object you're
working on so that you can make a 'save point' of your object.

usage my $cloneapi = $api->clone

=cut

sub cloneApi {
	return dclone(shift);
}

=head2 setRequestMethod()

The setRequestMethod function is used to change the method that the object
will use when running the request.

usage $api->setRequestMethod("POST")->......

=cut

sub setRequestMethod {
	my ($self, $method) = @_;
	$self->{mode} = $method;
	return $self;
}

=head2 setRequestContent()

The setRequestContent method will allow you to send something specifically
along in the HTTP::Request object when the call to the api is made.

For instance you may want to send the api method you're about to use a json
data structure, you could do:

$api->setRequestMethod($json)->methodthatrequiresjson

=cut

sub setRequestContent {
	my ($self, $content) = @_;
	$self->{request_content} = $content;
	return $self;
}

=head2 userAgentOptions()

The userAgentOptions method will allow you to send in a hash or hashref
that will be used as the options for the LWP::UserAgent object used for
making the api call.

For example:
$api->userAgentOptions(ssl_opts => {verify_hostname => 0});

=cut

sub userAgentOptions {
	my $self = shift;
	my $argref = ref($_[0]) ? $_[0] : {@_};
	$self->{useragent_options} = $argref;
	return $self;
}

=head1 AUTHORS

Sebastian Green-Husted, C<< <ricecake at tfm.nu> >>

Shane Utt, C<< <shaneutt at linux.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-rest-generic at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Rest-Generic>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Rest::Generic

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Rest-Generic>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Rest-Generic>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Rest-Generic>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Rest-Generic/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013 Sebastian Green-Husted, All Rights Reserved.

Copyright (C) 2013 Shane Utt, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
