package Template::Plugin::RoundRobin;
use strict;
use warnings;
use base qw(Data::RoundRobin Template::Plugin);
our $VERSION = '0.02';

1;

__END__

=head1 NAME

  Template::Plugin::RoundRobin - Server data in a round robin manner.

=head1 SYNOPSIS

    # Alternative backgrounds

    [% USE RoundRobin %]
    [% SET rr = RoundRobin.new("blue","red","green") %]
    [% FOR row = rows %]
    <tr style="color:[% rr.next %]">...</tr>
    [% END %]

=head1 DESCRIPTION

This plugin solves this one simple problem that sometime people want
alternative style on adjency objects for it's easier to read text on it.

This plugin provide works exactly the same way as L<Data::RoundRobin>.  You
should create a new instance whenever you want a new set of data.  It has two
methods, C<new()> and C<next()>. C<new()> is the constructor of this class, a
list of data is required, and C<next()> return the next element of that list.

=head1 SEE ALSO

L<Data::RoundRobin>

=head1 COPYRIGHT

Copyright 2006 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

