package Plack::Middleware::AMF;

use warnings;
use strict;

our $VERSION = '0.02';

use parent "Plack::Middleware";

use Data::AMF::Remoting;
use Plack::Request;
use Plack::Util;
use Plack::Util::Accessor qw/path headers_handler message_handler/;
use UNIVERSAL::require;

sub prepare_app {
	my $self = shift;
	
	unless (defined $self->headers_handler) {
		$self->headers_handler(\&_default_headers_handler);
	}

	unless (defined $self->message_handler) {
		$self->message_handler(\&_default_message_handler);
	}

	if (ref $self->headers_handler ne 'CODE') {
		die 'headers_handler should be a code reference';
	}

	if (ref $self->message_handler ne 'CODE') {
		die 'message_handler should be a code reference';
	}
}

sub call {
	my $self = shift;
	my $env  = shift;

	my $res = $self->_handle_amf($env);

	return $res if $res;

	return $self->app->($env);
}

sub _handle_amf {
	my ($self, $env) = @_;
	
	my $path_match = $self->path or return;
	my $path = $env->{PATH_INFO};

	for ($path) {
		my $matched = 'CODE' eq ref $path_match ? $path_match->($_) : $_ =~ $path_match;
		return unless $matched;
	}

	my $req = Plack::Request->new($env);
	my $res = $req->new_response(200);

	my $remoting = Data::AMF::Remoting->new(
		source              => $req->raw_body,
		headers_did_process => $self->headers_handler,
		message_did_process => $self->message_handler,
	);
	$remoting->run if $remoting->{source};

	$res->content_type('application/x-amf');
	$res->body($remoting->data);

	return $res->finalize;
}

sub _default_headers_handler {}

sub _default_message_handler {
	my $message = shift;

	my ($controller_name, $action_name) = split '\.', $message->target_uri;
	
	$controller_name->require or die $@;
	
	my $controller = $controller_name->new;
	my $action = $controller->can($action_name);
	
	if (defined $action) {
		return $controller->$action(@{ $message->value });
	}	
}

1;
__END__

=head1 NAME

Plack::Middleware::AMF - The great new Plack::Middleware::AMF!

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
	    enable "AMF", path => qr/^\/amf\/gateway/;
	    $app
    };

=head1 DESCRIPTION

Enable this middleware to allow your Plack-based application to handle Flash Remoting and Flex RPC.

=head1 CONFIGURATIONS

=head2 path

=head2 headers_handler

=head2 message_handler

=head1 METHOD

=head2 prepare_app

=head2 call

=head1 AUTHOR

Takuho Yoshizu, C<< <yoshizu at s2factory.co.jp> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-plack-middleware-amf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Plack-Middleware-AMF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Plack::Middleware::AMF


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Plack-Middleware-AMF>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Plack-Middleware-AMF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Plack-Middleware-AMF>

=item * Search CPAN

L<http://search.cpan.org/dist/Plack-Middleware-AMF/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Takuho Yoshizu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
