# $Id: /mirror/coderepos/lang/perl/R-Writer/trunk/lib/R/Writer/Range.pm 43085 2008-03-01T12:28:42.888222Z daisuke  $
#
# Copyright (c) 2008 DAisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package R::Writer::Range;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors($_) for qw(start end);

sub new { shift->SUPER::new({ start => $_[0], end => $_[1] }) }

sub as_string
{
    my $self = shift;
    return join(":", $self->start, $self->end);
}

1;

__END__

=head1 NAME

R::Writer::Range - Range Of Values

=head1 SYNOPSIS

  use R::Writer::Range;
  # Internal use only

=head1 METHODS

=head2 new

=head2 as_string

=cut
