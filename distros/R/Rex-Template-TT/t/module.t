#!perl

use Test2::V0;
use Test2::Tools::Exports;
use Test2::Tools::LoadModule;

use File::Temp;

use Rex::Commands; # for 'set'
use Rex::Commands::File; # for the 'template' function


load_module_ok 'Rex::Template::TT';
imported_ok qw/&template_toolkit/;


# embedded templates use the default engine when our engine isn't registered
is( template( '@hello_template', name => 'world' ), "Hello, world!");
is( template( '@hi_template',    name => 'world' ), "Hi, world!");

my $template;
$template = 'Hello, [% name %]!';
is( template_toolkit( \$template, { name => 'world' } ), 'Hello, world!');
is( template( \$template, { name => 'world' } ), 'Hello, [% name %]!');

{
    my $f = File::Temp->new;
    print $f 'Hello, [% name %]!';
    $f->close;
    is( template_toolkit( $f->filename, { name => 'world' } ), 'Hello, world!');
    is( template( $f->filename, { name => 'world' } ), 'Hello, [% name %]!');
}

# This code does not throw an exception: it warns using Rex::Logger::info
# so we need to mock that to check for the expected error!
#
#for my $key in qw(GET CALL SET DEFAULT INSERT INCLUDE PROCESS WRAPPER IF UNLESS
#    ELSE ELSIF FOR FOREACH WHILE SWITCH CASE USE PLUGIN FILTER MACRO PERL
#    RAWPERL BLOCK META TRY THROW CATCH FINAL NEXT LAST BREAK RETURN STOP CLEAR
#    TO STEP AND OR NOT MOD DIV END) {
#    like(
#        dies { template_toolkit( \$template, { $key => 1 } ) },
#        qr/.../,
#        'Using a TT keyword as a variable fails'
#        );
#}


done_testing;

# Straight from the docs:

__DATA__
@hello_template
Hello, <%= $name -%>!
@end

@hi_template
Hi, <%= $name -%>!
@end
