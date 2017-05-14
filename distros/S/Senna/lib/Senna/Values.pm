# $Id: /mirror/Senna-Perl/lib/Senna/Values.pm 2738 2006-08-17T19:02:18.939501Z daisuke  $
#
# Copyright (c) 2005-2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Senna::Values;
use strict;

*new = \&open;

sub add
{
    my $self = shift;
    my %args = @_;

    $self->xs_add(@args{qw(str weight)});
}

1;

__END__

=head1 NAME

Senna::Values - Wrapper Around sen_values

=head1 SYNOPSIS

  use Senna::Values;
  my $v = Senna::Values->new;
  $v->add(str => $str, weight => $weight);
  $v->close;

=head1 METHODS

=head2 new

=head2 open

creates a new Senna::Values instance. new() is a synonym for open()

=head2 close

=head2 add

=head1 AUTHOR

Copyright (C) 2005 - 2006 by Daisuke Maki <dmaki@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

Development funded by Brazil Ltd. E<lt>http://dev.razil.jp/project/senna/E<gt>

=cut
