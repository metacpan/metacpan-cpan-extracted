package Template::EmbeddedPerl;

our $VERSION = '0.001011';
$VERSION = eval $VERSION;

use warnings;
use strict;
use utf8;

use PPI::Document;
use File::Spec;
use Digest::MD5;
use Scalar::Util;
use Template::EmbeddedPerl::Compiled;
use Template::EmbeddedPerl::Utils qw(normalize_linefeeds generate_error_message);
use Template::EmbeddedPerl::SafeString;
use Regexp::Common qw /balanced/;

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
          ->                          # Dereference operator
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
  my %helpers = $self->get_helpers;
  foreach my $helper(keys %helpers) {
    if($self->{sandbox_ns}->can($helper)) {
      warn "Skipping injection of helper '$helper'; already exists in namespace $self->{sandbox_ns}" 
        if $ENV{DEBUG_TEMPLATE_EMBEDDED_PERL};
      next;
    }
    eval qq[
      package @{[ $self->{sandbox_ns} ]};
      sub $helper { \$self->get_helpers('$helper')->(\$self, \@_) }
    ]; die $@ if $@;
  }
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
  );
}

# Create a new template document in various ways

sub from_string {
  my ($proto, $template, %args) = @_;
  my $source = delete($args{source});
  my $self = ref($proto) ? $proto : $proto->new(%args);

  my $digest;
  if($self->{use_cache}) {
    $digest = Digest::MD5::md5_hex($template);
    if(my $cached = $self->{compiled_cache}->{$digest}) {
      return $self->{compiled_cache}->{$digest};
      return bless {
        template => $cached->{template},
        parsed => $cached->{parsed},
        code => $cached->{code},
        yat => $self,
        source => $source,
      }, 'Template::EmbeddedPerl::Compiled';     
    }  
  }

  $template = normalize_linefeeds($template);

  my @template = split(/\n/, $template);
  my @parsed = $self->parse_template($template);
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
  }, 'Template::EmbeddedPerl::Compiled'; 
}

