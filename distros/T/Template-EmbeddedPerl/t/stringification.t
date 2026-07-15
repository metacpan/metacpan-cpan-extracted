use Test::Most;
use File::Spec;
use Template::EmbeddedPerl;

{
    package Template::EmbeddedPerl::Stringification;

    sub new {
        my ($class) = @_;
        return bless {_append => []}, $class;
    }

    sub method1 {
        my ($self, $arg) = @_;
        push @{$self->{_append}}, $arg;
        return $self;
    }

    sub method2 {
        my ($self, $arg) = @_;
        push @{$self->{_append}}, $arg;
        return $self;
    }

    sub to_safe_string {
        my ($self, $view) = @_;
        $Template::EmbeddedPerl::Stringification::receiver = $view;
        return join(' ', @{$self->{_append}});
    }
}

{
    package Local::Stringification::View;
    use Moo;

    has title => (is => 'ro', required => 1);

    sub template { 'components/navigation' }
}

ok my $template = Template::EmbeddedPerl->new(interpolation => 1, auto_escape => 1),
    'Create Template::EmbeddedPerl object';

# Test 1: Basic
{
    my $object = Template::EmbeddedPerl::Stringification->new();
    my $string = 'Hello, <%= $_[0]->method1("John")->method2("Doe") %>!';
    my $compiled = $template->from_string($string);
    my $output   = $compiled->render($object);

    is($output, 'Hello, John Doe!', 'Basic rendering via to_safe_string');
    is(
        $Template::EmbeddedPerl::Stringification::receiver,
        $template,
        'legacy rendering passes the engine to to_safe_string',
    );
}

{
    my $object = Template::EmbeddedPerl::Stringification->new()
        ->method1('Typed')->method2('View');
    my $view = Local::Stringification::View->new(title => $object);
    my $typed_engine = Template::EmbeddedPerl->new(
        directories => [File::Spec->catdir(qw(t templates views))],
        auto_escape => 1,
    );

    is(
        $typed_engine->render_view($view),
        "<nav>Typed View</nav>\n",
        'typed rendering stringifies expression values',
    );
    is(
        $Template::EmbeddedPerl::Stringification::receiver,
        $view,
        'typed rendering passes the active view to to_safe_string',
    );
}

done_testing();
