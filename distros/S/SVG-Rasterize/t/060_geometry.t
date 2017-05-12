#!perl -T
use strict;
use warnings;

use Test::More tests => 188;
use Test::Exception;

use SVG;
use SVG::Rasterize;
use SVG::Rasterize::State;

sub matrix {
    my $rasterize;
    my $state;
    my $svg;
    
    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 10, height => 10)->firstChild;
    $state     = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => [1, 0, 0, 1, 0, 0]);

    can_ok($state, 'transform');
    is_deeply([$state->transform(4, -5)], [4, -5], 'identity');

    $state->{matrix} = [1, 0, 0, 1, 3, -1];
    is_deeply([$state->transform(-2, 3)], [1, 2], 'translate');

    $state->{matrix} = [0, -1, 1, 0, 0, 0];
    is_deeply([$state->transform(4, -1)], [-1, -4], 'rotate');
}

sub process_transform_attribute {
    my $si   = qr/[\+\-]/;
    my $in   = qr/$si?\d+/;
    my $fr   = qr/$si?(?:\d*\.\d+|\d+\.)/;
    my $ex   = qr/[eE]$si?\d+/;
    my $fl   = qr/$fr$ex?|$in$ex/;
    my $nu   = qr/(?:$in|$fl)/;
    my $wsp  = qr/[\x{20}\x{9}\x{D}\x{A}]/;
    my $cwsp = qr/$wsp+\,?$wsp*|\,$wsp*/;
    my $ma   = qr/matrix$wsp*\($wsp*(?:$nu$cwsp){5}$nu$wsp*\)/;
    my $tr   = qr/translate$wsp*\($wsp*$nu(?:$cwsp$nu)?$wsp*\)/;
    my $sc   = qr/scale$wsp*\($wsp*$nu(?:$cwsp$nu)?$wsp*\)/;
    my $ro   = qr/rotate$wsp*\($wsp*$nu(?:(?:$cwsp$nu){2})?$wsp*\)/;
    my $sx   = qr/skewX$wsp*\($wsp*$nu$wsp*\)/;
    my $sy   = qr/skewY$wsp*\($wsp*$nu$wsp*\)/;
    my $tf   = qr/(?:$ma|$tr|$sc|$ro|$sx|$sy)/;
    my $tfm  = qr/$tf(?:$cwsp$tf)*/;
    my $tfs  = qr/($tf)(?:$cwsp($tfm))?/;
    my $tfl  = qr/^$wsp*($tfm)?$wsp*$/;
    my $tfn  = qr/matrix|translate|scale|rotate|skewX|skewY/;
    my $tfc  = qr/($tfn)$wsp*\($wsp*($nu(?:$cwsp$nu)*)$wsp*\)/;
    my $str;
    my @pieces;
    my $template;

    ok('0'        =~ /^$in$/, '0 integer');
    ok('+0'       =~ /^$in$/, '+0 integer');
    ok('-0'       =~ /^$in$/, '-0 integer');
    ok('5'        =~ /^$in$/, '5 integer');
    ok('-1234'    =~ /^$in$/, '-1234 integer');
    ok('001'      =~ /^$in$/, '001 integer');
    ok('-'        !~ /^$in$/, '- no integer');
    ok('30'       !~ /^$fr$/, '30 no fraction');
    ok('0.1'      =~ /^$fr$/, '0.1 fraction');
    ok('30.'      =~ /^$fr$/, '30. fraction');
    ok('-30.'     =~ /^$fr$/, '-30. fraction');
    ok('-.1'      =~ /^$fr$/, '-.1 fraction');
    ok('+.3'      =~ /^$fr$/, '+.3 fraction');
    ok('+00.3'    =~ /^$fr$/, '+00.3 fraction');
    ok('e+03'     =~ /^$ex$/, 'e+03 exponent');
    ok('E4'       =~ /^$ex$/, 'E4 exponent');
    ok('E.4'      !~ /^$ex$/, 'E.4 no exponent');
    ok('30.'      =~ /^$fl$/, '30. floating point');
    ok('-30.'     =~ /^$fl$/, '-30. floating point');
    ok('-.1'      =~ /^$fl$/, '-.1 floating point');
    ok('+.3'      =~ /^$fl$/, '+.3 floating point');
    ok('+00.3'    =~ /^$fl$/, '+00.3 floating point');
    ok('30.E-01'  =~ /^$fl$/, '30.E-01 floating point');
    ok('-30.E-01' =~ /^$fl$/, '-30.E-01 floating point');
    ok('-.1E-01'  =~ /^$fl$/, '-.1E-01 floating point');
    ok('+.3E-01'  =~ /^$fl$/, '+.3E-01 floating point');
    ok('+00.3E-01'=~ /^$fl$/, '+00.3E-01 floating point');
    ok('+00.3E-01'=~ /^$fl$/, '+00.3E-01 floating point');
    ok('123E5'    =~ /^$fl$/, '123E5 floating point');
    ok('123E5'    !~ /^$in$/, '123E5 no integer');
    ok('123E5'    =~ /^$nu$/, '123E5 number');
    ok('12345'    =~ /^$nu$/, '12345 number');
    ok('+.1E-7'   =~ /^$nu$/, '+.1E-7 number');
    ok(" \t\n\r"  =~ /^$wsp+$/, 'white space control');
    ok('matrix( 1, 2. 3, 4, 5, 6)' =~ $ma, 'matrix');
    ok('matrix(1, 2, 3, 4, 5)'     !~ $ma, 'matrix');
    ok('translate (1.4E08 2)'      =~ $tr, 'translate');
    ok('translate ( -3 )'          =~ $tr, 'translate');
    ok('translate( -3 )'           =~ $tr, 'translate');
    ok('translate ( , )'           !~ $tr, 'translate');
    ok('scale (1.4E08 2)'          =~ $sc, 'scale');
    ok('scale ( -3 )'              =~ $sc, 'scale');
    ok('scale ( , )'               !~ $sc, 'scale');
    ok('rotate ( -3 )'             =~ $ro, 'rotate');
    ok('rotate (1.4E08 2)'         !~ $ro, 'no rotate');
    ok('rotate ( -3,1 ,-3.14 )'    =~ $ro, 'rotate');
    ok('rotate(-3, 1, -3.14)'      =~ $tf, 'transform');
    ok('rotate(-3, 1, -3.14)'      =~ $tfs, 'transforms');
    is($1, 'rotate(-3, 1, -3.14)', 'captured rotation');
    ok('skewX(  +3e0 )'            =~ $sx, 'skewX');
    ok('skewX(-3, 1)'              !~ $sx, 'no skewX');
    ok('skewY  (-0 )'              =~ $sy, 'skewY');
    ok('skewY(1,)'                 !~ $sy, 'no skewY');

    $str    = 'rotate(1.1, 2, 3) translate(-1) scale(2)';
    ok($str =~ $tfm, 'multiple transforms');
    ok($str =~ $tfs, 'transforms');
    is($1, 'rotate(1.1, 2, 3)', 'captured rotation');
    is($2, 'translate(-1) scale(2)', 'captured rest');

    $str    = '  rotate(1.1, -2.3e9, 3),translate( -1) ,  scale(2 )   '.
	'matrix ( 1.2,-3 , 0.1e-7,1 , -00.33, .0 )';
    ok($str =~ $tfl, 'transform-list');
    $str    = $1;
    @pieces = ();
    while($str) {
	if($str =~ $tfs) {
	    push(@pieces, $1);
	    $str = $2;
	}
	else { last }
    }
    ok(!$str, 'all eaten up');
    is_deeply(\@pieces,
	      ['rotate(1.1, -2.3e9, 3)', 'translate( -1)',
	       'scale(2 )', 'matrix ( 1.2,-3 , 0.1e-7,1 , -00.33, .0 )'],
	      'list');
    
    $template =
	[['rotate',    ['1.1', '-2.3e9', '3']],
	 ['translate', ['-1']],
	 ['scale',     ['2']],
	 ['matrix',    ['1.2', '-3', '0.1e-7', '1', '-00.33', '.0']]];
    for(my $i=0;$i<@$template;$i++) {
	ok($pieces[$i] =~ $tfc, 'matches tfc');
	is_deeply([$1, [split(/$cwsp/, $2)]], $template->[$i],
		  "piece $i matches template");
    }
}

