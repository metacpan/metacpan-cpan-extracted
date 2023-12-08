#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec::Functions qw(catfile);
use File::Temp qw(tempfile tempdir);
use IO::Barf qw(barf);
use SysV::Init::Service;

# Temporary directory.
my $temp_dir = tempdir('CLEANUP' => 1);

# Create fake service.
my $fake = <<'END';
#!/bin/sh
echo "[ ok ] Usage: /fake {start|stop|status}."
END

# Save to file.
my $fake_file = catfile($temp_dir, 'fake');
barf($fake_file, $fake);

# Chmod.
chmod 0755, $fake_file;

# Service object.
my $obj = SysV::Init::Service->new(
        'service' => 'fake',
        'service_dir' => $temp_dir,
);

# Get commands.
my @commands = $obj->commands;

# Print commands to output.
map { print $_."\n"; } @commands;

# Clean.
unlink $fake_file;

# Output:
# start
# stop
# status