package Struct::WOP;

use 5.006;
use strict;
use warnings;

use Scalar::Util qw/reftype refaddr/;
use Encode qw/decode encode/;

our $VERSION = '0.08';
our (%HELP, @MAYBE, $caller, $destruct);
BEGIN {
	%HELP = (
		arrayref => sub { return map { $_[0]->($_, $_[2]) } @{ $_[1] } },
		hashref => sub { $caller->can('filter_keys') && $caller->filter_keys($_[1]->{$_}, $_) and next or 
			$destruct && do { $_[3]{$_[0]->($_)} = $_[0]->($_[1]->{$_}, $_[2]) } || do { $_[1]->{$_} = $_[0]->($_[1]->{$_}, $_[2]) } for keys %{ $_[1] }; $_[3]; },
		scalarref => sub { ${$_[1]} =~ m/^[0-9.]+$/g ? $_[1] : do { ${$_[1]} =~ s/^(.*)$/$_[0]->(${$_[1]})/e; $_[1]; } && $destruct ? ${$_[1]} : $_[1]; }, 
		scalar => sub { eval { $_[1] = $_[0]->($_, $_[1], Encode::FB_CROAK); 1; } and last foreach @MAYBE; $_[1]; }
	);
}

sub import {
	my ($pkg) = shift;
	return unless my @export = @_;
	my $opts = ref $export[scalar @export - 1] ? pop @export : ['UTF-8'];
	@MAYBE = ref $opts eq 'HASH' ? do { $destruct = $opts->{destruct}; @{ $opts->{type} } } : @{ $opts };
	@export = qw/maybe_decode maybe_encode/ if scalar @export == 1 && $export[0] eq 'all';
	$caller = scalar caller();
	{
		no strict 'refs';
		do { *{"${caller}::${_}"} = \&{"${pkg}::${_}"} } foreach @export;
	}
}

sub maybe_decode {
	_maybe(shift, \&decode, \&maybe_decode, shift);
}

sub maybe_encode {
	_maybe(shift, \&encode, \&maybe_encode, shift);
}

sub _maybe {
	my $ref = reftype($_[0]);
	return $HELP{scalar}->($_[1], $_[0]) if !$ref;
	return $destruct ? _d_recurse($_[0], $ref, $_[2]) : _recurse($_[0], $ref, $_[2], $_[3] // {});
}

sub _recurse {
	my $addr = refaddr $_[0];
	return defined $_[3]->{$addr} ? $_[0] : do { $_[3]->{$addr} = 1 } && $_[1] eq 'SCALAR' ? $HELP{scalarref}->($_[2], $_[0]) : $_[1] eq 'ARRAY'
		? $HELP{arrayref}->($_[2], $_[0], $_[3]) && $_[0] : $_[1] eq 'HASH' ? $HELP{hashref}->($_[2], $_[0], $_[3], 1) && $_[0] : $_[0];
}

sub _d_recurse {
	return $_[1] eq 'SCALAR' ?  $HELP{scalarref}->($_[2], $_[0]) : $_[1] eq 'ARRAY' ? [ $HELP{arrayref}->($_[2], $_[0]) ] : $_[1] eq 'HASH' ? $HELP{hashref}->($_[2], $_[0], {}) : $_[0];
}

1;

__END__

=head1 NAME

Struct::WOP - deeply encode/decode a struct

=head1 VERSION

Version 0.08

=cut

=head1 SYNOPSIS

	use Struct::WOP qw/maybe_decode/ => [qw/UTF-8/];

	sub encoded_world_of_pain {
		maybe_decode(@_);
	}

	sub filter_keys {
		my ($self, $hashref, $key) = @_;

	}

=cut

=head1 EXPORT
 
=head2 maybe_decode
 
=head2 maybe_encode
 
=cut

=head1 AUTHOR

Robert Acock, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-struct-wop at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-WOP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Struct::WOP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Struct-WOP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Struct-WOP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Struct-WOP>

=item * Search CPAN

L<http://search.cpan.org/dist/Struct-WOP/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Robert Acock.

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
