#
# This file is part of Riak-Light
#
# This software is copyright (c) 2013 by Weborama.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;
use FindBin qw($Bin);
use Google::ProtocolBuffers;

Google::ProtocolBuffers->parsefile(
    "$Bin/riak.proto",
    {   generate_code    => "$Bin/../lib/Riak/Light/PBC.pm",
        create_accessors => 1
    }
);
