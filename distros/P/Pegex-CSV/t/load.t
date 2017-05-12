use lib (-e 't' ? 't' : 'test'), 'inc';

{
    use Test::More;
    eval "use YAML::XS; 1" or plan skip_all => 'YAML::XS required';
}

use TestML;

TestML->new(
    testml => do {local $/; <DATA>},
    bridge => 'TestMLBridge',
)->run;

{
    package TestMLBridge;
    use Pegex::Base;
    extends 'TestML::Bridge';
    use TestML::Util;

    use Pegex::CSV;

    sub csv_load {
        my ($self, $csv) = @_;
        $csv = $csv->value;
        $csv =~ s/~/ /g;
        return native(Pegex::CSV->new->load($csv));
    }

    sub yaml_load {
        my ($self, $yaml) = @_;
        return native(YAML::XS::Load($yaml->value));
    }

    sub yaml_dump {
        my ($self, $struct) = @_;
        return str YAML::XS::Dump($struct->value);
    }
}

__DATA__
%TestML 0.1.0

# Diff = 1
*csv.csv_load.yaml_dump == *yaml.yaml_load.yaml_dump

=== Simple
--- csv
a,b,c
1,2,3
--- yaml
- [a,b,c]
- ['1','2','3']

=== Multi character words
--- csv
foo,bar,baz
--- yaml
- [foo,bar,baz]

=== Spaces
--- csv
a , b , c~~
   d   ,   e  ,      foo~~~
--- yaml
- [a,b,c]
- [d,e,foo]

=== Empties
--- csv
,,,
,foo , ,bar,

--- yaml
- ['','','','']
- ['','foo','','bar','']

=== Quotes
--- csv
"", " ", ",","abc"
" def ", "  foo~~
  bar
  baz~~
", "
  Say ""WHAT""???"
--- yaml
- ['', ' ', ',', abc]
- [' def ', "  foo  \n  bar\n  baz  \n", "\n  Say \"WHAT\"???"]

=== No final newline
--- csv: foo bar, " baz "
--- yaml
- [foo bar, ' baz ']

=== Non ascii
--- csv
döt Net, Ingy
♥, ☺☻ , "Unicode™"
--- yaml
- [döt Net, Ingy]
- [♥,☺☻,Unicode™]

=== Single value lines
--- csv
foo
  bar~~
--- yaml
- [foo]
- [bar]

=== Empty stream
--- csv
--- yaml
[]

=== Blank lines
--- csv

~~~~~~~~~~
--- yaml
- ['']
- ['']

