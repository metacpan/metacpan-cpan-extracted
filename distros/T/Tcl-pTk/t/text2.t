# -*- perl -*-

# Based on text2.t from Perl/Tk 804.030_500
#
# TODO: there are more tests in Perl/Tk text2.t
# but they require adding support to Tcl::pTk
# for tying filehandle to Text widget

#
# Author: Slaven Rezic
#

# Here goes tests for non-core Tk methods

use warnings;
use strict;
use Tcl::pTk;

use Test::More tests => 9;

my $mw = MainWindow->new;
$mw->geometry("+10+10");

{
    my $t = $mw->Text(qw(-width 20 -height 10))->pack;
    $t->insert("end", "hello\nworld\nfoo\nbar\nworld\n");

    ok(!$t->FindNext('-f', '-e', '-c', 'doesnotexist'), 'Pattern does not exist');

    ok($t->FindNext('-f', '-e', '-c', 'world'), 'First search');
    my @first_index = split /\./, $t->index('insert');

    ok($t->FindNext('-forwards', '-e', '-c', 'world'), 'Second search');
    my @second_index = split /\./, $t->index('insert');
    cmp_ok($second_index[0], ">", $first_index[0], 'Really a forwards search');

    ok($t->FindNext('-b', '-e', '-c', 'world'), 'Backwards search');
    my @third_index = split /\./, $t->index('insert');
    cmp_ok($third_index[0], "<", $second_index[0], 'Really a backwards search');

    $t->destroy;
}


{
    my $t = $mw->Scrolled(qw(Text -width 20 -height 10))->pack;
    is $t->Contents, '', 'fresh Tcl::pTk::Text is empty';
    $t->Contents('newline-less');
    is $t->Contents, 'newline-less', 'content without newline';
    $t->Contents('');
    is $t->Contents, '', 'after emptying Tcl::pTk::Text';
    $t->destroy;
}

__END__
