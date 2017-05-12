package Module::New::Config;

use strict;
use warnings;
use Carp;
use File::HomeDir;
use Getopt::Long ();
use Path::Tiny ();
use YAML::Tiny;

sub new {
  my ($class, %options) = @_;

  my $parser = Getopt::Long::Parser->new(
    config => [qw( bundling ignore_case pass_through )]
  );

  my $self = bless { parser => $parser, %options }, $class;

  $self->load;
  $self;
}

sub file { shift->{file} }

sub get {
  my ($self, $key) = @_;
  return $self->{option}->{$key} if exists $self->{option}->{$key};
  return $self->{config}->{$key} if exists $self->{config}->{$key};
  return;
}

sub set {
  my $self = shift;

  if ( @_ and @_ % 2 == 0 ) {
    $self->{config} = { %{ $self->{config} || {} }, @_ };
  }
}

sub save {
  my $self = shift;

  $self->set(@_) if @_;

  $self->{file} ||= $self->_default_file;

  YAML::Tiny::DumpFile( $self->{file}, $self->{config} );
}

sub load {
  my $self = shift;

  if ( $self->{file} ) {
    return if $self->_load_and_merge( $self->{file} );
  }
  else {
    foreach my $file ( $self->_search ) {
      return if $self->_load_and_merge( $file );
    }
  }
  $self->_first_time;
}

sub _load_and_merge {
  my ($self, $file) = @_;

  return unless $file && -f $file;

  my $config;
  eval { $config = YAML::Tiny::LoadFile( $file ) };
  return if $@;

  foreach my $key ( keys %{ $config } ) {
    $self->{config}->{$key} = $config->{$key};
  }
  $self->{file} = $file;
  return 1;
}

sub get_options {
  my ($self, @specs) = @_;
  my $config = {};
  $self->{parser}->getoptions($config, @specs);
  $self->{option} = { %{ $self->{option} || {} }, %{ $config } };
}

sub _first_time {
  my $self = shift;
  my $author = $self->{author} || $self->_prompt('Enter Author: ');
  my $email  = $self->{email}  || $self->_prompt('Enter Email: ');

  $self->{file} ||= $self->_default_file;
  $self->{config} = {
    author => $author,
    email  => $email,
  };

  $self->save;
}

sub _search {
  my $self = shift;

  grep { $_->exists }
  map  {( $_->child('.new_perl_module.yml'),
          $_->child('.new_perl_module.yaml') )}
  ( Path::Tiny::path('.'), $self->_home );
}

sub _home { Path::Tiny::path( File::HomeDir->my_home ) }

sub _default_file { shift->_home->child('.new_perl_module.yml') }

sub _prompt {
  my ($self, $prompt) = @_;
  return if $self->{no_prompt}; # for test

  print $prompt;
  my $ret = <STDIN>; chomp $ret;
  return $ret;
}

1;

__END__

=head1 NAME

Module::New::Config

=head1 SYNOPSIS

  my $config = Module::New::Config->new( file => 'config.yaml' );

  my $value  = $config->get('some_key');
  $config->set('some_key' => 'value');

  $config->load;
  $config->save;

=head1 DESCRIPTION

Used internally to get/set the config value.

=head1 METHODS

=head2 new

takes an optional hash, creates an object, and loads a configuration file if any (or creates one if none is found).

=head2 get

If you pass a key, returns a value for the key. Without a key, returns the whole configuration hash reference.

=head2 set

takes pairs of key/value and update the config (temporarily). If you want to keep the configuration, use C<save> instead.

=head2 load

loads a configuration file written in YAML. The file is looked for in the current and home directory by default.

=head2 save

may take a hash to update, and saves the current configuration to a file.

=head2 file

returns the current config file.

=head2 get_options

takes L<Getopt::Long>'s specifications, parses @ARGV, and updates the current configuration.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
