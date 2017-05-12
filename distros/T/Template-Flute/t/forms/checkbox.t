#! perl

use strict;
use warnings;
use Test::More tests => 2;
use Template::Flute;

my $spec = <<EOF;
<specification name="checkbox">
<form name="colors" link="name">
<field name="color"/>
</form>
</specification>
EOF

my $html = <<EOF;
	<form name="colors">
		<input type="checkbox" name="color" value="red" />
		<input type="checkbox" name="color" value="blue" />
		<input type="checkbox" name="color" value="green" />
		<input type="submit" value="OK" />
	</form>
EOF

process_form({red => 0, blue => 1, green => 0});
process_form({red => 1, blue => 1, green => 0});

sub process_form {
    my ($color_map) = @_;
    my ($flute, $form, $out, $match, %colors_found, %colors_expected, @colors);

    while (my ($color, $checked) = each %$color_map) {
        if ($checked) {
            $colors_expected{$color} = 1;
            push @colors, $color;
        }
        else {
            $colors_expected{$color} = 0;
        }
    }

    $flute = Template::Flute->new(specification => $spec,
                                  template => $html,
                                  );

    $flute->process_template;

    $form = $flute->template->form('colors');

    $form->fill({color => \@colors});

    $out = $flute->process;
    $match = $out;

    # match input HTML tags
    while ($match =~ s%<input( checked="checked")? name="color" type="checkbox" value="(.*?)" />%%) {
        if ($1) {
            $colors_found{$2} = 1;
        }
        else {
            $colors_found{$2} = 0;
        }
    }

    is_deeply(\%colors_found, \%colors_expected,
              "Checkbox test for colors: " . join(', ', @colors))
        || diag "$out";
}
