package Nothing::Tiny;
use strict;
use warnings;

our $VERSION = '1';

=head1 NAME

Nothing::Tiny - a module that does nothing, albeit with no accessor 
overhead or non-core dependencies

=head1 SYNOPSIS

Sometimes modules with actual functionality are too slow or use too
much memory.  C<Nothing::Tiny> aims to balance features with memory
usage by doing nothing in the smallest amount of space possible.

Here's how to use it:

   use Nothing::Tiny;

Now you've done nothing, all while not adding any non-core
dependencies to your application!  Tinylicious!

=head1 AUTHOR

Jonathan Rockway C<< <jrockway@cpan.org> >>

=head1 COPYRIGHT

This module is free of software.  You may redistribute it under the
same terms as Perl itself.

=cut

1;
