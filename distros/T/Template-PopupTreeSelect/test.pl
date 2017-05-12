use Test::More qw(no_plan);
use_ok('Template::PopupTreeSelect');

my $data = { label    => "Root",
             value    => 'val0',
             children => [
                          { label    => "Top Category 1",
                            value       => 'val1',
                            children => [
                                         { label => "Sub Category 1",
                                           value    => 'val2'
                                         },
                                         { label => "Sub Category 2",
                                           value    => 'val3'
                                         },
                                        ],
                          },
                          { label  => "Top Category 2",
                              value     => 'val4',
                          },
                         ],
           };

my $select = Template::PopupTreeSelect->new(name => 'category',
                                        data => $data,
                                        title => 'Select a Category',
                                        button_label => 'Choose');
isa_ok($select, 'Template::PopupTreeSelect');

my $output = $select->output();
ok($output);

# see if all the labels made it
for ("Root","Top Category 1", "Sub Category 1",
     "Sub Category 2", "Top Category 2") {
    like($output, qr/$_/);
}

# see if all the values made it
for (0 .. 4) {
    like($output, qr/val$_/);
}

# this one should have CSS
like($output, qr/text\/css/);

# make one without CSS
my $nocss = Template::PopupTreeSelect->new(name => 'category',
                                       data => $data,
                                       title => 'Select a Category',
                                       button_label => 'Choose',
                                       include_css => 0);
isa_ok($nocss, 'Template::PopupTreeSelect');
my $nocss_output = $nocss->output;
ok($nocss_output);
ok($nocss_output !~ qr/text\/css/);
