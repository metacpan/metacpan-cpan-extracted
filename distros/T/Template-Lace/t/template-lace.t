use Test::Most;
use Template::Lace::DOM;

use_ok 'Template::Lace::Factory';

{
  package Local::Template::Nav;

  use Moo;

  has 'content' => (is=>'ro');

  sub template {
    return q[
      <nav>
      </nav>
    ]
  }

  sub on_component_add {
    my ($self, $dom) = @_;
    $dom->at('nav')
      ->content($self->content);
  }

  package Local::Template::Master;

  use Moo;

  has title => (is=>'ro', required=>1);
  has body => (is=>'ro', required=>1);

  sub prepare_dom {
    my ($self, $dom) = @_;
    $dom->body(sub { $_->append_content('<section id="ff">fffffff</section>') });
  }

  sub on_component_add {
    my ($self, $dom) = @_;
    $dom->title($self->title)
      ->body(sub {
        $_->at('h1')->append($self->body);
      });
  }

  sub template {
    my $class = shift;
    return q[
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8" />
          <meta content="width=device-width, initial-scale=1" name="viewport" />
          <title>Master Title</title>
          <link href="/static/base.css" rel="stylesheet" />
          <link href="/static/index.css" rel="stylesheet"/ >
        </head>
        <body id="body">
          <h1>Intro</h1>
        </body>
      </html>        
    ];
  }



  package Local::Template::User;

  use Moo;

  has [qw(title story cites form)] => (is=>'ro', required=>1);

  sub prepare_dom {
    my ($class, $dom) = @_;
    $dom->body(sub {
      $_->append_content('<meta version=1 />');
    });
  }

  sub add_debug {
    my ($self, $dom) = @_;
    $dom->at('body')
      ->append_content('<footer>INFO</footer>');
  }

  sub template {q[
    <layout-master
        title=\'title:content'
        body=\'body:content'>
      <html>
        <head>
          <title>Page Title</title>
        </head>
        <body>
          <layout-nav>
            <ul>
              <li>aaa</li>
            </ul>
          </layout-nav>
          <section id='story'>
            Story
          </section>
          <ul id="cites">
            <li>Citations</li>
          </ul>
          <lace-form action='/postit' query={"q":"$.title"} args=["1","2"]
              method='POST'>
            <lace-input type='text'
                name='user'
                label='User:'
                value='$.form.fields.user.value' />
            <lace-input type='password'
                name='passwd'
                label='Password'
                value=$.form.fields.passwd.value />
          </lace-form>
          <lace-timestamp tz='America/Chicago'/>
          <tag-anchor href='more.html' target='_top'>See More</tag-anchor>
        </body>
      </html>
    </layout-master>
  ]}

  sub process_dom {
    my ($self, $dom) = @_;
    $dom->title($self->title)
      ->at_id('#story', $self->story)
      ->ul('#cites', $self->cites);
  }

  package Local::Template::Timestamp;

  use Moo;
  use DateTime;

  has 'tz' => (is=>'ro', predicate=>'has_tz');

  sub time {
    my ($self) = @_;
    my $now = DateTime->now;
    $now->set_time_zone($self->tz)
      if $self->has_tz;
    return $now;
  }

  sub template {
    q[<span class='timestamp'>time</span>];
  }

  sub process_dom {
    my ($self, $dom) = @_;
    $dom->at('.timestamp')
      ->content($self->time);
  }

  package Local::Template::Form;

  use Moo;
  with 'Template::Lace::Model::HasChildren';

  has [qw(method action content query args)] => (is=>'ro', required=>1);

  sub template {q[
    <style id='formstyle'>sdfsdfsd</style>
    <form></form>
  ]}

  sub process_dom {
    my ($self, $dom) = @_;

    Test::Most::is_deeply $self->query, +{q=>'the real story'};
    Test::Most::is_deeply $self->args, [1,2];

    $dom->at('form')
      ->action($self->action)
      ->method($self->method)
      ->content($self->content);
  }

  package Local::Template::Input;

  use Moo;

  has [qw(name label type value container)] => (is=>'ro', required=>1);

  sub template {q[
    <style id="inputstyle">fff</style>
    <div>
      <label></label>
      <input></input>
    </div>
  ]}

  sub process_dom {
    my ($self, $dom) = @_;
    $dom->at('label')
      ->content($self->label)
      ->attr(for=>$self->name);
    $dom->at('input')->attr(
      type=>$self->type,
      value=>$self->value,
      name=>$self->name);
  }
}

