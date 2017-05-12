package Mojolicious::Plugin::ConfigSimple;
use Mojo::Base 'Mojolicious::Plugin';
use Config::Simple::Extended;

our $VERSION = '0.06';

sub register {
  my ($self, $app, $args) = @_;
  my $cfg;
  if(exists($args->{'config_file'})){ 
    unless( ref $args->{'config_file'} eq 'SCALAR' ){
      die 'config_file key requires a SCALAR';
    }
    $cfg = Config::Simple->new(
        $args->{'config_file'} );
  } elsif(exists($args->{'config_files'})){
    unless( ref $args->{'config_files'} eq 'ARRAY' ){
      die 'config_files key requires an ARRAYREF';
    }
    undef($cfg);
    foreach my $file (@{$args->{'config_files'}}){
      $cfg = Config::Simple::Extended->inherit({
          base_config => $cfg,
             filename => $file });
    }
  } else {
    die "Constructor invoked with no Confirguration File, see perldoc for details."
  }
  return wantarray ? ( \%{$cfg->vars}, $cfg ) : \%{$cfg->vars};
}

sub version {
  return <<"END";
Config::Simple => $Config::Simple::VERSION
Config::Simple::Extended => $Config::Simple::Extended::VERSION
Mojolicious::Plugin::ConfigSimple => $VERSION
END

}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::ConfigSimple - Config::Simple::Extended 

=head1 VERSION 

Version 0.06

my $version = &Mojolicious::Plugin::ConfigSimple::version;
will return the currently installed version numbers for the 
key dependent modules.

=head1 SYNOPSIS

  # Mojolicious
  my $ini = '/etc/myapp/config.ini';
  my ($config, $cfg) = $self->plugin('ConfigSimple' => { config_files => [ $ini ] } );

  # Mojolicious::Lite
  my ($config, $cfg) = $plugin 'ConfigSimple' => { config_file => $ini };

=head1 DESCRIPTION

L<Mojolicious::Plugin::ConfigSimple> is a L<Mojolicious> plugin.
It is a very simple wrapper around L<Config::Simple::Extended>, 
which in turn wraps L<Config::Simple>.  Those two modules fully 
document their uses and interfaces and you are encouraged to 
review their perldoc to learn more.  But a quick summary is 
available below.  If you prefer the more idiomatic Mojo tradition 
of an $app->config->{'data_structure'} to the object oriented 
interface provided by the returned $cfg object, say for instance 
to support hypnotoad, then by all means.  The non-object data 
structure is returned if invoked in scalar context.

=head1 METHODS

L<Mojolicious::Plugin::ConfigSimple> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new, { config_files => [ $ini ] });

Register plugin in L<Mojolicious> application.

Once that has been invoked in the ->starter() method of your 
application, you should then be able to invoke all of the methdos 
of Config::Simple and Config::Simple::Extended from anywhere in 
your application to access and manipulate your configuration.  

The plugin's constructor recognized only two keys.  It requires one or
the other, if both are provided, config_file wins.  config_file
requires a scalar value.  config_files requires an arrayref value.  

If you pass the wrong data type or fail to pass one of the recognized
keys, then the plugin dies with an informative error message.

Try these:

    my $debug = $cfg->param("default.debug");
    my $db_connection_credentials = $cfg->get_block( 'db' );
    my %cfg = $cfg->vars;

If this plugin is registered in scalar context, it returns
\%{$cfg->vars}, providing the data structure traditionally 
provided by $app->config in a Mojolicious environment.  

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 AUTHOR & COPYRIGHT

Copyright 2013-2015

Hugh Esco <hesco@campaignfoundations.com>

Released under the Gnu Public License v2, copy included

=cut

