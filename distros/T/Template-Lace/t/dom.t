use Test::Most;
use Template::Lace::DOM;
use Scalar::Util 'refaddr';


# General Helpers
{
  # clone
  {
    ok my $dom = Template::Lace::DOM->new('<h1>Hello</h1>');
    ok my $clone = $dom->clone;
    is "$dom", '<h1>Hello</h1>';
    is "$clone", '<h1>Hello</h1>';
    isnt refaddr($dom), refaddr($clone);
  }
  
  #overlay
  {
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
        ->body($dom->at('#body')->content)
        ->at('head')
        ->append_content("<meta startup='$now'>");

      return $new_dom
    }, scalar(localtime));

    ok $dom->at('html');
    ok $dom->at('meta');
    is $dom->at('title')->content, 'HW';
    is $dom->at('body')->content, 'Hello World';
  }

  #repeat
  {
    my $dom = Template::Lace::DOM->new("<ul><li>ITEMS</li></ul>");
    my @items = (qw/aaa bbb ccc/);

    $dom->at('li')
      ->repeat(sub {
          my ($li, $item, $index) = @_;
          $li->content($item);
      }, @items);

    is $dom->find('li')->[0]->content, 'aaa';
    is $dom->find('li')->[1]->content, 'bbb';
    is $dom->find('li')->[2]->content, 'ccc';
    is @{$dom->find('li')}, 3;     
  }

  #fill
  {
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

    is @{$dom->find('#stuff li')}, 3;
    is @{$dom->find('#stuff2 li')}, 3;
    is @{$dom->find('#ordered li')}, 3;
    is @{$dom->find('#list dd')}, 2;
  }

  #append_style_uniquely
  {
    my $dom = Template::Lace::DOM->new(qq[
      <html>
        <head>
        </head>
      </html>
    ]);

    $dom->append_style_uniquely(qq[
      <style id='one'>
       body h1 { border: 1px }
      </style>
    ]);

    $dom->append_style_uniquely(qq[
      <style id='one'>
       body h1 { border: 1px }
      </style>
    ]);

    $dom->append_style_uniquely(qq[
      <style id='two'>
       body h2 { border: 1px }
      </style>
    ]);

    $dom->append_style_uniquely(
      Template::Lace::DOM->new(qq[
       <style id='one'>
         body h1 { border: 1px }
        </style>
      ])
    );

    $dom->append_style_uniquely(
      Template::Lace::DOM->new(qq[
       <style id='three'>
         body h3 { border: 1px }
        </style>
      ])
    );

    my $page = Template::Lace::DOM->new(qq[
       <style id='four'>
         body h4 { border: 1px }
        </style>
        <div>Helloworld</div>
        <ul>
          <li>one</li>
          <li>two</li>
        </ul>
      ]);

    $dom->append_style_uniquely($page->at('style'));
    
    ok $dom->at('style[id="one"]');
    ok $dom->at('style[id="two"]');
    ok $dom->at('style[id="three"]');
    ok $dom->at('style[id="four"]');

    is @{$dom->find('style[id="one"]')}, 1;
    is @{$dom->find('style[id="two"]')}, 1;
    is @{$dom->find('style[id="three"]')}, 1;
    is @{$dom->find('style[id="four"]')}, 1;
  }

  #append_script_uniquely
  {
    my $dom = Template::Lace::DOM->new(qq[
      <html>
        <head>
        </head>
      </html>
    ]);

    $dom->append_script_uniquely(qq[
      <script id='one'>
       alert(1);
       </script>
    ]);

    $dom->append_script_uniquely(qq[
      <script id='one'>
       alert(1);
      </script>
    ]);

    $dom->append_script_uniquely(qq[
      <script id='two'>
       alert(2);
      </script>
    ]);

    $dom->append_script_uniquely(
      Template::Lace::DOM->new(qq[
       <script id='one'>
       alert(1);
        </script>
      ])
    );

    $dom->append_script_uniquely(
      Template::Lace::DOM->new(qq[
       <script id='three'>
       alert(3);
        </script>
      ])
    );

    my $page = Template::Lace::DOM->new(qq[
       <script id='four'>
       alert(4);
        </script>
        <div>Helloworld</div>
        <ul>
          <li>one</li>
          <li>two</li>
        </ul>
      ]);

    $dom->append_script_uniquely($page->at('script'));

    $dom->append_script_uniquely(qq[
      <script src="js/one.js"></script>
    ]);

    $dom->append_script_uniquely(qq[
      <script src="js/one.js"></script>
    ]);

    ok $dom->at('script[id="one"]');
    ok $dom->at('script[id="two"]');
    ok $dom->at('script[id="three"]');
    ok $dom->at('script[id="four"]');

    is @{$dom->find('script[id="one"]')}, 1;
    is @{$dom->find('script[id="two"]')}, 1;
    is @{$dom->find('script[id="three"]')}, 1;
    is @{$dom->find('script[id="four"]')}, 1;
    is @{$dom->find('script[src="js/one.js"]')}, 1;
  }

  #append_link_uniquely
  {
    my $dom = Template::Lace::DOM->new(qq[
      <html>
        <head>
        </head>
      </html>
    ]);

    $dom->append_link_uniquely(qq[
      <link href='css/1.css' />
    ]);

    $dom->append_link_uniquely(qq[
      <link href='css/1.css' />
    ]);

    $dom->append_link_uniquely(qq[
      <link href='css/2.css' />
    ]);

    $dom->append_link_uniquely(
      Template::Lace::DOM->new(qq[
      <link href='css/1.css' />
      ])
    );

    $dom->append_link_uniquely(
      Template::Lace::DOM->new(qq[
      <link href='css/3.css' />
      ])
    );

    my $page = Template::Lace::DOM->new(qq[
      <link href='css/4.css' />
        <div>Helloworld</div>
        <ul>
          <li>one</li>
          <li>two</li>
        </ul>
      ]);

    $dom->append_link_uniquely($page->at('link'));
    
    ok $dom->at('link[href="css/1.css"]');
    ok $dom->at('link[href="css/2.css"]');
    ok $dom->at('link[href="css/3.css"]');
    ok $dom->at('link[href="css/4.css"]');

    is @{$dom->find('link[href="css/1.css"]')}, 1;
    is @{$dom->find('link[href="css/2.css"]')}, 1;
    is @{$dom->find('link[href="css/3.css"]')}, 1;
    is @{$dom->find('link[href="css/4.css"]')}, 1;
  }
}

