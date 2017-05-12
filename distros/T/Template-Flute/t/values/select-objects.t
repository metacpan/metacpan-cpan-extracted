# Dropdown tests for values.

package My::Object;

use strict;
use warnings;

sub new {
    my ($class, %self) = @_;
    return bless \%self, $class;
}
sub code_method {
    return shift->{private_code};
}
sub name_method {
    return shift->{private_name};
}
sub code {
    return shift->{private_code};
}
sub name {
    return shift->{private_name};
}

package My::Object::Other;

sub new {
    my ($class, %self) = @_;
    return bless \%self, $class;
}
sub value {
    return shift->{private_code};
}
sub label {
    return shift->{private_name};
}

package main;

use strict;
use warnings;

use Test::More tests => 19;
use Template::Flute;
use Data::Dumper;

my ($spec, $html, @colors, $flute, $out, $expected);

$spec = q{<specification>
<value name="test" iterator="colors" iterator_value_key="code" iterator_name_key="name"/>
</specification>
};

$html = q{<html><select class="test"></select></html>};

foreach my $new ({private_code => 'red'},
                 {private_code => 'black'}) {
    my $obj = My::Object->new(%$new);
    push @colors, $obj;
    ok ($obj->can("code"), "object can call code");
    ok (!exists $obj->{code}, "the iterator_value_key is not accessible");
}

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              iterators => { colors => \@colors },
                             );

$out = $flute->process();

ok ($out =~ m%<option>red</option><option>black</option>%,
    "Test value with HTML dropdown.")
    || diag "HTML: $out.\n";


$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              iterators => { colors => \@colors },
                              values => { test => 'black' },
                             );

$out = $flute->process();

ok ($out =~ m%<option>red</option><option selected="selected">black</option>%,
    "Test value with HTML dropdown and selected value.")
    || diag "HTML: $out.\n";

@colors = ();

foreach my $new ({private_code => 'red',
                  private_name => 'Red',
                 },
                 {private_code => 'black',
                  private_name => 'Black',
                 }) {
    my $obj = My::Object->new(%$new);
    push @colors, $obj;
    ok ($obj->can("code"), "Object can call code");
    ok ($obj->can("name"), "Object can call name");
    ok (!exists $obj->{name}, "name not directly accessible");
    ok (!exists $obj->{code}, "code not directly accessible");
}

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              iterators => {colors => \@colors},
                             );

$out = $flute->process();

ok ($out =~ m%<option value="red">Red</option><option value="black">Black</option>%,
    "Test value with HTML dropdown and labels.")
    || diag "HTML: $out.\n";


$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              iterators => {colors => \@colors},
                              values => {test => 'black'},
                             );

$out = $flute->process();

ok ($out =~ m%<option value="red">Red</option><option selected="selected" value="black">Black</option>%,
    "Test value with HTML dropdown, labels and selected value.")
    || diag "HTML: $out.\n";


$spec =<<'SPEC';
<specification>
  <value name="color" iterator="colors"
         iterator_value_key="code_method" iterator_name_key="name_method"/>
</specification>
SPEC

$html =<<'HTML';
<html>
 <select class="color">
 <option value="example">Example</option>
 </select>
</html>
HTML

@colors = ();

foreach my $new ({private_code => 'red',
                  private_name => 'Red',
                 },
                 {private_code => 'black',
                  private_name => 'Black',
                 }) {
    push @colors, My::Object->new(%$new);
}

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              iterators => {colors => \@colors},
                              values => { color => 'black' },
                             );

$out = $flute->process();
$expected =<<'HTML';
<select class="color">
<option value="red">Red</option>
<option selected="selected" value="black">Black</option>
</select></body>
HTML

$expected =~ s/\n//g;

ok($out =~ m/\Q$expected\E/, "doc example ok") || diag $out;

# testing with auto iterators

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              auto_iterators => 1,
                              values => { color => 'black',
                                        colors => \@colors},
                             );

$out = $flute->process();
$expected =<<'HTML';
<select class="color">
<option value="red">Red</option>
<option selected="selected" value="black">Black</option>
</select></body>
HTML

$expected =~ s/\n//g;

ok($out =~ m/\Q$expected\E/, "doc example ok") || diag $out;

# diag "Testing with object which can call ->label and ->value";

$spec =<<'SPEC';
<specification>
  <value name="color" iterator="colors" />
</specification>
SPEC

@colors = ();

foreach my $new ({private_code => 'red',
                  private_name => 'Red',
                 },
                 {private_code => 'black',
                  private_name => 'Black',
                 }) {
    push @colors, My::Object::Other->new(%$new);
}


$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              iterators => {colors => \@colors},
                              values => { color => 'black' },
                             );

$out = $flute->process();
ok($out =~ m/\Q$expected\E/, "doc example ok with value and label method") || diag $out;



