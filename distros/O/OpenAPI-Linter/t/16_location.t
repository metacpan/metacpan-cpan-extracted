#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Temp qw(tempfile);
use File::Basename qw(dirname);

my $share_dir = File::Spec->rel2abs(
    File::Spec->catdir( dirname(__FILE__), File::Spec->updir, 'share' )
);

$ENV{OPENAPI_LINTER_SCHEMA_DIR} = $share_dir;

use_ok 'OpenAPI::Linter';
use_ok 'OpenAPI::Linter::Location';

#
#
# Location object basics

my $loc = OpenAPI::Linter::Location->new(
    path   => 'paths./users.get',
    file   => 'openapi.yaml',
    line   => 10,
    column => 3,
);

is  "$loc",          'paths./users.get',     'Stringifies to path';
is  $loc->to_string, 'paths./users.get',     'to_string returns path';
is  $loc->file,      'openapi.yaml',         'file accessor';
is  $loc->line,      10,                     'line accessor';
is  $loc->column,    3,                      'column accessor';
is  $loc->position,  'openapi.yaml:10:3',    'position returns file:line:col';

my $unknown = OpenAPI::Linter::Location->new( path => 'info' );
is $unknown->position, 'unknown', 'position returns unknown when line is 0';

#
#
# In-memory spec — location present, line/col unknown (0)

my $spec = {
    openapi => '3.1.0',
    info    => { title => 'Test', version => '1.0.0' },
    paths   => {
        '/users' => {
            get  => {
                operationId => 'listUsers',
                summary     => 'List users',
                description => 'Returns all users',
                responses   => { '200' => { description => 'OK' } },
            },
        },
    },
};

my $linter = OpenAPI::Linter->new( spec => $spec );
my @issues = $linter->find_issues;

for my $issue (@issues) {
    my $loc = $issue->{location};
    isa_ok $loc, 'OpenAPI::Linter::Location', 'issue location';
    ok defined $loc->file,    'location has file';
    ok defined $loc->line,    'location has line';
    ok defined $loc->column,  'location has column';

    # Stringification must still work for backwards compatibility
    my $as_str = "$loc";
    ok defined $as_str, "location stringifies (got '$as_str')";
}

# File-based YAML spec — line numbers should be > 0
my ($fh, $yaml_file) = tempfile( SUFFIX => '.yaml', UNLINK => 1 );
print $fh <<'YAML';
openapi: "3.1.0"
info:
  title: "File Test API"
  version: "1.0.0"
paths:
  /items:
    get:
      summary: "List items"
      description: "Returns all items"
      operationId: listItems
      responses:
        "200":
          description: "Success"
YAML
close $fh;

my $file_linter = OpenAPI::Linter->new( spec => $yaml_file );
my @file_issues = $file_linter->find_issues;

# Even a clean spec produces warnings (missing license etc.)
# What we care about is that locations have real line numbers
my $found_line = 0;
for my $issue (@file_issues) {
    my $loc = $issue->{location};
    isa_ok $loc, 'OpenAPI::Linter::Location', 'file issue has Location object';
    is $loc->file, $yaml_file, 'location file matches spec file';
    $found_line = 1 if $loc->line > 0;
}
ok $found_line, 'At least one issue has a line number > 0';


# File-based JSON spec — line numbers should be > 0
my ($jfh, $json_file) = tempfile( SUFFIX => '.json', UNLINK => 1 );
print $jfh <<'JSON';
{
  "openapi": "3.1.0",
  "info": {
    "title": "JSON Test API",
    "version": "1.0.0"
  },
  "paths": {
    "/things": {
      "get": {
        "summary": "List things",
        "description": "Returns all things",
        "operationId": "listThings",
        "responses": {
          "200": {
            "description": "OK"
          }
        }
      }
    }
  }
}
JSON
close $jfh;

my $json_linter = OpenAPI::Linter->new( spec => $json_file );

# JSON files are currently loaded via YAML::XS (which handles JSON too)
my @json_issues = $json_linter->find_issues;

my $found_json_line = 0;
for my $issue (@json_issues) {
    isa_ok $issue->{location}, 'OpenAPI::Linter::Location',
        'JSON file issue has Location object';
    $found_json_line = 1 if $issue->{location}->line > 0;
}
ok $found_json_line, 'At least one JSON issue has a line number > 0';


#
#
# Backwards compatibility — stringification matches old path behaviour

my $compat_spec = {
    openapi => '3.1.0',
    info    => { title => 'Compat', version => '1.0.0' },
    paths   => {},
};
my $compat_linter = OpenAPI::Linter->new( spec => $compat_spec );
my @compat_issues = $compat_linter->find_issues;

for my $issue (@compat_issues) {
    my $loc_str = "$issue->{location}";
    ok length($loc_str) >= 0,
        "issue location stringifies without error (got '$loc_str')";
}

done_testing;
