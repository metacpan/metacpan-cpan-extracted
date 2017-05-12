# $Id: /mirror/coderepos/lang/perl/MooseX-DOM/trunk/t/lib/Test/MxD/Simple.pm 68283 2008-08-12T02:34:53.003080Z daisuke  $

package Test::MxD::Simple;
use MooseX::DOM;

has_dom_root 'feed';
has_dom_attr 'attribute';
has_dom_child 'title';
has_dom_children 'multi';

no MooseX::DOM;

1;