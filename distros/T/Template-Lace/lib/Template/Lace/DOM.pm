use strict;
use warnings;
package Template::Lace::DOM;

use base 'Mojo::DOM58';
use Storable ();
use Scalar::Util;

# General Helpers

sub clone {
  return Storable::dclone(shift);
}

sub overlay {
  my ($self, $cb, @args) = @_;
  local $_ = $self;
  my $overlay_dom = $cb->($self, @args);
  $self->replace($overlay_dom);
}

sub wrap_at_content {
  my ($self, $new) = @_;
  $self->overlay(sub {
    $new->at('#content')
      ->replace($self);
  });
}

sub repeat {
  my ($self, $cb, @items) = @_;
  my $index = 0;
  my @nodes = map {
    my $cloned_dom = $self->clone;
    $index++;
    $cb->($cloned_dom, $_, $index);
    $cloned_dom;
  } @items;

  # Might be a faster way to do this...
  $self->parent->append_content($_) for @nodes;
  $self->remove;
  return $self;
}

sub smart_content {
  my ($self, $data) =@_;
  if($self->tag eq 'input') {
    $self->attr(value=>$data);
  } else {
    $self->content($data);
  }
  return $self;
}

sub fill {
  my ($self, $data, $is_loop) = @_;
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
        ->fill($data, $is_loop);
    } else {
      $self->repeat(sub {
        my ($dom, $datum, $index) = @_;
        $dom->fill($datum, 1);
      }, @$data);
    }
  } elsif(ref $data eq 'HASH') {
    foreach my $match (keys %{$data}) {
      if(!$is_loop) {
        my $dom = $self->at("#$match");
        $dom->fill($data->{$match}, $is_loop) if $dom;
      }
      $self->find(".$match")->each(sub {
          my ($dom, $count) = @_;
          $dom->fill($data->{$match}, $is_loop);
      });
    }
  } elsif(Scalar::Util::blessed $data) {
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
  } else {
    die "method 'fill' does not recognize these arguments.";
  }
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
sub class { shift->attribute_helper('class', @_) }
sub action { shift->attribute_helper('action', @_) }
sub method { shift->attribute_helper('method', @_) }


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
sub dl { shift->tag_helper_by_id('dl', @_) }

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

=repeat

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
      }, @items);

    print $dom->to_string;

Returns:

    <ul>
      <li>aaa</li>
      <li>bbb</li>
      <li>ccc</li>
    <ul>

You might want to see L</LIST HELPERS> and L</fill> as well.

=head2 smart_content

Like C<content> but when called on a tag that does not have content
(like C<input>) will attempt to 'do the right thing'.  For example
it will put the value into the 'value' attribute of the C<input>
tag.

Returns the original DOM.

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

In general C<fill> will try to do the right thing, even coping with
list tags such as C<ol> and <ul> correctly.  You maye find it more
magical than you like.  Also using this introduces a required structural
binding between you Model class and the ids and classes of tags in your
templates.  You might find this a great convention or fragile binding
depending on your outlook.

You might want to see L</LIST HELPERS> as well.

=head2 append_style_uniquely

=head2 append_script_uniquely

=head2 append_link_uniquely

Appends a style, script or link to the header 'uniquely' (that is we
don't append it if its already there).  The means used to determine
uniqueness is first to check for an exising id attribute, and then
in the case of scripts we look at the src tag, or the href tag for
a link.

You need to add the id attributes yourself and be consistent. In the
future we may add some type of md5 checksum on content when that exists.

Useful when you have a lot of components that need supporting scripts
or styles and you want to make sure you only add the required supporting
code once.

=head1 ATTRIBUTE HELPERS

The following methods are intended to make setting standard attributes on
HTML tags easier.  All methods return the DOM node instance of the tag making
it easier to chain several calls.

=head2 target

=head2 src

=head2 href

=head2 id

=head2 class

=head2 action

=head2 method

Example

    $dom->at('form')
      ->id('#login_form')
      ->action('/login')
      ->method('POST');

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
      <section>
        <dl id='list'>
          <dt>Name</dt>
          <dd id='name'></dd>
          <dt>Age</dt>
          <dd id='age'></dd>
        </dl>
      </section>]);

   $dom->ol('#ordered', [qw/11 22 33/]);

Returns:

    <section>
      <dl id="list">
        <dt>Name</dt>
        <dd id="name">joe</dd>
        <dt>Age</dt>
        <dd id="age">32</dd>
      </dl>
    </section>

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