sub transform {
    my $rasterize;
    my $state;
    my $svg;
    my $node;

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 10, height => 10)->firstChild;
    $node   = $svg->group(transform => "translate(10, 10)");
    $state     = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => [1, 0, 0, 1, 0, 0]);
    $state     = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 parent          => $state,
	 node            => $node,
	 node_name       => $node->getNodeName,
	 cdata           => undef,
	 child_nodes     => undef,
	 node_attributes => {$node->getAttributes});
    is_deeply($state->matrix, [1, 0, 0, 1, 10, 10], 'translate matrix');

    $svg   = SVG->new(width => 10, height => 10)->firstChild;
    $node  = $svg->group(transform => "translate(10, 0) scale(3)");
    $state     = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => [1, 0, 0, 1, 0, 0]);
    $state     = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 parent          => $state,
	 node            => $node,
	 node_name       => $node->getNodeName,
	 cdata           => undef,
	 child_nodes     => undef,
	 node_attributes => {$node->getAttributes});
    is_deeply([$state->transform(-1, 0.5)], [7, 1.5], 'translate scale');

    # with units
    is_deeply([$state->transform('3in', '-144pt')], [820, -540],
	      'with in and pt');

    $svg    = SVG->new(width => 10, height => 10)->firstChild;
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => [1, 0, 0, 1, 0, 0]);
    $node  = $svg->group(transform => "translate(7, -1) scale(3)");
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 parent          => $state,
	 node            => $node,
	 node_name       => $node->getNodeName,
	 cdata           => undef,
	 child_nodes     => undef,
	 node_attributes => {$node->getAttributes});
    $node  = $node->group(transform => "translate(-4.2)");
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 parent          => $state,
	 node            => $node,
	 node_name       => $node->getNodeName,
	 cdata           => undef,
	 child_nodes     => undef,
	 node_attributes => {$node->getAttributes});
    is_deeply([$state->transform(4, 9)], [6.4, 26], 'double nested');
}

