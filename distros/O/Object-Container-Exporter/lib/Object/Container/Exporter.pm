package Object::Container::Exporter;
use strict;
use warnings;
use parent 'Class::Singleton';
use Class::Load ();

our $VERSION = '0.03';

sub import {
    my ($class, @opts) = @_;

    my $caller = caller;

    if (scalar(@opts) == 1 and ($opts[0]||'') =~ /^-base$/i) {

        {
            no strict 'refs';
            push @{"${caller}::ISA"}, $class;
        }

        for my $func (qw/register register_namespace register_default_container_name/) {
            my $code = $class->can($func);
            no strict 'refs'; ## no critic.
            *{"$caller\::$func"} = sub { $code->($caller, @_) };
        }

        return;
    }
    elsif(scalar(@opts) >= 1 and ($opts[0]||'') !~ /^-no_export/i) {
        $class->_export_functions($caller => @opts);
    }

    unless (($opts[0]||'') =~ /^-no_export$/i) {
        $class->_export_container($caller);
    }
}

sub base_name {
    my $class = shift;
    $class = ref $class unless $class;
    (my $base_name = $class) =~ s/(::.+)?$//g;
    $base_name;
}

sub load_class {
    my ($class, $pkg) = @_;
    Class::Load::load_class($pkg);
}

sub _camelize {
    my $s = shift;
    join('', map{ ucfirst $_ } split(/(?<=[A-Za-z])_(?=[A-Za-z])|\b/, $s));
}

