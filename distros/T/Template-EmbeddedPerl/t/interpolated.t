use Test::Most;
use Template::EmbeddedPerl;
use utf8;

# test the interpolation mode

ok my $template = Template::EmbeddedPerl->new(
    prepend => 'my ($arg, $arg2, @args) = @_', 
    interpolation => 1
), 'Create Template::EmbeddedPerl object';

{
    my $template_str = '<p>Hello $arg</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render( 'John' );
    is( $output, '<p>Hello John</p>');
}

{
    my $template_str = '<p>Hello $arg, pleased to met you $arg</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render( 'John' );
    is( $output, '<p>Hello John, pleased to met you John</p>');
}

{
    my $obj = Test::Template::EmbeddedPerl::Object->new();
    my $template_str = '<p>Hello $arg->name</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render( $obj );
    is( $output, '<p>Hello John</p>');
}

{
    my $obj = Test::Template::EmbeddedPerl::Object->new();
    my $template_str = '<p>Hello $arg->name()</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render( $obj );
    is( $output, '<p>Hello John</p>');
}

{
    my $obj = Test::Template::EmbeddedPerl::Object->new();
    my $template_str = '<p>Hello $arg->name("Joe")</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render( $obj );
    is( $output, '<p>Hello Joe</p>');
}

{
    my $obj = Test::Template::EmbeddedPerl::Object->new();
    my $template_str = '<p>Hello $arg->chain->chain()->chain("aaa")->name("Joe")</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render( $obj );
    is( $output, '<p>Hello Joe</p>');
}

{
    my $obj = Test::Template::EmbeddedPerl::Object->new();
    my $template_str = '<p>Hello $arg->chain([1,2])->chain($arg2, [3,4])->chain({a=>1})->name("Joe")</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render( $obj, 5 );
    is( $output, '<p>Hello Joe</p>');
    is_deeply( $obj->{collect}, [
    [
        1,
        2,
    ],
    5,
    [
        3,
        4,
    ],
    {
        a => 1,
    },
    ]);
}

{
    my $obj = Test::Template::EmbeddedPerl::Object->new();
    my $template_str = '<p>Hello $arg->chain([1,2], sub {1})->name("Joe")</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render( $obj, 5 );
    is( $output, '<p>Hello Joe</p>');
    is_deeply( $obj->{collect}, [
        [
            1,
            2,
        ],
        1,
    ]);
}

{
    my $obj = Test::Template::EmbeddedPerl::Object->new();
    my $template_str = '<p>Hello $arg->chain($arg2->[1])->name("Joe")</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render( $obj, [1,2] );
    is( $output, '<p>Hello Joe</p>');
    is_deeply( $obj->{collect}, [2]);
}

{
    my $obj = Test::Template::EmbeddedPerl::Object->new();
    my $template_str = '<p>Hello $arg->chain($arg2->{name})->name("Joe")</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render( $obj, +{name=>'aa'} );
    is( $output, '<p>Hello Joe</p>');
    is_deeply( $obj->{collect}, ['aa']);
}

{
    my $template_str = '<p>Hello $args[0]</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render(1, 2, 'Jane');
    is( $output, '<p>Hello Jane</p>');
}

{
    my $template_str = '<p>Hello $arg->[1]</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render( [1,"Joe"] );
    is( $output, '<p>Hello Joe</p>');
}

{
    my $template_str = '<p>Hello $arg->{name}</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render({name=>'Jane'});
    is( $output, '<p>Hello Jane</p>');
}

{
    my $template_str = '<p>Hello $arg, you are $args[1] years old</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render( 'John', 'a', 1, 55 );
    is( $output, '<p>Hello John, you are 55 years old</p>');
}

{
    ok my $template = Template::EmbeddedPerl->new(
        prepend => 'my (%args) = @_', 
        interpolation => 1
    ), 'Create Template::EmbeddedPerl object';
    my $template_str = '<p>Hello $args{name}</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render(name=>'Jane');
    is( $output, '<p>Hello Jane</p>');
}

{
    my $template_str = '<p>Hello $arg->{name}[1]</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render({name=>[1,'Jane']});
    is( $output, '<p>Hello Jane</p>');
}

{
    my $template_str = '<p>Hello $arg->{name}[1]{name}</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render({name=>[1,{name=>'Jane'}]});
    is( $output, '<p>Hello Jane</p>');
}

{
    my $obj = Test::Template::EmbeddedPerl::Object->new();
    my $template_str = '<p>Hello $arg->{name}[1]->name</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render({name=>[1,$obj]});
    is( $output, '<p>Hello John</p>');
}

{
    my $obj = Test::Template::EmbeddedPerl::Object->new();
    my $template_str = '<p>Hello $arg->{name}[1]->name("Joe")</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render({name=>[1,$obj]});
    is( $output, '<p>Hello Joe</p>');
}

{
    my $obj = Test::Template::EmbeddedPerl::Object->new();
    my $template_str = '<p>Hello $arg->{name}[$arg2->[1]]->name("Joe")</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render({name=>[1,$obj]},[2,1]);
    is( $output, '<p>Hello Joe</p>');
}

{
    my $obj = Test::Template::EmbeddedPerl::Object->new();
    my $template_str = '<p>Hello $arg->{name}[$arg2->()]->name("Joe")</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render({name=>[1,$obj]},sub {1});
    is( $output, '<p>Hello Joe</p>');
}

{
    my $template_str = '<p>Hello \$arg</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render('John');
    is( $output, '<p>Hello $arg</p>');
}

{
    my $template_str = '<p>Hello $My::Package::var</p>';
    my $compiled     = $template->from_string($template_str);
    {
        no strict 'refs';
        $My::Package::var = 'World';
    }
    my $output = $compiled->render();
    is( $output, "<p>Hello ${My::Package::var}</p>");
}

