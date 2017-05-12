package Net::SixXS;
use v5.010;
use strict;
use warnings;

use version; our $VERSION = version->declare("v0.1.1");

use Carp 'croak';
use Scalar::Util 'blessed';

use Net::SixXS::Diag::None;

my $diag = Net::SixXS::Diag::None->new();

sub diag(;$)
{
	my ($v) = @_;

	if (defined $v) {
		if (!blessed $v || !$v->can('does') ||
		    !$v->does('Net::SixXS::Diag')) {
			croak 'Net::SixXS::diag() needs an object that '.
			    'does Net::SixXS::Diag';
		}
		$diag = $v;
	}
	return $diag;
}

1;
__END__

=encoding utf-8

=head1 NAME

Net::SixXS - interface to the SixXS.org services

=head1 SYNOPSIS

    use Net::SixXS::TIC::Client;

    my $tic = Net::SixXS::TIC::Client->new(username = 'me', password = 'none');
    $tic->connect;
    say for sort map $_->name, values %{$tic->tunnels};

=head1 DESCRIPTION

The C<Net::SixXS> suite contains helper classes to connect to the various
IPv6 tunnel services provided by SixXS (L<http://www.sixxs.net/>).

This implementation includes a simple TIC client (C<Net::SixXS::TIC::Client>),
a couple of trivial TIC servers (see C<Net::SixXS::TIC::Server> for a list),
and some data structures to facilitate their use.

The C<Net::SixXS> module itself only serves as a common repository for
subroutines and data used by all the modules in the hierarchy.

=head1 FUNCTIONS

The C<Net::SixXS> module currently only defines a single function:

=over 4

=item B<diag ([object])>

Get or set the object that will be used to output diagnostic information
by all the modules in the C<Net::SixXS> hierarchy.  The parameter, if
supplied, must implement the L<Net::SixXS::Diag> role.

By default this is set to a L<Net::SixXS::Diag::None> instance; thus,
unless a program overrides it, any diagnostic output from classes in
the C<Net::SixXS> hierarchy will be ignored.

=back

=head1 SEE ALSO

The TIC client class: L<Net::SixXS::TIC::Client>

The TIC server class: L<Net::SixXS::TIC::Server>

Diagnostics: L<Net::SixXS::Diag>, L<Net::SixXS::Diag::None>,
L<Net::SixXS::Diag::MainDebug>

=head1 LICENSE

Copyright (C) 2015  Peter Pentchev E<lt>roam@ringlet.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Peter Pentchev E<lt>roam@ringlet.netE<gt>

=cut

