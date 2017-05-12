use strict;
use Test::More;

BEGIN {
    eval { require Text::Xslate; };
    plan $@ ? (skip_all => 'no Text::Xslate') : ('no_plan');
}

{
    package Mock::Pages;
    use Sledge::Pages::Compat;
    use Sledge::Template::Xslate ({
      syntax => 'TTerse',
      module => ['Text::Xslate::Bridge::TT2Like'],
    });

    sub create_config { bless {}, 'Mock::Config' }

    package Mock::Config;
    sub tmpl_path { 't/template' }
    sub cache_dir { 't/cache' }

    package Dog;
    use parent qw(Class::Accessor);
    __PACKAGE__->mk_accessors(qw(bark name));

    sub bark { 'Bowwow' }
}

{
    my $dog = Dog->new({ name => 'Spot' });

    my $page = bless {}, 'Mock::Pages';
    $page->load_template('foo');
    $page->tmpl->param(foo => "foo");
    $page->tmpl->param(dog => $dog);

    my $out = $page->tmpl->output;
    like $out, qr/^Foo: foo/m, $out;
    like $out, qr/^Dog bark: Bowwow/m;
    like $out, qr/^Dog name: Spot/m;

    eval { $page->tmpl->add_associate(); };
    isa_ok $@, 'Sledge::Exception::UnimplementedMethod';

    eval { $page->tmpl->associate_namespace(); };
    isa_ok $@, 'Sledge::Exception::UnimplementedMethod';
}
