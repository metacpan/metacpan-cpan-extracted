use warnings;
use strict;

package Wifty::UI;
use base qw/Template::Declare/;
use Template::Declare::Tags;

sub test_smart_tag (&) {
    my $code = shift;

    smart_tag_wrapper {
        my %args = @_;
        outs(   "START "
              . join( ', ', map { "$_: $args{$_}" } sort keys %args )
              . "\n" );
        $code->();
        outs("END\n");
    };
}

template simple => sub {
    with( foo => 'bar' ),    #
      test_smart_tag { outs("simple\n"); };
};

template leak_check => sub {
    with( foo => 'bar' ),    #
      test_smart_tag { outs("first\n"); };
    test_smart_tag   { outs("second\n"); };
};

package main;
use Template::Declare::Tags;
Template::Declare->init( dispatch_to => ['Wifty::UI'] );

use Test::More tests => 4;
require "t/utils.pl";

my $simple = show('simple');
is(
    $simple,
    "\nSTART foo: bar\nsimple\nEND\n",
    "got correct output for simple"
);

my $leak_check = show('leak_check');
is(
    $leak_check,                        #
    "\nSTART foo: bar\nfirst\nEND\n"    #
      . "\nSTART \nsecond\nEND\n",      #
    "got correct output for simple"
);

##############################################################################
# Documentation example.
    package My::Template;
    use Template::Declare::Tags;
    use base 'Template::Declare';

    sub myform (&) {
        my $code = shift;

        smart_tag_wrapper {
            my %params = @_; # set using 'with'
            form {
                attr { map {$_ => $params{attr}{$_} } sort keys %{ $params{attr} } };
                $code->();
                input { attr { type => 'submit', value => $params{value} } };
            };
        };
    }

    template edit_prefs => sub {
        with(
            attr  => { id => 'edit_prefs', action => 'edit.html' },
            value => 'Save'
        ), myform {
            label { 'Time Zone' };
            input { type is 'text'; name is 'tz' };
        };
    };

    package main;
    Template::Declare->init( dispatch_to => ['My::Template'] );

ok my $output = Template::Declare->show('edit_prefs'), 'Get edit_prefs output';
is(
    $output,
    qq{

<form action="edit.html" id="edit_prefs">
 <label>Time Zone</label>
 <input type="text" name="tz" />
 <input type="submit" value="Save" />
</form>}, "got correct output for simple"
);
