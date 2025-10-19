package Mojolicious::Plugin::FontAwesomeHelpers;
use Mojo::Base 'Mojolicious::Plugin';

use version; our $VERSION = version->declare('v0.1.0');

use Carp         ();
use Scalar::Util qw(blessed);
use subs         qw(extract_block extract_flags);

sub register {
  my $self = shift;
  my $app  = shift;

  $app->helper('icon'    => \&_icon);
  $app->helper('fa_icon' => \&_icon);
  $app->helper('fa.icon' => \&_icon);

  $app->helper('stacked_icon' => \&_stack);
  $app->helper('fa_stack'     => \&_stack);
  $app->helper('fa.stack'     => \&_stack);

  $app->helper('fa.class' => sub { shift; _fa_class(@_) });
}

sub _stack {
  my $c             = shift;
  my $content_class = _fa_class('fa-stack', @_);

  my $content;
  if (@_ % 2 == 1) {
    my $block = extract_block \@_;
    $content = $block ? $block->() : pop;
  }
  else {
    Carp::croak "content is required in the form of text or a block";
  }

  my %html_options = @_;
  $content_class .= " $html_options{class}" if $html_options{class};
  $html_options{class} = $content_class;

  return $c->tag('span', class => $content_class, %html_options, $content);
}

sub _icon {
  my $c             = shift;
  my $icon          = shift;
  my $content_class = _fa_class($icon, @_);

  my $text;
  if (@_ % 2 == 1) {
    my $block = extract_block \@_;
    $text = $block ? $block->() : pop;
  }

  my %html_options = @_;
  $content_class .= " $html_options{class}" if $html_options{class};
  $html_options{class} = $content_class;
  $html_options{'aria-hidden'} //= 'true';

  my $html = $c->tag('i', %html_options);
  $html = $c->b($html . " $text") if $text;

  return $html;
}

sub _fa_class {
  my $icon    = shift;
  my $class   = blessed($icon) ? _try($icon, 'fa_class') : $icon;
  my %options = extract_flags \@_;

  $class .= " fa-$options{-size}"          if $options{-size};
  $class .= " fa-pull-$options{-pull}"     if $options{-pull};
  $class .= " fa-rotate-$options{-rotate}" if $options{-rotate};
  $class .= " fa-stack-$options{-stack}"   if $options{-stack};

  my $swap_opacity = defined $options{-opacity} && $options{-opacity} eq 'swap';
  $class .= " fa-swap-opacity" if $swap_opacity;

  my $auto_width = defined $options{-width} && $options{-width} eq 'auto';
  $class .= " fa-width-auto" if $auto_width;
  $class .= " fa-inverse"    if $options{-inverse};
  $class .= " fa-bounce"     if $options{-bounce};
  $class .= " fa-shake"      if $options{-shake};


  if (my $spin = $options{-spin}) {
    if ($spin eq 1) {
      $class .= " fa-spin";
    }
    elsif (ref $spin eq 'ARRAY') {
      $class .= " " . join(' ' => map {"fa-spin-$_"} @$spin);
    }
    else {
      $class .= " fa-spin-$spin";
    }
  }

  if (my $flip = $options{-flip}) {
    if ($flip eq 1) {
      $class .= " fa-flip";
    }
    else {
      $class .= " fa-flip-$flip";
    }
  }

  if ($options{-beat} && $options{-fade}) {
    $class .= " fa-beat-fade";
  }
  else {
    $class .= " fa-beat" if $options{-beat};
    $class .= " fa-fade" if $options{-fade};
  }

  $class;
}

# Utils

sub _try {
  my ($value, $method_name) = @_;
  return unless blessed($value);

  if (my $method = $value->can('fa_class')) {
    return $value->$method();
  }
}

sub extract_block {
  my $arrayref = shift;
  return delete $arrayref->[-1] if ref $arrayref->[-1] eq 'CODE';
  return undef;
}

