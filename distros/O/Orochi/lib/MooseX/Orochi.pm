package MooseX::Orochi;
use Moose qw(confess);
use Moose::Exporter;
use Orochi;

Moose::Exporter->setup_import_methods(
    with_meta => [ qw(bind_constructor inject) ],
    as_is     => [ qw(bind_value) ],
);

sub init_meta {
    shift;
    my %args = @_;

    my $meta = Moose::Util::find_meta( $args{for_class} );

    if ($meta->isa('Moose::Meta::Role')) {
        $meta = Moose::Meta::Role
            ->initialize('MooseX::Orochi::Meta::Class')
            ->apply( $meta )
        ;
    } else {
        Moose::Util::MetaRole::apply_metaroles(
            for             => $args{for_class},
            class_metaroles => {
                class => [ 'MooseX::Orochi::Meta::Class' ],
            },
        );
    }
    $meta;
}

sub bind_constructor ($;%) {
    my ($meta, $path, %args) = @_;
    $meta->bind_path($path);

    my $class = $args{injection_class} || 'Constructor';
    if ($class !~ s/^\+//) {
        $class = "Orochi::Injection::$class";
    }

    if (! Class::MOP::is_class_loaded( $class ) ) {
        Class::MOP::load_class($class);
    }

    if (! $class->isa('Orochi::Injection::Constructor')) {
        confess "$class is not a Orochi::Injection::Constructor subclass";
    }
    $meta->bind_injection( $class->new(%args, class => $meta->name) );
}

sub bind_value ($) {
    my $bind_to = (@_ == 1 && ref $_[0] ne 'ARRAY') ?
        [ $_[0] ] : $_[0];
    return Orochi::Injection::BindValue->new(bind_to => $bind_to);
}

sub inject ($$) {
    my ($meta, $path, $inject) = @_;
    $meta->add_injections( $path => $inject );
}

1;

__END__

=head1 NAME

MooseX::Orochi - Annotated Your Moose Classes With Orochi

=head1 SYNOPSIS

    package MyApp::MyClass;
    use Moose;
    use MooseX::Orochi;

    bind_constructor '/myapp/myclass' => (
        args => {
            arg1 => bind_value '/myapp/some/dep1',
            arg2 => bind_value '/myapp/some/dep2',
        }
    );

    # you can also inject random things
    inject '/foo/bar/baz' => Orochi::Injection::Constructor->new(
        class => 'FooBar',
        args  => { ... }
    );

    has arg1 => (...);
    has arg2 => (...);

    # Then, somewhere in your main code...

    my $c = Orochi->new();
    $c->inject_class( 'MyApp::MyClass' );

    my $object = $c->get( '/myapp/myclass' );

=head1 DESCRIPTION

MooseX::Orochi is a transparent add-on to your Moose-based classes that allows create a Depdency Injection Containers. If you don't know what that is, it basically allows you to define and assemble a set of objects that depend on eachother with no external configuration required.

With MooseX::Orochi, all you really need to do is

    1. Build a set of objects with MooseX::Orochi annotations
    2. use Orochi->inject_class() to inject your definitions
    3. use Orochi->get() to access the resulting objects.

=head1 PROVIDED DSL

=over 4

=item bind_constructor $path => %injection_args

Creates a Orochi::Injection::Constructor (or subclass thereof)

=item bind_value $path

Returns a Orochi::Injection::BindValue object, which will materialize when
the containing Injection is expanded.

=item inject $path => $injection

Injects the given injection.

=back

=head1 ANNOTATIONS WITH MooseX::Orochi

Suppose you have a dependency graph like the following:

  MyApp ---> MyApp::Model::Foo ---> MyApp::Schema ---> DBI Args
                               |
                               ---> MyApp::Logger ---> File Name

If you're building everything based on moose from scratch, you will define this dependency like the following. First, MyApp:

  package MyApp;
  use Moose;
  use MooseX::Orochi;

  has 'foo' => (
    is => 'ro',
    isa => 'MyApp::Model::Foo'
  );

  bind_constructor 'myapp' => (
    args => {
      foo => bind_value 'myapp/model/foo'
    }
  );


