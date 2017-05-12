# $Id: /mirror/coderepos/lang/perl/R-Writer/trunk/lib/R/Writer/Encoder.pm 43085 2008-03-01T12:28:42.888222Z daisuke  $
#
# Copyright (c) 2008 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package R::Writer::Encoder;
use strict;
use warnings;

use JSON::XS (); # XXX - Remove this in the future?
our $CODER = JSON::XS->new->allow_nonref;

sub new    { bless \my $c, shift }
sub encode { $CODER->encode($_[1]) }

1;

__END__

=head1 NAME

R::Writer::Encoder - Default Encoder

=head1 SYNOPSIS

  use R::Writer::Encoder;
  # Internal use only

=head1 METHODS

=head2 new

=head2 encode

=cut
