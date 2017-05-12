#!/usr/bin/perl

package Template::Declare::Anon;

use strict;
use warnings;

use base qw/Exporter/;

our $VERSION = "0.03";

use Template::Declare ();
use Template::Declare::Tags ();

use overload '""' => \&process;

our @EXPORT = qw( anon_template process );

sub anon_template (&) {
	my $self = shift;
	bless $self, __PACKAGE__;
}

sub process {
	my ( $template, @args ) = @_;

	local %Template::Declare::Tags::ELEMENT_ID_CACHE = ();
	local $Template::Declare::Tags::self = $Template::Declare::Tags::self || "Template::Declare";

	Template::Declare->new_buffer_frame;

	&$template($Template::Declare::Tags::self, @args);

	my $output = Template::Declare->buffer->data;

	Template::Declare->end_buffer_frame;

	return $output;
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Template::Declare::Anon - B<Deprecated> Anonymous Template::Declare templates

=head1 SYNOPSIS

This module is no longer necessary. The following code will just work:

	use Template::Declare::Tags 'HTML';

	print html {
		body {
			p { "foo" }
		}
	};

=head1 SEE ALSO

L<Template::Declare>

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2007 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute it and/or modify it
	under the terms of the MIT license or the same terms as Perl itself.

=cut
