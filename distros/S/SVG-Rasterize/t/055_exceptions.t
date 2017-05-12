#!perl -T
use strict;
use warnings;

use Test::More tests => 322;
use Test::Warn;

use SVG;
use Test::Exception;
use SVG::Rasterize;

sub test_caller {
    my $rasterize;
    my $state;

    is(scalar(@SVG::Rasterize::Exception::EXPORT)
       + scalar(@SVG::Rasterize::Exception::EXPORT_OK),
       30, 'number of exceptions');
    foreach(@SVG::Rasterize::Exception::EXPORT,
	    @SVG::Rasterize::Exception::EXPORT_OK)
    {
	$rasterize = SVG::Rasterize->new;
	warning_is { eval { $rasterize->$_ } } undef,
	    "no warning in rasterize->$_ without arguments";
	ok(defined($@), 'exception has been thrown');
	isa_ok($@, 'SVG::Rasterize::Exception::Base');

	$state = SVG::Rasterize::State->new
	    (rasterize       => $rasterize,
	     node_name       => 'svg',
	     node_attributes => {},
	     cdata           => undef,
	     child_nodes     => undef);
	warning_is { eval { $state->$_ } } undef,
	    "no warning in state->$_ without arguments";
	ok(defined($@), 'exception has been thrown');
	isa_ok($@, 'SVG::Rasterize::Exception::Base');
    }

    warning_is { eval { SVG::Rasterize::Exception::ex_se_lo
                           (bless({}, 'UNIVERSAL')) } }
        undef,
        "no warning in dummy call on UNIVERSAL";
    ok(defined($@), 'exception has been thrown');
    isa_ok($@, 'SVG::Rasterize::Exception::Base');
    ok($@->message =~
       qr/^Unexpected caller 'UNIVERSAL=HASH.*' in exception handling/,
       'message');
}

sub in_error {
    my $rasterize;

    foreach(@SVG::Rasterize::Exception::EXPORT,
	    @SVG::Rasterize::Exception::EXPORT_OK)
    {
	if($_ =~ /^ie/) {
	    $rasterize = SVG::Rasterize->new;
	    warning_is { eval { $rasterize->$_ } } undef,
	        "no warning in rasterize->$_ without arguments";
	    ok(defined($@), 'exception has been thrown');
	    isa_ok($@, 'SVG::Rasterize::Exception::InError');
	    warning_is { eval { SVG::Rasterize->$_ } } undef,
	        "no warning in SVG::Rasterize->$_ without arguments";
	    ok(defined($@), 'exception has been thrown');
	    isa_ok($@, 'SVG::Rasterize::Exception::InError');
	}
    }
}

sub test_ex_co_pt {
    my $rasterize;
    my $state;

    $rasterize = SVG::Rasterize->new;
    $state = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node_name       => 'svg',
	 node_attributes => {},
	 cdata           => undef,
	 child_nodes     => undef);
    warning_is { eval { $state->ex_co_pt } } undef,
        "no warning in state->ex_co_pt without arguments";
    ok(defined($@), 'exception has been thrown');
    isa_ok($@, 'SVG::Rasterize::Exception::Param');

    $state = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node_name       => 'svg',
	 node_attributes => {id => 'foo'},
	 cdata           => undef,
	 child_nodes     => undef);
    warning_is { eval { $state->ex_co_pt } } undef,
        "no warning in state->ex_co_pt without arguments";
    ok(defined($@), 'exception has been thrown');
    isa_ok($@, 'SVG::Rasterize::Exception::Param');
    ok($@->message =~ /ancestor for svg element with id foo/,
       'message contains id');
}

sub test_ex_pa {
    my $ex;
    my $rasterize;

    $rasterize = SVG::Rasterize->new;
    $rasterize->{state} = 'foo';
    throws_ok(sub { $rasterize->ex_pa('path data', 'bar') },
	      qr/Failed to process the path data string \'bar\' /,
	      'ex_pa message');
    $ex = $@;
    isa_ok($ex, 'SVG::Rasterize::Exception::Parse');
    isa_ok($ex, 'SVG::Rasterize::Exception::Base');
    isa_ok($ex, 'Exception::Class::Base');
    can_ok($ex, 'state');
    is($ex->state, 'foo', 'state is foo');

    $rasterize->{state} = 'qux';
    is_deeply([$rasterize->_split_path_data('M')], [1], 'in_error is 1');
}

