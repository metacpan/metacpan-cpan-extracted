package Object::Iterate::Tester;
use strict;

use vars qw($VERSION);

use warnings;
no warnings;

$VERSION     = '1.14';

=head1 NAME

Object::Iterate::Tester - test module that uses Object::Iterate

=head1 SYNOPSIS

	use Object::Iterate qw( imap );
	use Object::Iterate::Tester;

	my $object = Object::Iterate::Tester->new();

	my @list = imap { $_ } $object;

=head1 DESCRIPTION

=head1 SOURCE

This module is on Github:

	http://github.com/briandfoy/Object-Iterate
	
=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2014 brian d foy.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub new { bless [qw(a b c d e f)], shift }
sub __more__ { scalar @{ $_[0] } }
sub __next__ { shift  @{ $_[0] } }

1;
