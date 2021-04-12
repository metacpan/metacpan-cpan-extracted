package OpenAPI::Generator::From::Pod;

use strict;
use warnings;

use Carp;
use File::Find;
use OpenAPI::Generator::Util qw(merge_definitions);
use Pod::Simple::SimpleTree;

use constant OPENAPI_HEAD_NAME => 'OPENAPI';

BEGIN {

  if (eval { require YAML::XS }) {
    YAML::XS->import('Load');
  }
  elsif (eval { require YAML }) {
    YAML->import('Load');
  }
  else {
    CPAN::Meta::YAML->import('Load');
  }

}

sub new {

  bless {}, shift
}

sub generate {

  my($self, $conf) = @_;

  my $src = $conf->{src};
  $self->_check_src($src);
  my @files = $self->_src_as_files($src);

  my @defs;
  push @defs, $self->_parse_file($_) for @files;

  return unless @defs;

  merge_definitions(@defs);
}

sub _parse_file {
  my($self, $file) = @_;
  my $parser = Pod::Simple::SimpleTree->new;

  my $struct = $parser->parse_file($file)->root;
  my $openapi_node = $self->_extract_openapi_node($struct);

  unless ($openapi_node) {
    return;
  }

  my %common_definition = (
    paths => {},
    components => {
      schemas => {},
      parameters => {},
      securitySchemes => {},
    },
  );

  while (my($index, $node) = each @{$openapi_node}) {
    next unless ref $node eq uc'array';
    next unless $node->[0] eq 'item-text';

    my $item_name = $node->[2];

    my $definition_node = $openapi_node->[$index + 1];
    if (!$definition_node || $definition_node->[0] ne 'Verbatim') {
      croak("can not find definition for $node->[2]")
    }
    my $definition = Load $definition_node->[2];

    if ($item_name =~ /^\s*SCHEMA/) {
      my $schema_name = $self->_extract_component_name($item_name);
      $common_definition{components}{schemas}{$schema_name} = $definition;
    }
    elsif ($item_name =~ /^\s*PARAM/) {
      my $param_name = $self->_extract_component_name($item_name);
      $common_definition{components}{parameters}{$param_name} = $definition;
    }
    elsif ($item_name =~ /^\s*SECURITY/) {
      my $security_schema_name = $self->_extract_component_name($item_name);
      $common_definition{components}{securitySchemes}{$security_schema_name} = $definition;
    }
    else {
      my($method, $route) = $self->_extract_method_and_route($item_name);
      $common_definition{paths}{$route}{$method} = $definition;
    }
  }

  return \%common_definition;
}

sub _extract_component_name {

  my($type, $name) = split /\s/, $_[1];
  return $name;
}

sub _extract_method_and_route {

  my ($method, $route) = split /\s/, $_[1];
  return lc($method), $route
}

sub _extract_openapi_node {

  my($self, $struct) = @_;
  while (my($index, $node) = each @{$struct}) {
    next unless ref $node eq uc'array';
    if ($node->[2] eq OPENAPI_HEAD_NAME) {
      my $openapi_node = $struct->[$index + 1];
      if (!$openapi_node) {
        croak 'can not find openapi node: no nodes found below openapi annotation'
      }

      return $openapi_node;
    }
  }
}

sub _check_src {

  croak "$_[1] is not file or directory" unless(-f $_[1] or -d $_[1]);
  croak "$_[1] is not readable" unless(-r $_[1]);
}

sub _src_as_files {

  return $_[1] if -f $_[1];

  my @files;
  find sub { push @files, $File::Find::name if /\.(pm|pl|t|pod)$/ }, $_[1];
  @files
}

1

__END__

=head1 NAME

OpenAPI::Generator::From::Pod - Generate openapi definitions from Perl documentation!

=head1 SYNOPSIS

You probably want to use it from OpenAPI::Generator's exported subroutine called 'openapi_from':

  use OpenAPI::Generator;

  my $openapi_def = openapi_from(pod => {src => 'Controller.pm'});

But also you can use it directly:

  use OpenAPI::Generator::From::Pod;

  my $generator = OpenAPI::Generator::From::Pod->new;
  my $openapi_def = $generator->generate({src => 'Controllers/'})

=head1 POD FORMAT

Pod format should look like that:

Some other pod for your package:

  =head1 NAME

    Controller - some info about this package

After header 'OPENAPI' and '=over' OpenAPI definition block starts

  =head1 OPENAPI

  =over 2

List the elements of your OpenAPI definition

  =item GET /some/route # define openapi route

    parameters:
      ...

  =item SCHEMA User # define openapi components/schemes element

    type: object
    properites:
      ...

  =item SECURITY Cookie # define security schema

    ...

  =item PARAM userId # define parameter

    name: userId
    in: query
    schema:
      type: integer

After this '=back' whole OpenAPI block ends

  =back

=head1 METHODS

=over 4

=item new()

Creates new instance of class

  my $generator = OpenAPI::Generator::From::Pod->new

=item generate($conf)

Using just single Perl module

  $generator->generate({src => 'Controller.pm'});


Using directory of Perl modules

  $generator->generate({src => 'Controllers'});

=back

=head1 OPTIONS

=over 4

=item src

File path to module/directory of modules to read pod from

=back

=head1 AUTHOR

Anton Fedotov, C<< <tosha.fedotov.2000 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<https://github.com/doojonio/OpenAPI-Generator/issues>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc OpenAPI::Generator

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Anton Fedotov.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)