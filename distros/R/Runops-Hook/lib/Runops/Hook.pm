package Runops::Hook;

use strict;
use warnings;

our $VERSION = '0.03';

1;

__END__

=pod

=head1 NAME

Runops::Hook - B<DEPRECATED> (all functionality merged into L<Runops::Trace>

=head1 SYNOPSIS

	use Runops::Trace;

=head1 DESCRIPTION

L<Runops::Trace> 0.10 has been extended to support all the features of
Runops::Hook (thresholds, operator arguments, etc) and got a few more features
as well. Go check it out.

=head1 AUTHOR

Chia-Liang Kao E<lt>clkao@clkao.orgE<gt>

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Chia-Liang Kao, Yuval Kogman. All rights
	reserved. This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
