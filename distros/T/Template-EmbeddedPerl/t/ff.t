package Template::EmbeddedPerl::Test::FF;
$INC{'Template/EmbeddedPerl/Test/FF.pm'} = __FILE__;

## skip if Valiant isn't available

BEGIN {
  use Test::Most;
  eval "
    use Valiant::HTML::Util::View;
    use Valiant::HTML::Util::Form;
  ";
  plan skip_all => 'Valiant required for these tests' if $@;
}

{
  package Local::Person;

  use Moo;
  use Valiant::Validations;

  has first_name => (is=>'ro');
  has last_name => (is=>'ro');
  has persisted => (is=>'rw', required=>1, default=>0);
  
  validates ['first_name', 'last_name'] => (
    length => {
      maximum => 10,
      minimum => 3,
    }
  );
}

use Template::EmbeddedPerl;
use File::Spec;

ok my $yat = Template::EmbeddedPerl->new(
  auto_escape => 1,
  directories => [[Template::EmbeddedPerl->directory_for_package('Template::EmbeddedPerl::Test::FF'), 'templates']],
  prepend => 'use v5.40;use strictures 2;');

ok my $f = Valiant::HTML::Util::Form->new(view=>$yat);
ok my $person = Local::Person->new(first_name => 'aa', last_name => 'napiorkowski');

my $generated = '
<form accept-charset="UTF-8" class="new_local_person" enctype="application/x-www-form-urlencoded" id="new_local_person" method="post">
  <div>
    <label for="local_person_first_name">First Name</label>
    <input id="local_person_first_name" name="local_person.first_name" type="text" value="aa"/>
    <label for="local_person_last_name">Last Name</label>
    <input id="local_person_last_name" name="local_person.last_name" type="text" value="napiorkowski"/>
  </div>
</form>';

{
  my $position = tell( DATA );
  ok my $template = join '', <DATA>;
  seek DATA, $position, 0;
  ok my $generator1 = $yat->from_string($template);
  ok my $out = $generator1->render($f, $person);
  is $out, $generated, 'rendered template';
}

{
  ok my $generator1 = $yat->from_file('ff');
  ok my $out = $generator1->render($f, $person);
  is $out, $generated, 'rendered template';
}

{
  ok my $generator1 = $yat->from_data(__PACKAGE__);
  ok my $out = $generator1->render($f, $person);
  is $out, $generated, 'rendered template';
}

{
  my @path = (
    Template::EmbeddedPerl->directory_for_package('Template::EmbeddedPerl::Test::FF'),
    'templates',
    'ff.epl');

  open my $fh , '<', File::Spec->catfile(@path);

  ok my $generator1 = $yat->from_fh($fh);
  ok my $out = $generator1->render($f, $person);
  is $out, $generated, 'rendered template';
}


done_testing;

__DATA__
<% my ($f, $person) = @_ %>
<%= $f->form_for($person, sub($view, $fb, $person) { %>
  <div>
    <%= $fb->label('first_name') %>
    <%= $fb->input('first_name') %>
    <%= $fb->label('last_name') %>
    <%= $fb->input('last_name') %>
  </div>
<% }) %>