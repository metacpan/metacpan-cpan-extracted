# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 4;
BEGIN { 
	use_ok('Template');
	use_ok('Template::Plugin::HTML::Prototype');
};

my $template = new Template();
ok($template);
my $output;
ok($template->process(\*DATA, {}, \$output));
# print STDERR $output;

__END__

<html><head>
[% USE proto = HTML::Prototype %]
[% proto.define_javascript_functions %]
</head><body>
[% url = base _ 'edit/' _ page.title %]
[% proto.observe_field( 'editor', {
	url    => url,
	with   => "'body='+value",
	update => 'view'
} ) %]
[% proto.link_to_remote( 'Delete', {
        update = 'posts',
        url    = 'http://localhost/posts/'
    } ) %]
</body></html>
