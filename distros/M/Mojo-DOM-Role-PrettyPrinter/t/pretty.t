use Mojo::Base -strict;

use Test::More;

use Mojo::DOM;
my $class=Mojo::DOM->with_roles('+PrettyPrinter');

{
my $dom=$class->new('<div><p>first para</p><p>second para</p>');
is($dom->to_pretty_string,<<'EOT');
<div>
  <p>first para</p>
  <p>second para</p>
</div>
EOT
}

{
my $dom=$class->new('<div><Bare/></p>');
is($dom->to_pretty_string,<<'EOT');
<div>
  <bare />
</div>
EOT
}
{
my $dom=$class->new('<div><Bare with="attribute"/></div>');
is($dom->to_pretty_string,<<'EOT');
<div>
  <bare with="attribute" />
</div>
EOT
}
{
my $dom=$class->new('<div><Bare with="attribute"/></div>');
is($dom->to_pretty_string,<<'EOT');
<div>
  <bare with="attribute" />
</div>
EOT
}
{
my $dom=$class->new('<div><Bare with="attribute"/></div>');
is($dom->to_pretty_string,<<'EOT');
<div>
  <bare with="attribute" />
</div>
EOT
}

{
my $dom=$class->new('<div><Bare with="multiple" attribute="values"/><div with="multiple" attribute="values">OMG</div></div>');
is($dom->to_pretty_string,<<'EOT');
<div>
  <bare attribute="values"
        with="multiple" />
  <div attribute="values"
       with="multiple">OMG</div>
</div>
EOT
}

done_testing;