sub initial_viewport {
    my $rasterize;
    my $state;
    my $svg;
    my $node;
    my $attributes;

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new->firstChild;
    $state     = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 cdata           => undef,
	 child_nodes     => undef,
	 node_attributes => {$svg->getAttributes});

    $attributes = {width => 100, height => 50};
    $rasterize->_initial_viewport({$svg->getAttributes},
				  $attributes);
    is_deeply($attributes->{matrix}, [1, 0, 0, 1, 0, 0], 'matrix');

    $attributes = {width => '1in', height => '0.5in'};
    $rasterize->_initial_viewport({$svg->getAttributes},
				  $attributes);
    is_deeply($attributes->{matrix}, [1, 0, 0, 1, 0, 0], 'matrix');

    is($attributes->{width}, 90, 'width transformation');
    is($attributes->{height}, 45, 'height transformation');
    $attributes = {width => 10, height => 15};
    $rasterize->_initial_viewport({$svg->getAttributes},
				  $attributes);
    is_deeply($attributes->{matrix}, [1, 0, 0, 1, 0, 0], 'matrix');

    is($attributes->{width}, 10, 'width transformation');
    is($attributes->{height}, 15, 'height transformation');
    $attributes = {width => '1in', height => '0.5in'};
    $rasterize->_initial_viewport({$svg->getAttributes},
			       $attributes);
    is_deeply($attributes->{matrix}, [1, 0, 0, 1, 0, 0], 'matrix');

    is($attributes->{width}, 90, 'width transformation');
    is($attributes->{height}, 45, 'height transformation');

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 50)->firstChild;
    $state     = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 cdata           => undef,
	 child_nodes     => undef,
	 node_attributes => {$svg->getAttributes});
    is($state->node_attributes->{width}, 50, 'width attribute');
    $attributes = {width => 100, height => 50};
    $rasterize->_initial_viewport({$svg->getAttributes},
			       $attributes);
    is_deeply($attributes->{matrix}, [2, 0, 0, 1, 0, 0], 'matrix');

    $svg->attrib('height', 200);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 cdata           => undef,
	 child_nodes     => undef,
	 node_attributes => {$svg->getAttributes});
    $attributes = {width => 100, height => 50};
    $rasterize->_initial_viewport({$svg->getAttributes},
			       $attributes);
    is_deeply($attributes->{matrix}, [2, 0, 0, 0.25, 0, 0], 'matrix');

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new->firstChild;
    $svg->attrib('width', 100);
    $svg->attrib('height', 50);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 cdata           => undef,
	 child_nodes     => undef,
	 node_attributes => {$svg->getAttributes});
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    is_deeply($attributes->{matrix}, [1, 0, 0, 1, 0, 0], 
	      'matrix without viewBox');

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new->firstChild;
    $svg->attrib('width', 100);
    $svg->attrib('height', 50);
    $svg->attrib('viewBox', '50, 30, 200, 100');
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 cdata           => undef,
	 child_nodes     => undef,
	 node_attributes => {$svg->getAttributes});
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    is_deeply($attributes->{matrix}, [1, 0, 0, 1, 0, 0], 
	      'matrix with viewBox');
    is_deeply([$state->transform(50, 30)], [0, 0],
	      'transform with viewBox');
    is_deeply([$state->transform(50, 130)], [0, 50],
	      'transform with viewBox');
    is_deeply([$state->transform(250, 130)], [100, 50],
	      'transform with viewBox');
    is_deeply([$state->transform(250, 30)], [100, 0],
	      'transform with viewBox');

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new->firstChild;
    $svg->attrib('width', 100);
    $svg->attrib('height', 50);
    $svg->attrib('viewBox', '50, 30, 200, 100');
    $attributes = {width => 500, height => 200};
    $rasterize->_initial_viewport({$svg->getAttributes}, 
			       $attributes);
    is_deeply($attributes->{matrix}, [5, 0, 0, 4, 0, 0], 
	      'matrix with viewBox');
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => $attributes->{matrix});
    is_deeply([$state->transform(50, 30)], [0, 0],
	      'transform with viewBox');
    is_deeply([$state->transform(50, 130)], [0, 200],
	      'transform with viewBox');
    is_deeply([$state->transform(250, 130)], [500, 200],
	      'transform with viewBox');
    is_deeply([$state->transform(250, 30)], [500, 0],
	      'transform with viewBox');
}

