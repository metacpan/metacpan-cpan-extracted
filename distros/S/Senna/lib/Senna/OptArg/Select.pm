# $Id: /mirror/Senna-Perl/lib/Senna/OptArg/Select.pm 2491 2006-07-12T18:26:24.892479Z daisuke  $
#
# Copyright (c) 2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Senna::OptArg::Select;
use strict;

sub new
{
    my $class = shift;
    my %args  = @_;
    $class->xs_new(@args{qw(mode similarity_threshold max_interval weight_vector func func_arg)});
}

1;

__END__

=head1 NAME

Senna::OptArg::Select - Wrapper Around sen_select_optarg

=head1 SYNOPSIS

  Senna::OptArg::Select->new(
     mode => $mode,
     similarity_threshold => $threshold,
     max_interval => $max,
     weight_vector => [ ... ],
     func => \&func,
     func_args => [ ... ],
  );

=head1 METHODS

=head2 new
=head2 mode
=head2 similarity_threshold
=head2 max_interval
=head2 weight_vector
=head2 vector_size
=head2 func
=head2 func_arg

=cut