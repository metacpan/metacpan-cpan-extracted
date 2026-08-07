#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Template::Stencil;

plan skip_all => 'Eshu required for pretty => 1'
    unless eval { require Eshu; 1 };

my $messy = "<div>\n\n\n   \n<p>{% v %}</p>\n\t\n</div>";
my %data  = (v => 'x');

# pretty pipeline = strip blank lines, then Eshu->indent_html.
my $expected = do {
    my $plain = Template::Stencil->new->render($messy, \%data);
    (my $dense = $plain) =~ s/^[ \t\r]*\n//gm;
    Eshu->indent_html($dense);
};

# Engine-level option.
{
    my $s = Template::Stencil->new(pretty => 1);
    is($s->render($messy, \%data), $expected, 'pretty on new');
    unlike($s->render($messy, \%data), qr/\n[ \t]*\n/,
           'no blank lines survive');
}

# Per-render override in both directions.
{
    my $on  = Template::Stencil->new;
    is($on->render($messy, \%data, { pretty => 1 }), $expected,
       'per-render opt-in');
    my $off = Template::Stencil->new(pretty => 1);
    is($off->render($messy, \%data, { pretty => 0 }),
       Template::Stencil->new->render($messy, \%data),
       'per-render opt-out');
}

# Plays with wrapper and stays bytes.
{
    require File::Temp;
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    open my $fh, '>', "$dir/w.tmpl" or die $!;
    print $fh "<main>\n\n{% content %}\n\n</main>";
    close $fh;
    my $s = Template::Stencil->new(template_dir => $dir,
                                   wrapper => 'w.tmpl', pretty => 1);
    my $out = $s->render('<p>{% v %}</p>', \%data);
    like($out, qr/<main>\n\t<p>x<\/p>\n<\/main>/, 'wrapper prettified');
    ok(!utf8::is_utf8($out), 'still bytes by default');
}

# The output is stable across renders (cache + pretty interplay).
{
    my $s = Template::Stencil->new(pretty => 1);
    my $a = $s->render($messy, \%data);
    my $b = $s->render($messy, \%data);
    is($a, $b, 'stable across renders');
}

done_testing;
