use warnings;
use strict;


package TestApp::UI;
use base qw/Template::Declare/;
use Template::Declare::Tags;
use Test::More tests => 16;


template simple => sub {

html { 
    head { }
        body {
            show 'content'
        }
}

};

template content => sub {
        div { attr { id => 'body' }
            outs('This is my content')
        }

};


template closure_1 => sub {
    my $item = b { 'Bolded'};
    i { $item->() };
};

template closure_2 => sub {
    my $item = b { 'Bolded'};
    i { $item };
};

template closure_3 => sub {
    my $item = b { 'Bolded'};
    i { outs_raw($item)};
};

template closure_4 => sub {
    my $item = b { 'Bolded'};
    i { "My ". $item};
};

template closure_5 => sub {
    my $item = b { 'Bolded'};
    i { "My " , $item};
};

template closure_6 => sub {
                        outs('I decided to do '), i{'Something else'}, outs(' rather than ')

};

package Template::Declare::Tags;
require "t/utils.pl";
use Test::More;

our $self;
local $self = {};
bless $self, 'TestApp::UI';

Template::Declare->init( dispatch_to => ['TestApp::UI']);

{
Template::Declare->buffer->clear;
my $simple =(show('simple'));
ok($simple =~ 'This is my content');
#diag ($simple);
ok_lint($simple);
}
{
Template::Declare->buffer->clear;
my $simple =Template::Declare->show('simple');
ok($simple =~ 'This is my content');
#diag ($simple);
ok_lint($simple);
}
{
Template::Declare->buffer->clear;
Template::Declare->show('simple');
ok(Template::Declare->buffer->data() =~ 'This is my content');
ok_lint(Template::Declare->buffer->data());
}


for (qw(closure_1 closure_2 )) {
Template::Declare->buffer->clear;
my $simple = Template::Declare->show($_);
#diag ($simple);
like($simple, qr/<i>\s*<b>\s*Bolded\s*<\/b>\s*<\/i>/ms, "$_ matched");
ok_lint($simple);
}

for (qw(closure_3)) {
Template::Declare->buffer->clear;
my $simple = Template::Declare->show($_);
#diag ($simple);
like($simple, qr/<i>\s*<b>\s*Bolded\s*<\/b>\s*<\/i>/ms, "$_ matched");
ok_lint($simple);



for (qw(closure_5)) {
Template::Declare->buffer->clear;
my $simple = Template::Declare->show($_);
ok($simple =~ /<i>My\s*<b>Bolded\s*<\/b>\s*<\/i>/ms, "Showed $_");
#diag ($simple);
ok_lint(Template::Declare->buffer->data());

}

{
Template::Declare->buffer->clear;
my $simple = Template::Declare->show('closure_6');
ok($simple =~ /I decided to do\s*<i>\s*Something else\s*<\/i>/);
#diag ($simple);
ok_lint(Template::Declare->buffer->data());
}

};

1;
