package Nagios::Plugin::OverHTTP::Response;

use 5.008001;
use strict;
use warnings 'all';

###########################################################################
# METADATA
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.16';

###########################################################################
# MOOSE
use Moose 0.74;
use MooseX::StrictConstructor 0.08;

###########################################################################
# MOOSE ROLES
with 'MooseX::Clone';

###########################################################################
# MOOSE TYPES
use Nagios::Plugin::OverHTTP::Library qw(Status);

###########################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###########################################################################
# ATTRIBUTES
has 'message' => (
	is  => 'ro',
	isa => 'Str',
	required => 1,
);
has 'performance_data' => (
	is  => 'ro',
	isa => 'Str',
	clearer   => '_clear_performance_data',
	predicate => 'has_performance_data',
);
has 'response' => (
	is  => 'ro',
	isa => 'HTTP::Response',
	clearer   => '_clear_response',
	predicate => 'has_response',
	traits    => [qw/Clone/],
);
has 'status' => (
	is  => 'ro',
	isa => Status,
	coerce   => 1,
	required => 1,
);

###########################################################################
# MAKE MOOSE OBJECT IMMUTABLE
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Nagios::Plugin::OverHTTP::Response - Represents a parsed reponse from the HTTP
server

=head1 VERSION

This documentation refers to L<Nagios::Plugin::OverHTTP::Response> version 0.16

=head1 SYNOPSIS

  #TODO: Write this

=head1 DESCRIPTION

This module represents a parsed response from the HTTP server with additional
methods related to the operation of L<Nagios::Plugin::OverHTTP>.

=head1 ATTRIBUTES

=head2 message

B<Required>. This is the message (i.e. plugin output) from the plugin that was
parsed.

=head2 performance_data

This is a string that represents the performance data from the plugin.

=head2 response

This is the L<HTTP::Response> object that was parsed.

=head2 status

B<Required>. This is the status from the remote plugin.

=head1 METHODS

=head2 has_performance_data

This will return a Boolean of true if the response had any L</performance_data>
and false otherwise.

=head2 has_response

This will return a Boolean of true if the response had any L</response> and
false otherwise.

=head1 DEPENDENCIES

This module is dependent on the following modules:

=over 4

=item * L<Moose> 0.74

=item * L<MooseX::Clone> 0.05

=item * L<MooseX::StrictConstructor> 0.08

=item * L<Nagios::Plugin::OverHTTP::Library>

=item * L<namespace::clean> 0.04

=back

=head1 AUTHOR

Douglas Christopher Wilson, C<< <doug at somethingdoug.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-nagios-plugin-overhttp at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Nagios-Plugin-OverHTTP>. I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Douglas Christopher Wilson, all rights reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back
