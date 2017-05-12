package Mojolicious::Plugin::PPI;

use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Util;
use Mojo::ByteStream 'b';

use File::Basename ();
use File::Spec;

use PPI::HTML;

our $VERSION = '0.07';
$VERSION = eval $VERSION;

has 'line_numbers'  => 1;
has 'no_check_file' => 0;
has 'ppi_html_on'  => sub { PPI::HTML->new( line_numbers => 1 ) };
has 'ppi_html_off' => sub { PPI::HTML->new( line_numbers => 0 ) };
has 'src_folder';

has style => <<'END';
.ppi-code { 
  display: inline-block;
  min-width: 400px;
  background-color: #F8F8F8;
  border-radius: 10px;
  padding: 15px;
}
END

has class_style => sub {{
  line_number_on   => { display => 'inline' },
  line_number_off  => { display => 'none'   },

  cast => '#339999',
  comment => '#008080',
  core => '#FF0000',
  double => '#999999',
  heredoc_content => '#FF0000',
  interpolate => '#999999',
  keyword => '#BD2E2A',
  line_number => '#666666',
  literal => '#999999',
  magic => '#0099FF',
  match => '#9900FF',
  number => '#990000',
  operator => '#DD7700',
  pod => '#008080',
  pragma => '#A33AF7',
  regex => '#9900FF',
  single => '#FF33FF',
  substitute => '#9900FF',
  symbol => '#389A7D',
  transliterate => '#9900FF',
  word => '#999999',
}};

sub register {
  my ($plugin, $app) = (shift, shift);
  $plugin->initialize($app, @_);

  push @{$app->static->classes},   __PACKAGE__;
  push @{$app->renderer->classes}, __PACKAGE__;

  $app->helper( ppi => sub {
    return $plugin if @_ == 1;
    return $plugin->convert(@_); 
  });
  $app->helper( ppi_css => sub { $_[0]->ppi->generate_css(@_) } );
}

sub initialize {
  my ($plugin, $app) = (shift, shift);
  my %opts = @_ == 1 ? %{$_[0]} : @_;
  my @unknown;
  foreach my $key (keys %opts) {
    my $code = $plugin->can($key);
    unless ($code) {
      push @unknown, $key;
      next;
    }
    $plugin->$code($opts{$key});
  }

  if ( @unknown ) {
    warn "Unknown option(s): " . join(", ", @unknown) . "\n";
  }
}

sub convert {
  my $plugin = shift;
  my $c = shift;

  my %opts = $plugin->process_converter_opts(@_);

  my $converter = 
    $opts{line_numbers}
    ? $plugin->ppi_html_on
    : $plugin->ppi_html_off;

  my $id = $plugin->generate_id($c);

  my @tag = (
    $opts{inline} ? 'code' : 'pre',
    id    => $id,
    class => 'ppi-code ' . ($opts{inline} ? 'ppi-inline' : 'ppi-block'),
  );

  if ($opts{line_numbers}) {
    push @tag, ondblclick => "ppi_toggleLineNumbers('$id')";
    $c->stash('ppi.js.required' => 1);
  }

  my %render_opts = (
    'ppi.code' => $converter->html( $opts{file} ? $opts{file} : \$opts{string} ),
    'ppi.tag'  => \@tag,
  );

  #TODO use render_to_string once Mojo 5.00 is required
  return $c->include('ppi_template', %render_opts);
}

sub generate_id {
  my ($plugin, $c) = @_;
  return 'ppi' . $c->stash->{'ppi.id'}++;
}

sub check_file {
  my ($self, $file) = @_;
  return undef if $self->no_check_file;

  if ( my $folder = $self->src_folder ) {
    die "Could not find folder $folder\n" unless -d $folder;
    $file = File::Spec->catfile( $folder, $file );
  }

  return -e $file ? $file : undef;
}

sub process_converter_opts {
  my $plugin = shift;

  my $string = do {
    no warnings 'uninitialized';
    if (ref $_[-1] eq 'CODE') {
      Mojo::Util::trim pop->();
    }
  };

  my %opts;
  if (ref $_[-1]) {
    %opts = %{ pop() };
  }

  if ( @_ % 2 ) { 
    die "Cannot specify both a string and a block\n" if $string;

    $string = shift;
    $opts{file} = $plugin->check_file($string);
    unless ( $opts{file} ) {
      $opts{inline} //= 1;
    }

  }

  %opts = (%opts, @_) if @_;

  $opts{string} = $string unless defined $opts{file};

  $opts{line_numbers} //= 0 if $opts{inline};
  $opts{line_numbers} //= $plugin->line_numbers;

  return %opts;
}

