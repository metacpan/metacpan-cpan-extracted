package Object::Iterate::Tester;
use strict;

use vars qw($VERSION);

use warnings;
no warnings;

$VERSION     = '1.152';

=encoding utf8

=head1 NAME

Object::Iterate::Tester - test module that uses Object::Iterate

=head1 SYNOPSIS

	use Object::Iterate qw( imap );
	use Object::Iterate::Tester;

	my $object = Object::Iterate::Tester->new;

	my @list = imap { $_ } $object;

=head1 DESCRIPTION

=head1 SOURCE

This module is on Github:

	https://github.com/briandfoy/object-iterate

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2002-2026, brian d foy <briandfoy@pobox.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut

sub new { bless [qw(a b c d e f)], shift }
sub __more__ { scalar @{ $_[0] } }
sub __next__ { shift  @{ $_[0] } }

1;
