package Mojolicious::Plugin::Data::Validate::WithYAML;

# ABSTRACT: validate form input with Data::Validate::WithYAML

use strict;
use warnings;

use parent 'Mojolicious::Plugin';

use Carp;
use Data::Validate::WithYAML;
use File::Spec;

our $VERSION = 0.04;

sub register {
    my ($self, $app, $config) = @_;

    $config->{conf_path} ||= $self->home;
    $config->{no_steps}  //= 1;

    $app->helper( 'validate' => sub {
        my ($c, $file) = @_;

        if ( !$file ) {
            my @caller = caller(2);
            $file      = (split /::/, $caller[3])[-1];
        }

        my $path = File::Spec->rel2abs( File::Spec->catfile( $config->{conf_path}, $file . '.yml' ) );

        if ( !-e $path ) {
            croak "$path does not exist";
        }

        my $validator = Data::Validate::WithYAML->new(
            $path,
            %{ $config || { no_steps => 1 } },
        ) or croak $Data::Validate::WithYAML::errstr;

        my $params = $c->req->params->to_hash;
        my %errors = $validator->validate( %{ $params || {} } );

        my $prefix          = exists $config->{error_prefix} ? $config->{error_prefix} : 'ERROR_';
        my %prefixed_errors = map{ ( "$prefix$_" => $errors{$_} ) } keys %errors;

        return %prefixed_errors;
    });

    $app->helper( 'fieldinfo' => sub {
        my ($c, $file, $field, $subinfo) = @_;

        if ( !$file ) {
            my @caller = caller(2);
            $file      = (split /::/, $caller[3])[-1];
        }

        my $path = File::Spec->rel2abs( File::Spec->catfile( $config->{conf_path}, $file . '.yml' ) );

        if ( !-e $path ) {
            croak "$path does not exist";
        }

        my $validator = Data::Validate::WithYAML->new(
            $path,
            %{ $config || { no_steps => 1 } },
        ) or croak $Data::Validate::WithYAML::errstr;

        my $info = $validator->fieldinfo( $field );

        return if !$info;

        return $info if !$subinfo;
        return $info->{$subinfo};
    });
}

1;

__END__

=pod

=head1 NAME

Mojolicious::Plugin::Data::Validate::WithYAML - validate form input with Data::Validate::WithYAML

=head1 VERSION

version 0.04

=head1 SYNOPSIS

In your C<startup> method:

  sub startup {
      my $self = shift;
  
      # more Mojolicious stuff
  
      $self->plugin(
          'Data::Validate::WithYAML',
          {
              error_prefix => 'ERROR_',        # optional
              conf_path    => '/opt/app/conf', # path to the dir where all the .ymls are (optional)
          }
      );
  }

In your controller:

  sub register {
      my $self = shift;

      # might be (age => 'You are too young', name => 'name is required')
      # or with error_prefix (ERROR_age => 'You are too young', ERROR_name => 'name is required')
      my %errors = $self->validate( 'registration' );
  
      if ( %errors ) {
         $self->stash( %errors );
         $self->render;
         return; 
      }
  
      # create new user
  }

Your registration.yml

  ---
  age:
    type: required
    message: You are too young
    min: 18
  name:
    type: required
    message: name is required
  password:
    type: required
    plugin: PasswordPolicy
  website:
    type: optional
    plugin: URL

=head1 HELPERS

=head2 validate

    my %errors = $controller->validate( $yaml_name );

Validates the parameters. Optional parameter is I<$yaml_name>. If I<$yaml_name> is ommitted, the subroutine name (e.g. "register") is used.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