sub _export_functions {
    my ($self, $caller, @export_names) = @_;

    $self = $self->instance unless ref $self;

    for my $name (@export_names) {

        if ($caller->can($name)) { die qq{can't export $name for $caller. $name already defined in $caller.} }

        my $code = $self->{_register_namespace}->{$name} || sub {
            my $target = shift;
            my $container_name = join '::', $self->base_name, _camelize($name), _camelize($target);
            return $target ? $self->get($container_name) : $self;
        };

        {
            no strict 'refs';
            *{"${caller}::${name}"} = $code;
        }
    }
}

sub _export_container {
    my ($class, $caller) = @_;

    my $container_name = $class->instance->{_default_container_name} || 'container';

    if ($caller->can($container_name)) { die qq{can't export '$container_name' for $caller. '$container_name' already defined in $caller.} }
    my $code = sub {
        my $target = shift;
        return $target ? $class->get($target) : $class;
    };
    {
        no strict 'refs';
        *{"${caller}::${container_name}"} = $code;
    }
}

sub register {
    my ($self, $class, @init_opt) = @_;
    $self = $self->instance unless ref $self;

    my $initializer;
    if (@init_opt == 1 and ref($init_opt[0]) eq 'CODE') {
        $initializer = $init_opt[0];
    }
    else {
        $initializer = sub {
            Class::Load::load_class($class);
            $class->new(@init_opt);
        };
    }

    $self->{_registered_classes}->{$class} = $initializer;
}

sub register_namespace {
    my ($self, $method, $pkg) = @_;
    $self = $self->instance unless ref $self;
    my $class = ref $self;

    $pkg = _camelize($pkg);
    my $code = sub {
        my $target = shift;
        my $container_name = join '::', $pkg, _camelize($target);
        Class::Load::load_class($container_name);
        return $target ? $class->get($container_name) : $class;
    };

    $self->{_register_namespace}->{$method} = $code;
}

sub register_default_container_name {
    my ($self, $name) = @_;
    $self = $self->instance unless ref $self;
    $self->{_default_container_name} = $name;
}

sub get {
    my ($self, $class) = @_;
    $self = $self->instance unless ref $self;

    my $obj = $self->{_inflated_classes}->{$class} ||= do {
        my $initializer = $self->{_registered_classes}->{$class};
        $initializer ? $initializer->($self) : ();
    };


    return $obj if $obj;

    Class::Load::load_class($class);
    $obj = $self->{_inflated_classes}->{$class} = $class->new;
    $obj;
}

sub remove {
    my ($self, $class) = @_;
    $self = $self->instance unless ref $self;
    delete $self->{_inflated_classes}->{$class};
}

1;
__END__

=head1 NAME

Object::Container::Exporter - strong shortcuts to your classes.

=head1 SYNOPSIS

    #your application tree
    `-- MyApp
        |-- Api
        |   |-- Form
        |   |   `-- Foo.pm
        |   `-- User.pm
        |-- Container.pm
        `-- Foo.pm
    
    #your sub class
    package MyApp::Container;
    use Object::Container::Exporter -base;
    
    register_namespace form => 'Mock::Api::Form';
    
    register 'foo' => sub {
        my $self = shift;
        $self->load_class('Mock::Foo');
        Mock::Foo->new;
    };
    
    #your main script
    use MyApp::Container qw/api form/;
    
    container('foo')->say;
    
    my $row = api('User')->fetch;
    
    form('foo')->fillin($row->get_columns);

=head1 DESCRIPTION

Object::Container::Exporter is object container like L<Object::Container>.
The difference is that it has bulk registering the class object in your indeicate directory with container.

=head1 Bulk registering your indicated directory's class objects

Object::Container::Exporter provide the shortcut function to call the class object in your application' second directory.There is no 'use' and 'new' in your main script to access your class object.In this case, you must indicate the decamelized directory name as export function.

Examples are:

    #your application tree

    `-- MyApp
        |-- Api
        |   `-- Password.pm
        `-- Container.pm

    #your sub class
    package MyApp::Container;
    use Object::Container::Exporter -base;

    #your main script
    use MyApp::Container qw/api/;
    
    my $hash_val = api('Password')->generate($pass);

When you wanna export shortcut function to call the class object in any directory, you can register your original shortcut function in the sub class.

Examples are:

    #your application tree
    `-- MyApp
        |-- Model
        |   |-- Api
        |   |   `-- User.pm
        |   `-- Command
        |       `-- Password.pm
        `-- Container.pm

    #your sub class
    package MyApp::Container;
    use Object::Container::Exporter -base;

    register_namespace cmd => 'Mock::Model::Api::Command';

    #your main script
    use MyApp::Container qw/api cmd/;
    
    my $hash_val = cmd('Password')->generate($pass);

    my $row = api('User')->register(
        id   => 'nekokak',
        pass => $hash_val,
    );

Now, you have efficiently fun life development.

=head1 METHODS

=head2 register

Register classes to container.

Examples are:

    package MyApp::Container;
    use Object::Container::Exporter -base;

    #register($register_name, $initializer_code);
    register db => sub {
        my $self = shift;
        $self->load_class('DBI');
        DBI->connect('dbi:mysql:sandbox', 'root', 'pass', +{
            mysql_enable_utf8 => 1,
            PrintError        => 0,
            RaiseError        => 1,
        },);
    };

    #register($load_class,@opts);
    register 'WWW::Mechanize', @args;

=head2 register_namespace

You can register your original function name to call your application calss objects.

Example is:

    package MyApp::Container;
    use Object::Container::Exporter -base;

    register_namespace form => 'MyApp::Api::Form';

=head2 register_default_container_name

To call the object registered your sub class, the 'container' function exported. But you can change the export function name.

Example is:

    #your sub class
    package MyApp::Container;
    use Object::Container::Exporter -base;

    register_default_container_name 'con';

    register db => sub {
        my $self = shift;
        $self->load_class('DBI');
        DBI->connect('dbi:mysql:sandbox', 'root', 'pass',);
    };

    #your main script
    use MyApp::Container;
    
    my $user_bodys = con('db')->selectcolcall_arrayref('SELECT body FROM user');

=head2 get

Get the object that registered by 'register' method.

Examples are:
    #your sub class
    package MyApp::Container;
    use Object::Container::Exporter -base;

    register dbh => sub {
        my $self = shift;
        $self->load_class('DBI');
        DBI->connect('dbi:mysql:sandbox', 'root', 'pass',);
    };

    register teng => sub {
        my $self = shift;
        $self->load_class('MyApp::DB');

        MyApp::DB->new(
            dbh => $self->get('dbh'),#get registered object
        );
    };

    #your main script
    use MyApp::Container -no_export;
    
    my $obj = MyApp::Container->instance;

    my $row = $obj->get('teng')->single('user');

    ##or
    use MyApp::Container;

    my $obj = container;

    my $row = $obj->get('teng')->single('user');


=head2 remove

Remove the cached object that is created at C<get> method above.
Return value is the deleted object if it's exists.

=head2 load_class

Like require function.

Example is:

    package MyApp::Container;
    use Object::Container::Exporter -base;

    register db => sub {
        my $self = shift;
        $self->load_class('DBI');#load when call this code reference.
        DBI->connect('dbi:mysql:sandbox', 'root', 'pass',);
    };

=head1 AUTHOR

Atsushi Kobayashi E<lt>nekokak _at_ gmail _dot_ comE<gt>

=head1 CONTRIBUTORS

Hiroyuki Akabane: hirobanex

=head1 THANKS

Much of this documentation was taken from Object::Container

=head1 SEE ALSO

L<Object::Container>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