# Attribute Helpers
{
  my $dom = Template::Lace::DOM->new(qq[
    <html>
      <head>
       <form></form>
       <a></a>
      </head>
    </html>
  ]);

  $dom->at('a')
    ->href('go.html')
    ->target('_top');

  $dom->at('form')
    ->method('POST')
    ->action('login')
    ->class('formclass')
    ->id('login');

  is $dom->at('#login')->attr('method'), 'POST';
  is $dom->at('#login')->attr('action'), 'login';
  is $dom->at('#login')->attr('class'), 'formclass';
  is $dom->at('#login')->attr('id'), 'login';
  is $dom->at('a')->attr('href'), 'go.html';
  is $dom->at('a')->attr('target'), '_top';
}

# Unique Tag Helpers
{
  my $dom = Template::Lace::DOM->new(qq[
    <html>
      <head>
        <title></title>
      </head>
      <body>
      </body>
    </html>
  ]);

  $dom->title('HW')
    ->head(sub { $_->append_content('<meta description="Test" />') })
    ->body(sub { $_->content('Hello ') })
    ->html(sub { $_->body( sub { $_->append_content('World!') }) });

  is $dom->at('title')->content, 'HW';
  is $dom->at('meta')->attr('description'), 'Test';
  is $dom->at('body')->content, 'Hello World!';

}

# List Helpers
{
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

  is @{$dom->find('#stuff li')}, 3;
  is @{$dom->find('#stuff2 li')}, 3;
  is @{$dom->find('#ordered li')}, 3;
  is @{$dom->find('#list dd')}, 2;
}

{
  my $dom = Template::Lace::DOM->new(qq[
    <html>
      <head>
        <title></title>
      </head>
      <body>
        <p id='story'>...</p>
      </body>
    </html>
  ]);

  $dom->title('CTX')
    ->ctx(\my @cap, sub {
        my ($self, $data) = @_;
        $_->at('#story')->content($data);
      }, "Don't look down");

  is $dom->at('title')->content, 'CTX';
  is $dom->at('#story')->content, 'Don&#39;t look down';
  ok $cap[0];
}

#class
{
  my $dom = Template::Lace::DOM->new('<html><div>aaa</div></html>');
  $dom->at('div')->class({ completed=>1, selected=>0});
  is $dom->at('div')->attr('class'), 'completed';
}

#do
{
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

  $dom->at('section')
    ->do(
    '.@id' => 'classclass',
    '.@*' => +{ rev=>3, class=>'top', hidden=>1 },
    'section h2' => sub { $_->content('<blick>Wrathful Hound</blick>') },
    '#stuff', [qw/aaa bbbb ccc/],
    '#stuff2', [
      { link=>'1.html', info=>'one' },
      { link=>'2.html', info=>'two' },
      { link=>'3.html', info=>'<b>three</b>' },
    ],
    '#ordered', sub { $_->fill([qw/11 22 33/]) },
    '#list', +{
      name=>'joe', 
      age=>'32',
    },
    'a@href' => 'localhost://aaa.html',
  );

  is $dom->at('section')->attr('id'), 'classclass';
  is @{$dom->find('#stuff li')}, 3;
  is @{$dom->find('#stuff2 li')}, 3;
  is @{$dom->find('#ordered li')}, 3;
  is @{$dom->find('#list dd')}, 2;
}

