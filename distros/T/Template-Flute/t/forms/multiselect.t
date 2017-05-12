#!perl

use utf8;
use strict;
use warnings;
use Template::Flute;
use Test::More;
use Hash::MultiValue;

my $html = <<EOF;
<form name="calendar-configure">
<select multiple class="form-control" name="status"></select>
<select multiple class="form-control" name="institute"></select>
</form>
EOF

my $spec = <<EOF;
<specification>
  <form name="calendar-configure" link="name">
  <field name="status" iterator="status_iterator" />
  <field name="institute" iterator="institute_iterator" />
  </form>
</specification>
EOF

my %fillwith = (status => 'SSECOND',
                institute => [qw/ISIXTH ISEVENTH/]);

foreach my $values ({ %fillwith }, Hash::MultiValue->from_mixed(%fillwith)) {
    my $flute = Template::Flute->new(specification => $spec,
                                     template => $html,
                                     iterators => {
                                                   status_iterator => [ map { +{ value => $_, label => $_ } }
                                                                        qw/SFIRST SSECOND STHIRD/],
                                                   institute_iterator => [ map { +{ value => $_, label => $_ } }
                                                                           qw/IFIFTH ISIXTH ISEVENTH IEIGTH/],
                                                  },
                                    );
    $flute->process_template;
    my $form = $flute->template->form('calendar-configure');
    $form->fill($values);
    my $out = $flute->process;
    diag $out;
    foreach my $selected (qw/SSECOND ISIXTH ISEVENTH/) {
        like $out, qr{<option[^>]*selected[^>]*>$selected</option>};
    }
    foreach my $notselected (qw/SFIRST STHIRD IFIFTH IEIGTH/) {
        unlike $out, qr{<option[^>]*selected[^>]*>$notselected</option>};
        like $out, qr{<option value="$notselected">$notselected</option>};
    }
}


done_testing;
