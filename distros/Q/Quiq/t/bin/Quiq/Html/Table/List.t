#!/usr/bin/env perl

package Quiq::Html::Table::List::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Quiq::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Table::List');
}

# -----------------------------------------------------------------------------

our $Table = <<'__HTML__';
<table border="1" cellspacing="0">
<thead>
  <tr>
    <th>A</th>
    <th>B</th>
    <th>C</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td align="center" colspan="3">&nbsp;</td>
  </tr>
</tbody>
</table>
__HTML__

sub test_html : Test(2) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    my $html = Quiq::Html::Table::List->html($h);
    $self->is($html,'');

    $html = Quiq::Html::Table::List->html($h,
        titles=>[qw/A B C/],
    );
    $self->is($html,$Table);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Table::List::Test->runTests;

# eof