{
    my $template_str = '<p>Hello $My::Package::obj->name</p>';
    my $compiled     = $template->from_string($template_str);
    {
        no strict 'refs';
        $My::Package::obj = Test::Template::EmbeddedPerl::Object->new();
    }
    my $output = $compiled->render();
    is( $output, "<p>Hello @{[ $My::Package::obj->name ]}</p>");
}

{
    my $template_str = '<p>$arg$arg2</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render('Hello', 'World');
    is( $output, '<p>HelloWorld</p>');
}

{
    my $template_str = '<p>Hello $arg->name($arg2 ? "Yes" : "No")</p>';
    my $compiled     = $template->from_string($template_str);
    my $obj          = Test::Template::EmbeddedPerl::Object->new();
    $obj->{greet}    = sub { my ($self, $msg) = @_; return $msg; };
    my $output       = $compiled->render($obj, 1);
    is( $output, '<p>Hello Yes</p>');
}

{
    my $template_str = '<p>Hello "$arg"</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render('John');
    is( $output, '<p>Hello "John"</p>');
}

{
    my $template_str = '<p>Result: $arg->compute(sub { $_[0] * 2 })</p>';
    my $compiled     = $template->from_string($template_str);
    my $obj          = Test::Template::EmbeddedPerl::Object->new();
    my $output       = $compiled->render($obj);
    is( $output, '<p>Result: 10</p>');
}

{
    my $template_str = '<p>Hello $arg->{ $arg2 }</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render({ name => 'Jane' }, 'name');
    is( $output, '<p>Hello Jane</p>');
}

{
    my $template_str = '<p>Hello $arg->$arg2</p>';
    my $compiled     = $template->from_string($template_str);
    my $obj          = Test::Template::EmbeddedPerl::Object->new();
    my $output       = $compiled->render($obj, 'name');
    is( $output, '<p>Hello John</p>');
}

{
    ok my $template = Template::EmbeddedPerl->new(
        prepend => 'my ($арг) = @_', 
        interpolation => 1
    ), 'Create Template::EmbeddedPerl object';

    my $template_str = '<p>Hello $арг</p>'; # 'арг' is 'arg' in Cyrillic
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render('John');
    is( $output, '<p>Hello John</p>');
}


{
    my $template_str = '<p>Hello ${arg}</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render('John');
    is( $output, '<p>Hello John</p>');
}

{
    my $template_str = '<p>Hello ${arg}Nap</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render('John');
    is( $output, '<p>Hello JohnNap</p>');
}

{
    my $template_str = '<p>Hello ${arg}$arg2</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render('John', 'Nap');
    is( $output, '<p>Hello JohnNap</p>');
}

{
    my $obj = Test::Template::EmbeddedPerl::Object->new();
    my $template_str = '<p>Hello $arg'."\n".'->{name}['."\n".'$arg2->()]->'."\n".'name("Joe")</p>';
    my $compiled     = $template->from_string($template_str);
    my $output       = $compiled->render({name=>[1,$obj]},sub {1});
    is( $output, '<p>Hello Joe</p>');
}

{
    my $template_str = '<p>Result: $arg->compute(sub {'."\n".' $_[0] * 2 })</p>';
    my $compiled     = $template->from_string($template_str);
    my $obj          = Test::Template::EmbeddedPerl::Object->new();
    my $output       = $compiled->render($obj);
    is( $output, '<p>Result: 10</p>');
}

{
    my $template_str = '\
    <p>Result: $arg->compute(sub {
        my $arg = shift;
        return $arg * 5;
    })</p>';
    my $compiled     = $template->from_string($template_str);
    my $obj          = Test::Template::EmbeddedPerl::Object->new();
    my $output       = $compiled->render($obj);
    is( $output, '    <p>Result: 25</p>');
}

{
    my $template_str = '\
    <p>\
        %= $arg->compute(sub {\
            % my $value = shift\
            % $value = $value * 5\
            <div>$value</div>\
        % })\
    </p>';
    my $compiled     = $template->from_string($template_str);
    my $obj          = Test::Template::EmbeddedPerl::Object->new();
    my $output       = $compiled->render($obj);
    is( $output, '    <p>            <div>25</div>    </p>');
}

{
    my $template_str = '\
    <p>\
        %= $arg->two(sub {\
            <div>1</div>\
        % }, sub {\
            <div>2</div>\
        % })\
    </p>';
    my $compiled     = $template->from_string($template_str);
    my $obj          = Test::Template::EmbeddedPerl::Object->new();
    my $output       = $compiled->render($obj);
    is( $output, '    <p>CB1:            <div>1</div>CB2:            <div>2</div>    </p>');
}

{
    my $template_str = '\
    <p>\
        %= $arg->two(sub {\
            <div>1</div>
        <% }
        ,
        sub { %>\
            <div>2</div>\
        % })\
    </p>';
    my $compiled     = $template->from_string($template_str);
    my $obj          = Test::Template::EmbeddedPerl::Object->new();
    my $output       = $compiled->render($obj);
    is( $output, "    <p>CB1:            <div>1</div>\n        CB2:            <div>2</div>    </p>");
}

done_testing();

package Test::Template::EmbeddedPerl::Object;

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

sub chain {
    my ($self) = shift;
    push @{$self->{collect}}, map { ref $_ eq 'CODE' ? $_->(): $_ } @_;
    return $self;
}

sub name {
    my ($self, $name) = @_;
    return $name || 'John';
}

sub compute {
    my ($self, $code) = @_;
    return $code->(5);
}

sub two {
    my ($self, $cb1, $cb2) = @_;
    return 'CB1:'. $cb1->() .'CB2:'. $cb2->();
}

__END__
