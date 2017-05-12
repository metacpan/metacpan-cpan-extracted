package OTRS::OPM::Analyzer::Utils::Config;

# ABSTRACT: class to parse a yaml config

use strict;
use warnings;

use Carp;
use YAML::Tiny;
use File::Spec;
use File::Basename;

sub new{
    my ($class,$file) = @_;
    
    my $self = {};
    bless $self,$class;

    my $default_dir  = File::Spec->rel2abs( File::Basename::dirname( $0 ) );
    my $default_file = File::Spec->catfile( $default_dir,  'conf', 'base.yml' );
       $default_file = File::Spec->rel2abs( $default_file );
    
    $file ||= $default_file if -e $default_file;
    $self->load( $file ) if defined $file;
    return $self;
}

sub load{
    my ($self,$file) = @_;
    croak "no config file given" unless defined $file;

    my $result = eval{
        YAML::Tiny->read( $file );
    };

    $result ||= [];

    $self->{_config} = $result->[0] || {};

    return $self->{_config};
}

sub get {
    my ($self,$key) = @_;

    my $return;

    if( defined $key ){
        my $config = $self->{_config} || {};

        my @keys = split /(?<!\\)\./, $key;
        for my $subkey ( @keys ){
            $subkey =~ s/\\\././g;

            return if $config and $subkey and ref $config ne 'HASH';

            return if not exists $config->{$subkey};
            $config = $config->{$subkey};
        }

        $return = $config;
    }

    $return;
}

sub set {
    my ($self,$key,$value) = @_;

    $self->{_config} ||= {};

    if( defined $key ){
        my $config = $self->{_config} || {};

        my @keys = split /(?<!\\)\./, $key;
        while ( my $subkey = shift @keys ){
            $subkey =~ s/\\\././g;

            last if $subkey and $config and ref $config ne 'HASH';

            $config->{$subkey} = {} if not exists $config->{$subkey};

            if ( !@keys ) {
                $config->{$subkey} = $value;
            }
            else {
                $config = $config->{$subkey};
            }
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OTRS::OPM::Analyzer::Utils::Config - class to parse a yaml config

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use OTRS::OPM::Analyzer::Utils::Config;
  
  my $config = '/path/to/config.yml';
  my $obj    = OTRS::OPM::Analyzer::Utils::Config->new( $config );
  
  print $obj->get( 'app.path' ); # /opt/otrs/
  print $obj->get( 'app' )->{path}; # /opt/otrs/
  
  $obj->set( 'app.version', '3.3.3' );
  print $obj->get( 'app.version' ); # 3.3.3

config.yml

  ---
  app:
    path: /opt/otrs/

=head1 METHODS

=head2 new

Creates a new object of the config parser

  use OTRS::OPM::Analyzer::Utils::Config;
  
  my $config = '/path/to/config.yml';
  my $obj    = OTRS::OPM::Analyzer::Utils::Config->new( $config );

=head2 load

Loads a new config

  my $config = '/path/to/config.yml';
  my $obj    = OTRS::OPM::Analyzer::Utils::Config->new;
  $obj->load( $config );

=head2 get

Returns the value of a given config key. Multilevel hashes can be separated with a '.'

  print $obj->get( 'app.path' ); # /opt/otrs/
  print $obj->get( 'app' )->{path}; # /opt/otrs/

=head2 set

Sets a config option

  $obj->set( 'app.version', '3.3.3' );

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