sub generate_css {
  my ($plugin, $c) = @_;
  my $sheet = b("pre.ppi-code br { display: none; }\n");
  $$sheet .= $plugin->style."\n";
  my $cs = $plugin->class_style;
  foreach my $key (sort keys %$cs) {
    my $value = $cs->{$key};
    $value = { color => $value } unless ref $value;
    $$sheet .= ".ppi-code .$key { ";
    foreach my $prop ( sort keys %$value ) {
      $$sheet .= "$prop: $value->{$prop}; ";
    }
    $$sheet .= "}\n";
  }
  return $c->stylesheet(sub{$sheet});
}

1;

__DATA__

@@ ppi_template.html.ep

% if ( stash('ppi.js.required') and not stash('ppi.js.added') ) {
  %= javascript '/ppi_js.js'
  % stash('ppi.js.added' => 1);
% }

<%= tag @{stash('ppi.tag')} => begin =%>
  <%== stash('ppi.code') =%>
<% end %>

@@ ppi_js.js

function ppi_toggleLineNumbers(id) {
  var spans = document.getElementById(id).getElementsByTagName("span");
  for (i = 0; i < spans.length; i++){
    var span = spans[i];
    
    if ( span.className.indexOf('line_number') == -1 ) {
      continue;
    }

    var cl = span.className.split(' ');
    var index_on  = cl.indexOf('line_number_on');
    var index_off = cl.indexOf('line_number_off');

    if (index_on != -1) {
      cl.splice(index_on, 1);
    }
    if (index_off != -1) {
      cl.splice(index_off, 1);
    }

    if ( index_off == -1 ) {
      cl.push('line_number_off');
    } else {
      cl.push('line_number_on');
    }

    span.className = cl.join(' ');
  }
}


__END__

=head1 NAME

Mojolicious::Plugin::PPI - Mojolicious Plugin for Rendering Perl Code Using PPI

=head1 SYNOPSIS

 # Mojolicious
 $self->plugin('PPI');

 # Mojolicious::Lite
 plugin 'PPI';

 # In your template
 Perl is as simple as <%= ppi q{say "Hello World"} %>.

=head1 DESCRIPTION

L<Mojolicious::Plugin::PPI> is a L<Mojolicious> plugin which adds Perl syntax highlighting via L<PPI> and L<PPI::HTML>. Perl is notoriously hard to properly syntax highlight, but since L<PPI> is made especially for parsing Perl this plugin can help you show off your Perl scripts in your L<Mojolicious> webapp.

=head1 ATTRIBUTES

L<Mojolicious::Plugin::PPI> inherits all methods from L<Mojolicious::Plugin> and implements the following new ones.

=over

=item *

C<< line_numbers => [0/1] >> specifies if line numbers should be generated. Defaults to C<1> for file-based snippets, however C<0> is used for an inline snipppet unless explicitly overridden in the helper arguments.

=item *

C<< no_check_file => [0/1] >> specifies if a file check should be performed. Default C<0>.

=item *

C<< src_folder => 'directory' >> specifies a folder where input files will be found. When specified, if the directory is not found, a warning is issued, but not fatally. This functionality is not (currently) available for per-file alteration, so only use if all files will be in this folder (or subfolder). Remember, if this option is not specified, a full or relative path may be passed to L</ppi>.

=item *

C<< style => '.ppi-code { some: style; }' >> a string of overall style sheet to be applied via the C<ppi_css> helper.

=item *

C<< class_style => { class => 'string color', other_class => { style => 'pairs' } } >> This hashref's keys are individual element style definitions. If the value is a string, it is used as the value of the color attribute. If the value is another hashref, it is converted into style definitions.

=back

=head1 METHODS

L<Mojolicious::Plugin::PPI> inherits all methods from L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

  $plugin->register;

Register plugin in L<Mojolicious> application. At register time, key-value pairs for the plugin attributes may be supplied.

=head1 HELPERS

L<Mojolicous::Plugin::PPI> provides these helpers:

=head2 C<ppi>

  %== ppi 'my $code = "highlighted";'
  %== ppi 'file.pl'

Returns HTML form of Perl snippet or file. The behavior may be slightly different in each case. If the argument is the name of a file that exists, it will be loaded and used. If not the string will be interpreted as an inline snippet. In either form, the call to C<ppi> may take the additional option:

Additional key-value pairs may be passed which override the object's defaults. Most attributes are available (except: C<no_check_file> for now) and the additional key C<inline> lets you override the default choice of display inline vs block (by string vs file respectively).

=head2 C<ppi_css>

Injects a generated CSS style into the page, using style properties defined in the plugin attributes.

=head1 SEE ALSO

L<Mojolicious>, L<PPI>, L<PPI::HTML>

L<PPI>, L<PPI::HTML>

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mojolicious-Plugin-PPI>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2013 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
