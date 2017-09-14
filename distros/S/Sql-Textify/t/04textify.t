use strict;
use warnings;
use Test::More;

use_ok( 'Sql::Textify' );

my $test_ref = [
  # Simple Recordset
    {
      name => 'Simple Recordset',
      data => {
        fields => ['one', 'two'],
        rows => [
          ['first', 'second']
        ],
      },
      results => [
        {
          format => ['markdown', 'table'],
          text => '
one   | two   
------|-------
first | second
',
        },
        {
          format => ['markdown', 'record'],
          text => '# Record 1

Column | Value 
-------|-------
one    | first 
two    | second

',
        },
        {
          format => ['html', 'table'],
          text => '<table>
<thead>
  <th>one</th>
  <th>two</th>
</thead>
<tbody>
<tr>
  <td>first</td>
  <td>second</td>
</tr>
</tbody>
</table>

',
        },
        {
          format => ['html', 'record'],
          text => '<h1>Record 1</h1>

<table>
<tr>
  <th>one</th>
  <td>first</td>
</tr>
<tr>
  <th>two</th>
  <td>second</td>
</tr>
</table>

',
      }
      ]
    },
  #
  # More Lines
  #
    {
      name => 'More Lines',
      data => {
        fields => ['one', 'two'],
        rows => [
          ['first', 'second'],
          ['the loneliness of the long distance runner', 'long row']
        ],
      },
      results => [
        {
          format => ['markdown', 'table'],
          text => '
one                                        | two     
-------------------------------------------|---------
first                                      | second  
the loneliness of the long distance runner | long row
',
        },
        {
          format => ['markdown', 'record'],
          text => '# Record 1

Column | Value 
-------|-------
one    | first 
two    | second

# Record 2

Column | Value                                     
-------|-------------------------------------------
one    | the loneliness of the long distance runner
two    | long row                                  

',
        },
        {
          format => ['html', 'table'],
          text => '<table>
<thead>
  <th>one</th>
  <th>two</th>
</thead>
<tbody>
<tr>
  <td>first</td>
  <td>second</td>
</tr>
<tr>
  <td>the loneliness of the long distance runner</td>
  <td>long row</td>
</tr>
</tbody>
</table>

',
        },
        {
          format => ['html', 'record'],
          text => '<h1>Record 1</h1>

<table>
<tr>
  <th>one</th>
  <td>first</td>
</tr>
<tr>
  <th>two</th>
  <td>second</td>
</tr>
</table>

<h1>Record 2</h1>

<table>
<tr>
  <th>one</th>
  <td>the loneliness of the long distance runner</td>
</tr>
<tr>
  <th>two</th>
  <td>long row</td>
</tr>
</table>

',
      }
      ]
    },

  #
  # Quote Markdown and Html
  #
    {
      name => 'Quote Markdown and Html',
      data => {
        fields => ['column\'with"quotes|spaces and pipes', 'column<html>'],
        rows => [
          ['quotes \'"|space', '<h1></h1>'],
        ],
      },
      results => [
        { # there's not a standard way to quote markdown text
          # stackedit ignores html tags but interpreters correctly the quoted pipes .. markdown here ignores everyting
          format => ['markdown', 'table'],
          text => '
column\'with"quotes\|spaces and pipes | column<html>
-------------------------------------|-------------
quotes \'"\|space                     | <h1></h1>   
',
        },
        {
          format => ['html', 'table'],
          text => '<table>
<thead>
  <th>column&#39;with&quot;quotes|spaces and pipes</th>
  <th>column&lt;html&gt;</th>
</thead>
<tbody>
<tr>
  <td>quotes &#39;&quot;|space</td>
  <td>&lt;h1&gt;&lt;/h1&gt;</td>
</tr>
</tbody>
</table>

',
        },
      ]
    },
];


my $t     = Sql::Textify->new;

foreach my $test (@{ $test_ref }) {

    foreach my $result (@{ $test->{results} }) {
        $t->{format} = $result->{format}[0];
        $t->{layout} = $result->{format}[1];

        is( $t->_Do_Format($test->{data}), $result->{text}, "Test name=$test->{name}, format=$result->{format}[0], layout=$result->{format}[1]");
    }
}

done_testing;