#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 4;

use Template::Flute;
use Template::Flute::Iterator;
use Template::Flute::Utils;
use Template::Flute::I18N;


my $template = <<'HTML';
<form class="edit" action="/" method="POST">
  <select name="role" id="role">
    <option value="">Please select role</option>
  </select>
</form>
HTML

my $spec = <<'XML';
<specification>
  <form name="edit">
    <field name="role" id="role" iterator="roles" keep="empty_value"/>
  </form>
</specification>
XML

my $expected = <<'FORM';
<select id="role" name="role">
<option value="">Please select role</option>
<option selected="selected">1</option>
<option>2</option>
<option>3</option>
<option>4</option>
</select>
FORM

$expected =~ s/\n//g;
my $empty_value = q{<option value="">Please select role</option>};
my $selected = q{<option selected="selected">1</option>};


my $roles = [
             { value => '1' },
             { value => '2' },
             { value => '3' },
             { value => '4' },
            ];


my $flute = Template::Flute->new(specification => $spec,
                                 template => $template,
                                 iterators => { roles => $roles });

$flute->process_template;

my @forms = $flute->template->forms;

ok scalar(@forms), "Found forms";

foreach my $f ($flute->template->forms) {
    # this is what basically the TemplateFlute does.
    $f->fill({role => 1});
    foreach my $elt (@{$f->{sob}->{elts}})  {
        like $elt->sprint, qr{\Q$expected\E}, "form before processing looks good";
    }
}

like $flute->process, qr{\Q$expected\E}, "form in the output looks good";



foreach my $f ($flute->template->forms) {
    foreach my $elt (@{$f->{sob}->{elts}})  {
        like $elt->sprint, qr{\Q$expected\E}, "form after processing looks good";
    }
}

