# $Id: /mirror/Senna-Perl/lib/Senna/OptArg/Sort.pm 2496 2006-07-13T06:26:39.346347Z daisuke  $
#
# Copyright (c) 2005-2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Senna::OptArg::Sort;
use strict;

sub new
{
    my $class = shift;
    my %args  = @_;
    $class->xs_new(@args{qw(mode compar compar_arg)});
}

1;

__END__

=head1 NAME

Senna::OptArg::Sort - Wrapper Around sen_sort_optarg

=head1 SYNOPSIS

=head1 METHODS

=head2 new
=head2 compar
=head2 compar_arg
=head2 mode

=cut

