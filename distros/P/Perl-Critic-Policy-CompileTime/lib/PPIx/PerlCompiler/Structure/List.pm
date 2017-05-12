# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package PPIx::PerlCompiler::Structure::List;

use strict;
use warnings;

sub item {
    my ( $self, $index ) = @_;

    my $expression = $self->non_whitespace_child(0) or return;

    return unless $expression->isa('PPI::Statement::Expression');

    return $expression->non_whitespace_child($index);
}

1;
