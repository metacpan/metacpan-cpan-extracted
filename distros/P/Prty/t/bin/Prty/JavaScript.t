#!/usr/bin/env perl

package Prty::JavaScript::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

use Prty::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::JavaScript');
}

# -----------------------------------------------------------------------------

my $scriptTag1 = <<'__CODE__';
<script type="text/javascript" src="https://host.domain/script.js"></script>
__CODE__

my $scriptTag2 = <<'__CODE__';
<script type="text/javascript">
  $(document).ready(function() {
    $('#mandantenTable').DataTable({
      'paging': false,
      'info': false,
      'order': [[1,'asc']],
    });
  });
</script>
__CODE__

sub test_script : Test(4) {
    my $self = shift;

    my $h = Prty::Html::Tag->new;

    my $val = Prty::JavaScript->script($h);
    $self->is($val,'');

    $val = Prty::JavaScript->script($h,'https://host.domain/script.js');
    $self->is($val,$scriptTag1);

    $val = Prty::JavaScript->script($h,q|
        $(document).ready(function() {
            $('#mandantenTable').DataTable({
                'paging': false,
                'info': false,
                'order': [[1,'asc']],
            });
        });
    |);
    $self->is($val,$scriptTag2);

    $val = Prty::JavaScript->script($h,[
        'https://host.domain/script.js',q|
            $(document).ready(function() {
                $('#mandantenTable').DataTable({
                    'paging': false,
                    'info': false,
                    'order': [[1,'asc']],
                });
            });
        |,
    ]);
    $self->is($val,$scriptTag1.$scriptTag2);    
}

# -----------------------------------------------------------------------------

package main;
Prty::JavaScript::Test->runTests;

# eof
