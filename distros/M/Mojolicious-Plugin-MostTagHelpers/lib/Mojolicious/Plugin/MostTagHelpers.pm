package Mojolicious::Plugin::MostTagHelpers;

use Mojo::Base 'Mojolicious::Plugin';
use HTML::Tagset;

our $VERSION = eval 0.04;

our %skip = (
  b => 1, #Mojo::Bytestream
  c => 1, #Controller
  title => 1,
  param => 1,
);

sub register {
  my ($plugin, $app) = @_;
  foreach my $tag (keys %HTML::Tagset::isKnown) {
    next if $skip{$tag};
    $app->helper( $tag => _tag($tag) );
  }
  $app->helper( incremental => \&_incremental );
}

sub _tag {
  my $tag = shift;
  return sub {
    my $self = shift;
    my $id;
    my @class;
    if ($_[0] =~ /^[#.]/) {
      my $sel = shift;
      ($id)  = $sel =~ /\#([^#. ]+)/;
      @class = $sel =~ /\.([^#. ]+)/g;
    }
    return $self->tag(
      $tag,
      $id ? ( id => $id ) : (),
      @class ? ( class => join(' ', @class) ) : (),
      !$HTML::Tagset::emptyElement{$tag} ? @_ : undef
    );
  };
}

sub _gen_pod_list {
  my @list = map { "=item $_\n\n" } sort grep { !$skip{$_} } keys %HTML::Tagset::isKnown;
  return '=over', @list, '=back';
}

sub _incremental {
  my $c = shift;
  my $text = pop;
  my $i = shift || 1;

  $text = $text->() if eval { ref $text eq 'CODE' };

  require Mojo::DOM;
  my $dom = Mojo::DOM->new($text);
  $dom->xml(1);
  my $children = $dom->children;
  if ($children->size == 1) {
    $children = $children->[0]->children;
  }
  $children->each(sub{
    $_->{ms_overlay} = $i++ . '-';
  });

  require Mojo::ByteStream;
  return Mojo::ByteStream->new($dom->to_string);
}

1;

__END__

=head1 NAME

App::MojoSlides::MoreTagHelpers - More tag helpers for your templated and slides

=head1 SYNOPSIS

 %= div '#mydiv.myclass' => begin
   %= p '.myp.myq' => 'Text'
   %= p 'Other Text'
 % end

 <div id="mydiv" class="myclass">
  <p class="myp myq">Text</p>
  <p>Other Text</p>
 </div>

=head1 DESCRIPTION

Extra tag helpers useful for templating and slide making

=head1 NON-ELEMENT HELPERS

=over

=item incremental

 %= ul begin
   %= incremental begin
     %= li 'Always shown'
     %= li 'Shown after one click'
   % end
 % end

 %= incremental ul begin
   %= li 'Always shown'
   %= li 'Shown after one click'
 % end

  <ul>
    <li ms_overlay="1-">Always shown</li>
    <li ms_overlay="2-">Shown after one click</li>
  </ul>


Adds ms_overlay attributes to a sequence of elements with increasing start number.
Note that if passed an html element which has only one element, the attributes will be applied to the children of that attribute.
Because of this, the two templates above result in the same shown output.

=back

=head1 ELEMENTS

This module wraps lots of the HTML tags (though not all) into helpers.
If the helper gets a first argument that starts with C<#> or C<.>, that argument is parsed like a selector.
Note that only one id (the first) will be used if multiple are given.
Note that if C<id> or C<class> or attributes are passed by name, they will overwrite these.

While this module wraps a large number of HTML tags some have not been included.
Some elements are not included because of conflicts with existing keywords or helpers.
Others are not likely to be useful and are not included.
This list may change in the future, but common tags which meet the above critera are likely stable.


=over

=item a

=item abbr

=item acronym

=item address

=item applet

=item area

=item base

=item basefont

=item bdo

=item bgsound

=item big

=item blink

=item blockquote

=item body

=item br

=item button

=item caption

=item center

=item cite

=item code

=item col

=item colgroup

=item dd

=item del

=item dfn

=item dir

=item div

=item dl

=item dt

=item em

=item embed

=item fieldset

=item font

=item form

=item frame

=item frameset

=item h1

=item h2

=item h3

=item h4

=item h5

=item h6

=item head

=item hr

=item html

=item i

=item iframe

=item ilayer

=item img

=item input

=item ins

=item isindex

=item kbd

=item label

=item legend

=item li

=item link

=item listing

=item map

=item menu

=item meta

=item multicol

=item nobr

=item noembed

=item noframes

=item nolayer

=item noscript

=item object

=item ol

=item optgroup

=item option

=item p

=item plaintext

=item pre

=item q

=item s

=item samp

=item script

=item select

=item small

=item spacer

=item span

=item strike

=item strong

=item style

=item sub

=item sup

=item table

=item tbody

=item td

=item textarea

=item tfoot

=item th

=item thead

=item tr

=item tt

=item u

=item ul

=item var

=item wbr

=item xmp

=item ~comment

=item ~directive

=item ~literal

=item ~pi

=back

=head1 METHODS

=over

=item register
  register plugin

=back