sub preserve_aspect_ratio {
    my $rasterize;
    my $state;
    my $svg;
    my $node;
    my $attributes;

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new->firstChild;
    $svg->attrib(width => 800);
    $svg->attrib(height => 600);
    $svg->attrib(viewBox => '0, 0, 2000, 3000');
    $svg->attrib(preserveAspectRatio => 'none');
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => $attributes->{matrix});
    is_deeply([$state->transform(0, 0)], [0, 0],
	      'transform with pAR none');
    is_deeply([$state->transform(0, 3000)], [0, 600],
	      'transform with pAR none');
    is_deeply([$state->transform(2000, 3000)], [800, 600],
	      'transform with pAR none');
    is_deeply([$state->transform(2000, 0)], [800, 0],
	      'transform with pAR none');

    $svg->attrib(preserveAspectRatio => 'xMinYMin');
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => $attributes->{matrix});
    is_deeply([$state->transform(0, 0)], [0, 0],
	      'transform with pAR xMinYMin');
    is_deeply([$state->transform(0, 3000)], [0, 600],
	      'transform with pAR xMinYMin');
    is_deeply([$state->transform(2000, 3000)], [400, 600],
	      'transform with pAR xMinYMin');
    is_deeply([$state->transform(2000, 0)], [400, 0],
	      'transform with pAR xMinYMin');

    $svg->attrib(preserveAspectRatio => 'xMinYMin meet');
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => $attributes->{matrix});
    is_deeply([$state->transform(0, 0)], [0, 0],
	      'transform with pAR xMinYMin meet');
    is_deeply([$state->transform(0, 3000)], [0, 600],
	      'transform with pAR xMinYMin meet');
    is_deeply([$state->transform(2000, 3000)], [400, 600],
	      'transform with pAR xMinYMin meet');
    is_deeply([$state->transform(2000, 0)], [400, 0],
	      'transform with pAR xMinYMin meet');

    $svg->attrib(preserveAspectRatio => 'xMinYMin slice');
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => $attributes->{matrix});
    is_deeply([$state->transform(0, 0)], [0, 0],
	      'transform with pAR xMinYMin slice');
    is_deeply([$state->transform(0, 3000)], [0, 1200],
	      'transform with pAR xMinYMin slice');
    is_deeply([$state->transform(2000, 3000)], [800, 1200],
	      'transform with pAR xMinYMin slice');
    is_deeply([$state->transform(2000, 0)], [800, 0],
	      'transform with pAR xMinYMin slice');

    $svg->attrib(preserveAspectRatio => 'xMidYMin');
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => $attributes->{matrix});
    is_deeply([$state->transform(0, 0)], [200, 0],
	      'transform with pAR xMidYMin');
    is_deeply([$state->transform(0, 3000)], [200, 600],
	      'transform with pAR xMidYMin');
    is_deeply([$state->transform(2000, 3000)], [600, 600],
	      'transform with pAR xMidYMin');
    is_deeply([$state->transform(2000, 0)], [600, 0],
	      'transform with pAR xMidYMin');

    $svg->attrib(preserveAspectRatio => 'xMidYMin slice');
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => $attributes->{matrix});
    is_deeply([$state->transform(0, 0)], [0, 0],
	      'transform with pAR xMidYMin slice');
    is_deeply([$state->transform(0, 3000)], [0, 1200],
	      'transform with pAR xMidYMin slice');
    is_deeply([$state->transform(2000, 3000)], [800, 1200],
	      'transform with pAR xMidYMin slice');
    is_deeply([$state->transform(2000, 0)], [800, 0],
	      'transform with pAR xMidYMin slice');

    $svg->attrib(preserveAspectRatio => 'xMaxYMin');
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => $attributes->{matrix});
    is_deeply([$state->transform(0, 0)], [400, 0],
	      'transform with pAR xMaxYMin');
    is_deeply([$state->transform(0, 3000)], [400, 600],
	      'transform with pAR xMaxYMin');
    is_deeply([$state->transform(2000, 3000)], [800, 600],
	      'transform with pAR xMaxYMin');
    is_deeply([$state->transform(2000, 0)], [800, 0],
	      'transform with pAR xMaxYMin');

    $svg->attrib(preserveAspectRatio => 'xMaxYMin slice');
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => $attributes->{matrix});
    is_deeply([$state->transform(0, 0)], [0, 0],
	      'transform with pAR xMaxYMin slice');
    is_deeply([$state->transform(0, 3000)], [0, 1200],
	      'transform with pAR xMaxYMin slice');
    is_deeply([$state->transform(2000, 3000)], [800, 1200],
	      'transform with pAR xMaxYMin slice');
    is_deeply([$state->transform(2000, 0)], [800, 0],
	      'transform with pAR xMaxYMin slice');

    $svg->attrib(preserveAspectRatio => 'xMinYMid');
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => $attributes->{matrix});
    is_deeply([$state->transform(0, 0)], [0, 0],
	      'transform with pAR xMinYMid');
    is_deeply([$state->transform(0, 3000)], [0, 600],
	      'transform with pAR xMinYMid');
    is_deeply([$state->transform(2000, 3000)], [400, 600],
	      'transform with pAR xMinYMid');
    is_deeply([$state->transform(2000, 0)], [400, 0],
	      'transform with pAR xMinYMid');

    $svg->attrib(preserveAspectRatio => 'xMinYMid slice');
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => $attributes->{matrix});
    is_deeply([$state->transform(0, 0)], [0, -300],
	      'transform with pAR xMinYMid slice');
    is_deeply([$state->transform(0, 3000)], [0, 900],
	      'transform with pAR xMinYMid slice');
    is_deeply([$state->transform(2000, 3000)], [800, 900],
	      'transform with pAR xMinYMid slice');
    is_deeply([$state->transform(2000, 0)], [800, -300],
	      'transform with pAR xMinYMid slice');

    $svg->attrib(preserveAspectRatio => 'xMidYMid');
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => $attributes->{matrix});
    is_deeply([$state->transform(0, 0)], [200, 0],
	      'transform with pAR xMidYMid');
    is_deeply([$state->transform(0, 3000)], [200, 600],
	      'transform with pAR xMidYMid');
    is_deeply([$state->transform(2000, 3000)], [600, 600],
	      'transform with pAR xMidYMid');
    is_deeply([$state->transform(2000, 0)], [600, 0],
	      'transform with pAR xMidYMid');

    $svg->attrib(preserveAspectRatio => 'xMidYMid slice');
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => $attributes->{matrix});
    is_deeply([$state->transform(0, 0)], [0, -300],
	      'transform with pAR xMidYMid slice');
    is_deeply([$state->transform(0, 3000)], [0, 900],
	      'transform with pAR xMidYMid slice');
    is_deeply([$state->transform(2000, 3000)], [800, 900],
	      'transform with pAR xMidYMid slice');
    is_deeply([$state->transform(2000, 0)], [800, -300],
	      'transform with pAR xMidYMid slice');

    $svg->attrib(preserveAspectRatio => 'xMaxYMid');
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => $attributes->{matrix});
    is_deeply([$state->transform(0, 0)], [400, 0],
	      'transform with pAR xMaxYMid');
    is_deeply([$state->transform(0, 3000)], [400, 600],
	      'transform with pAR xMaxYMid');
    is_deeply([$state->transform(2000, 3000)], [800, 600],
	      'transform with pAR xMaxYMid');
    is_deeply([$state->transform(2000, 0)], [800, 0],
	      'transform with pAR xMaxYMid');

    $svg->attrib(preserveAspectRatio => 'xMaxYMid slice');
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => $attributes->{matrix});
    is_deeply([$state->transform(0, 0)], [0, -300],
	      'transform with pAR xMaxYMid slice');
    is_deeply([$state->transform(0, 3000)], [0, 900],
	      'transform with pAR xMaxYMid slice');
    is_deeply([$state->transform(2000, 3000)], [800, 900],
	      'transform with pAR xMaxYMid slice');
    is_deeply([$state->transform(2000, 0)], [800, -300],
	      'transform with pAR xMaxYMid slice');

    $svg->attrib(preserveAspectRatio => 'xMinYMax');
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => $attributes->{matrix});
    is_deeply([$state->transform(0, 0)], [0, 0],
	      'transform with pAR xMinYMax');
    is_deeply([$state->transform(0, 3000)], [0, 600],
	      'transform with pAR xMinYMax');
    is_deeply([$state->transform(2000, 3000)], [400, 600],
	      'transform with pAR xMinYMax');
    is_deeply([$state->transform(2000, 0)], [400, 0],
	      'transform with pAR xMinYMax');

    $svg->attrib(preserveAspectRatio => 'xMinYMax slice');
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => $attributes->{matrix});
    is_deeply([$state->transform(0, 0)], [0, -600],
	      'transform with pAR xMinYMax slice');
    is_deeply([$state->transform(0, 3000)], [0, 600],
	      'transform with pAR xMinYMax slice');
    is_deeply([$state->transform(2000, 3000)], [800, 600],
	      'transform with pAR xMinYMax slice');
    is_deeply([$state->transform(2000, 0)], [800, -600],
	      'transform with pAR xMinYMax slice');

    $svg->attrib(preserveAspectRatio => 'xMidYMax');
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => $attributes->{matrix});
    is_deeply([$state->transform(0, 0)], [200, 0],
	      'transform with pAR xMidYMax');
    is_deeply([$state->transform(0, 3000)], [200, 600],
	      'transform with pAR xMidYMax');
    is_deeply([$state->transform(2000, 3000)], [600, 600],
	      'transform with pAR xMidYMax');
    is_deeply([$state->transform(2000, 0)], [600, 0],
	      'transform with pAR xMidYMax');

    $svg->attrib(preserveAspectRatio => 'xMidYMax slice');
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => $attributes->{matrix});
    is_deeply([$state->transform(0, 0)], [0, -600],
	      'transform with pAR xMidYMax slice');
    is_deeply([$state->transform(0, 3000)], [0, 600],
	      'transform with pAR xMidYMax slice');
    is_deeply([$state->transform(2000, 3000)], [800, 600],
	      'transform with pAR xMidYMax slice');
    is_deeply([$state->transform(2000, 0)], [800, -600],
	      'transform with pAR xMidYMax slice');

    $svg->attrib(preserveAspectRatio => 'xMaxYMax');
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => $attributes->{matrix});
    is_deeply([$state->transform(0, 0)], [400, 0],
	      'transform with pAR xMaxYMax');
    is_deeply([$state->transform(0, 3000)], [400, 600],
	      'transform with pAR xMaxYMax');
    is_deeply([$state->transform(2000, 3000)], [800, 600],
	      'transform with pAR xMaxYMax');
    is_deeply([$state->transform(2000, 0)], [800, 0],
	      'transform with pAR xMaxYMax');

    $svg->attrib(preserveAspectRatio => 'xMaxYMax slice');
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => $attributes->{matrix});
    is_deeply([$state->transform(0, 0)], [0, -600],
	      'transform with pAR xMaxYMax slice');
    is_deeply([$state->transform(0, 3000)], [0, 600],
	      'transform with pAR xMaxYMax slice');
    is_deeply([$state->transform(2000, 3000)], [800, 600],
	      'transform with pAR xMaxYMax slice');
    is_deeply([$state->transform(2000, 0)], [800, -600],
	      'transform with pAR xMaxYMax slice');

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new->firstChild;
    $svg->attrib(width => 400);
    $svg->attrib(height => 300);
    $svg->attrib(viewBox => '200, -500, 8000, 3000');
    $svg->attrib(preserveAspectRatio => 'none');
    $svg->attrib(preserveAspectRatio => 'defer xMidYMax meet');
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => $attributes->{matrix});
    is_deeply([$state->transform(200, -500)], [0, 150],
	      'transform with pAR xMidYMax');
    is_deeply([$state->transform(200, 2500)], [0, 300],
	      'transform with pAR xMidYMax');
    is_deeply([$state->transform(8200, 2500)], [400, 300],
	      'transform with pAR xMidYMax');
    is_deeply([$state->transform(8200, -500)], [400, 150],
	      'transform with pAR xMidYMax');

    $svg->attrib(preserveAspectRatio => 'defer   xMidYMax  slice');
    $attributes = {};
    $rasterize->_initial_viewport({$svg->getAttributes}, $attributes);
    $state  = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef,
	 matrix          => $attributes->{matrix});
    is_deeply([$state->transform(200, -500)], [-200, 0],
	      'transform with pAR xMidYMax');
    is_deeply([$state->transform(200, 2500)], [-200, 300],
	      'transform with pAR xMidYMax');
    is_deeply([$state->transform(8200, 2500)], [600, 300],
	      'transform with pAR xMidYMax');
    is_deeply([$state->transform(8200, -500)], [600, 0],
	      'transform with pAR xMidYMax');
}

matrix;
process_transform_attribute;
transform;
initial_viewport;
preserve_aspect_ratio;
