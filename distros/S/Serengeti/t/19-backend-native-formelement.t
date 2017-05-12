#!/usr/bin/perl

use strict;
use warnings;

use HTTP::Response;
use JavaScript;

use Test::More qw(no_plan);
use Test::Exception;

BEGIN { use_ok("Serengeti::Backend::Native::Document"); }

use Serengeti::Backend::Native;

my $source = <<'__END_OF_HTML__';
<html>
<body>
    <form method="post" id="form1" action="http://localhost/test_post">
        <input name="username" type="text" value="claes"/>
        <input name="password" type="password" value=""/>
        <textarea>Foo bar</textarea>
        <select name="type">
            <option value="foo">foo</option>
            <option value="bar" selected>foo</option>
        </select>
    </form>
    <form name="test_form" id="form2" method="get" action="http://localhost/test_get">
    </form>
    
</body>
</html>
__END_OF_HTML__

my $document = Serengeti::Backend::Native::Document->new($source, {
    browser => __PACKAGE__,
});

my $rt = JavaScript::Runtime->new();
my $cx = $rt->create_context();

Serengeti::Backend::Native->setup_document_jsapi($cx);

$cx->bind_function(diag => sub { diag @_ });
$cx->bind_function(ok => sub { ok(shift, shift) });
$cx->bind_function(is => sub { is(shift, shift, shift) });

$cx->eval(<<'__END_OF_JS__');
function test_forms(document) {
    ok(document.forms);
    is(document.forms[0].id, "form1");
    is(document.forms["test_form"].id, "form2");
    
    is(document.forms[0].name, "");
    is(document.forms[0].action, "http://localhost/test_post");
    is(document.forms[0].method, "post");
    is(document.forms[0].enctype, "application/x-www-form-urlencoded");
    
    is(document.forms[0].length, 4);
    is(document.forms[0].elements[0].value, "claes");
    is(document.forms[0].elements[0].form, document.forms[0]);
    is(document.forms[1].length, 0);
    
    document.forms[0].submit({
        password: "quax",
    });
    
    document.forms[1].submit();
}

__END_OF_JS__
diag $@ if $@;

my $self;

my ($called_post, $post_url, $post_data, $post_options);
sub post {
    ($self, $post_url, $post_data, $post_options) = @_;
    $called_post = 1;
    return HTTP::Response->new();
}

my ($called_get, $get_url, $get_query, $get_options);
sub get {
    ($self, $get_url, $get_query, $get_options) = @_;
    $called_get = 1;
    return HTTP::Response->new();
}

$cx->call("test_forms", $document);
diag $@ if $@;

is($called_post, 1);
is($post_url, "http://localhost/test_post");
is_deeply($post_data, {
   username => "claes",
   password => "quax",
   type => "foo",
});

is($called_get, 1);
is($get_url, "http://localhost/test_get");