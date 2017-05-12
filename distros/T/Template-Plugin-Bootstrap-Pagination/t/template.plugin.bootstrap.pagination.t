use strict;
use warnings;

use Test::More 0.94 tests => 10;
use Test::Exception;
use Template;
use Template::Plugin::Bootstrap::Pagination;
use Data::Page;

my $pagination_template_string = <<"EOTEMPLATE";
[%- USE Bootstrap.Pagination -%]
[%- Bootstrap.Pagination.pagination(pager = pager, uri = uri) -%]
EOTEMPLATE

my $pager_template_string = <<"EOTEMPLATE";
[%- USE Bootstrap.Pagination -%]
[%- Bootstrap.Pagination.pager(pager = pager, uri = uri) -%]
EOTEMPLATE

subtest 'pagination in template' => sub {
	plan tests => 1;

	my $template = Template->new(STRICT => 1);
	my $output;
	my $result = $template->process(\$pagination_template_string, {
		pager => Data::Page->new(42, 10, 2),
		uri   => 'http://www.example.com/blog/__PAGE__.html'
	}, \$output) or die $template->error();

	my $expected = compress_expected(<<EOEXPECTED
<div class="pagination">
	<ul>
		<li><a href="http://www.example.com/blog/1.html">&laquo;</a></li>
		<li><a href="http://www.example.com/blog/1.html">1</a></li>
		<li class="active"><span>2</span></li>
		<li><a href="http://www.example.com/blog/3.html">3</a></li>
		<li><a href="http://www.example.com/blog/4.html">4</a></li>
		<li><a href="http://www.example.com/blog/5.html">5</a></li>
		<li><a href="http://www.example.com/blog/3.html">&raquo;</a></li>
	</ul>
</div>
EOEXPECTED
	);
	is($output, $expected, 'output ok');
};


subtest 'pagination() for Bootstrap 2 test' => sub {
	plan tests => 4;

	my $plugin = Template::Plugin::Bootstrap::Pagination->new(undef, {
		pager => Data::Page->new(12, 10, 2),
		uri   => 'http://www.example.com/blog/__PAGE__.html',
		prev_text => 'Previous',
		next_text => 'Next',
	});

	# Basic case
	my $expected = compress_expected(<<EOEXPECTED
<div class="pagination">
	<ul>
		<li><a href="http://www.example.com/blog/1.html">Previous</a></li>
		<li><a href="http://www.example.com/blog/1.html">1</a></li>
		<li class="active"><span>2</span></li>
		<li class="disabled"><span>Next</span></li>
	</ul>
</div>
EOEXPECTED
	);
	is($plugin->pagination(), $expected, 'output ok');

	# Center pagination
	$expected = compress_expected(<<EOEXPECTED
<div class="pagination pagination-centered">
	<ul>
		<li class="disabled"><span>Previous</span></li>
		<li class="disabled"><span>Next</span></li>
	</ul>
</div>
EOEXPECTED
	);
	is($plugin->pagination({
		pager    => Data::Page->new(2, 10, 2),
		centered => 1,
	}), $expected, 'output ok');

	# Right align pagination
	$expected = compress_expected(<<EOEXPECTED
<div class="pagination pagination-right">
	<ul>
		<li class="disabled"><span>Previous</span></li>
		<li class="disabled"><span>Next</span></li>
	</ul>
</div>
EOEXPECTED
	);
	is($plugin->pagination({
		pager => Data::Page->new(2, 10, 2),
		right => 1,
	}), $expected, 'output ok');

	# Size
	$expected = compress_expected(<<EOEXPECTED
<div class="pagination pagination-small">
	<ul>
		<li class="disabled"><span>Previous</span></li>
		<li class="disabled"><span>Next</span></li>
	</ul>
</div>
EOEXPECTED
	);
	is($plugin->pagination({
		pager => Data::Page->new(2, 10, 2),
		size  => 'small',
	}), $expected, 'output ok');
};


