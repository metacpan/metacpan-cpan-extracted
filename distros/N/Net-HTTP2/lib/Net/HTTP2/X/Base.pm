package Net::HTTP2::X::Base;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::HTTP2::X::Base - Base error class for L<Net::HTTP2>

=head1 DESCRIPTION

Most errors that Net::HTTP2 throws are instances of this class, which
itself extends L<X::Tiny::Base>.

=cut

#----------------------------------------------------------------------

use parent 'X::Tiny::Base';

1;
