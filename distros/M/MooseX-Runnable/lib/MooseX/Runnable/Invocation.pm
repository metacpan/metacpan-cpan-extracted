package MooseX::Runnable::Invocation;

our $VERSION = '0.10';

use Moose;
use MooseX::Types -declare => ['RunnableClass'];
use MooseX::Types::Moose qw(Str HashRef ArrayRef);
use List::SomeUtils qw(uniq);
use Params::Util qw(_CLASS);
use Class::Load;
use namespace::autoclean;

# we can't load the class until plugins are loaded,
# so we have to handle this outside of coerce

subtype RunnableClass,
  as Str,
  where { _CLASS($_) };


with 'MooseX::Runnable'; # this class technically follows
                         # MX::Runnable's protocol

has 'class' => (
    is       => 'ro',
    isa      => RunnableClass,
    required => 1,
);

has 'plugins' => (
    is         => 'ro',
    isa        => HashRef[ArrayRef[Str]],
    default    => sub { +{} },
    required   => 1,
    auto_deref => 1,
);

sub BUILD {
    my $self = shift;

    # it would be nice to use MX::Object::Pluggable, but our plugins
    # are too configurable

    my $plugin_ns = 'MooseX::Runnable::Invocation::Plugin::';
    for my $plugin (keys %{$self->plugins}){
        my $orig = $plugin;
        $plugin = "$plugin_ns$plugin" unless $plugin =~ /^[+]/;
        $plugin =~ s/^[+]//g;

        Class::Load::load_class( $plugin );

        my $does_cmdline = $plugin->meta->
          does_role('MooseX::Runnable::Invocation::Plugin::Role::CmdlineArgs');

        my $args;
        if($does_cmdline){
            $args = eval {
                $plugin->_build_initargs_from_cmdline(
                    @{$self->plugins->{$orig}},
                );
            };

            if($@) {
                confess "Error building initargs for $plugin: $@";
            }
        }
        elsif(!$does_cmdline && scalar @{$self->plugins->{$orig}} > 0){
            confess "You supplied arguments to the $orig plugin, but it".
              " does not know how to accept them.  Perhaps the plugin".
              " should consume the".
              " 'MooseX::Runnable::Invocation::Plugin::Role::CmdlineArgs'".
              " role?";
        }

        $plugin->meta->apply(
            $self,
            defined $args ? (rebless_params => $args) : (),
        );
    }
}

sub load_class {
    my $self = shift;
    my $class = $self->class;

    Class::Load::load_class( $class );

    confess 'We can only work with Moose classes with "meta" methods'
      if !$class->can('meta');

    my $meta = $class->meta;

    confess "The metaclass of $class is not a Moose::Meta::Class, it's $meta"
      unless $meta->isa('Moose::Meta::Class');

    confess 'MooseX::Runnable can only run classes tagged with '.
      'the MooseX::Runnable role'
        unless $meta->does_role('MooseX::Runnable');

    return $meta;
}

sub apply_scheme {
    my ($self, $class) = @_;

    my @schemes = grep { defined } map {
        eval { $self->_convert_role_to_scheme($_) }
    } map {
        eval { $_->meta->calculate_all_roles };
    } $class->linearized_isa;

    eval {
        foreach my $scheme (uniq @schemes) {
            $scheme->apply($self);
        }
    };
}


sub _convert_role_to_scheme {
    my ($self, $role) = @_;

    my $name = $role->name;
    return if $name =~ /\|/;
    $name = "MooseX::Runnable::Invocation::Scheme::$name";

    return eval {
        Class::Load::load_class($name);
        warn "$name was loaded OK, but it's not a role!" and return
          unless $name->meta->isa('Moose::Meta::Role');
        return $name->meta;
    };
}

sub validate_class {
    my ($self, $class) = @_;

    my @bad_attributes = map { $_->name } grep {
        $_->is_required && !($_->has_default || $_->has_builder)
    } $class->get_all_attributes;

    confess
       'By default, MooseX::Runnable calls the constructor with no'.
       ' args, but that will result in an error for your class.  You'.
       ' need to provide a MooseX::Runnable::Invocation::Plugin or'.
       ' ::Scheme for this class that will satisfy the requirements.'.
       "\n".
       "The class is @{[$class->name]}, and the required attributes are ".
         join ', ', map { "'$_'" } @bad_attributes
           if @bad_attributes;

    return; # return value is meaningless
}

sub create_instance {
    my ($self, $class, @args) = @_;
    return ($class->name->new, @args);
}

sub start_application {
    my $self = shift;
    my $instance = shift;
    my @args = @_;

    return $instance->run(@args);
}

sub run {
    my $self = shift;
    my @args = @_;

    my $class = $self->load_class;
    $self->apply_scheme($class);
    $self->validate_class($class);
    my ($instance, @more_args) = $self->create_instance($class, @args);
    my $exit_code = $self->start_application($instance, @more_args);
    return $exit_code;
}

1;
