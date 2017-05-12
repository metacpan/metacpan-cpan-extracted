# ============================================================================
package MooseX::App::Plugin::Config;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;
use MooseX::App::Role;

use MooseX::Types::Path::Class;
use Config::Any;

has 'config' => (
    is              => 'ro',
    isa             => 'Path::Class::File',
    coerce          => 1,
    predicate       => 'has_config',
    documentation   => q[Path to command config file],
    traits          => ['MooseX::App::Meta::Role::Attribute::Option'],
    cmd_type        => 'proto',
    cmd_position    => 99990,
);

has '_config_data' => (
    is              => 'ro',
    isa             => 'HashRef',
    predicate       => 'has_config_data',
);

sub plugin_metaroles {
    my ($self,$class) = @_;

    return {
        class   => ['MooseX::App::Plugin::Config::Meta::Class'],
    }
}

1;

__END__

=encoding utf8

=head1 NAME

MooseX::App::Plugin::Config - Config files your MooseX::App applications

=head1 SYNOPSIS

In your base class:

 package MyApp;
 use MooseX::App qw(Config);
 
 option 'global_option' => (
     is          => 'rw',
     isa         => 'Int',
 );

In your command class:

 package MyApp::Some_Command;
 use MooseX::App::Command;
 extends qw(MyApp);
 
 option 'some_option' => (
     is          => 'rw',
     isa         => 'Str',
 );

Now create a config file (see L<Config::Any>) eg. a yaml file:

 ---
 global:
   global_option: 123
 some_command:
   global_option: 234
   some_option: "hello world"

The user can now call the program with a config file:

 bash$ myapp some_command --config /path/to/config.yml

=head1 METHODS

=head2 config

Read the config filename

=head2 _config_data

The full content of the loaded config file

=head1 SEE ALSO

L<Config::Any>

=cut