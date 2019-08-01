use Mojo::Base -strict;

use Test::More;
use Mojo::DOM;

my $dom = Mojo::DOM->new('');
is $dom, '', 'sanity';
ok $dom->with_roles('+Form')->does('Mojo::DOM::Role::Form'), 'obj compose';
$dom = Mojo::DOM->with_roles('+Form')->new('');
ok $dom->does('Mojo::DOM::Role::Form'), 'class compose';

# Form values
$dom = Mojo::DOM->with_roles('+Form')->new(<<EOF);
<form action="/foo">
  <p>Test</p>
  <input type="text" name="a" value="A" />
  <input type="checkbox" name="q">
  <input type="checkbox" checked name="b" value="B">
  <input type="radio" name="r">
  <input type="radio" checked name="c" value="C">
  <input name="s">
  <input type="checkbox" name="t" value="">
  <input type=text name="u">
  <select multiple name="f">
    <option value="F">G</option>
    <optgroup>
      <option>H</option>
      <option selected>I</option>
      <option selected disabled>V</option>
    </optgroup>
    <option value="J" selected>K</option>
    <optgroup disabled>
      <option selected>I2</option>
    </optgroup>
  </select>
  <select name="n"><option>N</option></select>
  <select multiple name="q"><option>Q</option></select>
  <select name="y" disabled>
    <option selected>Y</option>
  </select>
  <select name="d">
    <option selected>R</option>
    <option selected>D</option>
  </select>
  <textarea name="m">M</textarea>
  <button name="o" value="O">No!</button>
  <input type="submit" name="p" value="P" />
</form>
<form><input type="submit" name="a" value="A"></form>
<form>
  <input type="button" name="b" value="B" disabled>
  <input type="button" name="c" value="C">
</form>
<form><input type="image" name="c" value="C"></form>
<form>
  <button name="e" value="E" disabled>
  <button name="d" value="D">
</form>
<form></form>
EOF
is $dom->at('p')->val,                         undef, 'no value';
is $dom->at('input')->val,                     'A',   'right value';
is $dom->at('input:checked')->val,             'B',   'right value';
is $dom->at('input:checked[type=radio]')->val, 'C',   'right value';
is_deeply $dom->at('select')->val, ['I', 'J'], 'right values';
is $dom->at('select option')->val,                          'F', 'right value';
is $dom->at('select optgroup option:not([selected])')->val, 'H', 'right value';
is $dom->find('select')->[1]->at('option')->val, 'N', 'right value';
is $dom->find('select')->[1]->val, undef, 'no value';
is $dom->find('select')->[2]->val, undef, 'no value';
is $dom->find('select')->[2]->at('option')->val, 'Q', 'right value';
is $dom->at('select[disabled]')->val, 'Y', 'right value';
is $dom->find('select')->last->val, 'D', 'right value';
is $dom->find('select')->last->at('option')->val, 'R', 'right value';
is $dom->at('textarea')->val, 'M', 'right value';
is $dom->at('button')->val,   'O', 'right value';
is $dom->at('form')->find('input')->last->val, 'P', 'right value';
is $dom->at('input[name=q]')->val, 'on',  'right value';
is $dom->at('input[name=r]')->val, 'on',  'right value';
is $dom->at('input[name=s]')->val, undef, 'no value';
is $dom->at('input[name=t]')->val, '',    'right value';
is $dom->at('input[name=u]')->val, undef, 'no value';
my $form = {a => 'A', b => 'B', c => 'C', d => 'D', f => ['I', 'J'], m => 'M',
  n => undef, p => 'P', q => undef, r => 'on', s => undef, t => '', u => undef};
is_deeply $dom->at('form')->val('input[name=p]'), $form, 'correct form values';

my $all_forms = $dom->find('form')->map(sub { $_->val });
delete $form->{p};
$form->{o} = 'O';
is_deeply $all_forms, [$form, {a=>'A'}, {}, {'c.x'=>1, 'c.y'=>1}, {d=>'D'}, {}],
  'all the forms';

# various input button types, with and without selectors
# image
$dom = Mojo::DOM->with_roles('+Form')->new('<form><input type=image /></form>');
is_deeply $dom->at('form')->val('input[type=image]'), {x => 1, y => 1},
  'x + y coords';
is_deeply $dom->at('form')->val(), {x => 1, y => 1},
  'x + y coords';
$dom = Mojo::DOM->with_roles('+Form')->new('<form><input type=image name=pic /></form>');
is_deeply $dom->at('form')->val('input[name=pic]'),
  {'pic.x' => 1, 'pic.y' => 1}, 'x + y coords';
is_deeply $dom->at('form')->val(), {'pic.x' => 1, 'pic.y' => 1}, 'x + y coords';
$dom = Mojo::DOM->with_roles('+Form')->new('<form><input type=image width=100 height=50 /></form>');
my $image_form = $dom->at('form')->val();
is_deeply [sort keys %$image_form], [qw{x y}], 'correct';
ok $image_form->{x} >= 1 && $image_form->{x} <= 100, 'valid x value';
ok $image_form->{y} >= 1 && $image_form->{y} <= 50, 'valid y value';

