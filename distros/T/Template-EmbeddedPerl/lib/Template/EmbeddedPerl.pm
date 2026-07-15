package Template::EmbeddedPerl;

our $VERSION = '0.001016';
$VERSION = eval $VERSION;

use warnings;
use strict;
use utf8;

use PPI::Document;
use File::Spec;
use Digest::MD5;
use Encode qw(encode);
use Scalar::Util;
use Template::EmbeddedPerl::Arguments;
use Template::EmbeddedPerl::Compiled;
use Template::EmbeddedPerl::RenderContext;
use Template::EmbeddedPerl::RenderFrame;
use Template::EmbeddedPerl::Utils qw(
  diagnostic_source_label
  normalize_linefeeds
  generate_error_message
);
use Template::EmbeddedPerl::SafeString;
use Regexp::Common qw /balanced/;

our $ACTIVE_RENDERER;

# used for the variable interpolation feature
my $balanced_parens   = $RE{balanced}{-parens => '()'};
my $balanced_brackets = $RE{balanced}{-parens => '[]'};
my $balanced_curlies  = $RE{balanced}{-parens => '{}'};

# Custom recursive pattern for ${...}
my $balanced_dollar_curly = qr/
    \$\{
    (?<brace_content>
        [^{}]+
        |
        \{ (?&brace_content) \}
    )*
    \}
    /x;

my $variable_regex = qr/
    (?<!\\)                           # Negative lookbehind for backslash
    (?<variable>
      (?:                             # Variable can be in one of two formats:
        \$ \w+ (?: :: \w+ )*          # 1. $variable, possibly with package names
      |
        $balanced_dollar_curly        # 2. ${...}, using balanced delimiters
      )
      (?:                             # Non-capturing group for operators
        (?:
          (\s*)->(\s*)                # Dereference operator
          (?:
            \$? \w+                   # Method name, possibly starting with $
            (?: $balanced_parens )?   # Optional method arguments
          |
            $balanced_brackets        # Array dereference after '->'
          |
            $balanced_curlies         # Hash dereference after '->'
          )
        )
      |
        $balanced_brackets            # Array dereference
      |
        $balanced_curlies             # Hash dereference
      )*
    )
/x;


my $variable_regex2 = qr/
    (?<!\\)                           # Negative lookbehind for backslash
    (?<variable>                      # Named capturing group 'variable'
      \$
      \w+ (?: :: \w+ )*               # Variable name, possibly with package names
      (?:                             # Non-capturing group for operators
        (?:
          ->                          # Dereference operator
          (?:
            \$? \w+                       # Method name
            (?: $balanced_parens )?   # Optional method arguments
          |
            $balanced_brackets        # Array dereference after '->'
          |
            $balanced_curlies         # Hash dereference after '->'
          )
        )
      |
        $balanced_brackets            # Array dereference
      |
        $balanced_curlies             # Hash dereference
      )*
    )
/x;

## New Instance of the core template methods

sub raw { my ($self, @args) = @_; return Template::EmbeddedPerl::SafeString::raw(@args) }
sub safe { my ($self, @args) = @_; return Template::EmbeddedPerl::SafeString::safe(@args) }
sub safe_concat { my ($self, @args) = @_; return Template::EmbeddedPerl::SafeString::safe_concat(@args) }
sub html_escape { my ($self, @args) = @_; return Template::EmbeddedPerl::SafeString::html_escape(@args) }
sub url_encode { my ($self, @args) = @_; return Template::EmbeddedPerl::Utils::uri_escape(@args) }
sub escape_javascript { my ($self, @args) = @_; return Template::EmbeddedPerl::Utils::escape_javascript(@args) }

sub trim {
  my ($self, $string) = @_;
  if ( (Scalar::Util::blessed($string)||'') eq 'Template::EmbeddedPerl::SafeString') {
    $string =~s/^[ \t]+|[ \t]+$//g;
    return $self->raw($string);
  } else {
    $string =~s/^[ \t]+|[ \t]+$//g;
  }
  return $string;
}

sub mtrim {
  my ($self, $string) = @_;
  if ( (Scalar::Util::blessed($string)||'') eq 'Template::EmbeddedPerl::SafeString') {
    $string =~s/^[ \t]+|[ \t]+$//mg;
    return $self->raw($string);
  } else {
    $string =~s/^[ \t]+|[ \t]+$//mg;
  }
  return $string;
}

sub directory_for_package {
  my $self = shift;
  my $class = ref($self) || $self;
  my $package = @_ ? shift(@_) : $class;
 
  $package =~ s/::/\//g;
  my $path = $INC{"${package}.pm"};
  my ($volume,$directories,$file) = File::Spec->splitpath( $path );

  return $directories;
}

sub new {
  my $class = shift;
  my (%args) = (
    open_tag => '<%',
    close_tag => '%>',
    expr_marker => '=',
    line_start => '%',
    smart_lines => 0,
    sandbox_ns => 'Template::EmbeddedPerl::Sandbox',
    directories => [],
    template_extension => 'epl',
    auto_escape => 0,
    auto_flatten_expr => 1,
    prepend => '',
    preamble => '',
    use_cache => 0,
    vars => 0,
    comment_mark => '#',
    interpolation => 0,
    @_,
  );

  %args = (%args, $class->config,) if $class->can('config');

  my $self = bless \%args, $class;

  $self->inject_helpers;
  return $self;
}

