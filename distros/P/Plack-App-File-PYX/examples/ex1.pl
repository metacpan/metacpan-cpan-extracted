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
(html
(head
(title
-Title
)title
)head
(body
(div
-Hello world
)div
)body
)html
END
barf($temp_pyx_file, $pyx);

# Run application with one PYX file.
my $app = Plack::App::File::PYX->new('file' => $temp_pyx_file)->to_app;
Plack::Runner->new->run($app);

# Output:
# HTTP::Server::PSGI: Accepting connections at http://0:5000/

# > curl http://localhost:5000/
# <html><head><title>Title</title></head><body><div>Hello world</div></body></html>