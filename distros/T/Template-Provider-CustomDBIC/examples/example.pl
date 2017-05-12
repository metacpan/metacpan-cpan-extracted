#!/usr/bin/perl -wT

use My::CustomDBIC::Schema;
use Template;
use Template::Provider::CustomDBIC;

my $schema = My::CustomDBIC::Schema->connect(
    $dsn, $user, $password, \%options
);
my $resultset = $schema->resultset('Template');

my $template = Template->new({
    LOAD_TEMPLATES => [
        Template::Provider::CustomDBIC->new({
            RESULTSET => $resultset,
            # Other template options like COMPILE_EXT...
        }),
    ],
});

# Process the template 'my_template' from resultset 'Template'.
$template->process('my_template');
# Process the template 'other_template' from resultset 'Template'.
$template->process('other_template');


1;