sub from_data {
  my ($proto, $package, @args) = @_;

  eval "require $package;"; if ($@) {
    die "Failed to load package '$package': $@";
  }

  my $data_handle = do { no strict 'refs'; *{"${package}::DATA"}{IO} };
  if (defined $data_handle) {
    #my $position = tell( $data_handle );
    my $data_content = do { local $/; <$data_handle> };
    #seek $data_handle, $position, 0;
    my $package_file = $package;
    $package_file =~ s/::/\//g;
    my $path = $INC{"${package_file}.pm"};
    return $proto->from_string($data_content, @args, source => "${path}/DATA");
  } else {
    print "No __DATA__ section found in package $package.\n";
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
  my $file = "${file_proto}.@{[ $self->{template_extension} ]}";

  # find if it exists in the directories
  foreach my $dir (@{ $self->{directories} }) {
    $dir = File::Spec->catdir(@$dir) if ((ref($dir)||'') eq 'ARRAY');
    my $path = File::Spec->catfile($dir, $file);
    if (-e $path) {
      open my $fh, '<', $path or die "Failed to open file $path: $!";
      my %args = (@args, source => $path);
      return $self->from_fh($fh, %args);
    }
  }
  die "File $file not found in directories: @{[ join ', ', @{ $proto->{directories} } ]}";
}

# Methods to parse and compile the template

sub parse_template {
  my ($self, $template) = @_;
  my $open_tag = $self->{open_tag};
  my $close_tag = $self->{close_tag};
  my $expr_marker = $self->{expr_marker};
  my $line_start = $self->{line_start};
  my $comment_mark = $self->{comment_mark};

  ## support shorthand line start tags ##

  # Convert all lines starting with %= to start with <%= and then add %> to the end
  $template =~ s/^\s*${line_start}${expr_marker}(.*?)(?=\\?$)/${open_tag}${expr_marker}$1${close_tag}/mg;
  # Convert all lines starting with % to start with <% and then add %> to the end
  $template =~ s/^\s*${line_start}(.*?)(?=\\?$)/${open_tag}$1${close_tag}/mg;

  ## Escapes so you can actually have % and %= in the template
  # Convert all lines starting with \%= to start instead with %=
  $template =~ s/^\s*\\${line_start}${expr_marker}(.*)$/${line_start}${expr_marker}$1/mg;
  # Convert all lines starting with \% to start instead with %
  $template =~ s/^\s*\\${line_start}(.*)$/${line_start}$1/mg;

  # This code parses the template and returns an array of parsed blocks.
  # Each block is represented as an array reference with two elements: the type and the content.
  # The type can be 'expr' for expressions enclosed in double square brackets,
  # 'code' for code blocks enclosed in double square brackets,
  # or 'text' for plain text blocks.
  # The content is the actual content of the block, trimmed of leading and trailing whitespace.

  #my @segments = split /(\Q${open_tag}\E.*?\Q${close_tag}\E)/s, $template;
  my @segments = split /((?<!\\)\Q${open_tag}\E.*?(?<!\\)\Q${close_tag}\E)/s, $template;
  my @parsed = ();

  foreach my $segment (@segments) {

    my ($open_type, $content, $close_type) = ($segment =~ /^(\Q${open_tag}${expr_marker}\E|\Q$open_tag\E)(.*?)(\Q${expr_marker}${close_tag}\E|\Q$close_tag\E)?$/s);
    if(!$open_type) {
      # Remove \ from escaped line_start, open_tag, and close_tag
      $segment =~ s/\\${line_start}/${line_start}/g;
      $segment =~ s/\\${open_tag}/${open_tag}/g;
      $segment =~ s/\\${close_tag}/${close_tag}/g;
      $segment =~ s/\\${expr_marker}${close_tag}/${expr_marker}${close_tag}/g;

      # check the segment for comment lines 
      $segment =~ s/^[ \t]*?${comment_mark}.*$/\\/mg;
      $segment =~ s/^[ \t]*?\\${comment_mark}/${comment_mark}/mg;

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
      # Support trim with =%>
      $content = "trim $content" if $close_type eq "${expr_marker}${close_tag}";

      # ?? ==%> or maybe something else...
      # $parsed[-1][1] =~s/[ \t]+$//mg if $close_type eq "${expr_marker}${close_tag}";
 
      # Remove \ from escaped line_start, open_tag, and close_tag
      $content =~ s/\\${line_start}/${line_start}/g;
      $content =~ s/\\${open_tag}/${open_tag}/g;
      $content =~ s/\\${close_tag}/${close_tag}/g;
      $content =~ s/\\${expr_marker}${close_tag}/${expr_marker}${close_tag}/g;

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
    $safe_or_not = ' safe_concat ';
  } else {
    $safe_or_not = $self->{auto_escape} ? ' safe ' : '';
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
      $compiled .= "@{[$escaped_newline_start ? qq[\n]:'' ]} \$_O .= \"" . quotemeta($content) . "\";@{[$escaped_newline_end ? qq[\n]:'' ]}";
    }
  }

  $compiled = $self->compiled($compiled);

  warn "Compiled: $compiled\n" if $ENV{DEBUG_TEMPLATE_EMBEDDED_PERL};

  my $code = eval $compiled; if($@) {
    die generate_error_message($@, $template, $source);
  }

  return $code;
}

sub compiled {
  my ($self, $compiled) = @_;
  my $wrapper = "package @{[ $self->{sandbox_ns} ]}; ";
  $wrapper .= "use strict; use warnings; use utf8; @{[ $self->{preamble} ]}; ";
  $wrapper .= "sub { my \$_O = ''; @{[ $self->{prepend} ]}; ${compiled}; return \$_O; };";
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
and customizable sandbox environments.

Its quite similar to L<Mojo::Template> and other embedded Perl template engines
but its got one trick the others can't do (see L<EXCUSE> below).

B<NOTE>: This is a very basic template engine, which doesn't have lots of things
you probably need like template includes / partials and so forth.  That's by
design since I plan to wrap this in a L<Catalyst> view which will provide
all those features.  If you want to use this stand alone you might need to add
those features yourself (or ideally put something on CPAN that wraps this to 
provide those features).  Or you can pay me to do it for you ;)

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


You can add '=' to the closing tag to indicate that the expression should be trimmed of leading
and trailing whitespace. This is useful when you want to include the expression in a block of text.
where you don't want the whitespace to affect the output.

  <% Perl code =%>
  <%= Perl expression, replaced with result, trimmed =%>

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

The namespace for the sandbox environment. Default is C<< 'Template::EmbeddedPerl::Sandbox' >>.
Basically the template is compiled into an anponymous subroutine and this is the namespace
that subroutine is executed in.  This is a security feature to prevent the template from
accessing the outside environment.

=item * C<directories>

An array reference of directories to search for templates. Default is an empty array.
A directory to search can be either a string or an array reference containing each part
of the path to the directory.  Directories will be searched in order listed.

  my $template = Template::EmbeddedPerl->new(directories=>['/path/to/templates']);
  my $template = Template::EmbeddedPerl->new(directories=>[['/path', 'to', 'templates']]);

I don't do anything smart to make sure you don't reference templates in dangerous places.
So be careful to make sure you don't let application users specify the template path.

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
anonymous subroutines.  However you cannot span lines, you must close all open parens and braces
on the same line.  You can review the existing test case at C<t/interpolation.t> for examples.

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

Escapes JavaScript entities in a string. Useful for making strings safe to use
 in JavaScript.

=item * C<trim>

Trims leading and trailing whitespace from a string.

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

