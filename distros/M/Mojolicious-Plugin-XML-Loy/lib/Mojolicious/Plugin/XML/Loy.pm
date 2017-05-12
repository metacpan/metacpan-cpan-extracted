package Mojolicious::Plugin::XML::Loy;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Loader qw/load_class/;
use Mojo::Util qw!deprecated!;
use XML::Loy;

our $VERSION = '0.14';

my %base_classes;

# Register Plugin
sub register {
  my ($plugin, $mojo, $param) = @_;

  my $namespace = 'XML::Loy::';
  my $max_size = 1024 * 1024;

  # Load parameter from Config file
  if (my $config_param = $mojo->config('XML-Loy')) {
    $param = { %$param, %$config_param };
  };

  if (exists $param->{max_size} && $param->{max_size} =~ /^\d+$/) {
    $max_size = delete $param->{max_size};
  };

  # Create new XML helpers
  foreach my $helper (keys %$param) {

    # Already defined
    if (exists $mojo->renderer->helpers->{$helper}) {
      $mojo->log->debug("Helper '$helper' already defined");
      next;
    };

    my @helper = @{ $param->{ $helper } };
    my $base = shift @helper;

    $base = 'XML::Loy' if $base eq '-Loy';

    if (index($base, '-') == 0) {
      $base =~ s/^-//;
      $base = ($base eq 'Loy' ? 'XML::Loy' : $namespace . "$base");
    };

    # Load module if not loaded
    unless (exists $base_classes{$base}) {

      # Load base class
      if (my $e = load_class $base) {
	for ($mojo->log) {
	  $_->error("Exception: $e")  if ref $e;
	  $_->error(qq{Unable to load base class "$base"});
	};
	next;
      };

      my $mime   = $base->mime;
      my $prefix = $base->_prefix;

      # Establish mime types
      if ($mime && $prefix) {

	# Apply mime type
	$mojo->types->type($prefix => $mime);
      };

      # module loaded
      $base_classes{$base} = [$prefix => $mime];
    };

    # Code generation for ad-hoc helper
    my $code = 'sub { shift;' .
      ' { use bytes; return if length("@_") > ' . $max_size . '} ' .
      ' my $doc = ' . $base . '->new( @_ );';

    # Extend base class
    if (@helper) {
      $code .= '$doc->extension(' .
	join(',', map( '"' . qq{$_"}, @helper)) .
      ");";
    };
    $code .= 'return $doc };';

    # Eval code
    my $code_ref = eval $code;

    # Evaluation error
    $mojo->log->fatal($@ . ': ' . $!) and next if $@;

    # Create helper
    $mojo->helper($helper => $code_ref);
  };

  # Plugin wasn't registered before
  unless (exists $mojo->renderer->helpers->{'new_xml'}) {

    # Default 'new_xml' helper
    $mojo->helper(
      new_xml => sub {
	shift;
	return XML::Loy->new( @_ );
      });

    my $reply_xml = sub {
      my ($c, $xml) = @_;
      my $format = 'xml';

      # Check format based on mime type
      my $class = ref $xml;
      if ($base_classes{$class}) {
	if ($base_classes{$class}->[0] && $base_classes{$class}->[1]) {
	  $format = $base_classes{$class}->[0];
	};
      };

      # render XML with correct mime type
      return $c->render(
	'data'   => $xml->to_pretty_xml,
	'format' => $format,
	@_
      );
    };

    # Add 'render_xml' helper
    $mojo->helper(
      render_xml => sub {
	deprecated 'render_xml is deprecated in favor of reply->xml';
	$reply_xml->(@_);
      }
    );

    # Add 'reply->xml' helper
    $mojo->helper('reply.xml' => $reply_xml);
  };
};


1;


__END__

=pod

=head1 NAME

Mojolicious::Plugin::XML::Loy - XML Generation with Mojolicious


=head1 SYNOPSIS

  # Mojolicious
  $mojo->plugin(
    'XML::Loy' => {
      new_activity => [-Atom, -ActivityStreams],
      new_hostmeta => [-XRD, -HostMeta],
      new_myXML    => [-Loy, -Atom, -Atom::Threading]
    });

  # In controllers use the generic new_xml helper
  my $xml = $c->new_xml('entry');

  # Create a new XML::Loy document
  my $xml = $app->new_xml('html');

  $xml->add('header')->add(
    title => 'XML-Loy example' => 'My Title!'
  );

  for ($xml->add('body' => { style => 'color: red' })) {
    $_->add(p => 'First paragraph');
    $_->add(p => { -type => 'raw' } => 'Second')
      ->add(b => 'paragraph');
  };

  # Render document with the correct mime-type
  $c->reply->xml($xml);

  # Content-Type: application/xml
  # <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  # <html>
  #   <header>
  #
  #     <!-- My Title! -->
  #     <title>XML-Loy example</title>
  #   </header>
  #   <body style="color: red">
  #     <p>First paragraph</p>
  #     <p>Second<b>paragraph</b></p>
  #   </body>
  # </html>

  # Use newly created helper
  my $xrd = $c->new_hostmeta;

  # Create a document based on the defined xml profile
  $xrd->host('sojolicio.us');

  # Render document with the correct mime-type
  $c->reply->xml($xrd);

  # Content-Type: application/xrd+xml
  # <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  # <XRD xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0"
  #      xmlns:hm="http://host-meta.net/xrd/1.0"
  #      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  #   <hm:Host>sojolicio.us</hm:Host>
  # </XRD>


=head1 DESCRIPTION

L<Mojolicious::Plugin::XML::Loy> is a plugin to support
XML document generation based on L<XML::Loy>.


=head1 METHODS

L<Mojolicious::Plugin::XML::Loy> inherits all methods
from L<Mojolicious::Plugin> and implements the following
new ones.

=head2 register

  # Mojolicious
  $mojo->plugin(XML::Loy => {
    max_size     => 2048,
    new_activity => [-Atom, -ActivityStreams]
  });

  # Mojolicious::Lite
  plugin XML::Loy => {
    new_activity => [-Atom, -ActivityStreams]
  };

  # In your config file
  {
    XML::Loy => {
      new_activity => [-Atom, -ActivityStreams]
    }
  };

Called when registering the plugin.
Accepts new xml profiles, defined by the
name of the associated generation helper
and an array reference defining the profile.
The first element in the array is the base class,
followed by all extensions.
To create a helper extending the base class,
use C<-Loy> as the first element.

  $mojo->plugin('XML::Loy' => {
    new_myXML => [-Loy, 'MyXML::Loy::Extension']
  });

In addition to that, the C<max_size> in bytes of xml documents
to be parsed can be defined (defaults to C<1024 * 1024>).

All parameters can be set either as part of the configuration
file with the key C<XML-Loy> or on registration
(that can be overwritten by configuration).


=head1 HELPERS

=head2 new_xml

  my $xml = $c->new_xml('entry');
  print $xml->to_pretty_xml;

Creates a new generic L<XML::Loy> document.
All helpers created on registration accept
the parameters as defined in the constructors of
the L<XML::Loy> base classes.


=head2 reply->xml

  $c->reply->xml($xml);
  $c->reply->xml($xml, status => 404);

Renders documents based on L<XML::Loy>
using the defined mime-type of the base class.


=head1 DEPENDENCIES

L<Mojolicious>,
L<XML::Loy>.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-XML-Loy


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2016, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the terms of the Artistic License version 2.0.

=cut
