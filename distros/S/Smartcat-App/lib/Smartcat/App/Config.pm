use strict;
use warnings;

package Smartcat::App::Config;
use base ( "Class::Accessor", "Class::Data::Inheritable" );

use Config::Tiny;
use File::Basename;
use File::Spec::Functions qw(catfile);
use File::HomeDir;

use Data::Dumper;

__PACKAGE__->mk_classdata( 'attribute_map' => {} );

sub new {
    my $class = shift @_;

    my $self = bless( {}, $class );

    return $self;
}

sub validate_log {
    my ( $self, $value ) = @_;

    die
"ConfigError: 'log' parent directory, which is set to '$value', does not point to a valid directory"
      if defined $value && !-d dirname($value);

    return 1;
}

sub get_config_file {
    my $config_dir =
      File::HomeDir->my_dist_config( "Smartcat::App", { create => 1 } );
    return catfile( $config_dir, 'config' );
}

sub load {
    my $self = shift @_;
    $self = $self->new unless ref $self;

    my $config_file = $self->get_config_file;
    if ( -e $config_file ) {
        $self->{instance} = Config::Tiny->read( $config_file, "utf8" );
    }
    else {
        $self->{instance} = Config::Tiny->new;
    }

    foreach my $attribute ( keys %{ $self->attribute_map } ) {
        my $args_key           = $self->attribute_map->{$attribute};
        my $validate_attribute = "validate_$attribute";
        my $value              = $self->{instance}->{_}->{$args_key};
        $self->$attribute($value)
          if !defined $self->can($validate_attribute)
          || $self->$validate_attribute($value);
    }

    return $self;
}

sub save {
    my $self = shift @_;
    foreach my $attribute ( keys %{ $self->attribute_map } ) {
        my $args_key = $self->attribute_map->{$attribute};
        $self->{instance}->{_}->{$args_key} = $self->$attribute;
    }
    $self->{instance}->write( $self->get_config_file, "utf8" );
}

sub cat {
    my $self        = shift @_;
    my $config_file = $self->get_config_file;
    print `cat $config_file\n`;
}

__PACKAGE__->attribute_map(
    {
        'username' => 'token_id',
        'password' => 'token',
        'log'      => 'log'
    }
);

__PACKAGE__->mk_accessors( keys %{ __PACKAGE__->attribute_map } );

1;