Notice the use of MooseX::Orochi, and the calls to C<bind_constructor>. It
tells us that an instance of MyApp can be retrieved by the name 'myapp'

  $c->get('myapp');

and that the value for argument C<foo> should be taken from another
injected resource named 'myapp/model/foo'

  MyApp->new(foo => $c->get('myapp/model/foo'));

If you were to use Setter injection instead, then it will lead to Orochi calling Orochi::Injection::Setter, which in turn will call MyApp's constructor, and setter(s) like so:

  bind_constructor 'myapp' => (
    injection_type => 'Setter',
    setter_params => {
      foo => bind_value 'myapp/model/foo'
    }
  );

  # above will trigger the following code:
  my $app = MyApp->new();
  $app->foo($c->get('myapp/model/foo'));

The rest of the classes works mostly the same way. Here's MyApp::Model::Foo, and MyApp::Logger:

  package MyApp::Model::Foo;
  use Moose;
  use MooseX::Orochi;

  has 'schema' => (
    is => 'ro',
    isa => 'MyApp::Schema',
  );

  bind_constructor 'myapp/model/foo' => (
    args => {
      schema => bind_value 'myapp/schema',
      logger => bind_value 'myapp/logger',
    }
  );

  package MyApp::Logger;
  use Moose;
  use MooseX::Orochi;
  use MooseX::Types::Path::Class;

  has 'filename' => (
    is => 'ro',
    isa => 'Path::Class::File',
    coerce => 1
  );

  bind_constructor 'myapp/logger' => (
    args => {
      filename => bind_value 'myapp/logger/filename'
    }
  );

MyApp::Schema is a bit different, in that it is DBIx::Class::Schema based, and you won't be calling new() to instantiate it (you'd call C<connection()>), and you don't pass a name => value pair (you'd pass @connect_info).

  package MyApp::Schema;
  use Moose;
  use MooseX::Orochi;
  extends 'DBIx::Class::Schema';

  bind_contructor 'schema/master' => (
    args        => bind_value 'myapp/schema/connect_info',
    deref_args  => 1,
    constructor => 'connection'
  );

Here, we declare that MyApp::Schema will use myapp/schema/connect_info as its
arguments (which will be de-referenced when passed to the constructor), and that
we should use the method named 'connection' as the constructor.

The value to 'myapp/schema/connect_info' needs to be declared else where:

  my $c = Orochi->new();
  $c->inject_literal(
    'myapp/schema/connect_info' => [ 'dbi:mysql:dbname=foo', .... ] );

Finally, we need to put everything together by registering these classes to our Orochi instance:

  my $c = Orochi->new();
  $c->inject_literal(
    'myapp/logger/filename' => '/path/to/file.txt');
  $c->inject_literal(
    'myapp/schema/connect_info' => [ 'dbi:mysql:dbname=foo', .... ] );
  $c->inject_class($_) for qw(
    MyApp::Logger
    MyApp::Schema
    MyApp::Model::Foo
    MyApp
  );
  # or $c->inject_namespace('MyApp');

  my $app = $c->get('myapp');

There are sometimes those modules that you just can touch from outside.
In those cases, you will have to provide the objects yourself:

  $c->inject('/path/to/another/dependency' => 
    $c->construct( sub { ... } ) );

=head1 SUBCLASS

Once you use MooseX::Orochi, every subclass can re-use the bind instructions.

    package MyApp;
    use Moose;
    use MooseX::Orochi;

    bind_constructor 'myapp' => ( ... );


    package MyApp::Extended;
    use Moose;

    extends 'MyApp';

In the above case, unless you explicitly override the bind instructions
in MyApp::Extended, you can inject MyApp::Extended and expect it to be
available at

    $c->get('myapp');

=head1 TODO

Documentation. Samples. Tests.

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
