use Test::Most;
use Template::Pure::ParseUtils;

# Helper function to make the tests less verbose
sub data { +{ Template::Pure::ParseUtils::parse_data_spec(shift) } }
sub match { +{ Template::Pure::ParseUtils::parse_match_spec(shift) } }
sub template { [ Template::Pure::ParseUtils::parse_data_template(shift) ] }
sub itr { +{ Template::Pure::ParseUtils::parse_itr_spec(shift) } }

# Test cases for match spec parsing
is_deeply match('title'), +{mode=>'replace', css=>'title', target=>'content', absolute=>''};
is_deeply match('^title'), +{mode=>'replace', css=>'title', target=>'node', absolute=>''};
is_deeply match('+title'), +{mode=>'prepend', css=>'title', target=>'content', absolute=>''};
is_deeply match('title+'), +{mode=>'append', css=>'title', target=>'content', absolute=>''};
is_deeply match('^+title'), +{mode=>'prepend', css=>'title', target=>'node', absolute=>''};
is_deeply match('^title+'), +{mode=>'append', css=>'title', target=>'node', absolute=>''};
is_deeply match('a@href'), +{mode=>'replace', css=>'a', target=>\'href', absolute=>''};
is_deeply match('+a@href'), +{mode=>'prepend', css=>'a', target=>\'href', absolute=>''};
is_deeply match('a@href+'), +{mode=>'append', css=>'a', target=>\'href', absolute=>''};
is_deeply match('a#link@href'), +{mode=>'replace', css=>'a#link', target=>\'href', absolute=>''};
is_deeply match('+a#link@href'), +{mode=>'prepend', css=>'a#link', target=>\'href', absolute=>''};
is_deeply match('a#link@href+'), +{mode=>'append', css=>'a#link', target=>\'href', absolute=>''};
is_deeply match('@href'), +{mode=>'replace', css=>'.', target=>\'href', absolute=>''};
is_deeply match('^.'), +{mode=>'replace', css=>'.', target=>'node', absolute=>''};
is_deeply match('html|'), +{mode=>'filter', css=>'html', target=>'', absolute=>''};

# Test case for data path parsing
is_deeply data('aaa.bbb'), +{
  absolute => '',
  filters => [],
  path => [
    {
      key => "aaa",
      maybe => "",
      optional => ""
    },
    {
      key => "bbb",
      maybe => "",
      optional => ""
    }
  ],
};

is_deeply data('/maybe:aaa/optional:bbb/maybe:optional:ccc/optional:maybe:ddd'), +{
  absolute => 1,
  filters => [],
  path => [
    {
      key => "aaa",
      maybe => 1,
      optional => ""
    },
    {
      key => "bbb",
      maybe => "",
      optional => 1
    },
    {
      key => "ccc",
      maybe => 1,
      optional => 1
    },
    {
      key => "ddd",
      maybe => 1,
      optional => 1
    }
  ],
};

is_deeply data('meta.info | truncate(30,"...") | tc'), +{
  absolute => "",
  filters => [
    ['truncate', 30, '...'],
    ['tc'],
  ],
  path => [
    {
      key => "meta",
      maybe => "",
      optional => "",
    },
    {
      key => "info",
      maybe => "",
      optional => "",
    },
  ],
};

is_deeply data('aaa.bbb.ccc|f0 | f1("aa") | f2("ff", ={ddd.eee | xx(1,={zz.11 | xx | pp}) }) | f3(11,22)'), +{
  absolute => "",
  filters => [
    [
      "f0"
    ],
    [
      "f1",
      "aa"
    ],
    [
      "f2",
      "ff",
      {
        absolute => "",
        filters => [
          [
            "xx",
            1,
            {
              absolute => "",
              filters => [
                [
                  "xx"
                ],
                [
                  "pp"
                ]
              ],
              path => [
                {
                  key => "zz",
                  maybe => "",
                  optional => ""
                },
                {
                  key => 11,
                  maybe => "",
                  optional => ""
                }
              ]
            }
          ]
        ],
        path => [
          {
            key => "ddd",
            maybe => "",
            optional => ""
          },
          {
            key => "eee",
            maybe => "",
            optional => ""
          }
        ]
      }
    ],
    [
      "f3",
      11,
      22
    ]
  ],
  path => [
    {
      key => "aaa",
      maybe => "",
      optional => ""
    },
    {
      key => "bbb",
      maybe => "",
      optional => ""
    },
    {
      key => "ccc",
      maybe => "",
      optional => ""
    }
  ]
};

is_deeply template('Hello ={foo} world!'), [
  'Hello ',
  {
    absolute => '',
    filters => [],
    path => [
      { key=>'foo', maybe=>'', optional=>'' },
    ],
  },
  ' world!',
];

is_deeply template('Hello ={meta.first_name | tc(={settings.length | tc(={foo})})} ={meta.last_name} world ={aaa.bbb}!'), [
  'Hello ',
 {
    absolute => "",
    filters => [
      [
        "tc",
        {
          absolute => "",
          filters => [
            [
              "tc",
              {
                absolute => "",
                filters => [],
                path => [
                  {
                    key => "foo",
                    maybe => "",
                    optional => ""
                  }
                ]
              }
            ]
          ],
          path => [
            {
              key => "settings",
              maybe => "",
              optional => ""
            },
            {
              key => "length",
              maybe => "",
              optional => ""
            }
          ]
        }
      ]
    ],
    path => [
      {
        key => "meta",
        maybe => "",
        optional => ""
      },
      {
        key => "first_name",
        maybe => "",
        optional => ""
      }
    ]
  },
  ' ',
  {
    absolute => '',
    filters=> [],
    path => [
      { key=>'meta', maybe=>'', optional=>'' },
      { key=>'last_name', maybe=>'', optional=>'' },
    ],
  },
  ' world ',
  {
    absolute => '',
    filters=> [],
    path => [
      { key=>'aaa', maybe=>'', optional=>'' },
      { key=>'bbb', maybe=>'', optional=>'' },
    ],
  },
  '!',
];

is_deeply itr('user<-users'), +{
  user => +{
    absolute => '',
    filters => [],
    path => [
      { key => 'users', optional => '', maybe => '' },
    ],
  },
};

is_deeply itr('friend<-user.friends'), +{
  friend => +{
    absolute => '',
    filters => [],
    path => [
      { key => 'user', optional => '', maybe => '' },
      { key => 'friends', optional => '', maybe => '' },
    ],
  },
};

is_deeply data("'literal data single quote'"), +{
  absolute => '',
  filters => [],
  path => [],
  literal => 'literal data single quote',
};

is_deeply data('"literal data double quote"'), +{
  absolute => '',
  filters => [],
  path => [],
  literal => 'literal data double quote',
};

done_testing;
