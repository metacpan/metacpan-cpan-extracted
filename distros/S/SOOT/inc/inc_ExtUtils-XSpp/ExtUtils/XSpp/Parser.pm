package ExtUtils::XSpp::Parser;

use strict;
use warnings;

use IO::Handle;
use ExtUtils::XSpp::Grammar;

=head1 NAME

ExtUtils::XSpp::Parser - an XS++ parser

=cut

sub _my_open {
  my $file = shift;

  open my $in, "<", $file
    or die "Failed to open '$file' for reading: $!";

  return $in;
}

=head2 ExtUtils::XSpp::Parser::new( file => path )

Create a new XS++ parser.

=cut

sub new {
  my $class = shift;
  my $this = bless {}, $class;
  my %args = @_;

  $this->{FILE} = $args{file};
  $this->{STRING} = $args{string};
  $this->{PARSER} = ExtUtils::XSpp::Grammar->new;
  $this->{PLUGINS} = {};

  return $this;
}

=head2 ExtUtils::XSpp::Parser::parse

Parse the file data; returns true on success, false otherwise,
on failure C<get_errors> will return the list of errors.

=cut

sub parse {
  my $this = shift;
  my $fh;
  if( $this->{FILE} ) {
      $fh = _my_open( $this->{FILE} );
  } else {
      open $fh, '<', \$this->{STRING}
        or die "Failed to create file handle from in-memory string";
  }
  my $buf = '';

  my $parser = $this->{PARSER};
  $parser->YYData->{LEX}{FH} = $fh;
  $parser->YYData->{LEX}{BUFFER} = \$buf;
  $parser->YYData->{LEX}{FILE} = $this->{FILE};
  local $parser->YYData->{PARSER} = $this;

  $this->{DATA} = $parser->YYParse( yylex   => \&ExtUtils::XSpp::Grammar::yylex,
                                    yyerror => \&ExtUtils::XSpp::Grammar::yyerror,
                                    yydebug => 0x00,
                                   );
  if (ref($this->{DATA})) {
    unshift @{$this->{DATA}},
      ExtUtils::XSpp::Node::Raw->new(rows =>['#include <exception>']);
  }
}

sub include_file {
  my $this = shift;
  my( $file ) = @_;
  my $buf = '';
  my $new_lex = { FH     => _my_open( $file ),
                  FILE   => $file,
                  BUFFER => \$buf,
                  NEXT   => $this->{PARSER}->YYData->{LEX},
                  };

  $this->{PARSER}->YYData->{LEX} = $new_lex;
}

=head2 ExtUtils::XSpp::Parser::get_data

Returns a list containing the parsed data. Each item of the list is
a subclass of C<ExtUtils::XSpp::Node>

=cut

sub get_data {
  my $this = shift;
  die "'parse' must be called before calling 'get_data'"
    unless exists $this->{DATA};

  return $this->{DATA};
}

=head2 ExtUtils::XSpp::Parser::get_errors

Returns the parsing errors as an array.

=cut

sub get_errors {
  my $this = shift;

  return @{$this->{ERRORS}};
}

=head2 ExtUtils::XSpp::Parser::load_plugin

Loads the specified plugin and calls its C<register_plugin> method.

=cut

sub load_plugin {
  my( $this, $package ) = @_;

  if (eval "require ExtUtils::XSpp::Plugin::$package;") {
    $package = "ExtUtils::XSpp::Plugin::$package";
  }
  elsif (!eval "require $package;") {
    die "Could not load XS++ plugin '$package' (neither via the namespace "
       ."'ExtUtils::XS++::Plugin::$package' nor via '$package'). Reason: $@";
  }

  # only call register_plugin once
  if (!$this->{PLUGINS}{$package}) {
    $package->register_plugin( $this );
    $this->{PLUGINS}{$package} = 1;
  }

  # TODO handle %load_plugin parameters

  return 1;
}

=head2 ExtUtils::XSpp::Parser::add_post_process_plugin

Adds the specified plugin to be called after parsing is complete to
modify the parse tree before it is emitted.

=cut

sub add_post_process_plugin {
  my( $this, %args ) = @_;

  push @{$this->{PLUGINS}{POST_PROCESS}}, $args{plugin};
}

sub post_process_plugins { $_[0]->{PLUGINS}{POST_PROCESS} || [] }

=head2 ExtUtils::XSpp::Parser::add_class_tag_plugin

Adds the specified plugin to the list of plugins that can handle custom
%foo annotations for a class.

=cut

sub add_class_tag_plugin {
  my( $this, %args ) = @_;
  my $tag = $args{tag} || '_any_';

  push @{$this->{PLUGINS}{CLASS_TAG}{$tag}}, $args{plugin};
}

sub handle_class_tag_plugins {
  my( $this, $class, @args ) = @_;

  _handle_plugin( $this, $this->{PLUGINS}{CLASS_TAG}, 'class',
                  'handle_class_tag', [ $class, @args ] );
}

=head2 ExtUtils::XSpp::Parser::add_function_tag_plugin

Adds the specified plugin to the list of plugins that can handle custom
%foo annotations for a function.

=cut

sub add_function_tag_plugin {
  my( $this, %args ) = @_;
  my $tag = $args{tag} || '_any_';

  push @{$this->{PLUGINS}{FUNCTION_TAG}{$tag}}, $args{plugin};
}

sub handle_function_tag_plugins {
  my( $this, $function, @args ) = @_;

  _handle_plugin( $this, $this->{PLUGINS}{FUNCTION_TAG}, 'function',
                  'handle_function_tag', [ $function, @args ] );
}

=head2 ExtUtils::XSpp::Parser::add_method_tag_plugin

Adds the specified plugin to the list of plugins that can handle custom
%foo annotations for a function.

=cut

sub add_method_tag_plugin {
  my( $this, %args ) = @_;
  my $tag = $args{tag} || '_any_';

  push @{$this->{PLUGINS}{METHOD_TAG}{$tag}}, $args{plugin};
}

sub handle_method_tag_plugins {
  my( $this, $method, @args ) = @_;

  _handle_plugin( $this, $this->{PLUGINS}{METHOD_TAG}, 'method',
                  'handle_method_tag', [ $method, @args ] );
}

=head2 ExtUtils::XSpp::Parser::add_toplevel_tag_plugin

Adds the specified plugin to the list of plugins that can handle custom
%foo top level directives.

=cut

sub add_toplevel_tag_plugin {
  my( $this, %args ) = @_;
  my $tag = $args{tag} || '_any_';

  push @{$this->{PLUGINS}{TOPLEVEL_TAG}{$tag}}, $args{plugin};
}

sub handle_toplevel_tag_plugins {
  my( $this, @args ) = @_;

  _handle_plugin( $this, $this->{PLUGINS}{TOPLEVEL_TAG}, 'top-level',
                  'handle_toplevel_tag', [ undef, @args ] );
}

sub _handle_plugin {
  my( $this, $plugins, $plugin_type, $plugin_method, $plugin_args ) = @_;
  my $tag = $plugin_args->[1];

  my $handled;
  foreach my $plugin ( @{$plugins->{$tag} || []}, @{$plugins->{_any_} || []} ) {
    $handled ||= $plugin->$plugin_method( @$plugin_args );
    last if $handled;
  }

  die "Unhandled $plugin_type annotation $tag" unless $handled;
}

sub current_file { $_[0]->{PARSER}->YYData->{LEX}{FILE} }

1;
