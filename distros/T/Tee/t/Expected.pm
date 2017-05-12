#
# This file is part of Tee
#
# This software is Copyright (c) 2006 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
package t::Expected;
@EXPORT = qw( expected );
@ISA = qw( Exporter );
use strict;
use Exporter;

my %expected = (
    "STDOUT" => "# STDOUT: hello world\n",
    "STDERR" => "# STDERR: goodbye, cruel world\n",
);

sub expected {
    return $expected{+shift};
}

1;