sub inject_helpers {
  my ($self) = @_;
  my $sandbox_ns = $self->{sandbox_ns};
  die "Invalid sandbox namespace '$sandbox_ns'"
    unless defined($sandbox_ns) && $sandbox_ns =~ /\A[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*\z/;

  my %helpers = $self->get_helpers;
  foreach my $helper(keys %helpers) {
    die "Invalid template helper name '$helper'"
      unless $helper =~ /\A[A-Za-z_]\w*\z/;

    if($self->{sandbox_ns}->can($helper)) {
      warn "Skipping injection of helper '$helper'; already exists in namespace $self->{sandbox_ns}" 
        if $ENV{DEBUG_TEMPLATE_EMBEDDED_PERL};
      next;
    }
    eval qq[
      package @{[ $self->{sandbox_ns} ]};
      sub $helper {
        my \$context = Template::EmbeddedPerl->_current_render_context('$helper');
        my \$engine = \$context->engine;
        \$engine->get_helpers('$helper')->(\$engine, \@_);
      }
    ]; die $@ if $@;
  }
}

sub _current_render_context {
  my ($class, $helper) = @_;
  my $context = $ACTIVE_RENDERER;

  die "Template helper '$helper' called outside render context" unless $context;

  return $context;
}

sub _new_render_context {
  my ($self, %args) = @_;
  return Template::EmbeddedPerl::RenderContext->new(
    engine => $self,
    frame => Template::EmbeddedPerl::RenderFrame->new,
    %args,
  );
}

sub render_view {
  my ($self, $view) = @_;
  die "render_view requires a blessed view object\n"
    unless Scalar::Util::blessed($view);

  my $context = $self->_new_render_context(
    view => $view,
    root_view => $view,
  );
  return $context->render_view_object($view);
}

sub get_helpers {
  my ($self, $helper) = @_;
  my %helpers = ($self->default_helpers, %{ $self->{helpers} || +{} });

  %helpers = (%helpers, $self->helpers) if $self->can('helpers');
 
  return $helpers{$helper} if defined $helper;
  return %helpers;
}

sub default_helpers {
  my $self = shift;
  return (
    raw               => sub { my ($self, @args) = @_; return $self->raw(@args); },
    safe              => sub { my ($self, @args) = @_; return $self->safe(@args); },
    safe_concat       => sub { my ($self, @args) = @_; return $self->safe_concat(@args); },
    html_escape       => sub { my ($self, @args) = @_; return $self->html_escape(@args); },
    url_encode        => sub { my ($self, @args) = @_; return $self->url_encode(@args); },
    escape_javascript => sub { my ($self, @args) = @_; return $self->escape_javascript(@args); },
    trim              => sub { my ($self, $arg) = @_; return $self->trim($arg); },
    mtrim             => sub { my ($self, $arg) = @_; return $self->mtrim($arg); },
    partial           => sub {
      my ($engine, $identifier, @args) = @_;
      my $context = Template::EmbeddedPerl->_current_render_context('partial');
      my $output = $context->render_file('partial', $identifier, @args);
      return $engine->raw($output);
    },
    view              => sub {
      my ($engine, $target, @args) = @_;
      my $body = @args && ref($args[-1]) eq 'CODE' ? pop @args : undef;
      my $context = Template::EmbeddedPerl->_current_render_context('view');
      my $output = $context->frame->with_transaction(sub {
        my $child = $context->build_child_view($target, \@args);
        my $captured = $body ? $body->($child) : '';
        return $context->frame->with_body(
          defined($captured) ? $captured : '',
          sub {
            return $context->with(view => $child)->render_view_object($child);
          },
        );
      });
      return $engine->raw($output);
    },
    layout            => sub {
      my ($engine, $identifier, @args) = @_;
      my $context = Template::EmbeddedPerl->_current_render_context('layout');
      $context->frame->register_layout($identifier, @args);
      return;
    },
    content_for       => sub {
      my ($engine, @args) = @_;
      my ($name, $callback) = _content_capture_arguments('content_for', @args);
      my $frame = Template::EmbeddedPerl->_current_render_context('content_for')->frame;
      my $output = $callback->();
      $frame->append_content($name, $engine->raw(defined $output ? $output : ''));
      return;
    },
    content_replace   => sub {
      my ($engine, @args) = @_;
      my ($name, $callback) = _content_capture_arguments('content_replace', @args);
      my $frame = Template::EmbeddedPerl->_current_render_context('content_replace')->frame;
      my $output = $callback->();
      $frame->replace_content($name, $engine->raw(defined $output ? $output : ''));
      return;
    },
    has_content       => sub {
      my ($engine, @args) = @_;
      my ($name) = _content_name_arguments('has_content', @args);
      return Template::EmbeddedPerl->_current_render_context('has_content')->frame
        ->has_content($name);
    },
    yield             => sub {
      my ($engine, @args) = @_;
      my $frame = Template::EmbeddedPerl->_current_render_context('yield')->frame;
      my $output = @args
        ? $frame->content(_content_name_arguments('yield', @args))
        : $frame->default_body;
      return $engine->raw($output);
    },
    to_safe_string    => sub {
      my ($engine, @args) = @_;
      my $context = Template::EmbeddedPerl->_current_render_context('to_safe_string');
      my $receiver = defined($context->view) ? $context->view : $engine;
      return map {
        Scalar::Util::blessed($_) && $_->can('to_safe_string')
        ? $_->to_safe_string($receiver)
        : $_;
      } @args;
    },
  );
}

sub _content_capture_arguments {
  my ($helper, @args) = @_;
  die "Invalid $helper arguments" unless @args == 2;
  my ($name, $callback) = @args;
  die "Invalid $helper name" unless defined($name) && !ref($name) && length($name);
  die "Invalid $helper callback" unless ref($callback) eq 'CODE';
  return ($name, $callback);
}

sub _content_name_arguments {
  my ($helper, @args) = @_;
  die "Invalid $helper arguments" unless @args == 1;
  my ($name) = @args;
  die "Invalid $helper name" unless defined($name) && !ref($name) && length($name);
  return $name;
}

# Create a new template document in various ways

sub from_string {
  my ($proto, $template, %args) = @_;
  my $source = delete($args{source});
  my $identifier = delete($args{identifier});
  my $self = ref($proto) ? $proto : $proto->new(%args);
  my $diagnostic_source = diagnostic_source_label($source);

  my $digest;
  if($self->{use_cache}) {
    $self->{compiled_cache} ||= {};
    $digest = Digest::MD5::md5_hex(
      $template,
      "\0template-source\0",
      encode('UTF-8', $diagnostic_source),
    );
    if(my $cached = $self->{compiled_cache}->{$digest}) {
      return bless {
        template => $cached->{template},
        parsed => $cached->{parsed},
        code => $cached->{code},
        yat => $self,
        source => $source,
        identifier => $identifier,
      }, 'Template::EmbeddedPerl::Compiled';     
    }  
  }

  $template = normalize_linefeeds($template);

  my @template = split(/\n/, $template);
  my ($rewritten_template) = eval {
    Template::EmbeddedPerl::Arguments->rewrite(
      $template,
      comment_mark => $self->{comment_mark},
      line_start => $self->{line_start},
      open_tag => $self->{open_tag},
      close_tag => $self->{close_tag},
    );
  };
  if ($@) {
    my $error = $@;
    $error =~ s/ at template line (\d+)\n\z/ at $diagnostic_source line $1\n/;
    die $error;
  }

  my @parsed = $self->parse_template($rewritten_template);
  my $code = $self->compile(\@template, $source, @parsed);

  if($self->{use_cache}) {
    $self->{compiled_cache}->{$digest} = {
      template => \@template,
      parsed => \@parsed,
      code => $code,
    };
  }

  return bless {
    template => \@template,
    parsed => \@parsed,
    code => $code,
    yat => $self,
    source => $source,
    identifier => $identifier,
  }, 'Template::EmbeddedPerl::Compiled'; 
}

sub from_data {
  my ($proto, $package, @args) = @_;

  die "Invalid package name '$package'"
    unless defined($package) && $package =~ /\A[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*\z/;

  my $package_file = $package;
  $package_file =~ s{::}{/}g;
  eval { require "${package_file}.pm"; 1 }; if ($@) {
    die "Failed to load package '$package': $@";
  }

  my $data_handle = do { no strict 'refs'; *{"${package}::DATA"}{IO} };
  if (defined $data_handle) {
    my $position = tell($data_handle);
    my $data_content = do { local $/; <$data_handle> };
    seek($data_handle, $position, 0)
      or die "Failed to restore __DATA__ handle for package '$package': $!"
      if defined($position) && $position >= 0;
    my $path = $INC{"${package_file}.pm"};
    return $proto->from_string($data_content, @args, source => "@{[ $path || $package ]}/DATA");
  } else {
    die "No __DATA__ section found in package '$package'";
  }
}

sub from_fh {
  my ($proto, $fh, @args) = @_;
  my $data = do { local $/; <$fh> };
  close $fh;

  return $proto->from_string($data, @args);
}

sub from_file {
  my ($proto, $file_proto, @args) = @_;
  my $self = ref($proto) ? $proto : $proto->new(@args);
  my $path = $self->_resolve_template_file($file_proto);
  $Template::EmbeddedPerl::RenderContext::SOURCE_OBSERVER->($self, $file_proto, $path)
    if $Template::EmbeddedPerl::RenderContext::SOURCE_OBSERVER;
  return $self->_from_resolved_file($file_proto, $path, @args);
}

sub _from_resolved_file {
  my ($self, $identifier, $path, @args) = @_;
  open my $fh, '<', $path or die "Failed to open file $path: $!";
  my %args = (@args, source => $path, identifier => $identifier);
  return $self->from_fh($fh, %args);
}

sub _template_candidates {
  my ($self, $identifier) = @_;
  my $file = "$identifier.$self->{template_extension}";
  return map {
    File::Spec->catfile(ref($_) eq 'ARRAY' ? File::Spec->catdir(@$_) : $_, $file)
  } @{ $self->{directories} };
}

sub _resolve_template_file {
  my ($self, $identifier) = @_;
  my @candidates = $self->_template_candidates($identifier);
  return $_ for grep { -e $_ } @candidates;
  die "Template '$identifier' not found; searched: " . join(', ', @candidates) . "\n";
}

sub _snake_case_segment {
  my ($self, $segment) = @_;
  $segment =~ s/([A-Z]+)([A-Z][a-z])/$1_$2/g;
  $segment =~ s/([a-z0-9])([A-Z])/$1_$2/g;
  return lc $segment;
}

sub _class_to_template {
  my ($self, $class) = @_;
  my $namespace = $self->{view_namespace};
  my $prefix = defined($namespace) ? "$namespace\::" : undef;

  die "Cannot resolve template for view class '$class'\n"
    unless defined($prefix) && index($class, $prefix) == 0;

  my $suffix = substr($class, length($prefix));
  die "Cannot resolve template for view class '$class'\n" unless length($suffix);

  return join '/', map { $self->_snake_case_segment($_) } split /::/, $suffix;
}

sub _logical_view_class {
  my ($self, $logical_name) = @_;

  die "Invalid logical view name '$logical_name'\n"
    unless defined($logical_name)
      && !ref($logical_name)
      && $logical_name =~ /\A[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*\z/;

  my $namespace = $self->{view_namespace};
  die "Logical view '$logical_name' requires view_namespace\n"
    unless defined($namespace) && length($namespace);
  die "Invalid view_namespace '$namespace'\n"
    unless $namespace =~ /\A[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*\z/;

  return "$namespace\::$logical_name";
}

sub _construct_view {
  my ($self, $logical_name, $args, $context) = @_;
  my $class = $self->_logical_view_class($logical_name);

  unless ($class->can('new')) {
    my $class_file = "$class.pm";
    $class_file =~ s{::}{/}g;
    my $loaded = eval { require $class_file; 1 };
    die "Failed to load logical view '$logical_name' as '$class': $@"
      unless $loaded;
  }

  my $factory = $self->{view_factory};
  die "view_factory must be a code reference\n"
    if defined($factory) && ref($factory) ne 'CODE';

  my $view;
  if ($factory) {
    my $constructed = eval {
      $view = $factory->($class, {%$args}, $context);
      1;
    };
    die "view_factory failed for logical view '$logical_name' as '$class': $@"
      unless $constructed;
  } else {
    my $constructed = eval {
      $view = $class->new(%$args);
      1;
    };
    die "Failed to construct logical view '$logical_name' as '$class': $@"
      unless $constructed;
  }

  die "view_factory did not return a blessed view for '$logical_name'\n"
    if $factory && !Scalar::Util::blessed($view);
  die "Constructor did not return a blessed view for '$logical_name'\n"
    unless Scalar::Util::blessed($view);

  return $view;
}

sub _resolve_view_template {
  my ($self, $view) = @_;
  my $class = Scalar::Util::blessed($view) || ref($view) || "$view";

  if (Scalar::Util::blessed($view) && $view->can('template')) {
    my $template = $view->template;
    return $template if defined($template) && length($template);
  }

  return $self->_class_to_template($class);
}

# Methods to parse and compile the template

sub parse_template {
  my ($self, $template) = @_;
  my $open_tag = $self->{open_tag};
  my $close_tag = $self->{close_tag};
  my $expr_marker = $self->{expr_marker};
  my $line_start = $self->{line_start};
  my $comment_mark = $self->{comment_mark};
  my $trim_close_tag = "-${close_tag}";
  my $expr_trim_close_tag = "${expr_marker}${close_tag}";

  ## support shorthand line start tags ##

  if ($self->{smart_lines}) {
    $template =~ s{\r\n}{\n}g;
    $template =~ s{
        ^[\t ]*\Q${line_start}${expr_marker}\E(.*?)(\n|\z)
    }{
        $open_tag . $expr_marker . $1 . $close_tag
          . (length($2) ? "\\\n" : '')
    }mgex;
    $template =~ s{
        ^[\t ]*(?!\Q${close_tag}\E[\t ]*$)\Q${line_start}\E(.*?)(\n|\z)
    }{
        $open_tag . $1 . $close_tag
          . (length($2) ? "\\\n" : '')
    }mgex;
  } else {
    # Convert all lines starting with %= to start with <%= and then add %> to the end
    $template =~ s{^\s*\Q${line_start}${expr_marker}\E(.*?)(?=\\?$)}{${open_tag}${expr_marker}$1${close_tag}}mg;
    # Convert all lines starting with % to start with <% and then add %> to the end
    # Exclude lines containing only the closing tag from conversion.
    $template =~ s{^\s*(?!\Q${close_tag}\E\s*\\?$)\Q${line_start}\E(.*?)(?=\\?$)}{${open_tag}$1${close_tag}}mg;
  }

  ## Escapes so you can actually have % and %= in the template
  # Convert all lines starting with \%= to start instead with %=
  $template =~ s{^\s*\\\Q${line_start}${expr_marker}\E(.*)$}{${line_start}${expr_marker}$1}mg;
  # Convert all lines starting with \% to start instead with %
  $template =~ s{^\s*\\\Q${line_start}\E(.*)$}{${line_start}$1}mg;

  # This code parses the template and returns an array of parsed blocks.
  # Each block is represented as an array reference with two elements: the type and the content.
  # The type can be 'expr' for expressions enclosed in double square brackets,
  # 'code' for code blocks enclosed in double square brackets,
  # or 'text' for plain text blocks.
  # The content is the actual content of the block, trimmed of leading and trailing whitespace.

  #my @segments = split /(\Q${open_tag}\E.*?\Q${close_tag}\E)/s, $template;
  my @segments = split /((?<!\\)\Q${open_tag}\E.*?(?<!\\)\Q${close_tag}\E)/s, $template;
  my @parsed = ();
  my $trim_next_text = 0;

  foreach my $segment (@segments) {

    my ($open_type, $content, $close_type) = ($segment =~ /^(\Q${open_tag}${expr_marker}\E|\Q$open_tag\E)(.*?)(\Q${trim_close_tag}\E|\Q${expr_trim_close_tag}\E|\Q$close_tag\E)?$/s);
    if(!$open_type) {
      if($trim_next_text) {
        $trim_next_text = 0;
        if($segment =~ s/\A[ \t]*\n//) {
          $segment = "\\\n$segment";
        } else {
          $segment =~ s/\A[ \t]*\z//;
        }
      }

      # Remove \ from escaped line_start, open_tag, and close_tag
      $segment =~ s{\\\Q${line_start}\E}{${line_start}}g;
      $segment =~ s{\\\Q${open_tag}\E}{${open_tag}}g;
      $segment =~ s{\\\Q${close_tag}\E}{${close_tag}}g;
      $segment =~ s{\\\Q${expr_marker}${close_tag}\E}{${expr_marker}${close_tag}}g;

      # check the segment for comment lines 
      $segment =~ s{^[ \t]*?\Q${comment_mark}\E.*?(\\?)$}{$1}mg;
      $segment =~ s{^[ \t]*?\\\Q${comment_mark}\E}{${comment_mark}}mg;

      if($self->{interpolation}) {
        my @parts = ();
        my $pos = 0;

        while ($segment =~ /$variable_regex/g) {

            my $match_start = $-[0];
            my $match_end   = $+[0];
            my $matched_var = $+{variable};

            # Add non-matching part before the match
            if ($match_start > $pos) {
              my $text = substr($segment, $pos, $match_start - $pos);
              $text =~ s/\\\$/\$/gm; # Any escaped $ (\$) should be unescaped
              push @parts, ['text', $text ];
            }

            # Add the matching variable
            push @parts, ['expr', $matched_var ];

            $pos = $match_end;
        }
        # Add any remaining non-matching part
        if ($pos < length($segment)) {
            my $text = substr($segment, $pos);
            $text =~ s/\\\$/\$/gm; # Any escaped $ (\$) should be unescaped
            push @parts, [ 'text', $text ];
        }
        push @parsed, @parts;
      } else {
        push @parsed, ['text', $segment];
      }
    } else {
      $trim_next_text = 0 if $trim_next_text;

      # Support trim with =%>
      $content = "trim $content"
        if $open_type eq "${open_tag}${expr_marker}" && $close_type eq $expr_trim_close_tag;
      $trim_next_text = 1 if $close_type eq $trim_close_tag;

      # ?? ==%> or maybe something else...
      # $parsed[-1][1] =~s/[ \t]+$//mg if $close_type eq "${expr_marker}${close_tag}";
 
      # Remove \ from escaped line_start, open_tag, and close_tag
      $content =~ s{\\\Q${line_start}\E}{${line_start}}g;
      $content =~ s{\\\Q${open_tag}\E}{${open_tag}}g;
      $content =~ s{\\\Q${close_tag}\E}{${close_tag}}g;
      $content =~ s{\\\Q${expr_marker}${close_tag}\E}{${expr_marker}${close_tag}}g;

      if ($open_type eq "${open_tag}${expr_marker}") {
        push @parsed, ['expr', tokenize($content)];
      } elsif ($open_type eq $open_tag) {
        push @parsed, ['code', tokenize($content)];
      }
    }
  }

  return @parsed;
}

sub compile {
  my ($self, $template, $source, @parsed) = @_;

  my $compiled = '';
  my $safe_or_not = '';
  my $flatten_or_not = '';

  if($self->{auto_escape} && $self->{auto_flatten_expr}) {
    $safe_or_not = ' safe_concat to_safe_string ';
  } else {
    $safe_or_not = $self->{auto_escape} ? ' safe to_safe_string ' : '';
    $flatten_or_not = $self->{auto_flatten_expr} ? ' join "", ' : '';
  }

  for my $block (@parsed) {
    next if $block eq '';
    my ($type, $content, $has_unmatched_open, $has_unmatched_closed) = @$block;

    if ($type eq 'expr') { # [[= ... ]]
      $compiled .= '$_O .= ' . $flatten_or_not . $safe_or_not . $content . ";";
    } elsif ($type eq 'code') { # [[ ... ]]
      $compiled .= $content . ";";
    } else {
      # if \\n is present in the content, replace it with ''
      my $escaped_newline_start = $content =~ s/^\\\n//mg;
      my $escaped_newline_end = $content =~ s/\\\n$//mg;

      $content =~ s/^\\\\/\\/mg;   
      $compiled .= ("\n" x $escaped_newline_start)
        . ' $_O .= "' . quotemeta($content) . '";'
        . ("\n" x $escaped_newline_end);
    }
  }

  $compiled = $self->compiled($compiled, $source);

  warn "Compiled: $compiled\n" if $ENV{DEBUG_TEMPLATE_EMBEDDED_PERL};

  my $code = eval $compiled; if($@) {
    die generate_error_message($@, $template, $source);
  }

  return $code;
}

sub compiled {
  my ($self, $compiled, $source) = @_;
  my $diagnostic_source = diagnostic_source_label($source);
  my $wrapper = "package @{[ $self->{sandbox_ns} ]}; ";
  $wrapper .= "use strict; use warnings; use utf8; @{[ $self->{preamble} ]}; ";
  $wrapper .= "sub { my \$__context = shift; my \$_O = ''; my \$self = \$__context->view; @{[ $self->{prepend} ]};\n";
  $wrapper .= qq{#line 1 "$diagnostic_source"\n};
  $wrapper .= "${compiled}; return \$_O; };";
  return $wrapper;
}

sub tokenize {
  my $content = shift;
  my $document = PPI::Document->new(\$content);
  my ($has_unmatched_open, $has_unmatched_closed) = mark_unclosed_blocks($document);
  return ($document, $has_unmatched_open, $has_unmatched_closed);
}

sub mark_unclosed_blocks {
  my ($element) = @_;
  my $blocks = $element->find('PPI::Structure::Block');
  my $has_unmatched_open = mark_unclosed_open_blocks($element); 
  my $has_unmatched_closed = mark_unmatched_close_blocks($element);

  return ($has_unmatched_open, $has_unmatched_closed);
}

sub is_control_block {
  my ($block) = @_;

  # Get the parent of the block
  my $parent = $block->parent;

  # Check if the parent is a control statement
  if ($parent && ($parent->isa('PPI::Statement::Compound') || $parent->isa('PPI::Statement'))) {
    my $keyword = $parent->schild(0); # Get the first child of the statement, which should be the control keyword
    if ($keyword && $keyword->isa('PPI::Token::Word')) {
      # Check if the keyword is a control structure keyword
      return 1 if $keyword->content =~ /^(if|else|elsif|while|for|foreach|unless|given|when|until)$/;
    }
  }

  return 0;
}

sub mark_unclosed_open_blocks {
  my ($element, $level) = @_;
  my $blocks = $element->find('PPI::Structure::Block');
  return unless $blocks;

  my $has_unmatched_open = 0;
  foreach my $block (@$blocks) {
    next if $block->finish; # Skip if closed
    next if is_control_block($block);
    $has_unmatched_open = 1;
    
    my @children = @{$block->{children}||[]};
    $block->{children} = [
      bless({ content => " " }, 'PPI::Token::Whitespace'),
      bless({
        children => [
          bless({ content => " " }, 'PPI::Token::Whitespace'),
          bless({
            children => [
              bless({ content => "my" }, 'PPI::Token::Word'),
              bless({ content => " " }, 'PPI::Token::Whitespace'),
              bless({ content => "\$_O" }, 'PPI::Token::Symbol'),
              bless({ content => "=" }, 'PPI::Token::Operator'),
              bless({ content => "\"\"", separator => "\"" }, 'PPI::Token::Quote::Double'),
            ],
          }, 'PPI::Statement::Variable'),
          @children,
        ],
      }, 'PPI::Statement'),
    ];
  }
  return $has_unmatched_open;
}

sub mark_unmatched_close_blocks {
  my ($element, $level) = @_;
  my $blocks = $element->find('PPI::Statement::UnmatchedBrace');
  return unless $blocks;

  foreach my $block (@$blocks) {
    next if $block eq ')'; # we only care about }
    my @children = @{$block->{children}||[]};
    $block->{children} = [
      bless({ content => 'raw' }, 'PPI::Token::Word'),
      bless({
          children => [
              bless({
                  children => [
                      bless({ content => '$_O' }, 'PPI::Token::Symbol'),
                  ],
              }, 'PPI::Statement::Expression'),
          ],
          start  => bless({ content => '(' }, 'PPI::Token::Structure'),
          finish => bless({ content => ')' }, 'PPI::Token::Structure'),
      }, 'PPI::Structure::List'),
      bless({ content => ';' }, 'PPI::Token::Structure'),
      @children,
    ],
  }
  return 1;
}

sub render {
  my ($self, $template, @args) = @_;
  my $compiled = $self->from_string($template);
  return $compiled->render(@args);
}

1;

=head1 NAME

Template::EmbeddedPerl - A template processing engine using embedding Perl code

=head1 SYNOPSIS

  use Template::EmbeddedPerl;

Create a new template object:

  my $template = Template::EmbeddedPerl->new(); # default open and close tags are '<%' and '%>'

Compile a template from a string:

  my $compiled = $template->from_string('Hello, <%= shift %>!');

execute the compiled template:

  my $output = $compiled->render('John');

C<$output> is:

  Hello, John!

You can also use class methods to create compiled templates
in one step if you don't need the reusable template object

  my $compiled = Template::EmbeddedPerl->from_string('Hello, <%= shift %>!');
  my $output = $compiled->render('John');

Or you can render templates from strings directly:

  my $template = Template::EmbeddedPerl->new(use_cache => 1); # cache compiled templates
  my $output = $template->render('Hello, <%= shift %>!', 'John');

Other class methods are available to create compiled templates from files, file handles, 
and data sections.  See the rest of the docs for more information.

=head1 DESCRIPTION

C<Template::EmbeddedPerl> is a template engine that allows you to embed Perl code
within template files or strings. It provides methods for creating templates
from various sources, including strings, file handles, and data sections.

The module also supports features like helper functions, automatic escaping,
and customizable template compilation namespaces.

Its quite similar to L<Mojo::Template> and other embedded Perl template engines
but its got one trick the others can't do (see L<EXCUSE> below).

The core supports standalone composition with partials, layouts, named content
blocks, and optional typed view objects. Framework integrations can provide a
view resolver when logical child names need application-specific construction
or dependency injection.

=head1 ACKNOWLEDGEMENTS

I looked at L<Mojo::Template> and I lifted some code and docs from there.  I also
copied some of their test cases.   I was shooting for something reasonable similar
and potentially compatible with L<Mojo::Template> but with some additional features.
L<Template::EmbeddedPerl> is similiar to how template engines in popular frameworks 
like Ruby on Rails and also similar to EJS in the JavaScript world.  So nothing weird
here, just something people would understand and be comfortable with.  A type of
lowest common denominator.  If you know Perl, you will be able to use this after
a few minutes of reading the docs (or if you've used L<Mojo::Template> or L<Mason>
you might not even need that).

=head1 EXCUSE

Why create yet another one of these embedded Perl template engines?  I wanted one
that could properly handle block capture like following:

    <% my @items = map { %>
      <p><%= $_ %></p>
    <% } @items %>

Basically none of the existing ones I could find could handle this.  If I'm wrong
and somehow there's a flag or approach in L<Mason> or one of the other ones that
can handle this please let me know.

L<Mojo::Template> is close but you have to use C<begin> and C<end> tags to get a similar
effect and it's not as flexible as I'd like plus I want to be able to use signatures in
code like the following:

    <%= $f->form_for($person, sub($view, $fb, $person) { %>
      <div>
        <%= $fb->label('first_name') %>
        <%= $fb->input('first_name') %>
        <%= $fb->label('last_name') %>
        <%= $fb->input('last_name') %>
      </div>
    <% }) %>

Again, I couldn't find anything that could do this.   Its actually tricky because of the way
you need to localize capture of template output when inside a block.  I ended up using L<PPI>
to parse the template so I could properly find begin and end blocks and also distinguish between
control blocks (like C<if> an C<unless>) blocks that have a return like C<sub> or C<map> blocks.
In L<Mojo::Template> you can do the following (its the same but not as pretty to my eye):

    <% my $form = $f->form_for($person, begin %>
      <% my ($view, $fb, $person) = @_; %>
      <div>
        <%= $fb->label('first_name') %>
        <%= $fb->input('first_name') %>
        <%= $fb->label('last_name') %>
        <%= $fb->input('last_name') %>
      </div>
    <% end; %>

On the other hand my system is pretty new and I'm sure there are bugs and issues I haven't
thought of yet.  So you probably want to use one of the more mature systems like L<Mason> or
L<Mojo::Template> unless you really need the features I've added. Or your being forced to use
it because you're working for me ;)

=head1 TEMPLATE SYNTAX

The template syntax is similar to other embedded Perl template engines. You can embed Perl
code within the template using opening and closing tags. The default tags are C<< '<%' >> and
C<< '%>' >>, but you can customize them when creating a new template object.  You should pick
open and closing tags that are not common in your template content.

All templates get C<strict>, C<warnings> and C<utf8> enabled by default.  Please note this
is different than L<Mojo::Template> which does not seem to have warnings enabled by default.
Since I like very strict templates this default makes sense to me but if you tend to play
fast and loose with your templates (for example you don't use C<my> to declare variables) you
might not like this.  Feel free to complain to me, I might change it.

Basic Patterns:

  <% Perl code %>
  <%= Perl expression, replaced with result %>

Examples:

  <% my @items = qw(foo bar baz) %>
  <% foreach my $item (@items) { %>
    <p><%= $item %></p>
  <% } %>

Would output:

  <p>foo</p>
  <p>bar</p>
  <p>baz</p>

You can also use the 'line' version of the tags to make it easier to embed Perl code, or at
least potentially easier to read.  For example:

% my @items = qw(foo bar baz)
% foreach my $item (@items) {
    <p><%= $item %></p>
% }

=head2 Smart Lines and Named Arguments

Set C<smart_lines> to a true value to make a line beginning with C<< % >> or C<< %= >>
a complete directive without a trailing delimiter. This is especially useful
for declarative named template arguments:

  % args $name, $greeting = 'Hello', $heading = sub { "Hello, $name" }
  <p><%= $heading %></p>

C<args> must be the first executable directive. An argument without a default
is required; a scalar expression supplies a default; a coderef is a lazy
default evaluated only when its argument is absent. An explicit C<undef> is a
supplied value and does not evaluate a lazy default. Render arguments are named
key/value pairs when a template declares C<args>.


You can add '=' to the closing tag to indicate that the expression should be trimmed of leading
and trailing whitespace. This is useful when you want to include the expression in a block of text.
where you don't want the whitespace to affect the output.

  <%= Perl expression, replaced with result, trimmed =%>

You can add '-' to the closing tag to trim whitespace after the tag through the next
newline. This is useful when a readable code block should not emit a leading newline
before the next element, for example in partial HTML responses.

  <% Perl code -%>
  <%= Perl expression, replaced with result -%>

If you want to skip the newline after the closing tag you can use a backslash.

  <% Perl code %>\
  <%= Perl expression, replaced with result, no newline %>\

You probably don't care about this so much with HTML since it collapses whitespace but it can be
useful for other types of output like plain text or if you need some embedded Perl inside
your JavaScript.

If you really need that backslash in your output you can escape it with another backslash.

  <%= "This is a backslash: " %>\\

If you really need to use the actual tags in your output you can escape them with a backslash.

  \<%       => <%
  \<%=      => <%=
  \%>       => %>
  \%=       => %=
  \%        => %

Lastly you can add full line comments to your templates that will be removed from the final
output

  # This is a comment
  <p>Regular HTML</p>

A comment is declared with a single C<#> at the start of the line (or with only whitespace preceeding it).
This line will be removed from the output, including its newline.   If you really need a '#'you can escape it
with C<\#> (this is only needed if the '#' is at the beginning of the line, or there's only preceding whitespace.

=head2 Interpolation Syntax

If you want to embed Perl variables directly in the template without using the C<%= ... %> syntax,
you can enable interpolation. This allows you to embed Perl variables directly in the template
without using the C<%= ... %> syntax. For example:

  my $template = Template::EmbeddedPerl->new(interpolation => 1, prepend => 'my $name = shift');
  my $compiled = $template->from_string('Hello, $name!');
  my $output = $compiled->render('John');

C<$output> is:

  Hello, John!

This works by noticing a '$' followed by a Perl variable name (and method calls, etc). So if you
need to put a real '$' in your code you will need to escape it with C<\$>.

This only works on a single line and is intended to help reduce template complexity and noise
for simple placeholder template sections.  Nevertheless I did try top make it work with reasonable
complex single variable expressions.  Submit a test case if you find something that doesn't work
which you think should.

See the section on the interpolation configuration switch below for more information.  This is
disabled by default and I consider it experimental at this time since parsing Perl code with
regular expressions is a bit of a hack.

=head1 METHODS

=head2 new

  my $template = Template::EmbeddedPerl->new(%args);

Creates a new C<Template::EmbeddedPerl> object. Accepts the following arguments:

=over 4

=item * C<open_tag>

The opening tag for template expressions. Default is C<< '<%' >>. You should use
something that's not common in your template content.

=item * C<close_tag>

The closing tag for template expressions. Default is C<< '%>' >>.

=item * C<expr_marker>

The marker indicating a template expression. Default is C<< '=' >>.

=item * C<sandbox_ns>

The namespace where templates are compiled. Default is C<< 'Template::EmbeddedPerl::Sandbox' >>.
This isolates unqualified symbols but is not a security boundary: templates execute arbitrary
Perl and can access modules, files, processes, and application globals. Only compile templates
from trusted sources.

=item * C<directories>

An array reference of directories to search for templates. Default is an empty array.
A directory to search can be either a string or an array reference containing each part
of the path to the directory.  Directories will be searched in order listed.

  my $template = Template::EmbeddedPerl->new(directories=>['/path/to/templates']);
  my $template = Template::EmbeddedPerl->new(directories=>[['/path', 'to', 'templates']]);

I don't do anything smart to make sure you don't reference templates in dangerous places.
So be careful to make sure you don't let application users specify the template path.

The first matching file wins. Partials, layouts, explicit typed-view templates,
and convention-derived typed-view templates use this same ordered search path.

=item * C<smart_lines>

Boolean indicating whether a line beginning with C<< % >> or C<< %= >> is a complete
directive. Default is C<0>. See L</Smart Lines and Named Arguments>.

=item * C<view_namespace>

Optional namespace prefix for logical typed-view class lookup and
convention-based typed-view template lookup. For a logical name, the engine
prefixes this namespace to find the class. For a view without an explicit
template, the matching prefix is removed, C<::> becomes C</>, and each
remaining CamelCase segment is converted to lowercase snake case. Acronym runs
stay together: C<HTML>, C<HTMLPage>, and C<ContactList> become C<html>,
C<html_page>, and C<contact_list>.

For example, C<MyApp::View::HTML::ContactList> with
C<view_namespace =E<gt> 'MyApp::View'> resolves C<html/contact_list> before the
normal C<template_extension> is added.

=item * C<view_factory>

Optional coderef used to construct nested logical typed views. It receives
C<< ($class, \%args, $context) >> and must return a blessed object. C<$class>
is the class resolved from the logical name and C<view_namespace>; C<\%args>
contains only values supplied by the template. Use it for dependency injection,
such as C<root> and C<parent> relationships. Without a factory, the engine
calls C<< $class->new(%args) >>.

=item * C<template_extension>

The file extension for template files. Default is C<< 'epl' >>. So for example:

  my $template = Template::EmbeddedPerl->new(directories=>['/path/to/templates', 'path/to/other/templates']);
  my $compiled = $template->from_file('hello');

Would look for a file named C<hello.epl> in the directories specified.

=item * C<auto_escape>

Boolean indicating whether to automatically escape content. Default is C<< 0 >>.
You probably want this enabled for web content to prevent XSS attacks.  If you have this
on and want to return actual HTML you can use the C<raw> helper function. Example:
  
    <%= raw '<a href="http://example.com">Example</a>' %>

Obviously you need to be careful with this.

The C<raw> helper (also available as a method on the template object) takes the string
and turns it into an instance of L<Template::EmbeddedPerl::SafeString>.  The auto escape
code when it sees that object knows to pass it thru without trying to escape it.  The 
C<raw> helper has a version called C<safe> which does any needed encoding first (or passes
unchanged any already created safe string objects).

If the value is an object that does C<to_safe_string> then the object will first be converted
to a safe string by calling it. Legacy C<render> methods pass the template
engine as the first parameter; typed C<render_view> rendering passes the active
view. That allows you to safely stringify objects without needing to do so
manually.

B<NOTE> we only check for objects with the C<to_safe_string> method when using C<auto_escape>
If you are not using this safety feature and you are manually performing any needed escaping
then you can just use ordinary overloading to stringify your object values.

=item * C<auto_flatten_expr>

Boolean indicating whether to automatically flatten expressions. Default is C<< 1 >>.
What this means is that if you have an expression that returns an array we will join
the array into a string before outputting it.  Example:

    <% my @items = qw(foo bar baz); %>
    <%= map { "$_ " } @items %>

Would output:

    foo bar baz

=item * C<preamble>

Add Perl code to the 'preamble' section of the compiled template. This is to top of the generated
script prior to the anonymous sub representing your template.Default is an empty string. For example
you can enable modern Perl features like signatures by setting this to C<< 'use v5.40;' >>.

Use this to setup any pragmas or modules you need to use in your template code.

=item * C<prepend>

Perl code to prepend to the compiled template. Default is an empty string. This goes just inside the
anonyous subroutine that is called to return your document string. For example you can use this to
pull passed arguments off C<@_>.

=item * C<helpers>

A hash reference of helper functions available to the templates. Default is an empty hash.
You can add your own helper functions to this hash and they will be available to the templates.
Example:

  my $template = Template::EmbeddedPerl->new(helpers => {
    my_helper => sub { return 'Hello, World!' },
  });

=item * C<use_cache>

Boolean indicating whether to cache compiled templates. Default is C<< 0 >>.
If you set this to C<< 1 >>, the module will cache compiled templates in memory. This is
only useful if you are throwing away the template object after compiling a template.
For example:

  my $ep = Template::EmbeddedPerl->new(use_cache => 1);
  my $output = $ep->render('Hello, <%= shift %>!', 'John');

In the case above since you are not capturing the compiled template object each time
you call C<render> you are recompiling the template. which could get expensive.

On the other hand if you are keeping the template object around and reusing it you don't
need to enable this.  Example:

  my $ep = Template::EmbeddedPerl->new(use_cache => 1);
  my $compiled = $ep->from_string('Hello, <%= shift %>!');
  my $output = $compiled->render('John');

In the valid above the compiled template is cached and reused each time you call C<render>.

Obviously this only works usefully in a persistent environment like mod_perl or a PSGI server.

=item * C<comment_mark>

Defaults to '#'. Indicates the beginning of a comment in the template which is to be removed
from the output.

=item * C<interpolation>

Boolean indicating whether to enable interpolation in the template. Default is C<< 0 >> (disabled).

Interpolation allows you to embed Perl variables directly in the template without using the
C<%= ... %> syntax. For example:

  my $template = Template::EmbeddedPerl->new(interpolation => 1, prepend => 'my ($name) = @_');
  my $output = $template->render('Hello, $name!', 'John');

This will output:

  Hello, John!

Interpolation is reasonable sophisticated and will handle many cases including have more
then one variable in a line.  For example:

  my $template = Template::EmbeddedPerl->new(interpolation => 1, prepend => 'my ($first, $last) = @_');
  my $output = $template->render('Hello, $first $last!', 'John', 'Doe');

This will output:

  Hello, John Doe!

It can also handle variables that are objects and call methods on them.  For example:

  my $template = Template::EmbeddedPerl->new(interpolation => 1, prepend => 'my ($person_obj) = @_');
  my $output = $template->render('Hello, $person_obj->first_name $person_obj->last_name!', Person->new('John', 'Doe'));

This will output:

  Hello, John Doe!

If you need to disambiguate a variable from following text you enclose the variable in curly braces.

  my $template = Template::EmbeddedPerl->new(interpolation => 1);
  my $output = $template->render('Hello, ${arg}XXX', 'John');

This will output:

  Hello, JohnXXX

You can nest method calls and the methods can contain arguments of varying complexity, including
anonymous subroutines.  There is a limited ability to span lines; you make break lines across the 
deference operator and in many cases across balanced parenthesis, square and curly brackets.  If you
do so you cannot mix 'template text' with the Perl code.  For example:

  <div class="name">
    $person->profile
      ->first_name
  </div>

and

  $obj->compute(
    sub {
      my $arg = shift;
      return $arg * 2;
    }
  )

are both valid.  But this will fail:

  <p>
    $arg->compute(sub {
      my $value = shift;
      $value = $value * 5
      <div>$value</div>
    })
  </p>

For this case you need to use the C<%= ... %> syntax or %= and %:

  <p>
    %= $arg->compute(sub {
      % my $value = shift;
      % $value = $value * 5
      <div>$value</div>
    % })
  </p>

You can review the existing test case at C<t/interpolation.t> for examples.

This works by noticing a '$' followed by a Perl variable name (and method calls, etc). So if you
need to put a real '$' in your code you will need to escape it with C<\$>.  It does not work
for other perl sigils at this time (for example '@' or '%').  

This feature is experimental so if you have trouble with it submit a trouble ticket with test
case (review the C<t/interpolation.t> test cases for examples of the type of test cases I need).
I intend interpolation to be a 'sweet spot' feature that tries to reduce amount of typing
and overall template 'noise', not something that fully parses Perl code.  Anything super crazy
should probably be encapsulated in a helper function anyway.

=back

=head2 from_string

  my $compiled = $template->from_string($template_string, %args);

Creates a compiled template from a string. Accepts the template content as a
string and optional arguments to modify behavior. Returns a
C<Template::EmbeddedPerl::Compiled> object.

pass 'source => $path' to the arguments to specify the source of the template if you
want neater error messages.

This can be called as a class method as well::

  my $compiled = Template::EmbeddedPerl->from_string($template_string, %args);

Useful if you don't need to keep the template object around.  This works 
for all the other methods as well (C<from_file>, C<from_fh>, C<from_data>).

=head2 from_file

  my $compiled = $template->from_file($file_name, %args);

Creates a compiled template from a file. Accepts the filename (without extension)
and optional arguments. Searches for the file in the directories specified during
object creation.

=head2 from_fh

  my $compiled = $template->from_fh($filehandle, %args);

Creates a compiled template from a file handle. Reads the content from the
provided file handle and processes it as a template.

pass 'source => $path' to the arguments to specify the source of the template if you
want neater error messages.

=head2 from_data

  my $compiled = $template->from_data($package, %args);

Creates a compiled template from the __DATA__ section of a specified package.
Returns a compiled template object or dies if the package cannot be loaded or
no __DATA__ section is found.

=head2 trim

  my $trimmed = $template->trim($string);

Trims leading and trailing whitespace from the provided string. Returns the
trimmed string.

=head2 mtrim

Same as C<trim> but trims leading and trailing whitespace for a multiline string.

=head2 default_helpers

  my %helpers = $template->default_helpers;

Returns a hash of default helper functions available to the templates.

=head2 get_helpers

  my %helpers = $template->get_helpers($helper_name);

Returns a specific helper function or all helper functions if no name is provided.

=head2 parse_template

  my @parsed = $template->parse_template($template);

Parses the provided template content and returns an array of parsed blocks.

=head2 compile

  my $code = $template->compile($template, @parsed);

Compiles the provided template content into executable Perl code. Returns a
code reference.

=head2 directory_for_package

  my $directory = $template->directory_for_package($package);

Returns the directory containing the package file.
If you don't provide a package name it will use the current package for C<$template>.

Useful if you want to load templates from the same directory as your package.

=head2 render

  my $output = $template->render($template, @args);

Compiles and executes the provided template content with the given arguments. You might
want to enable the cache if you are doing this.

Compatibility note: C<render> and C<Template::EmbeddedPerl::Compiled::render>
keep every legacy argument, including a blessed first argument, in C<@_>. They
do not infer a typed C<$self>.

=head2 render_view

B<Experimental:> Typed view support, including C<render_view>, C<view>,
C<view_namespace>, and C<view_factory>, may change as real-world integration
needs become clearer.

  my $output = $template->render_view($view);

Renders a preconstructed blessed view object. Its template receives that object
as lexical C<$self>. A non-blessed value is an error. Root and nested views use
the same template precedence:

=over 4

=item 1.

A nonempty C<< $view->template >> result.

=item 2.

The C<view_namespace> convention.

=back

Use the C<view> helper for a nested typed object. C<< view $object >> renders a
preconstructed child, which bypasses construction. C<< view $logical_name,
%args >> resolves its class from C<view_namespace> and calls
C<< $class->new(%args) >> by default. If configured, C<view_factory> alone
performs construction and receives C<< ($class, \%args, $context) >>; use it
to inject dependencies. The final coderef, if any, is a wrapper body. In that
callback lexical C<$self> remains the caller; the callback argument is the
wrapper object, and the wrapper template itself receives the wrapper as
C<$self>.

The core accepts any blessed object. Moo is used only by the test and cookbook
examples. L<Template::EmbeddedPerl::Cookbook::TypedViews> contains complete Moo
examples for applications that use it.

=head1 HELPER FUNCTIONS

The module provides a set of default helper functions that can be used in templates.

=over 4

=item * C<raw>

Returns a string as a safe string object without escaping.   Useful if you
want to return actual HTML to your template but you better be 
sure that HTML is safe.

    <%= raw '<a href="http://example.com">Example</a>' %>

=item * C<safe>

Returns a string as a safe html escaped string object that will not be 
escaped again.

=item * C<safe_concat>

Like C<safe> but for multiple strings.  This will concatenate the strings into
a single string object that will not be escaped again.

=item * C<html_escape>

Escapes HTML entities in a string.  This differs for C<safe> in that it will
just do the escaping and not wrap the string in a safe string object.

=item * C<url_encode>

Encodes a string for use in a URL.

=item * C<escape_javascript>

Escapes a value for use inside a JavaScript string, including preventing a closing
C<script> tag from terminating an enclosing HTML script element. This is not a general
JavaScript sanitizer; use a context-appropriate sanitizer for untrusted code.

=item * C<trim>

Trims leading and trailing whitespace from a string.

=item * C<partial>

C<< partial $identifier, %args >> renders an untyped template immediately with
the caller's C<$self>. Its output is safe rendered output and is not escaped a
second time by C<auto_escape>.

=item * C<layout>

C<< layout $identifier, %args >> registers an untyped outer template for the
current output. Layout arguments are independent named arguments for the
layout. Multiple layouts nest with the first declaration outermost.

=item * C<yield>

C<yield> returns the current body. C<< yield $name >> returns named content
captured in the current render frame.

=item * C<content_for>, C<content_replace>, and C<has_content>

C<< content_for $name, sub { ... } >> appends named content in render order.
C<content_replace> replaces it, and C<< has_content $name >> reports whether
the named content is nonempty.

=item * C<view>

Renders a typed child as described in L</render_view>. The optional final
coderef supplies the wrapper body.

=back

=head1 ERROR HANDLING

If an error occurs during template compilation or rendering, the module will
throw an exception with a detailed error message. The error message includes
the source of the template, the line number, and the surrounding lines of the
template to help with debugging.  Example:

Can't locate object method "input" at /path/to/templates/hello.yat line 4.

  3:     <%= label('first_name') %>
  4:     <%= input('first_name') %>
  5:     <%= errors('last_name') %>

Each top-level C<render>, compiled-template C<render>, and C<render_view> call
creates exactly one render frame. Nested partials, layouts, and views share that
frame. Render cycles are rejected with their active chain. A nested exception is
decorated with one source-aware C<Render stack>; failed rendering restores the
frame's body, named content, layouts, and stack state so the engine can be
reused for a later top-level render.

=head1 ENVIRONMENT VARIABLES

The module respects the following environment variables: 

=over 4

=item * C<DEBUG_TEMPLATE_EMBEDDED_PERL>

Set this to a true value to print the compiled template code to the console. Useful
when trying to debug difficult compilation issues, especially given this is early
access code and you might run into bugs.

=back

=head1 REPORTING BUGS & GETTING HELP

If you find a bug, please report it on the GitHub issue tracker at
L<https://github.com/jjn1056/Template-EmbeddedPerl/issues>.  The bug tracker is
the easiest way to get help with this module from me but I'm also on irc.perl.org
under C<jnap>.

=head1 DEDICATION

This module is dedicated to the memory of my dog Bear who passed away on 17 August 2024.
He was a good companion and I miss him.

If this module is useful to you please consider donating to your local animal shelter
or rescue organization.

=head1 AUTHOR

John Napiorkowski, C<< <jjnapiork@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut


__END__

%= join '', map {
  <p>%= $_</p>
} @items;
% my $X=1; my $bb = join '', map {
  <p>%= $_</p>
} @items;
% if(1)
  <span>One: %= ttt</span>
}
% my $a=[1,2,3]; foreach my $item (sub { @items }->()) {
  foreach my $index (0..2) {
    foreach my $i2 (2..3) {
    <div>
      %= $item.' '.$index. ' '.$i2
    </div>
  }}
  %= sub {
    <p>%= "A: @{[ $a->[2] ]}" %%</p>
  }->();
}
%= "BB: $bb"
