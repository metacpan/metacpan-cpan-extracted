#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;

# {{{ Initialization
BEGIN {
  sub POE::Kernel::ASSERT_DEFAULT () { 1 }
  sub POE::Kernel::TRACE_DEFAULT  () { 1 }
  sub POE::Kernel::TRACE_FILENAME () { "./test-output.err" }

  use_ok('POE');
  use_ok('POE::Filter::RecDescent');
}
# }}}

{ my $f = POE::Filter::RecDescent->new(<<'_EOF_');
  startrule : "1"
            { [ 'StartRule' => [ $item[1] ] ] }
_EOF_
  my $rec = $f->get( [ q(1) ] );
  is_deeply($rec, [ [ 'StartRule', [qw( 1 )] ] ], "Grammar" );
}
