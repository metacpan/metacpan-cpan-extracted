#!/usr/bin/perl -w

# For bug: http://hottub.perlfect.com/pipermail/tangram-t2-maintainers/2003-November/000108.html

use lib "t";
use TestNeeds qw(Set::Object);

require "t/Capture.pm";
require "t/misc/RefImage.pm";
use strict;
use Test::More tests => 1;

use Tangram qw(:compat_quiet);
use Tangram::Relational;
use Tangram::Schema;

my $schema = Tangram::Schema->new(
    classes => {
        'Document' => {
            id => 1,
            fields => { ref_image =>
			{ image => { to => [ 'Image' ] } }
                      },
            bases => [ 'Base' ],
            table => 'Document',
                           },
        'Base'     => {
            id       => 2,
            fields   => { },
            abstract => 1,
            table    => 'Base',
                           },
              }
);

my $output = new Capture();
$output->capture_print();
eval { Tangram::Relational->deploy($schema); };
is( $@, "", "schema with new type inheriting from Tangram::Ref doesn't die" );
my $result = $output->release_stdout();
