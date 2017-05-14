# $Id: /mirror/Senna-Perl/lib/Senna/Set.pm 2879 2006-08-31T03:08:01.291533Z daisuke  $
#
# Copyright (c) 2005-2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Senna::Set;
use strict;

*new = \&open;
sub open
{
    my $class = shift;
    my %args  = @_;
    $class->xs_open(@args{qw(key_size value_size n_entries)});
}

1;

__END__

=head1 NAME

Senna::Set - Wrapper Around sen_set

=head1 METHODS

=head2 new

=head2 open

=head2 close

=head2 info

=head1 AUTHOR

Copyright (C) 2005 - 2006 by Daisuke Maki <dmaki@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

Development funded by Brazil Ltd. E<lt>http://dev.razil.jp/project/senna/E<gt>

=cut