sub extract_flags {
  my $arrayref = shift;
  my %flags    = ();

ITEM:
  for (my $i = 0; $i < @$arrayref; $i++) {
    my $item = $arrayref->[$i];
    if ($item =~ /^-/) {
      $flags{$item} = $arrayref->[$i + 1];
      splice @$arrayref, $i => 2;
      last ITEM unless @$arrayref;
      $i -= 2;
      next ITEM;
    }
    if ($item =~ /^:/) {
      $item =~ s/^:/-/;
      $flags{"$item"} = 1;
      splice @$arrayref, $i => 1;
      last ITEM unless @$arrayref;
      $i--;
    }
  }

  wantarray ? %flags : \%flags;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::FontAwesomeHelpers - Mojolicious helpers for Font Awesome icons

=head1 SYNOPSIS

  # template.html.ep
  %= icon 'fas fa-chevron' # => <i class="fas fa-chevron" aria-hidden="true"></i>
  %= icon 'fas fa-chevron', 'Back' # => <i class="fas fa-chevron" aria-hidden="true"></i> Back

  # ViewModel.pm
  package ViewModel {
    # ... other methods
    sub fa_class { 'fas fa-circle' }
  }

  # another_template.html.ep
  %= icon ViewModel->new # => <i class="fas fa-circle" aria-hidden="true"></i>
  %= icon ViewModel->new, 'A Circle' # => <i class="fas fa-circle" aria-hidden="true"></i> A Circle

=head1 HELPERS

=head2 icon

  %= icon 'fas fa-chevron' # => <i class="fas fa-chevron" aria-hidden="true"></i>
  %= icon 'fas fa-chevron', 'Back' # => <i class="fas fa-chevron" aria-hidden="true"></i> Back

  %= icon ViewModel->new # => <i class="fas fa-circle" aria-hidden="true"></i>
  %= icon ViewModel->new, 'A Circle' # => <i class="fas fa-circle" aria-hidden="true"></i> A Circle

  %= icon 'fas fa-chevron', (id => 'back', class => 'fa-solid'), 'Back'
    # => <i id="back", class="fas fa-chevron fa-solid" aria-hidden="true"></i> Back

  %= icon 'fas fa-chevron' => begin
   <b>Back</b>
  %= end
    # => <i class="fas fa-chevron aria-hidden="true"></i> <b>Back</b>

Renders a Font Awesome icon using an C<i> tag. It will also handle accessibility
concerns.

It can be used with two string arguments specifying the icon style and name
respectively. A third argument can be given to specify text that should be rendered
adjacent to the icon.

If the first argument is an object that implements a C<fa_class> method then the
return value of that method will be used to specify the icon and a second argument,
if provided, will be rendered as text adjacent to the icon.

All other arguments will be rendered as HTML attributes on the C<i> tag.

=head2 fa_icon

  %= fa_icon 'fas fa-circle' # => "<i class="fas fa-circle" aria-hidden="true"></i>

An alias of L</"icon">.

=head2 fa->icon

  %= $c->fa->icon('fas fa-circle') # => "<i class="fas fa-circle" aria-hidden="true"></i>

An alias of L</"icon">.

=head2 stacked_icon

  %= stacked_icon -size => '2x' => begin
    %= icon 'fa-solid fa-square', -stack => '2x'
    %= icon 'fab fa-twitter', -stack => '1x', :inverse
  %= end

=head2 fa_stack

An alias of L</"stacked_icon">

=head2 fa->stack

An alias of L</"stacked_icon">

=head2 fa->class

  %= $c->fa->class('fas fa-circle') # => "fas fa-circle"
  %= $c->fa->class('fas fa-circle', -size => 'sm') # => "fas fa-circle fa-sm"

  %= $c->fa->class(ViewModel->new) # => "fas fa-circle"
  %= $c->fa->class(ViewModel->new, -size => 'sm') # => "fas fa-circle fa-sm"

=head3 Options

=head4 -size

=head4 -rotate

=head4 -flip

=head4 -stack

=head4 -inverse

=head4 -beat

=head4 -fade

=head4 -beat & -fade

=head4 -bounce

=head4 -shake

=head4 -spin

=head4 -pull

=head4 -width

=head4 -opacity

=cut