{ # Forms
  my $dom = Template::Lace::DOM->new(q[
    <html>
      <form id='login'>
        <textarea name='details'>info</textarea>
        <input type='text' name='user' />
        <input type='hidden' name='uid' />
        <input type='password' name='passwd' />
        <input type='checkbox' name='toggle'/> <!-- value is bool 'checked' -->
        <input type='radio' name='choose' />  <!-- fill type value is 'checked' -->
        <select name='cars'> <!-- fill type -->
          <option value='honda'>Honda</option>   <!-- 'selected' -->
        </select>
        <select name='jobs'>
          <optgroup label='Example'>
            <option>Example</option>
          </optgroup>
        </select>
      </form>
    </html>
    ]);

  { # select API
    my $localdom = $dom->clone;
    $localdom->select('cars', [
      +{ value=>'honda', content=>'Honda' },
      +{ value=>'ford', content=>'Ford', selected=>1 },
      +{ value=>'gm', content=>'General Motors' },
    ]);
    
    $localdom->select('jobs', [
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

    is $localdom->at('option[value="honda"]')->content, 'Honda';
    is $localdom->at('option[value="ford"]')->content, 'Ford';
    is $localdom->at('option[value="ford"]')->attr('selected'), 'on';
    is $localdom->at('option[value="gm"]')->content, 'General Motors';

    is $localdom->at('option[value="slacker"]')->content, 'Slacker';
    is $localdom->at('option[value="couch_potato"]')->content, 'Couch Potato';
    is $localdom->at('option[value="digger"]')->content, 'Digger';
    is $localdom->at('option[value="brain"]')->content, 'Brain Surgeon';
  }

  { # 'radio' API
    my $localdom = $dom->clone;

    $localdom->radio('choose',[
      +{id=>'id1', value=>1},
      +{id=>'id2', value=>2},
      ]);

    is $localdom->at('#id1')->attr('value'), 1;
    is $localdom->at('#id2')->attr('value'), 2;
  }

  {
    my $localdom = $dom->clone;
    $localdom->at('html')->fill(+{
        login => +{
          user => 'Hi User',
          uid => 111,
          passwd => 'nopass',
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
          jobs => [
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
          ],
        },
      });

    is $localdom->at('#id1')->attr('value'), 1;
    is $localdom->at('#id2')->attr('value'), 2;
    is $localdom->at('#id2')->attr('selected'), 'on';

    is $localdom->at('option[value="honda"]')->content, 'Honda';
    is $localdom->at('option[value="ford"]')->content, 'Ford';
    is $localdom->at('option[value="ford"]')->attr('selected'), 'on';
    is $localdom->at('option[value="gm"]')->content, 'General Motors';
    is $localdom->at('option[value="slacker"]')->content, 'Slacker';
    is $localdom->at('option[value="couch_potato"]')->content, 'Couch Potato';
    is $localdom->at('option[value="digger"]')->content, 'Digger';
    is $localdom->at('option[value="brain"]')->content, 'Brain Surgeon';
  }
}

# do bugs
{
  my $dom = Template::Lace::DOM->new(q[
    <section>
      <ol id="list">
        <li>example</li>
      </ol>
      <form id='login'>
        <input type='checkbox' name='toggle'/>
        <ol id='toggle_errors'>
          <li>ERR</li>
        </ol>
        <select name='tags'>
          <option>example</option>
        </select>
      </form>
    </section>]);

  $dom->do(
    'input[name="toggle"]@checked' => 1,
    'select[name="tags"]' => [1,2,3],
    '#list' => [1,2,3],
    '#toggle_errors' => undef,
  );

  is $dom->at('input[name="toggle"]')->attr('checked'), 'on';
  is $dom->at('select[name="tags"]')->find('option')->[0]->content, 1;
  ok !$dom->at('#toggle_errors');
}

# wrap_with
{
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

  $inner->append_js_src_uniquely('/js/common1.js');
  $inner->append_js_src_uniquely('/js/common2.js');
  $inner->append_js_src_uniquely('/js/common2.js');

  is $inner->at('title')->content, 'Wrapped';
  is $inner->at('h1')->content, 'Hi';
  ok $inner->at('script[src="/js/common1.js"]');
  ok $inner->at('script[src="/js/common2.js"]');
  is scalar(@{$inner->find('script[src="/js/common2.js"]')}), 1;
}

done_testing;
