package Protocol::Redis::Faster;

use strict;
use warnings;

use parent 'Protocol::Redis';

our $VERSION = '0.004';

1;

=head1 NAME

Protocol::Redis::Faster - Optimized pure-perl Redis protocol parser/encoder (DEPRECATED)

=head1 DESCRIPTION

This is an empty subclass of L<Protocol::Redis>. The optimizations it used to
contain have been implemented in the base class. Consider
L<Protocol::Redis::XS> for faster parsing.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHORS

Dan Book <dbook@cpan.org>

Jan Henning Thorsen <jhthorsen@cpan.org>

=head1 CREDITS

Thanks to Sergey Zasenko <undef@cpan.org> for the original L<Protocol::Redis>
and defining the API.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Dan Book, Jan Henning Thorsen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Protocol::Redis>
