use lib 'inc';

{
    use Test::More;
    eval "use XML::Simple; 1" or
        plan skip_all => 'XML::Simple required';
}

use TestML;

TestML->new(
    testml => do { local $/; <DATA> },
    bridge => 'main',
)->run;

{
    package main;
    use base 'TestML::Bridge';
    use TestML::Util;
    use Template::Toolkit::Simple;

    sub render_template {
        my ($self, $context) = @_;
        my $t = -d 't' ? 't' : 'test';
        return str tt
            ->post_chomp
            ->path("$t/template")
            ->data("$t/render.xml")
            ->render($context->value);
    }
}

__DATA__
%TestML 0.1.0

Plan = 1;

*template.render_template == *result;

=== Simple Render
--- template: letter.tt
--- result
Hi Löver,

Have a nice day.

Smööches, Ingy
