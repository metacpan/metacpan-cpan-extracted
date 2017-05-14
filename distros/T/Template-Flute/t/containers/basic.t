#
# Tests for containers.
use strict;
use warnings;

use Test::More;
use Template::Flute;

my (@tests, @tests_id, $html, $spec, $flute, $out);

@tests = ([q{<container name="box" value="username"/>}, {}, 0],
	  [q{<container name="box" value="username"/>}, 
	   {username => 'racke'}, 1],
	  [q{<container name="box" value="!username"/>}, 
	   {}, 1],
	  [q{<container name="box" value="!username"/>}, 
	   {username => 'racke'}, 0],
	  [q{<container name="box" value="foo|bar"/>}, 
	   {}, 0],
	  [q{<container name="box" value="foo|bar"/>}, 
	   {foo => 1}, 1],
	  [q{<container name="box" value="foo|bar"/>}, 
	   {bar => 1}, 1],
	  [q{<container name="box" value="foo|bar"/>}, 
	   {foo => 1, bar => 1}, 1],
	  [q{<container name="box" value="foo|!bar"/>}, 
	   {}, 1],
	  [q{<container name="box" value="foo|!bar"/>}, 
	   {foo => 1}, 1],
	  [q{<container name="box" value="foo|!bar"/>}, 
	   {bar => 1}, 0],
	  [q{<container name="box" value="foo|!bar"/>}, 
	   {foo => 1, bar => 1}, 1],
	  [q{<container name="box" value="foo&amp;bar"/>}, 
	   {}, 0],
	  [q{<container name="box" value="foo&amp;bar"/>}, 
	   {foo => 1}, 0],
	  [q{<container name="box" value="foo&amp;bar"/>}, 
	   {bar => 1}, 0],
	  [q{<container name="box" value="foo&amp;bar"/>}, 
	   {foo => 1, bar => 1}, 1],
	  [q{<container name="box" value="foo&amp;!bar"/>}, 
	   {}, 0],
	  [q{<container name="box" value="foo&amp;!bar"/>}, 
	   {foo => 1}, 1],
	  [q{<container name="box" value="foo&amp;!bar"/>}, 
	   {bar => 1}, 0],
	  [q{<container name="box" value="foo&amp;!bar"/>}, 
	   {foo => 1, bar => 1}, 0],
    );

@tests_id = ([q{<container name="box" id="box" value="username"/>}, {}, 0],
	     [q{<container name="box" id="box" value="username"/>}, 
	      {username => 'racke'}, 1],
	     [q{<container name="box" id="box" value="!username"/>}, 
	      {}, 1],
	     [q{<container name="box" id="box" value="!username"/>}, 
	      {username => 'racke'}, 0],
    );

plan tests => scalar @tests + @tests_id + 5;

$html = q{<html><div class="box">USER</div></html>};

my $i;

for my $t (@tests) {
    $i++;

    $flute = Template::Flute->new(specification => $t->[0],
				  template => $html,
				  values => $t->[1]);

    $out = $flute->process();

    if ($t->[2]) {
	ok($out =~ m%<html><head></head><body><div class="box">USER</div></body></html>%, "$i: $out");
    }
    else {
	ok($out !~ m%<html><head></head><body><div class="box">USER</div></body></html>%, "$i: $out");
    }
}

# test for a bug where only the first <div> block was removed from the HTML output
$html .= $html;

$flute = Template::Flute->new(specification => q{<container name="box" value="!username"/>},
			      template => "<html>$html</html>",
			      values => {username => 'racke'});

$out = $flute->process();

ok ($out !~  m%<html><div class="box">USER</div><html>%, "Duplicate container: $out.");

# add test for containers with id attribute
$i = 0;

$html = q{<html><div id="box">USER</div></html>};

for my $t (@tests_id) {
    $i++;

    $flute = Template::Flute->new(specification => $t->[0],
				  template => $html,
				  values => $t->[1]);

    $out = $flute->process();

    if ($t->[2]) {
        ok($out =~ m%<html><head></head><body><div id="box">USER</div></body></html>%, "$i: $out")
            || diag $out;
    }
    else {
        ok($out !~ m%<html><div id="box">USER</div></html>%, "$i: $out")
            || diag $out;
    }
}

# add test for container and value sharing same HTML element
$html = q{<html><div class="message">MESSAGE</div></html>};
$spec = q{<specification>
<container name="message" value="message">
<value name="message" field="message"/>
</container>
</specification>
};

$flute = Template::Flute->new(specification => $spec,
			      template => $html,
			      values => {message => 'Alright'},
    );

$out = $flute->process();

ok($out =~ m%<html><head></head><body><div class="message">Alright</div></body></html>%, 'container shares value with value present') || diag $out;

$flute = Template::Flute->new(specification => $spec,
			      template => $html,
    );

$out = $flute->process();

ok($out !~ m%<html><head></head><body><div class="message">.*</div></body></html>%, 'container shares value with value not present') || diag $out;

# add test for container and value sharing same HTML element through ID
$html = q{<html><div id="message">MESSAGE</div></html>};
$spec = q{<specification>
<container name="message" value="message" id="message">
<value name="message" field="message" id="message"/>
</container>
</specification>
};

$flute = Template::Flute->new(specification => $spec,
			      template => $html,
			      values => {message => 'Alright'},
    );

$out = $flute->process();

ok($out =~ m%<html><head></head><body><div id="message">Alright</div></body></html>%, 'container shares value with value present using HTML id attribute') || diag $out;

$flute = Template::Flute->new(specification => $spec,
			      template => $html,
    );

$out = $flute->process();

ok($out !~ m%<html><head></head><body><div id="message">.*</div></body></html>%, 'container shares value with value not present using HTML id attribute') || diag $out;
