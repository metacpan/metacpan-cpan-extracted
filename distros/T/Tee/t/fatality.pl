#
# This file is part of Tee
#
# This software is Copyright (c) 2006 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
select(STDERR);
$|++;
select(STDOUT);
$|++;
print STDOUT "# STDOUT: hello world\n";
print STDERR "# STDERR: goodbye, cruel world\n";
exit 1;
