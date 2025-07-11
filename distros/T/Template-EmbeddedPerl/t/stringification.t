use Test::Most;
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
        return join(' ', @{$self->{_append}});
    }
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
}

done_testing();
