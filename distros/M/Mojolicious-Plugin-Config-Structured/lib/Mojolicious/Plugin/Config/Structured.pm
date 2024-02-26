package Mojolicious::Plugin::Config::Structured 1.004;
use v5.22;
use warnings;

# ABSTRACT: Mojolicious Plugin for Config::Structured: provides Mojo app access to structured configuration data

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Config::Structured - provides Mojo app access to structured configuration data

=head1 SYNOPSIS

  # For a full Mojo app
  $self->plugin('Config::Structured' => {config_file => $filename});

  ...

  if ($c->conf->feature->enabled) {
    ...
  }

  say $c->conf->email->recipient->{some_feature};

=head1 DESCRIPTION

Mojolicious Plugin for L<Config::Structured>: locates and reads config and definition files and loads them into a 
Config::Structured instance, made available globally via the C<conf> method.

=cut

use Mojo::Base 'Mojolicious::Plugin';

use Config::Structured;
use Readonly;

use experimental qw(signatures);

Readonly::Scalar our $PERIOD           => q{.};
Readonly::Scalar our $CONF_FILE_SUFFIX => q{conf};
Readonly::Scalar our $DEF_FILE_SUFFIX  => q{def};

=pod

=head1 METHODS

L<Mojolicious::Plugin::Config::Structured> inherits all methods from L<Mojolicious::Plugin> and implements the following
new ones

=head2 register

    $plugin->register(Mojolicious->new, [structure_file => $struct_fn,] [config_file => $config_file])

Register plugin in L<Mojolicious> application. C<structure_file> is the filesystem path of the file that defines the 
configuration definition. If omitted, a sane default is used (C<./{app}.conf.def>) relative to the mojo app home.

C<config_file> is the filesystem path of the file that provides the active configuration. If omitted, a sane default is
used (C<./{app}.{mode}.conf> or C<./{app}.conf>)

=cut

sub register ($self, $app, $params) {
  my @search =
    ($params->{structure_file}, $app->home->child(join($PERIOD, $app->moniker, $CONF_FILE_SUFFIX, $DEF_FILE_SUFFIX))->to_string);
  my ($def_file) = grep {defined && -r -f} @search;    #get the first existing, readable file
  unless (defined($def_file) && -r -f $def_file) {
    $app->log->error(sprintf('[Config::Structured] No configuration structure found (tried to read from `%s`)', $def_file // ''));
    die("[Config::Structured] Cannot continue without a valid conf structure");
  }

  @search = (
    $params->{config_file},
    $app->home->child(join($PERIOD, $app->moniker, $app->mode, $CONF_FILE_SUFFIX))->to_string,
    $app->home->child(join($PERIOD, $app->moniker, $CONF_FILE_SUFFIX))->to_string
  );
  my ($conf_file) = grep {defined && -r -f} @search;    #get the first existing, readable file
  unless (defined($conf_file)) {
    $app->log->warn('[Config::Structured] Initializing with empty configuration');
    $conf_file = {};
  }

  my $conf = Config::Structured->new(
    config    => $conf_file,
    structure => $def_file,
    hooks     => $params->{hooks},
  )->__register_default;

=pod

=head2 conf

This method is used to access the loaded configuration from within the Mojo 
application. Returns the root L<Config::Structured> instance.

=cut

  $app->helper(
    conf => sub {
      return $conf;
    }
  );

  return;
}

=head1 AUTHOR

Mark Tyrrell C<< <mark@tyrrminal.dev> >>

=head1 LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;

__END__
