#
# This file is part of MooX-Options
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package TestNamespaceClean;
use Moo;
use MooX::Options;
use namespace::clean -except => [qw/_options_data _options_config/];

option foo => ( is => 'ro', format => 's' );

1;
