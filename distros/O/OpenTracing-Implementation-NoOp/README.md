# Perl - OpenTracing Implementation with NoOp

The NoOp Implementation will 'disable' the entire OpenTracing infrastructure by
making almost every method do nothing, or return a 'NoOp' object.

This way, none of the code will break if there is no OpenTracing active.

## LICENSE INFORMATION

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is
provided “as is” and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.
