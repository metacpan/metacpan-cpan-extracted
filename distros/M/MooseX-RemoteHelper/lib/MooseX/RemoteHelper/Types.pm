package MooseX::RemoteHelper::Types;
use strict;
use warnings;

our $VERSION = '0.001021'; # VERSION

use MooseX::Types    -declare => [qw( Bool TrueFalse )];
use MooseX::Types::Moose -all => { -prefix => 'Moose' };

subtype TrueFalse, as MooseStr,
	where {
		$_ =~ m/^(true|t|f|false|enable[d]?|disable[d]?)|yes|y|no|n$/ixms;
	};

subtype Bool, as MooseBool;
coerce  Bool, from TrueFalse,
	via {
		my $val = lc $_;
		if ( $val =~ m/^(t|enable|y)/xms ) {
			return 1;
		}
		elsif ( $val =~  /^(f|disable|n)/xms ) {
			return 0;
		}
		return 0;
	};

1;
# ABSTRACT: Types to help with things commonly needed by remotes

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::RemoteHelper::Types - Types to help with things commonly needed by remotes

=head1 VERSION

version 0.001021

=head1 SUBROUTINES

=head2 Bool

coerces from string where values could match (case insensitive):

	true, t, false, f, enable[d], disable[d], yes, y, no, n

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/xenoterracide/moosex-remotehelper/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooseX::RemoteHelper|MooseX::RemoteHelper>

=back

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
