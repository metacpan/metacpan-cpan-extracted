use Test::More tests => 12;

package Item;

sub new  { bless {}, __PACKAGE__ };
sub zero { () }
sub one  { (1) }
sub two  { (1, 2) }

package main;

use strict;
use warnings;
use vars '$VAR1';
use Template;

sub _is_deeply {
    my ($str, @args) = @_;

    my $template = <<"";
[% FILTER collapse %]
[% USE arrayref = ArrayRef %]
[% USE Dumper %]
[% SET item = $str %]
[% Dumper.dump(item) %]
[% END %]

    my $vars = { item => Item->new, zero => \&Item::zero, one => \&Item::one, two => \&Item::two };
    my $tt = Template->new({ EVAL_PERL => 1 });
    my $output = '';
    $tt->process(\$template, $vars, \$output) || die $tt->error(), "\n";

    undef $VAR1;
    eval $output;

    if ($@) {
        fail($@);
    }
    else {
        is_deeply($VAR1, @args);
    }
}

_is_deeply('zero' , '');
_is_deeply('one'  , 1);
_is_deeply('two'  , [1, 2]);

_is_deeply('item.zero' , '');
_is_deeply('item.one'  , 1);
_is_deeply('item.two'  , [1, 2]);

_is_deeply('arrayref.zero' , []);
_is_deeply('arrayref.one'  , [1]);
_is_deeply('arrayref.two'  , [1, 2]);

_is_deeply('item.arrayref.zero' , []);
_is_deeply('item.arrayref.one'  , [1]);
_is_deeply('item.arrayref.two'  , [1, 2]);