use Template::Lace::Utils ':ALL';
ok my $factory = Template::Lace::Factory->new(
  model_class=>'Local::Template::User',
  component_handlers=>+{
    tag => {
      anchor => mk_component {
        my ($self, %attrs) = @_;
        return "<a href='$_{href}' target='$_{target}'>$_{content}</a>";
      }
    },
    layout => sub {
      my ($name, $args, %args) = @_;
      $name = ucfirst $name;
      return Template::Lace::Factory->new(model_class=>"Local::Template::$name");
    },
    lace => {
      timestamp => Template::Lace::Factory->new(model_class=>'Local::Template::Timestamp'),
      form => Template::Lace::Factory->new(model_class=>'Local::Template::Form'),
      input => Template::Lace::Factory->new(model_class=>'Local::Template::Input'),
    },
  },
);

ok my $renderer = $factory->create(
  title => 'the real story',
  story => 'you are doomed to discover you can never recover...',
  cites => [
    'another book',
    'yet another',
    'padding'],
  form => +{
    fields => +{
      user => +{ value => 'jjn'},
      passwd => +{ value => 'whatwhyhow?'},
    },
  });

$renderer->call(sub {
  my ($model, $dom) = @_;
  $model->add_debug($dom);
});

$renderer->call('add_debug');

ok my $html = $renderer->render;
ok my $dom = Template::Lace::DOM->new($html);

is $dom->at('nav li')->content, 'aaa';
is $dom->find('meta')->[0]->attr('charset'), 'utf-8';
is $dom->find('meta')->[1]->attr('name'), 'viewport';
is $dom->find('link')->[0]->attr('href'), '/static/base.css';
is $dom->find('link')->[1]->attr('href'), '/static/index.css';
is $dom->find('style')->[0]->content, 'sdfsdfsd';
is $dom->find('style')->[1]->content, 'fff';

is $dom->at('input[name="user"]')->attr('value'), 'jjn';
is $dom->at('input[name="passwd"]')->attr('value'), 'whatwhyhow?';

is $dom->find('#cites li')->[0]->content, 'another book';
is $dom->find('#cites li')->[1]->content, 'yet another';
is $dom->find('#cites li')->[2]->content, 'padding';

is $dom->at('title')->content, 'the real story';
is $dom->at('#story')->content, 'you are doomed to discover you can never recover...';
is $dom->at('#ff')->content, 'fffffff';
ok $dom->at('span.timestamp')->content;
is $dom->at('a')->content, 'See More';

{
  package Local::Template::NoProcessDom;

  use Moo;

  sub template { qq{
    <section>
      Hello <span id="name">NAME</span>, you are <span id="age"></span> years old!
    </section>
  }}

  sub fill_name {
    my ($self, $dom, $name) = @_;
    $dom->do('#name', $name);
  }

  sub fill_age {
    my ($self, $dom, $age) = @_;
    $dom->do('#age', $age);
  }

  my $factory = Template::Lace::Factory->new(
    model_class=>'Local::Template::NoProcessDom');

  my $renderer = $factory->create();

  $renderer->call('fill_name', 'John');
  $renderer->call('fill_age', '42');
  
  my $html = $renderer->render;
  my $dom = Template::Lace::DOM->new($html);

  Test::Most::is $dom->at('#name')->content, 'John';
  Test::Most::is $dom->at('#age')->content, '42';
}


done_testing;

__END__
generated HTML

<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta content="width=device-width, initial-scale=1" name="viewport">
  <title>the real story</title>
  <link href="/static/base.css" rel="stylesheet">
  <link href="/static/index.css" rel="stylesheet">
  <style id="formstyle">
  sdfsdfsd
  </style>
  <style id="inputstyle">
  fff
  </style>
</head>
<body id="body">
  <h1>Intro</h1>
  <section id="story">
    you are doomed to discover you can never recover...
  </section>
  <ul id="cites">
    <li>another book</li>
    <li>yet another</li>
    <li>padding</li>
  </ul>
  <form action="/postit" method="post">
    <div>
      <label for="user">User:</label> <input name="user" type="text" value="jjn">
    </div>
    <div>
      <label for="passwd">Password</label> <input name="passwd" type="password" value="whatwhyhow?">
    </div>
  </form><span class="timestamp">2017-04-24T11:18:37</span>
  <meta>
  <section id="ff">
          fffffff
  </section>
</body>
</html>