subtest 'pagination() for Bootstrap 3 test' => sub {
	plan tests => 4;

	my $plugin = Template::Plugin::Bootstrap::Pagination->new(undef, {
		pager => Data::Page->new(12, 10, 2),
		uri   => 'http://www.example.com/blog/__PAGE__.html',
		prev_text => 'Previous',
		next_text => 'Next',
		version => 3,
	});

	# Basic case
	my $expected = compress_expected(<<EOEXPECTED
<div class="text-left">
	<ul class="pagination">
		<li><a href="http://www.example.com/blog/1.html">Previous</a></li>
		<li><a href="http://www.example.com/blog/1.html">1</a></li>
		<li class="active"><span>2</span></li>
		<li class="disabled"><span>Next</span></li>
	</ul>
</div>
EOEXPECTED
	);
	is($plugin->pagination(), $expected, 'output ok');

	# Center pagination
	$expected = compress_expected(<<EOEXPECTED
<div class="text-center">
	<ul class="pagination">
		<li class="disabled"><span>Previous</span></li>
		<li class="disabled"><span>Next</span></li>
	</ul>
</div>
EOEXPECTED
	);
	is($plugin->pagination({
		pager    => Data::Page->new(2, 10, 2),
		centered => 1,
	}), $expected, 'output ok');

	# Right align pagination
	$expected = compress_expected(<<EOEXPECTED
<div class="text-right">
	<ul class="pagination">
		<li class="disabled"><span>Previous</span></li>
		<li class="disabled"><span>Next</span></li>
	</ul>
</div>
EOEXPECTED
	);
	is($plugin->pagination({
		pager => Data::Page->new(2, 10, 2),
		right => 1,
	}), $expected, 'output ok');

	# Size
	$expected = compress_expected(<<EOEXPECTED
<div class="text-left">
	<ul class="pagination pagination-sm">
		<li class="disabled"><span>Previous</span></li>
		<li class="disabled"><span>Next</span></li>
	</ul>
</div>
EOEXPECTED
	);
	is($plugin->pagination({
		pager => Data::Page->new(2, 10, 2),
		size  => 'small',
	}), $expected, 'output ok');
};


subtest 'pagination() with many pages test' => sub {
	plan tests => 1;

	my $plugin = Template::Plugin::Bootstrap::Pagination->new(undef, {
		pager => Data::Page->new(10000, 10, 500),
		uri   => 'http://www.example.com/blog/__PAGE__.html',
		prev_text => 'Previous',
		next_text => 'Next',
		siblings  => 1,
	});

	# Basic case
	my $expected = compress_expected(<<EOEXPECTED
<div class="pagination">
	<ul>
		<li><a href="http://www.example.com/blog/499.html">Previous</a></li>
		<li><a href="http://www.example.com/blog/1.html">1</a></li>
		<li class="disabled"><span>&hellip;</span></li>
		<li><a href="http://www.example.com/blog/499.html">499</a></li>
		<li class="active"><span>500</span></li>
		<li><a href="http://www.example.com/blog/501.html">501</a></li>
		<li class="disabled"><span>&hellip;</span></li>
		<li><a href="http://www.example.com/blog/1000.html">1000</a></li>
		<li><a href="http://www.example.com/blog/501.html">Next</a></li>
	</ul>
</div>
EOEXPECTED
	);
	is($plugin->pagination(), $expected, 'output ok');
};


subtest 'pager in template' => sub {
	plan tests => 1;

	my $template = Template->new(STRICT => 1);
	my $output;
	my $result = $template->process(\$pager_template_string, {
		pager => Data::Page->new(42, 10, 2),
		uri   => 'http://www.example.com/blog/__PAGE__.html'
	}, \$output) or die $template->error();

	my $expected = compress_expected(<<EOEXPECTED
<ul class="pager">
	<li><a href="http://www.example.com/blog/1.html">&laquo;</a></li>
	<li><a href="http://www.example.com/blog/3.html">&raquo;</a></li>
</ul>
EOEXPECTED
	);
	is($output, $expected, 'output ok');
};


