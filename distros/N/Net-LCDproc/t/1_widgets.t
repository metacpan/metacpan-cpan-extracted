use Test::More;

if (!defined $ENV{LCDPROC_TESTS}) {
    plan skip_all =>
      "Set LCDPROC_TESTS for full tests\nYou can also override defaults with LCDPROC_SERVER and LCDPROC_PORT\nSee docs for full details";
} else {
    plan tests => 10;
}

use Net::LCDproc;

my %lcdproc_opts;
$lcdproc_opts{server} = $ENV{LCDPROC_SERVER} if $ENV{LCDPROC_SERVER};
$lcdproc_opts{port}   = $ENV{LCDPROC_PORT}   if $ENV{LCDPROC_PORT};

ok $lcdproc = Net::LCDproc->new(%lcdproc_opts), 'Construct an Net::LCDproc';
isa_ok $lcdproc, 'Net::LCDproc', '...gives the correct class';

# screen
ok $screen = Net::LCDproc::Screen->new(id => "main");
ok $screen->set('name',      'Test Screen');
ok $screen->set('heartbeat', 'off');
ok $lcdproc->add_screen($screen);

# title
ok my $title = Net::LCDproc::Widget::Title->new(
    id   => 'title',
    text => 'Net::LCDproc Widget Tests'
);
ok $screen->add_widget($title);

# string
ok my $string = Net::LCDproc::Widget::String->new(
    id   => "string",
    x    => 1,
    y    => 2,
    text => $0
);
ok $screen->add_widget($string);

