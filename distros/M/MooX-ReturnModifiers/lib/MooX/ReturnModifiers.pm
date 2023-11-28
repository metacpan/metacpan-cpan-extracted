package MooX::ReturnModifiers;

use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = '1.000001';

use Exporter 'import';

our @EXPORT = qw/return_modifiers/;
our @EXPORT_OK = qw/return_modifiers return_has return_with return_around return_extends return_before return_after return_sub/;

sub return_modifiers {
	my $target = shift;
	my %modifiers = ();
	$_[0] ||= [qw/has with around extends before after sub/];
	for ( @{ $_[0] } ) {
		if ($_ eq 'sub') {
			$modifiers{$_} = sub {
				my ($sub, $cb) = @_;
				no strict 'refs';
				*{"${target}::${sub}"} = $cb;
			};
			next;
		}
		unless ( $modifiers{$_} = $target->can($_) ) {
			croak "Can't find method <$_> in <$target>";
		}
	}
	return $_[1] ? \%modifiers : %modifiers;
}

sub return_has {return_modifiers($_[0], [qw/has/], 1)->{has}}

sub return_with {return_modifiers($_[0], [qw/with/], 1)->{with}}

sub return_after {return_modifiers($_[0], [qw/after/], 1)->{after}}

sub return_before {return_modifiers($_[0], [qw/before/], 1)->{before}}

sub return_around {return_modifiers($_[0], [qw/around/], 1)->{around}}

sub return_extends {return_modifiers($_[0], [qw/extends/], 1)->{extends}}

sub return_sub {return_modifiers($_[0], [qw/sub/], 1)->{sub}}

1;

__END__

=head1 NAME

MooX::ReturnModifiers - Returns Moo Modifiers as a Hash

=head1 VERSION

Version 1.000001

=head1 SYNOPSIS

	use MooX::ReturnModifiers;

	sub import {
		my $target = caller;
		my %modifiers = return_modifiers($target);

		...
		$modifiers{has}->();
		$modifiers{with}->();
		$modifiers{extends}->();
		$modifiers{around}->();
		$modifiers{before}->();
		$modifiers{after}->();
		$modifiers{sub}->();
	}

	.... OR ......

	use MooX::ReturnModifiers qw/return_has/

	sub import {
		my $target = caller;
		my $has = return_has($target);

		$has->( .... );
	}


=head1 EXPORT

=head2 return_modifiers

Return a list of Moo modifers. You can optionally pass your own ArrayRef of keys as the second argument.

	my %modifiers = return_modifiers($target, [qw/has/]);

	....

	#	(
	#	   has => sub { ... }
	#	)

=head2 EXPORT OK

=head2 return_has

	my $has = return_has($target);

=head2 return_extends

	my $extends = return_extends($target);

=head2 return_with

	my $with = return_with($target);

=head2 return_around

	my $around = return_around($target);

=head2 return_before

	my $before = return_before($target);

=head2 return_after

	my $after = return_after($target);

=head2 return_sub

	my $sub = return_sub($target);

=head1 AUTHOR

Robert Acock, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moox-returnmodifiers at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-ReturnModifiers>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MooX::ReturnModifiers

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-ReturnModifiers>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooX-ReturnModifiers>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooX-ReturnModifiers>

=item * Search CPAN

L<http://search.cpan.org/dist/MooX-ReturnModifiers/>

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
