package PDF::Collage::Template;
use v5.24;
use warnings;
{ our $VERSION = '0.003' }

use Carp;
use English;
use Template::Perlish ();
use Data::Resolver    ();
use PDF::Builder;

use Moo;
use experimental qw< signatures >;
no warnings qw< experimental::signatures >;

use namespace::clean;

has commands  => (is => ro => required => 1);
has functions => (is => 'lazy');
has logger    => (is => 'lazy');
has metadata  => (is => 'lazy');

has _src_cache => (is => 'lazy');
has _data      => (is => 'lazy');
has _defaults  => (is => 'lazy');
has _fonts     => (is => 'lazy');
has _pdf       => (is => 'lazy');

sub _build_functions ($self) { return {} }
sub _build_logger    ($self) {
   eval { require Log::Any; Log::Any->get_logger }
}
sub _build_metadata   ($self) { return {} }
sub _build__src_cache ($self) { return {} }
sub _build__data      ($self) { return {} }
sub _build__defaults  ($self) { return {} }
sub _build__fonts     ($self) { return {} }
sub _build__pdf       ($self) { return PDF::Builder->new }

sub render ($self, $data) {
   $self->new(    # hand over to a disposable clone
      commands  => $self->commands,
      functions => $self->functions,
      _data     => $data,
   )->_real_render;
} ## end sub render

sub _real_render ($self) {
   for my $command ($self->commands->@*) {
      my $op     = $command->{op} =~ s{-}{_}rgmxs;
      my $method = $self->can('_op_' . $op)
        or croak "unsupported op<$command->{op}>";
      $self->$method($command);
   } ## end for my $command ($self->...)
   return $self->_pdf;
} ## end sub _real_render

sub _tpr ($self, $tmpl) {
   return Template::Perlish::render($tmpl, $self->_data,
      {functions => $self->functions});
}

sub _expand ($self, $command, @keys) {
   my %auto_expand = map { $_ => 1 } @keys;
   my %overall     = ($self->_defaults->%*, $command->%*);
   my %retval;
   for my $key (sort { $a cmp $b } keys %overall) {
      my $nkey = $key =~ s{-}{_}rgmxs;
      next if exists $retval{$nkey};
      my $value = $overall{$key};
      $retval{$nkey} = $auto_expand{$nkey} ? $self->_tpr($value) : $value;
   } ## end for my $key (sort { $a ...})
   return \%retval;
} ## end sub _expand

sub __pageno ($input)   { return $input eq 'last' ? 0 : $input }

sub __fc_list ($key) {
   my @command = ('fc-list', $key, qw< file style >);
   open my $fh, '-|', @command or croak "fc-list: $OS_ERROR";
   my @candidates = map {
      s{\s+\z}{}mxs;
      my ($filename, $style) = m{\A (.*?): \s* :style=(.*)}mxs
         or croak "fc-list: unexpected line '$_'";
      my %style = map { $_ => 1 } split m{,}mxs, $style;
      {filename => $filename, style => \%style};
   } <$fh>;
   return unless @candidates;
   return $candidates[0]{filename} if @candidates == 1;

   # get Regular/Normal if exists
   for my $candidate (@candidates) {
      return $candidate->{filename}
         if $candidate->{style}{Regular} || $candidate->{style}{Normal};
   }

   # bail out, request more data
   croak "fc-list: too many outputs for '$key'";
}

sub _font    ($s, $key) {
   if (! defined($s->_fonts->{$key})) {
      $key = $key =~ m{\A fc: (.*) \z}mxs ? __fc_list($1)
         : $key =~ m{\A file: (.*) \z}mxs ? $1
         :                                  $key;
      $s->_fonts->{$key} = $s->_pdf->font($key);
   }
   return $s->_fonts->{$key};
}

sub _op_add_image ($self, $command) {
   my $opts  = $self->_expand($command, qw< page path x y width height >);
   my $page  = $self->_pdf->open_page(__pageno($opts->{page} // 'last'));
   my $image = $self->_pdf->image($opts->{path});
   $page->object($image, $opts->@{qw< x y width height >});
   return;
} ## end sub _op_add_image

sub __parse_pages ($input) {
   return $input if ref($input); # already represented as an array
   my @pages = map {
      my ($from, $to) = split m{-}mxs, $_, 2;
      defined($to) ? ($from .. $to) : $from;
   } split m{[\s,]+}mxs, $input;
   return \@pages;
}

sub _op_add_page ($self, $command) {
   my $opts =
     $self->_expand($command, qw< page from from_path from_page >);
   my $target_n = __pageno($opts->{page} // 'last');
   defined(my $source_path = $opts->{from} // $opts->{from_path})
     or return $self->_pdf->page($target_n);
   my $source = $self->_src_cache->{$source_path}
      //= PDF::Builder->open($source_path);

   my $retval;
   my $source_ns = __parse_pages($opts->{from_page} // 'last');
   for my $sn ($source_ns->@*) {
      my $source_n = __pageno($sn);
      $retval = $self->_pdf->import_page($source, $source_n, $target_n);
      $target_n++ if $target_n; # only advance if not 0 = last
   }
   return $retval;
} ## end sub _op_add_page

sub _op_add_text ($self, $command) {
   my $opts =
     $self->_expand($command, qw< align page font font_family font_size x y >);

   my $content =
     $self->_render_text($opts->@{qw< text text_template text_var >});

   my $font = $self->_font($opts->{font} // $opts->{font_family});
   my $font_size = $opts->{font_size};

   my ($x, $y) = map { $_ // 0 } $opts->@{qw< x y >};

   my $align = $opts->{align} // 'start';
   if ($align ne 'start') {
      my $width = $font_size * $font->width($content);
      $x -= $align eq 'end' ? $width : ($width / 2);
   }

   my $page = $self->_pdf->open_page(__pageno($opts->{page} // 'last'));
   my $text = $page->text;
   $text->position($x, $y);
   $text->font($font, $opts->{font_size});
   $text->text($content // '');

   return $self;
} ## end sub _op_add_text

sub _render_text ($self, $plain, $template, $crumbs) {
   return $plain                 if defined $plain;
   return $self->_tpr($template) if defined $template;
   return Template::Perlish::traverse($self->_data, $crumbs) // ''
     if defined $crumbs;
   return;
} ## end sub _render_text

sub _op_set_defaults ($self, $command) {
   my $defaults = $self->_defaults;
   while (my ($key, $value) = each $command->%*) {
      next if $key eq 'op';
      if (defined $value) { $defaults->{$key} = $value }
      else                { delete $defaults->{$key} }
   }
   return;
} ## end sub _op_set_defaults

sub _default_log ($self, $command) {
   warn "[$command->{level}] $command->{message}\n";
   return $self;
}

sub _op_log ($self, $command) {
   my $logger = $self->logger or return $self->_default_log($command);
   my $method = $logger->can(lc($command->{level}) // 'info')
      or return $self->_default_log($command);
   $logger->$method($command->{message});
   return $self;
}

1;