# submit
$dom = Mojo::DOM->with_roles('+Form')->new(<<EOF);
<form><input type=submit name=example /><input name=car value=vw></form>
EOF
is_deeply $dom->at('form')->val('input[name=example]'),
  {car => 'vw', example => 'Submit'}, 'valueless Submit';
is_deeply $dom->at('form')->val(), {car => 'vw', example => 'Submit'},
  'valueless Submit';
# button - client side only cannot submit without javascript
$dom = Mojo::DOM->with_roles('+Form')->new('<form><input type=button name=x value=y /></form>');
is_deeply $dom->at('form')->val(), {}, 'not clicked, not included';
is_deeply $dom->at('form')->val('input[name=x]'), {},
  'clicked, button means not included';
$dom = Mojo::DOM->with_roles('+Form')->new('<form><button type=reset name=x value=y /></form>');
is_deeply $dom->at('form')->val(), {}, 'not clicked, not included';
is_deeply $dom->at('form')->val('input[name=x]'), {},
  'clicked, button means not included';
$dom = Mojo::DOM->with_roles('+Form')->new('<form><button type=button name=x value=y /></form>');
is_deeply $dom->at('form')->val(), {}, 'not clicked, not included';
is_deeply $dom->at('form')->val('input[name=x]'), {},
  'clicked, button means not included';

# multiple submit options
$dom = Mojo::DOM->with_roles('+Form')->new(<<EOF);
<html>
<head></head>
<body>
<div></div>
<form action="/form">
  <input type=submit name="sub0" formaction="/process-form" disabled />
  <fieldset>
    <input type=submit name="sub1" formaction="/process-form" />
  </fieldset>
  <input type=submit name="sub2" />
  <input type=submit name="sub3" formmethod="post" />
  <input type=text name=textual value=data />
</form>
</body>
</html>
EOF
is_deeply $dom->at('form')->val(), {sub1 => 'Submit', textual => 'data'},
  'correct default first submit item';
is_deeply $dom->at('form')->val('input[name=sub0]'), {textual => 'data'},
  'disabled buttons cannot be enabled';
is_deeply $dom->at('form')->val('input[name=sub2]'),
  {sub2 => 'Submit', textual => 'data'}, 'no clicks - no form?';
is_deeply [$dom->at('form')->target('input[name=sub2]')],
  [qw{GET /form url-encoded}], 'default action';
is_deeply [$dom->at('form')->target('input[name=sub1]')],
  [qw{GET /process-form url-encoded}], 'updated action';
is_deeply [$dom->at('form')->target('input[name=sub3]')],
  [qw{POST /form url-encoded}], 'updated method';
is_deeply [$dom->at('form')->target('input[name=sub0]')], [], 'cannot submit';

$dom = Mojo::DOM->with_roles('+Form')->new(<<EOF);
<!-- https://html.spec.whatwg.org/multipage/form-elements.html#dom-fieldset-elements -->
<form>
<fieldset name="clubfields" disabled>
 <legend> <label>
  <input type=checkbox name=club onchange="form.clubfields.disabled = !checked">
  Use Club Card
 </label> </legend>
 <p><label>Name on card: <input name=clubname required></label></p>
 <p><label>Card num: <input name=clubnum required pattern="[-0-9]+"></label></p>
 <p><label>Expiry date: <input name=clubexp type=month></label></p>
</fieldset>
</form>
EOF

is_deeply $dom->at('form')->val, {club => 'on'}, # todo: check this should be on
  q{excluding those that are descendants of the fieldset}.
  q{ element's first legend element child};
delete $dom->at('fieldset')->tree->[2]{disabled};
is_deeply $dom->at('form')->val, {club => 'on',
  map { $_ => undef } qw{clubname clubnum clubexp}}, 'enabled fieldset';

$dom = Mojo::DOM->with_roles('+Form')->new(<<EOF);
<form action="/form"><input type=text name=enter value=user /></form>
EOF
is_deeply $dom->at('form')->val, {enter => 'user'}, 'no submit button';
is_deeply [$dom->at('form')->target], [qw{GET /form url-encoded}], 'no submit';

$dom = Mojo::DOM->with_roles('+Form')->new(<<'EOF');
<div>
  <form>
    <input type=submit formaction="/" formmethod="POST" formenctype="multipart">
    <input type=submit id="no-action" formmethod="POST" formenctype="multipart">
  </form>
</div>
EOF
is $dom->target, undef, 'not a form';
is $dom->at('form')->target('great'), undef, 'not in the form';
is_deeply [$dom->at('form')->target], [qw{POST / multipart}], 'target';
is_deeply [$dom->at('form')->target('#no-action')], ['POST', '#', 'multipart'],
  'target';

done_testing;