subtest 'pager() test' => sub {
	plan tests => 2;

	my $plugin = Template::Plugin::Bootstrap::Pagination->new(undef, {
		align => 1,
		pager => Data::Page->new(42, 10, 2),
		uri   => 'http://www.example.com/blog/__PAGE__.html',
		prev_text => 'Previous',
		next_text => 'Next',
	});
	my $expected = compress_expected(<<EOEXPECTED
<ul class="pager">
	<li class="previous"><a href="http://www.example.com/blog/1.html">Previous</a></li>
	<li class="next"><a href="http://www.example.com/blog/3.html">Next</a></li>
</ul>
EOEXPECTED
	);
	is($plugin->pager(), $expected, 'output ok');

	$expected = compress_expected(<<EOEXPECTED
<ul class="pager">
	<li class="previous"><a href="http://www.example.com/blog/1.html">foo</a></li>
	<li class="next"><a href="http://www.example.com/blog/3.html">bar</a></li>
</ul>
EOEXPECTED
	);
	is($plugin->pager({
		prev_text => 'foo',
		next_text => 'bar',
	}), $expected, 'output ok');
};


subtest '_pager_item() test' => sub {
	plan tests => 4;

	my $plugin = Template::Plugin::Bootstrap::Pagination->new();

	my $item = $plugin->_pager_item('/1.html', 'foo');
	is($item, '<li><a href="/1.html">foo</a></li>', 'item ok');

	$item = $plugin->_pager_item('/1.html', 'foo', 'previous');
	is($item, '<li class="previous"><a href="/1.html">foo</a></li>', 'item ok');

	$item = $plugin->_pager_item('/1.html', 'foo', 'previous', 'bar');
	is($item, '<li class="previous bar"><a href="/1.html">foo</a></li>', 'item ok');

	$item = $plugin->_pager_item(undef, 'foo', 'previous');
	is($item, '<li class="previous disabled"><span>foo</span></li>', 'item ok');
};


subtest '_prev_next_uri() test' => sub {
	plan tests => 8;

	my $plugin = Template::Plugin::Bootstrap::Pagination->new();
	my @cases = (
		[Data::Page->new(42, 10, 2), 'http://www.example.com/blog/1.html', 'http://www.example.com/blog/3.html'],
		[Data::Page->new(42, 10, 1), undef, 'http://www.example.com/blog/2.html'],
		[Data::Page->new(42, 10, 5), 'http://www.example.com/blog/4.html', undef],
		[Data::Page->new(1, 10, 1), undef, undef],
	);

	for my $case (@cases) {
		my ($prev, $next) = $plugin->_prev_next_uri({
			factor => 1,
			offset => 0,
			pager  => $case->[0],
			uri    => 'http://www.example.com/blog/__PAGE__.html',
		});
		is($prev, $case->[1], 'prev uri ok');
		is($next, $case->[2], 'next uri ok');
	}
};


subtest '_uri_for_page() test' => sub {
	plan tests => 6;

	my $plugin = Template::Plugin::Bootstrap::Pagination->new();
	my @cases = (
		[1, 1, 0, 'http://www.example.com/blog/1.html'],
		[2, 1, 0, 'http://www.example.com/blog/2.html'],
		[1, 1, -1, 'http://www.example.com/blog/0.html'],
		[2, 1, -1, 'http://www.example.com/blog/1.html'],
		[1, 10, -1, 'http://www.example.com/blog/0.html'],
		[2, 10, -1, 'http://www.example.com/blog/10.html'],
	);

	for my $case (@cases) {
		my ($prev, $next) = $plugin->_uri_for_page($case->[0], {
			factor => $case->[1],
			offset => $case->[2],
			uri    => 'http://www.example.com/blog/__PAGE__.html',
		});
		is($prev, $case->[3], 'prev uri ok');
	}
};


subtest 'exceptions on errors test' => sub {
	plan tests => 4;

	my $plugin = Template::Plugin::Bootstrap::Pagination->new();

	throws_ok(sub {
		$plugin->pager(),
	}, qr{Required 'pager' parameter not passed or not a 'Data::Page' instance}, 'pager required');
	throws_ok(sub {
		$plugin->pagination(),
	}, qr{Required 'pager' parameter not passed or not a 'Data::Page' instance}, 'pager required');

	throws_ok(sub {
		$plugin->pager({
			pager => Data::Page->new(42, 10, 1),
		}),
	}, qr{Required 'uri' parameter not passed}, 'pager required');
	throws_ok(sub {
		$plugin->pagination({
			pager => Data::Page->new(42, 10, 1),
		}),
	}, qr{Required 'uri' parameter not passed}, 'pager required');
};


sub compress_expected {
	my ($expected) = @_;
	$expected =~ s{(?:\n|^\s*)}{}gxms;
	return $expected;
}

done_testing();
