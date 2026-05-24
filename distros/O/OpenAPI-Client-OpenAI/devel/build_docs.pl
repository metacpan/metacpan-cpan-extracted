#!/usr/bin/env perl
use 5.026;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";

use Path::Tiny;
use OpenAPI::Client::OpenAI::DocGen;

my $spec_file  = $ARGV[0] // 'share/openapi.yaml';
my $output_dir = $ARGV[1] // '.';

OpenAPI::Client::OpenAI::DocGen->new(
    spec_file  => $spec_file,
    output_dir => $output_dir,
)->run;

say "Wrote POD under $output_dir/lib/OpenAPI/Client/OpenAI/";
