use strict;
use warnings;
package Template::Lace::DOM;

use base 'Mojo::DOM58';
use Storable ();
use Scalar::Util;

# General Helpers

sub ctx {
  my $self = shift;
  local $_ = $self;
  if(ref($_[0]) eq 'ARRAY') {
    push @{$_[0]}, $_[1]->($self, @_[2..$#_]);
  } else {
    $_[0]->($self, @_[1..$#_]);
  }
  return $self;
}

sub clone {
  return Storable::dclone(shift);
}

sub overlay {
  my ($self, $cb, @args) = @_;
  local $_ = $self;
  my $overlay_dom = $cb->($self, @args);
  $self->replace($overlay_dom);
}

sub wrap_with {
  my ($self, $new, $target) = @_;
  $target ||= '#content';
  $self->overlay(sub {
    $new->at($target)
      ->content($self);
    return $new;
  });
}

sub repeat {
  my ($self, $cb, @items) = @_;
  my $index = 0;
  my @nodes = map {
    my $cloned_dom = $self->clone;
    $index++;
    my $returned_dom = $cb->($cloned_dom, $_, $index);
    $returned_dom;
  } @items;


  # Might be a faster way to do this...
  $self->replace(join '', @nodes);
  return $self;
}

sub smart_content {
  my ($self, $data) = @_;
  if($self->tag eq 'input') {
    if((ref($data)||'') eq 'HASH') {
      if(exists($data->{selected})) {
        $data->{selected} = 'on';
      }
      $self->attr($data);
    } else {
      if(($self->attr('type')||'') eq 'checkbox') {
        $self->boolean_attribute_helper('checked', $data);
      } else {
        $self->attr(value=>$data);
      }
    }
  } elsif($self->tag eq 'option') {
    if((ref($data)||'') eq 'HASH') {
      $self->attr(value=>$data->{value});
      $self->attr(selected=>'on') if $data->{selected};
      $self->content(escape_html($data->{content}));
    } else {
      $self->attr(value=>$data);
      $self->content(escape_html($data));
    }
  } elsif($self->tag eq 'optgroup') {
    $self->attr(label=>escape_html($data->{label}));
    if(my $option_dom = $self->at('option')) {
      $option_dom->fill($data->{options});
    } else {
      warn "optgroup with no options."
    }
  } else {
    $self->content(escape_html($data));
  }
  return $self;
}

sub fill {
  my ($self, $data, $is_loop, $is_form) = @_;
  if(ref \$data eq 'SCALAR') {
    $self->smart_content($data);
  } elsif(ref $data eq 'CODE') {
    local $_ = $self;
    $data->($self);
  } elsif(ref $data eq 'ARRAY') {
    if(
        (($self->tag||'') eq 'ol')
        || (($self->tag||'') eq 'ul')
      )
    {
      $self->at('li')
        ->fill($data, $is_loop, $is_form);
    } elsif(($self->tag||'') eq 'select') {
      if(my $optgroup = $self->at('optgroup')) {
        $optgroup->fill($data, $is_loop, $is_form);
      } elsif(my $option = $self->at('option')) {
        $option->fill($data, $is_loop, $is_form);
      } else {
        warn "Found 'select' without option or optgroup";
      }   
    } else {
      $self->repeat(sub {
        my ($dom, $datum, $index) = @_;
        $dom->fill($datum, 1);
        return $dom;
      }, @$data);
    }
  } elsif(ref $data eq 'HASH') {
    if(
      (($self->tag||'') eq 'option')
        and exists($data->{content})
        and exists($data->{value})
    ) {
      $self->smart_content($data);
    } elsif(
        (($self->tag||'') eq 'optgroup')
        and exists($data->{options})
        and exists($data->{label})
    ) {
      $self->smart_content($data);
    } elsif(
        (($self->tag||'') eq 'input')
        and exists($data->{value})
    ) {
      $self->smart_content($data);
    } else {
      foreach my $match (keys %{$data}) {
        if(!$is_loop) {
          my $dom;
          if($dom = $self->at("#$match")) {
            $is_form = 1 if $dom->tag eq 'form';
            $dom->fill($data->{$match}, $is_loop, $is_form);
            next;
          } elsif($dom = $self->at("*[data-lace-id='$match']")) {
            $is_form = 1 if $dom->tag eq 'form';
            $dom->fill($data->{$match}, $is_loop, $is_form);
            next;
          }
        }
        $self->find(".$match")->each(sub {
            my ($dom, $count) = @_;
            $is_form = 1 if $dom->tag eq 'form';
            $dom->fill($data->{$match}, $is_loop, $is_form);
        });
        if($is_form) {
          # Sorry, I'll come up with less suck when I can.
          $self->find("input[name='$match']")->each(sub {
              my ($dom, $count) = @_;
              $dom->fill($data->{$match}, $is_loop, $is_form);
          });
          $self->find("select[name='$match']")->each(sub {
              my ($dom, $count) = @_;
              $dom->fill($data->{$match}, $is_loop, $is_form);
          });
          $self->find("textarea[name='$match']")->each(sub {
              my ($dom, $count) = @_;
              $dom->fill($data->{$match}, $is_loop, $is_form);
          });
        }
      }
    }
  } elsif(Scalar::Util::blessed $data) {
    if($data->isa('Template::Lace::DOM')) {
      $self->content($data);
    } else {
      my @fields = $data->meta->get_attribute_list;
      foreach my $match (@fields) {
        if(!$is_loop) {
          my $dom = $self->at("#$match");
          $dom->fill($data->$match, $is_loop) if $dom;
        }
        $self->find(".$match")->each(sub {
            my ($dom, $count) = @_;
            $dom->fill($data->$match, $is_loop);
        });
      }
    }
  } else {
    die "method 'fill' does not recognize these arguments.";
  }
}

sub append_js_src_uniquely {
  my ($self, $src, $attrs) = @_;
  unless($self->at("script[src='$src']")) {
    my $extra_attrs = join ' ', map { "$_='$attrs->{$_}'"  } keys %{$attrs||+{}};
    $self->at('head')
     ->append_content("<script type='text/javascript' src='$src' $extra_attrs></script>");
  }
  return $self;
}

sub append_css_href_uniquely {
  my ($self, $href, $attrs) = @_;
  unless($self->at("link[href='$href']")) {
    my $extra_attrs = join ' ', map { "$_='$attrs->{$_}'"  } keys %{$attrs||+{}};
    $self->at('head')
     ->append_content("<link rel='stylesheet' href='$href' $extra_attrs />");
  }
  return $self;
}

sub append_style_uniquely {
  my $self = shift;
  my $style_dom = ref($_[0]) ? shift : ref($self)->new(shift);
  $style_dom = (($style_dom->tag||'') eq 'style') ?
    $style_dom : $style_dom->at('style');

  if(my $id = $style_dom->attr('id')) {
    my $head = $self->at("head") || return $self;
    unless($head->at("style[id='$id']")) {
      $head->append_content($style_dom);
    }
  }
  return $self;
}

sub append_script_uniquely {
  my $self = shift;
  my $script_dom = ref($_[0]) ? shift : ref($self)->new(shift);
  $script_dom = (($script_dom->tag||'') eq 'script') ?
    $script_dom : $script_dom->at('script');

  if(my $id = $script_dom->attr('id')) {
    my $head = $self->at("head") || return $self;
    unless($head->at("script[id='$id']")) {
      $head->append_content($script_dom);
    }
  } elsif(my $src = $script_dom->attr('src')) {
    my $head = $self->at("head") || return $self;
    unless($head->at("script[src='$src']")) {
      $head->append_content($script_dom);
    }
  }
  return $self;
}

sub append_link_uniquely {
  my $self = shift;
  my $link_dom = ref($_[0]) ? shift : ref($self)->new(shift);
  $link_dom = (($link_dom->tag||'') eq 'link') ?
    $link_dom : $link_dom->at('link');
  if(my $href = $link_dom->attr('href')) {
    my $head = $self->at("head") || return $self;
    unless($head->at("link[href='$href']")) {
      $head->append_content($link_dom);
    }
  }
  return $self;
}

my %_escape_table = (
  '&' => '&amp;', 
  '>' => '&gt;', 
  '<' => '&lt;',
  q{"} => '&quot;',
  q{'} => '&#39;' );

sub escape_html {
  my ($value) = @_;
  return unless defined $value;
  $value =~ s/([&><"'])/$_escape_table{$1}/ge;
  return $value;
}

sub _do_attr {
  my ($self, $attr, $val) = @_;
  if($attr eq ':content') {
    $self->fill($val);
  } elsif(
    ($attr eq 'checked')
    || ($attr eq 'selected')
    || ($attr eq 'hidden')
  ) {
    $self->attr($attr=>'on') if $val;
  } else {
    $self->attr($attr=>$val);
  }
}

sub _do {
  my ($self, $maybe_attr, $action) = @_;
  if($maybe_attr) {
    die "Current selected element is not a tag" unless $self->tag;
    if($maybe_attr eq '*') {
      die 'action must be a hashref' unless ref($action) eq 'HASH';
      map { $self->_do_attr($_, $action->{$_}) } keys %$action;
    } else {
      $self->_do_attr($maybe_attr => $action);
    }
  } elsif(!ref $action) {
    if(defined $action) {
      $self->smart_content($action);
    } else {
      $self->remove;
    }
  } else {
    $self->fill($action);
  }
}

sub do {
  my $self = shift;
  while(@_) {
    my ($matchspec, $action) = (shift, shift);
    my ($css, $maybe_attr) = split('@', $matchspec);
    if($css ne '.') {
      $self->find($css)
        ->each(sub { $_->_do($maybe_attr, $action) });
    } else {
      $self->_do($maybe_attr, $action);
    }
  }
  return $self;
}

# attribute helpers (tag specific or otherwise

sub attribute_helper {
  my ($self, $attr, @args) = @_;
  $self->attr($attr, @args);
  return $self;
}

sub target { shift->attribute_helper('target', @_) }
sub src { shift->attribute_helper('src', @_) }
sub href { shift->attribute_helper('href', @_) }
sub id { shift->attribute_helper('id', @_) }
sub action { shift->attribute_helper('action', @_) }
sub method { shift->attribute_helper('method', @_) }
sub colspan { shift->attribute_helper('colspan', @_) }
sub alt { shift->attribute_helper('alt', @_) }
sub enctype { shift->attribute_helper('enctype', @_) }
sub formaction { shift->attribute_helper('formaction', @_) }
sub headers { shift->attribute_helper('headers', @_) }
sub size { shift->attribute_helper('size', @_) }
sub value { shift->attribute_helper('value', @_) }

sub multiple {
  my $self = shift;
  $self->attr(multiple=>'multiple');
  return $self;
}

sub class {
  my ($self, @proto) = @_;
  if(ref($proto[0]) eq 'HASH') {
    my $classes = join ' ', grep { $proto[0]->{$_} } keys %{$proto[0]};
    return $self->attribute_helper('class', $classes);
  } elsif(ref($proto[0]) eq 'ARRAY') {
    my $classes = join ' ', @{$proto[0]};
    return $self->attribute_helper('class', $classes);    
  } else {
    return $self->attribute_helper('class',@proto);
  }
}

sub boolean_attribute_helper {
  my ($self, $name, $value) = @_;
  $self->attribute_helper($name, 'on') if $value;
}

sub checked { shift->boolean_attribute_helper('checked', @_) }
sub selected { shift->boolean_attribute_helper('selected', @_) }
sub hidden { shift->boolean_attribute_helper('hidden', @_) }


# unique tag helpers

sub unique_tag_helper {
  my ($self, $tag, $proto) = @_;
  my $dom = $self->at($tag);
  if(ref $proto eq 'CODE') {
    local $_ = $dom;
    $proto->($dom);
  } elsif(ref $proto) {
    $dom->fill($proto);
  } else {
    $dom->smart_content($proto);
  }
  return $self;
}

sub title { shift->unique_tag_helper('title', @_) }
sub body { shift->unique_tag_helper('body', @_) }
sub head { shift->unique_tag_helper('head', @_) }
sub html { shift->unique_tag_helper('html', @_) }

# element helpers

sub tag_helper_by_id {
  my ($self, $tag, $id, $proto) = @_;
  return $self->unique_tag_helper("$tag$id", $proto);
}

sub list_helper_by_id {
  my ($self, $tag, $id, $proto) = @_;
  my $target = ref($proto) eq 'ARRAY' ? "$tag$id li" : "$tag$id";
  return $self->unique_tag_helper($target, $proto);
}

sub form { shift->tag_helper_by_id('form', @_) }
sub ul { shift->list_helper_by_id('ul', @_) }
sub ol { shift->list_helper_by_id('ol', @_) }

sub dl {
  my ($self, $id, $proto) = @_;
  my $target = "dl$id";
  if(ref($proto) eq 'HASH') {
    $self->at("dl$id")->fill($proto);
  } elsif(ref($proto) eq 'ARRAY') {
    my $dl = $self->at("dl$id");
    my $collection = $dl->find("dt,dd");
    my $new = ref($self)
      ->new($collection->join)
      ->fill($proto);
    $dl->content($new);
  }
  return $self;
}

sub select {
  my ($self, $name, $proto) = @_;
  my $tag = $name=~/^\.#/ ? "$name" : "select[name=$name]";
  return $self->unique_tag_helper($tag, $proto);
}

sub radio {
  my ($self, $name, $proto) = @_;
  my $tag = $name=~/^\.#/ ? "$name" : "input[type='radio'][name=$name]";
  return $self->unique_tag_helper($tag, $proto);

}

sub at_id {
  my ($self, $id, $data) = @_;
  $self->at($id)->fill($data);
  return $self;
}


1;

=head1 NAME

Template::Lace::DOM - DOM searching and tranformation engine

=head1 SYNOPSIS

    sub process_dom {
      my ($self, $dom) = @_;
      $dom->body($self->body);
    }

=head1 DESCRIPTION

L<Template::Lace::DOM> is a subclass of L<Mojo::DOM58> that exists to abstract
the DOM engine used by L<Template::Lace> as well as to provide some helper methods
intended to make the most common types of transformations on your DOM easier.

The helper API described here is one of the more 'under consideration / development'
parts of L<Template::Lace> since without a lot of usage in the wild its a bit hard
to be sure exactly what type of helpers and in what form are most useful.  Take
the follower API with regard to the fact I will change things if necessary.

=head1 GENERAL HELPER METHODS

This class defines the following methods for general use

=head2 clone

Uses L<Storable> C<dclone> to clone the current DOM.

=head2 ctx

Execute a DOM under a given data context, return DOM.  Example

    my $dom = Template::Lace::DOM->new(qq[
      <section>
        <p id='story'>...</p>
      </section>
    ]);

    $dom->ctx(sub {
          my ($self, $data) = @_;
          $_->at('#story')->content($data);
        }, "Don't look down")
      ->... # more commands on $dom;

Returns:

      <section>
        <p id='story'>Don&#39;t look down'</p>
      </section>

Isolate running transformaions on a DOM to explicit data.  Makes it easier to create
reusable snips of transformations.

=head2 overlay

Overlay the current DOM with a new one.  Examples a coderef that should return the
new DOM and any additional arguments you want to pass to the coderef.  Example;

    my $dom = Template::Lace::DOM->new(qq[
      <h1 id="title">HW</h1>
      <section id="body">Hello World</section>
      </html>
    ]);

    $dom->overlay(sub {
      my ($dom, $now) = @_; # $dom is also localized to $_
      my $new_dom = Template::Lace::DOM->new(qq[
        <html>
          <head>
            <title>PAGE_TITLE</title>
          </head>
          <body>
            STUFF
          </body>
        </html>
      ]);

      $new_dom->title($dom->at('#title')->content)
        ->body($dom->at('#body'))
        ->at('head')
        ->append_content("<meta startup='$now'>");

      return $new_dom;
    }, scalar(localtime));

Returns example:

    <html>
      <head>
        <title>HW</title>
      <meta startup="Fri Apr 21 15:45:49 2017"></head>
      <body>Hello World</body>
    </html>

Useful to encapsulate a lot of the work when you want to apply a standard
layout to a web page or section there of.

=wrap_with 

Makes it easier to wrap a current DOM with a 'layout' DOM.  Layout DOM
replaces original.  Example

    my $master = Template::Lace::DOM->new(qq[
      <html>
        <head>
          <title></title>
        </head>
        <body id="content">
        </body>
      </html>
    ]);

    my $inner = Template::Lace::DOM->new(qq[
      <h1>Hi</h1>
      <p>This is a test of the emergency broadcasting networl</p>
    ]);

    $inner->wrap_with($master)
      ->title('Wrapped');

    print $inner;

Returns:

    <html>
      <head>
        <title>Wrapped</title>
      </head>
      <body id="content">
        <h1>Hi</h1>
        <p>This is a test of the emergency broadcasting networl</p>
      </body>
    </html>

By default we match the wrapping DOM ($master in the given example) at the '#content' id
for the template.  You can specify an alternative match point by passing it as a second
argument to C<wrap_with>.


=head2 repeat

Repeat a match as in a loop.  Example:

    my $dom = Template::Lace::DOM->new("<ul><li>ITEMS</li></ul>");
    my @items = (qw/aaa bbb ccc/);

    $dom->at('li')
      ->repeat(sub {
          my ($li, $item, $index) = @_;
          # $li here is DOM that represents the original '<li>ITEMS</li>'
          # each repeat gets that (as a lone of the original) and you can
          # modify it.
          $li->content($item);
          return $li;
      }, @items);

    print $dom->to_string;

Returns:

    <ul>
      <li>aaa</li>
      <li>bbb</li>
      <li>ccc</li>
    <ul>

Basically you have a coderef that gets a cloned copy of the matched DOM and you
need to return a new DOM that replaces it.  Generally you might just modify the
current comment (as in the given example) but you are permitted to replace the
DOM totally.

You might want to see L</LIST HELPERS> and L</fill> as well.

=head2 smart_content

Like C<content> but when called on a tag that does not have content
(like C<input>) will attempt to 'do the right thing'.  For example
it will put the value into the 'value' attribute of the C<input>
tag.

Returns the original DOM.

B<NOTE> We also html escape values here, since this is usually the
safest thing.

B<NOTE> Possibly magical method that will need lots of fixes.

=head2 fill

Used to 'fill' a DOM node with data inteligently by matching hash keys
or methods to classes (or ids) and creating repeat loops when the data
contains an arrayref.

C<fill> will recursively descend the data structure you give it and match
hash keys to tag ids or tag classes and then arrayrefs to tag classes only
(since ids can't be repeated).

Useful to rapidly fill data into a DOM if you don't mind the structual
binding between classes/ids and your data.  Examples:

    my $dom = Template::Lace::DOM->new(q[
      <section>
        <ul id='stuff'>
          <li></li>
        </ul>
        <ul id='stuff2'>
          <li>
            <a class='link'>Links</a> and Info: 
            <span class='info'></span>
          </li>
        </ul>
        <ol id='ordered'>
          <li></li>
        </ol>
        <dl id='list'>
          <dt>Name</dt>
          <dd id='name'></dd>
          <dt>Age</dt>
          <dd id='age'></dd>
        </dl>
      </section>
    ]);

    $dom->fill({
        stuff => [qw/aaa bbb ccc/],
        stuff2 => [
          { link=>'1.html', info=>'one' },
          { link=>'2.html', info=>'two' },
          { link=>'3.html', info=>'three' },
        ],
        ordered => [qw/11 22 33/],
        list => {
          name=>'joe', 
          age=>'32',
        },
      });

Produces:

    <section>
      <ul id="stuff">       
        <li>aaa</li><li>bbb</li><li>ccc</li>
      </ul>
      <ul id="stuff2">
      <li>
          <a class="link">1.html</a> and Info: 
          <span class="info">one</span>
        </li><li>
          <a class="link">2.html</a> and Info: 
          <span class="info">two</span>
        </li><li>
          <a class="link">3.html</a> and Info: 
          <span class="info">three</span>
        </li>
      </ul>
      <ol id="ordered">
        <li>11</li><li>22</li><li>33</li>
      </ol>
      <dl id="list">
        <dt>Name</dt>
        <dd id="name">joe</dd>
        <dt>Age</dt>
        <dd id="age">32</dd>
      </dl>
    </section>

In addition we also match and fill form elements based on the C<name>
attribute, even automatically unrolling arrayrefs of hashrefs correctly
for C<select> and C<input[type='radio']>.  HOWEVER you must first match
a form element (by id or class), for example:

    my $dom = Template::Lace::DOM->new(q[
      <section>
        <form id='login'>
          <input type='text' name='user' />
          <input type='checkbox' name='toggle'/>
          <input type='radio' name='choose' />
          <select name='cars'>
            <option value='value1'>Value</option>
          </select>
        </form>
      </section>]);

    $dom->at('html')
      ->fill(+{
        login => +{
          user => 'Hi User',
          toggle => 'on',
          choose => [
            +{id=>'id1', value=>1},
            +{id=>'id2', value=>2, selected=>1},
          ],
          cars => [
            +{ value=>'honda', content=>'Honda' },
            +{ value=>'ford', content=>'Ford', selected=>1 },
            +{ value=>'gm', content=>'General Motors' },
          ],
        },
      });

    print $dom;

Would return:

    <section>
      <form id="login">
        <input name="user" type="text" value="Hi User">
        <input name="toggle" type="checkbox" value="on">
        <input id="id1" name="choose" type="radio" value="1">
        <input id="id2" name="choose" selected="on" type="radio" value="2"> 
        <select name="cars">
          <option value="honda">Honda</option>
          <option selected="on" value="ford">Ford</option>
          <option value="gm">General Motors</option>
        </select>
      </form>
    </section>

This is done because lookup by C<name> globally would impact performance 
and return too many false positives.

In general C<fill> will try to do the right thing, even coping with
list tags such as C<ol>, C<ul> and input type tags (including C<select> and
Radio input tags) correctly.  You maye find it more magical than you like.
Also using this introduces a required structural
binding between you Model class and the ids and classes of tags in your
templates.  You might find this a great convention or fragile binding
depending on your outlook.

You might want to see L</LIST HELPERS> as well.

=head2 append_style_uniquely

=head2 append_script_uniquely

=head2 append_link_uniquely

Appends a style, script or link tag to the header 'uniquely' (that is we
don't append it if its already there).  The means used to determine
uniqueness is first to check for an exising id attribute, and then
in the case of scripts we look at the src tag, or the href tag for
a link.

You need to add the id attributes yourself and be consistent. In the
future we may add some type of md5 checksum on content when that exists.

Useful when you have a lot of components that need supporting scripts
or styles and you want to make sure you only add the required supporting
code once.

Examples:

    $dom->append_style_uniquely(qq[
       <style id='four'>
         body h4 { border: 1px }
        </style>]);

B<NOTE> This should be the entire tag element.

=head2 append_css_href_uniquely

=head2 append_js_src_uniquely

Similar to the previous group of helpers L</append_link_uniquely>, etc. but
instead of taking the entire tag this just wants a URI which is either the
src attribute for a C<script> tag, or the href attribute of a C<link> tag.
Useful for quickly adding common assets to your pages.  URIs are added uniquely
so you don't have to worry about checking for the presence it first.

    $dom->append_js_src_uniquely('/js/common1.js')
      ->append_js_src_uniquely('/js/common2.js')
      ->append_js_src_uniquely('/js/common2.js')

Would render similar to:

    <html>
      <head>
        <title>Wrapped</title>
        <script src="/js/common1.js" type="text/javascript"></script>
        <script src="/js/common2.js" type="text/javascript"></script>
      </head>
      <body id="content">
        <h1>Hi</h1>
        <p>This is a test of the emergency broadcasting networl</p>
      </body>
    </html>

We append these to the last node inside the C<head> element content.

=head2 do

B<NOTE>: Helper is evolving and may change.

Allows you to run a list of CSS matches at once.  For example:

    my $dom = Template::Lace::DOM->new(q[
      <section>
        <h2>title</h2>
        <ul id='stuff'>
          <li></li>
        </ul>
        <ul id='stuff2'>
          <li>
            <a class='link'>Links</a> and Info: 
            <span class='info'></span>
          </li>
        </ul>

        <ol id='ordered'>
          <li></li>
        </ol>
        <dl id='list'>
          <dt>Name</dt>
          <dd id='name'></dd>
          <dt>Age</dt>
          <dd id='age'></dd>
        </dl>
        <a>Link</a>
      </section>
    ]);

    $dom->do(
      'section h2' => 'Wrathful Hound',
      '#stuff', [qw/aaa bbbb ccc/],
      '#stuff2', [
        { link=>'1.html', info=>'one' },
        { link=>'2.html', info=>'two' },
        { link=>'3.html', info=>'three' },
      ],
      '#ordered', sub { $_->fill([qw/11 22 33/]) },
      '#list', +{
        name=>'joe', 
        age=>'32',
      },
      'a@href' => 'localhost://aaa.html',
    );

Returns:

    <section>
      <h2>Wrathful Hound</h2>
      <ul id="stuff">
        
      <li>aaa</li><li>bbbb</li><li>ccc</li></ul>
      <ul id="stuff2">
        
      <li>
          <a class="link" href="localhost://aaa.html">1.html</a> and Info: 
          <span class="info">one</span>
        </li><li>
          <a class="link" href="localhost://aaa.html">2.html</a> and Info: 
          <span class="info">two</span>
        </li><li>
          <a class="link" href="localhost://aaa.html">3.html</a> and Info: 
          <span class="info">three</span>
        </li></ul>

      <ol id="ordered">
        
      <li>11</li><li>22</li><li>33</li></ol>
      <dl id="list">
        <dt>Name</dt>
        <dd id="name">joe</dd>
        <dt>Age</dt>
        <dd id="age">32</dd>
      </dl>
      <a href="localhost://aaa.html">Link</a>
    </section>

Takes a list of pairs where the first item in the pair is a match specification
and the second is an action to take on it.  The match specification is basically
just a CSS match with one added feature to make it easier to fill values into
attributes, if the match specification ends in C<@attr> the action taken is to
fill that attribute.

Additionally if the action is a simple, scalar value we automatically HTML escape
it for you

B<NOTE> if you want to set content or attributes on the DOM that ->do is run on
you can use '.' as the match specification.

=head1 ATTRIBUTE HELPERS

The following methods are intended to make setting standard attributes on
HTML tags easier.  All methods return the DOM node instance of the tag making
it easier to chain several calls.

=head2 target

=head2 src

=head2 href

=head2 id

=head2 action

=head2 method

=head2 size

=head2 headers

=head2 formaction

=head2 enctype

=head2 alt

=head2 colspan

=head2 value

Example

    $dom->at('form')
      ->id('#login_form')
      ->action('/login')
      ->method('POST');

=head2 checked

=head2 selected

=head2 hidden

=head2 multiple

These attribute helpers have a special feature, since its basically a boolean attribute
will check the passed value for its truth state, setting the attribute value to 'on'
when true, but NOT setting the attribute at all if its false.

=head2 class

This attribute helper has a special shortcup to make it easier to programmtically set
several classes based on a property.  If your argument is a hashref, all the keys whose
values are true will be added.  For example:

    my $dom = Template::Lace::DOM->new('<html><div>aaa</div></html>');

    $dom->at('div')->class({ completed=>1, selected=>0});

    print $dom;

Returns:

    <html><div class="completed">aaa</div></html>

If you instead use an arrayref, all the classes are just added.

Useful to reduce some boilerplate.

=head1 UNIQUE TAG HELPERS

Helpers to access tags that are 'unique', typically only appearing
on a page once.  Can accept a coderef, reference or scalar value.
All return the original DOM for ease of chaining.

=head2 html

=head2 head

=head2 title

=head2 body

Examples:

    my $data = +{
      intro_title => "Things Todo...",
      status => {
        active_items => 2,
        competed_items => 10,
        late_items => 0,
      },
      items => [
        'walk dogs',
        'buy milk',
      ],
    };

    my $dom = Template::Lace::DOM->new(qq[
      <html>
        <head>
          <title>TITLE</title>
        </head>
        <body>
          <h1 id='intro_title'>TITLE</h1>
          <dl>
          </dl>
            <dt>Active</dt>
            <dd id='active_items'>0</dd>
            <dt>Completed</dt>
            <dd id='completed_items'>0</dd>
            <dt>Late</dt>
            <dd id='late_items'>0</dd>
          </dl>
          <ol>
            <li class='items'>ITEMS</li>
          </ol>
        </body>
      </html>
    ]);

    $dom->title($data->{intro_title})
      ->head(sub {
        $_->append_content('<meta description="a page" />');
        $_->append_content('<link href="/css/core.css" />');
      })->body($data);

    print $dom->to_string;

Returns

      <html>
        <head>
          <title>Things Todo...</title>
        </head>
        <body>
          <h1 id='intro_title'>Things Todo...</h1>
          <dl>
          </dl>
            <dt>Active</dt>
            <dd id='active_items'>2</dd>
            <dt>Completed</dt>
            <dd id='completed_items'>10</dd>
            <dt>Late</dt>
            <dd id='late_items'>0</dd>
          </dl>
          <ol>
            <li class='items'>walk dog</li>
            <li class='items'>buy milk</li>
          </ol>
        </body>
      </html>

Under the hood we use L</fill> and L<smart_content> as well as L<repeat>
as necessary.  More magic for less code but at some code in performance
and possible support / code understanding.

=head1 LIST TAG HELPERS

Helpers to make populating data into list type tags easier.  All return
the original DOM to make chaining easier.

    my $dom = Template::Lace::DOM->new(q[
      <section>
        <ul id='stuff'>
          <li></li>
        </ul>
        <ul id='stuff2'>
          <li>
            <a class='link'>Links</a> and Info: 
            <span class='info'></span>
          </li>
        </ul>

        <ol id='ordered'>
          <li></li>
        </ol>
        <dl id='list'>
          <dt>Name</dt>
          <dd id='name'></dd>
          <dt>Age</dt>
          <dd id='age'></dd>
        </dl>
      </section>
    ]);

  $dom->ul('#stuff', [qw/aaa bbbb ccc/]);
  $dom->ul('#stuff2', [
    { link=>'1.html', info=>'one' },
    { link=>'2.html', info=>'two' },
    { link=>'3.html', info=>'three' },
  ]);

  $dom->ol('#ordered', [qw/11 22 33/]);

  $dom->dl('#list', {
    name=>'joe', 
    age=>'32',
  });


=head2 ul

=head2 ol

Both helper make it easier to populate an array reference of data into
list tags.

Example:

    my $dom = Template::Lace::DOM->new(q[
      <section>
        <ul id='stuff'>
          <li></li>
        </ul>
        <ul id='stuff2'>
          <li>
            <a class='link'>Links</a> and Info: 
            <span class='info'></span>
          </li>
        </ul>

        <ol id='ordered'>
          <li></li>
        </ol>
        <dl id='list'>
          <dt>Name</dt>
          <dd id='name'></dd>
          <dt>Age</dt>
          <dd id='age'></dd>
        </dl>
      </section>
    ]);

  $dom->ul('#stuff', [qw/aaa bbbb ccc/]);
  $dom->ul('#stuff2', [
    { link=>'1.html', info=>'one' },
    { link=>'2.html', info=>'two' },
    { link=>'3.html', info=>'three' },
  ]);

  $dom->ol('#ordered', [qw/11 22 33/]);

Returns:

    <section>
      <ul id="stuff">     
        <li>aaa</li>
        <li>bbbb</li>
        <li>ccc</li>
      </ul>
      <ul id="stuff2">     
        <li>
          <a class="link">1.html</a> and Info: 
          <span class="info">one</span>
        </li>
        <li>
          <a class="link">2.html</a> and Info: 
          <span class="info">two</span>
        </li>
        <li>
          <a class="link">3.html</a> and Info: 
          <span class="info">three</span>
        </li>
      </ul>
      <ol id="ordered">
      <li>11</li>
      <li>22</li>
      <li>33</li>
      </ol>
    </section>

=head2 dl

this helper will either an arrayref or hashref and attempt to 'do the
right thing'.  Example:

  my $dom = Template::Lace::DOM->new(q[
    <dl id='hashref'>
      <dt>Name</dt>
      <dd id='name'></dd>
      <dt>Age</dt>
      <dd id='age'></dd>
    </dl>
    <dl id='arrayref'>
      <dt class='term'></dt>
      <dd class='value'></dd>
    </dl>
  ]);

  $dom->dl('#hashref', +{
    name=>'John',
    age=> '48'
  });

  $dom->dl('#arrayref', [
      +{ term=>'Name', value=> 'John'},
      +{ term=>'Age', value=> 42 },
      +{ term=>'email', value=> [
          'jjn1056@gmail.com',
          'jjn1056@yahoo.com']},
  ]);
 
Returns:

    <dl id="hashref">
      <dt>Name</dt>
       <dd id="name">John</dd>
      <dt>Age</dt>
        <dd id="age">48</dd>
    </dl>
    <dl id="arrayref">
      <dt class="term">Name</dt>
        <dd class="value">John</dd>
      <dt class="term">Age</dt>
       <dd class="value">42</dd>
      <dt class="term">email</dt>
        <dd class="value">jjn1056@gmail.com</dd>
        <dd class="value">jjn1056@yahoo.com</dd>
    </dl>

=head2 select

The C<select> tag for the purposes of filling its C<options> is
treated as a type of list tag.

    my $dom = Template::Lace::DOM->new(q[
      <form>
        <select name='cars'>
          <option>Example</options>
        </select>
      </form>]);

    $dom->select('cars', [
      +{ value=>'honda', content=>'Honda' },
      +{ value=>'ford', content=>'Ford', selected=>1 },
      +{ value=>'gm', content=>'General Motors' },
    ]);

    print $dom;

Returns:

    <select name="cars">
      <option value="honda">Honda</option>
      <option selected="on" value="ford">Ford</option>
      <option value="gm">General Motors</option>
    </select>

Please note that match 'id' is on the C<name> attribute of the C<select>
tag, not of the C<id> attribute as it is on other list helper types.

You can also populate option groups as in the following:

    my $dom = Template::Lace::DOM->new(q[
      <select name='jobs'>
        <optgroup label='Example'>
          <option>Example</option>
        </optgroup>
      </select>]);

    $dom->select('jobs', [
      +{
        label=>'Easy',
        options => [
          +{ value=>'slacker', content=>'Slacker' },
          +{ value=>'couch_potato', content=>'Couch Potato' },
        ],
      },
      +{
        label=>'Hard',
        options => [
          +{ value=>'digger', content=>'Digger' },
          +{ value=>'brain', content=>'Brain Surgeon' },
        ],
      },
    ]);

    print $dom;

Would return:

    <select name="jobs">    
      <optgroup label="Easy">
        <option value="slacker">Slacker</option>
        <option value="couch_potato">Couch Potato</option>
      </optgroup>
      <optgroup label="Hard">
        <option value="digger">Digger</option>
        <option value="brain">Brain Surgeon</option>
      </optgroup>
    </select>

=head2 radio

List helper for a radio input type.  Example

    my $dom = Template::Lace::DOM->new("
      <form>
        <input type='radio' name='choose' />
      </form>");

    $dom->radio('choose',[
      +{id=>'id1', value=>1},
      +{id=>'id2', value=>2, selected=>1},
      ]);

    print $dom;

Returns;

    <form>
      <input id="id1" name="choose" type="radio" value="1">
      <input id="id2" name="choose" type="radio" value="2" selected="on">
    </form>

=head1 GENERAL TAG HELPERS

Helpers to work with common tags. All return the original DOM to make
chaining easier.

=head2 form

Form tag helper. Example:

    $dom->form('#login', sub {
      $_->action('login.html'); 
    });

=head1 SEE ALSO
 
L<Template::Lace>.

=head1 AUTHOR

Please See L<Template::Lace> for authorship and contributor information.
  
=head1 COPYRIGHT & LICENSE
 
Please see L<Template::Lace> for copyright and license information.

=cut 
