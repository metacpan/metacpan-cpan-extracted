# $Id: /mirror/Senna-Perl/lib/Senna/Records.pm 2794 2006-08-21T01:00:25.021535Z daisuke  $
#
# Copyright (c) 2005-2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Senna::Records;
use strict;

*new = \&open;
sub open
{
    my $class = shift;
    my %args  = @_;
    $class->xs_open(@args{qw(record_unit subrec_unit max_n_subrecs)});
}

sub next
{
    my $self = shift;
    my @p = $self->xs_next();
    if (@p) {
        my %h;
        @h{qw(key score section pos n_subrecs)} = @p;
        return Senna::Record->new(%h);
    }
    return ();
}

1;

__END__

=head1 NAME

Senna::Records - Wrapper for sen_records Data Type

=head1 METHODS

=head2 new
=head2 open
=head2 next
=head2 close
=head2 curr_key
=head2 curr_score
=head2 nhits
=head2 find
=head2 difference
=head2 intersect
=head2 subtract
=head2 union
=head2 rewind

=head1 AUTHOR

Copyright (C) 2005 - 2006 by Daisuke Maki <dmaki@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

Development funded by Brazil Ltd. E<lt>http://dev.razil.jp/project/senna/E<gt>

=cut

