#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 6;

use lib qw( t/lib );
use TemplateProviderCustomDBICTest;

use Template;
use Template::Provider::CustomDBIC;


my $schema    = TemplateProviderCustomDBICTest->init_schema();
my $resultset = $schema->resultset('Template');


# Test Template::Provider::CustomDBIC with a SCHEMA.
my $schema_provider = Template::Provider::CustomDBIC->new({
                          SCHEMA => $schema,
                      });
isa_ok( $schema_provider, 'Template::Provider::CustomDBIC' );
isa_ok( $schema_provider, 'Template::Provider'       );

my $template2 = Template->new({ LOAD_TEMPLATES => [ $schema_provider ] });

my $schema_test;
$template2->process( 'Template/test', {}, \$schema_test );
is( $schema_test,
    'This test was a success',
    'Parsed template by SCHEMA' );


# Test Template::Provider::CustomDBIC with a RESULTSET.
my $resultset_provider = Template::Provider::CustomDBIC->new({
                             RESULTSET => $resultset,
                         });
isa_ok( $resultset_provider, 'Template::Provider::CustomDBIC' );
isa_ok( $resultset_provider, 'Template::Provider'       );

my $template = Template->new({ LOAD_TEMPLATES => [ $resultset_provider ] });

my $resultset_test;
$template->process( 'test', {}, \$resultset_test );
is( $resultset_test,
    'This test was a success',
    'Parsed template by RESULTSET' );


1;
