package Task::Bot::Training;
BEGIN {
  $Task::Bot::Training::VERSION = '0.02';
}

use 5.010;

use Bot::Training;
use Bot::Training::MegaHAL;
use Bot::Training::StarCraft;

1;

__END__

=head1 NAME

Task::Bot::Training - Install all known L<Bot::Training> modules

=head1 DESCRIPTION

This module installs all the currently known L<Bot::Training> modules:

=over

=item * L<Bot::Training>

=item * L<Bot::Training::MegaHAL>

=item * L<Bot::Training::StarCraft>

=back

=cut

=head1 AUTHORS

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
