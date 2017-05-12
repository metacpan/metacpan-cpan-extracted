#!/usr/bin/perl -wT

use My::DBIC::Schema;
use Template;
use Template::Provider::DBIC;

my $schema = My::DBIC::Schema->connect(
    $dsn, $user, $password, \%options
);
my $resultset = $schema->resultset('Template');

my $template = Template->new({
    LOAD_TEMPLATES => [
        Template::Provider::DBIC->new({
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