sub test_ie {
    my $rasterize;
    my $svg;
    my $ex;

    $rasterize = SVG::Rasterize->new;

    $svg = SVG->new(width => 100, height => 100);
    $svg->rect(width => 10, height => -10);
    throws_ok(sub { $rasterize->rasterize(svg => $svg) },
	      qr/Negative rectangle height \-10\./,
	      'negative rectangle height');
    $ex = $@;
    isa_ok($ex, 'SVG::Rasterize::Exception::InError');
    isa_ok($ex, 'SVG::Rasterize::Exception::Base');
    isa_ok($ex, 'Exception::Class::Base');
    can_ok($ex, 'state');
    isa_ok($ex->state, 'SVG::Rasterize::State', 'state isa State');
    is($ex->state->node_name, 'rect', 'node name is rect');

    $svg = SVG->new(width => 100, height => 100);
    $svg->rect(width => -10, height => 1);
    throws_ok(sub { $rasterize->rasterize(svg => $svg) },
	      qr/Negative rectangle width \-10\./,
	      'undefined rectangle width');

    $svg = SVG->new(width => 100, height => 100);
    $svg->rect(width => 1, height => 1, rx => -1);
    throws_ok(sub { $rasterize->rasterize(svg => $svg) },
	      qr/Negative rectangle corner radius \-1\./,
	      'undefined rectangle rx');

    $svg = SVG->new(width => 100, height => 100);
    $svg->rect(width => 1, height => 1, ry => -1);
    throws_ok(sub { $rasterize->rasterize(svg => $svg) },
	      qr/Negative rectangle corner radius \-1\./,
	      'undefined rectangle ry');
}

sub test_pv {
    my $ex;
    my $rasterize;

    $rasterize = SVG::Rasterize->new;
    throws_ok(sub { $rasterize->px_per_in('foo') },
	      qr/foo/,
	      'ex_pv message');
    $ex = $@;
    isa_ok($ex, 'SVG::Rasterize::Exception::ParamsValidate');
    isa_ok($ex, 'SVG::Rasterize::Exception::Base');
    isa_ok($ex, 'Exception::Class::Base');
    can_ok($ex, 'state');
    ok(!defined($ex->state), 'state is undefined');

    $rasterize = SVG::Rasterize->new;
    $rasterize->{state} = 'bar';
    throws_ok(sub { $rasterize->px_per_in('foo') },
	      qr/foo/,
	      'ex_pv message');
    $ex = $@;
    is($ex->state, 'bar', 'state is bar');
}

sub test_ie_pv {
    my $rasterize;
    my $svg;
    my $ex;

    $rasterize = SVG::Rasterize->new;

    $svg = SVG->new(width => 100, height => 100);
    $svg->rect(width => 10, height => 10, style => 'stroke-width:foo');
    throws_ok(sub { $rasterize->rasterize(svg => $svg) },
	      qr/Property stroke-width failed validation:/,
	      'stroke-width foo');
    $ex = $@;
    isa_ok($ex, 'SVG::Rasterize::Exception::InError');
    isa_ok($ex, 'SVG::Rasterize::Exception::Base');
    isa_ok($ex, 'Exception::Class::Base');
    can_ok($ex, 'state');
    isa_ok($ex->state, 'SVG::Rasterize::State', 'state isa State');
    is($ex->state->node_name, 'rect', 'node name is rect');
}

sub readonly {
    my $rasterize;
    my $svg;
    my $state;

    $rasterize = SVG::Rasterize->new;
    throws_ok(sub { $rasterize->engine('foo') },
	      qr/Attribute SVG::Rasterize->engine is readonly/,
	      'readonly attribute');

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 10, height => 10)->firstChild;
    $state     = SVG::Rasterize::State->new
	(rasterize       => $rasterize,
	 node            => $svg,
	 node_name       => $svg->getNodeName,
	 node_attributes => {$svg->getAttributes},
	 cdata           => undef,
	 child_nodes     => undef);
    throws_ok(sub { $state->parent('foo') },
	      qr/Attribute SVG::Rasterize::State->parent is readonly/,
	      'readonly attribute');
}

test_caller;
in_error;
test_ex_co_pt;
test_ex_pa;
test_ie;
test_pv;
test_ie_pv;
readonly;
