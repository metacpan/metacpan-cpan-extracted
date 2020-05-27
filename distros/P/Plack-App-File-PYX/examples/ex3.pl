#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp;
use IO::Barf;
use Plack::App::File::PYX;
use Plack::Runner;

# Temporary file with PYX.
my $temp_pyx_file = File::Temp->new->filename;

# PYX file.
my $pyx = <<'END';
?xml version="1.0"
(svg
Axmlns http://www.w3.org/2000/svg
(rect
Ax 80
Ay 60
Awidth 250
Aheight 250
Arx 20
Astyle fill:#ff0000; stroke:#000000; stroke-width:2px;
)rect
(rect
Ax 140
Ay 120
Awidth 250
Aheight 250
Arx 40
Astyle fill:#0000ff; stroke:#000000; stroke-width:2px; fill-opacity:0.7;
)rect
)svg
END
barf($temp_pyx_file, $pyx);

# Run application with one PYX file.
my $app = Plack::App::File::PYX->new(
        'content_type' => 'image/svg+xml',
        'file' => $temp_pyx_file,
        'indent' => 'Tags::Output::Indent',
)->to_app;
Plack::Runner->new->run($app);

# Output:
# HTTP::Server::PSGI: Accepting connections at http://0:5000/

# > curl http://localhost:5000/
# <?xml version="1.0"?>
# <svg xmlns="http://www.w3.org/2000/svg">
#   <rect x="80" y="60" width="250" height="250" rx="20" style=
#     "fill:#ff0000; stroke:#000000; stroke-width:2px;">
#   </rect>
#   <rect x="140" y="120" width="250" height="250" rx="40" style=
#     "fill:#0000ff; stroke:#000000; stroke-width:2px; fill-opacity:0.7;">
#   </rect>
# </svg>