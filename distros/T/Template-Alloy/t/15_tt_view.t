# -*- Mode: Perl; -*-

=head1 NAME

02_view.t - Test the ability to handle views in Template::Alloy

=cut

#============================================================= -*-perl-*-
#
# The tests used here where originally written by Andy Wardley
# They have been modified to work with this testing framework
# The following is the original Copyright notice included with
# the t/view.t document that these tests were taken from.
#
# Tests the 'View' plugin.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2000 Andy Wardley. All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# Id: view.t 131 2001-06-14 13:20:12Z abw
#
#========================================================================

our ($module, $N, $is_tt, $compile_perl);
BEGIN {
    $module = 'Template::Alloy';
    if (grep {/tt/i} @ARGV) {
        $module = 'Template';
    }
    $is_tt = $module eq 'Template';
    $N = ! $is_tt ? 105 : 53;
};

use strict;
use Test::More tests => $N;

use_ok($module);

my $skipped;
SKIP: {
    if (! eval { require Template::View } || ! $Template::View::VERSION) {
        $skipped = 1;
        skip("Template::View is not installed - skipping Template::View integration tests", $N - 1);
    } elsif (! UNIVERSAL::isa('Template::View', 'Template::Base')) {
        $skipped = 1;
        skip("Template::View doesn't appear to be from the Template Toolkit installation - skipping Template::View integration tests", $N - 1);
    } elsif ($Template::View::VERSION < 2.14) {
        $skipped = 1;
        skip("Template::View is not recent version - skipping Template::View integration tests", $N - 1);
    } elsif ($Template::View::VERSION >= 3) {
        $skipped = 1;
        skip("Template::View seems to be an experimental version - skipping Template::View integration tests", $N - 1);
    }
};
exit if $skipped;


sub process_ok { # process the value and say if it was ok
    my $str  = shift;
    my $test = shift;
    my $vars = shift || {};
    my $conf = local $vars->{'tt_config'} = $vars->{'tt_config'} || [];
    push @$conf, (COMPILE_PERL => $compile_perl) if $compile_perl;
    my $obj  = shift || $module->new(@$conf); # new object each time
    my $out  = '';
    my $line = (caller)[2];
    delete $vars->{'tt_config'};

    $obj->process(\$str, $vars, \$out);
    my $ok = ref($test) ? $out =~ $test : $out eq $test;
    if ($ok) {
        ok(1, "Line $line   \"$str\" => \"$out\"");
        return $obj;
    } else {
        ok(0, "Line $line   \"$str\"");
        warn "# Was:\n$out\n# Should've been:\n$test\n";
        print $obj->error if $obj->can('error');
        print $obj->dump_parse_tree(\$str) if $obj->can('dump_parse_tree');
        exit;
    }
}

### This next section of code is verbatim from Andy's code
#------------------------------------------------------------------------
{
package Foo;

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub present {
    my $self = shift;
    return '{ ' . join(', ', map { "$_ => $self->{ $_ }" } 
		       sort keys %$self) . ' }';
}

sub reverse {
    my $self = shift;
    return '{ ' . join(', ', map { "$_ => $self->{ $_ }" } 
		       reverse sort keys %$self) . ' }';
}
}
#------------------------------------------------------------------------
{
package Blessed::List;

sub as_list {
    my $self = shift;
    return @$self;
}
}
#------------------------------------------------------------------------

my $vars = {
    foo => Foo->new( pi => 3.14, e => 2.718 ),
    blessed_list => bless([ "Hello", "World" ], 'Blessed::List'),
};


for $compile_perl (($is_tt) ? (0) : (0, 1)) {
    my $is_compile_perl = "compile perl ($compile_perl)";

###----------------------------------------------------------------###
### These are Andy's tests coded as Paul's process_oks

### View plugin usage

process_ok("[% USE v = view -%]
[[% v.prefix %]]" => "[]", $vars);

process_ok("[% USE v = view( map => { default='any' } ) -%]
[[% v.map.default %]]" => "[any]", $vars);

process_ok("[% USE view( prefix=> 'foo/', suffix => '.tt2') -%]
[[% view.prefix %]bar[% view.suffix %]]
[[% view.template_name('baz') %]]" => "[foo/bar.tt2]
[foo/baz.tt2]", $vars);

process_ok("[% USE view( prefix=> 'foo/', suffix => '.tt2') -%]
[[% view.prefix %]bar[% view.suffix %]]
[[% view.template_name('baz') %]]" => "[foo/bar.tt2]
[foo/baz.tt2]", $vars);

process_ok("[% USE view -%]
[% view.print('Hello World') %]
[% BLOCK text %]TEXT: [% item %][% END -%]" => "TEXT: Hello World\n", $vars);

process_ok("[% USE view -%]
[% view.print( { foo => 'bar' } ) %]
[% BLOCK hash %]HASH: {
[% FOREACH key = item.keys.sort -%]
   [% key %] => [% item.\$key %]
[%- END %]
}
[% END -%]" => "HASH: {
   foo => bar
}\n\n", $vars);

process_ok("[% USE view -%]
[% view = view.clone( prefix => 'my_' ) -%]
[% view.view('hash', { bar => 'baz' }) %]
[% BLOCK my_hash %]HASH: {
[% FOREACH key = item.keys.sort -%]
   [% key %] => [% item.\$key %]
[%- END %]
}
[% END -%]" => "HASH: {
   bar => baz
}\n\n", $vars);

process_ok("[% USE view(prefix='my_') -%]
[% view.print( foo => 'wiz', bar => 'waz' ) %]
[% BLOCK my_hash %]KEYS: [% item.keys.sort.join(', ') %][% END %]

" => "KEYS: bar, foo\n\n\n", $vars);

process_ok("[% USE view -%]
[% view.print( view ) %]
[% BLOCK Template_View %]Printing a Template::View object[% END -%]" => "Printing a Template::View object\n", $vars);

process_ok("[% USE view(prefix='my_') -%]
[% view.print( view ) %]
[% view.print( view, prefix='your_' ) %]
[% BLOCK my_Template_View %]Printing my Template::View object[% END -%]
[% BLOCK your_Template_View %]Printing your Template::View object[% END -%]" => "Printing my Template::View object
Printing your Template::View object\n" , $vars);

process_ok("[% USE view(prefix='my_', notfound='any' ) -%]
[% view.print( view ) %]
[% view.print( view, prefix='your_' ) %]
[% BLOCK my_any %]Printing any of my objects[% END -%]
[% BLOCK your_any %]Printing any of your objects[% END -%]" => "Printing any of my objects
Printing any of your objects
", $vars);

process_ok("[% USE view(prefix => 'my_', map => { default => 'catchall' } ) -%]
[% view.print( view ) %]
[% view.print( view, default='catchsome' ) %]
[% BLOCK my_catchall %]Catching all defaults[% END -%]
[% BLOCK my_catchsome %]Catching some defaults[% END -%]" => "Catching all defaults
Catching some defaults
", $vars);

process_ok("[% USE view(prefix => 'my_', map => { default => 'catchnone' } ) -%]
[% view.default %]
[% view.default = 'catchall' -%]
[% view.default %]
[% view.print( view ) %]
[% view.print( view, default='catchsome' ) %]
[% BLOCK my_catchall %]Catching all defaults[% END -%]
[% BLOCK my_catchsome %]Catching some defaults[% END -%]" => "catchnone
catchall
Catching all defaults
Catching some defaults
", $vars);

process_ok("[% USE view(prefix='my_', default='catchall' notfound='lost') -%]
[% view.print( view ) %]
[% BLOCK my_lost %]Something has been found[% END -%]" => "Something has been found
", $vars);

process_ok("[% USE view -%]
[% TRY ;
     view.print( view ) ;
   CATCH view ;
     \"[\$error.type] \$error.info\" ;
   END
%]" => qr{^\Q[view] file error - Template_View: not found\E}, $vars);

process_ok("[% USE view -%]
[% view.print( foo ) %]" => "{ e => 2.718, pi => 3.14 }", $vars);

process_ok("[% USE view -%]
[% view.print( foo, method => 'reverse' ) %]" => "{ pi => 3.14, e => 2.718 }", $vars);

process_ok("[% USE view(prefix='my_', include_naked=0, view_naked=1) -%]
[% BLOCK my_foo; \"Foo: \$item\"; END -%]
[[% view.view_foo(20) %]]
[[% view.foo(30) %]]" => "[Foo: 20]
[Foo: 30]", $vars);

process_ok("[% USE view(prefix='my_', include_naked=0, view_naked=0) -%]
[% BLOCK my_foo; \"Foo: \$item\"; END -%]
[[% view.view_foo(20) %]]
[% TRY ;
     view.foo(30) ;
   CATCH ;
     error.info ;
   END
%]" => "[Foo: 20]
no such view member: foo", $vars);

process_ok("[% USE view(map => { HASH => 'my_hash', ARRAY => 'your_list' }) -%]
[% BLOCK text %]TEXT: [% item %][% END -%]
[% BLOCK my_hash %]HASH: [% item.keys.sort.join(', ') %][% END -%]
[% BLOCK your_list %]LIST: [% item.join(', ') %][% END -%]
[% view.print(\"some text\") %]
[% view.print({ alpha => 'a', bravo => 'b' }) %]
[% view.print([ 'charlie', 'delta' ]) %]" => "TEXT: some text
HASH: alpha, bravo
LIST: charlie, delta", $vars);

process_ok("[% USE view(item => 'thing',
	    map => { HASH => 'my_hash', ARRAY => 'your_list' }) -%]
[% BLOCK text %]TEXT: [% thing %][% END -%]
[% BLOCK my_hash %]HASH: [% thing.keys.sort.join(', ') %][% END -%]
[% BLOCK your_list %]LIST: [% thing.join(', ') %][% END -%]
[% view.print(\"some text\") %]
[% view.print({ alpha => 'a', bravo => 'b' }) %]
[% view.print([ 'charlie', 'delta' ]) %]" => "TEXT: some text
HASH: alpha, bravo
LIST: charlie, delta", $vars);

process_ok("[% USE view -%]
[% view.print('Hello World') %]
[% view1 = view.clone( prefix='my_') -%]
[% view1.print('Hello World') %]
[% view2 = view1.clone( prefix='dud_', notfound='no_text' ) -%]
[% view2.print('Hello World') %]
[% BLOCK text %]TEXT: [% item %][% END -%]
[% BLOCK my_text %]MY TEXT: [% item %][% END -%]
[% BLOCK dud_no_text %]NO TEXT: [% item %][% END -%]" => "TEXT: Hello World
MY TEXT: Hello World
NO TEXT: Hello World
", $vars);

process_ok("[% USE view( prefix = 'base_', default => 'any' ) -%]
[% view1 = view.clone( prefix => 'one_') -%]
[% view2 = view.clone( prefix => 'two_') -%]
[% view.default %] / [% view.map.default %]
[% view1.default = 'anyone' -%]
[% view1.default %] / [% view1.map.default %]
[% view2.map.default = 'anytwo' -%]
[% view2.default %] / [% view2.map.default %]
[% view.print(\"Hello World\") %] / [% view.print(blessed_list) %]
[% view1.print(\"Hello World\") %] / [% view1.print(blessed_list) %]
[% view2.print(\"Hello World\") %] / [% view2.print(blessed_list) %]
[% BLOCK base_text %]ANY TEXT: [% item %][% END -%]
[% BLOCK one_text %]ONE TEXT: [% item %][% END -%]
[% BLOCK two_text %]TWO TEXT: [% item %][% END -%]
[% BLOCK base_any %]BASE ANY: [% item.as_list.join(', ') %][% END -%]
[% BLOCK one_anyone %]ONE ANY: [% item.as_list.join(', ') %][% END -%]
[% BLOCK two_anytwo %]TWO ANY: [% item.as_list.join(', ') %][% END -%]" => "any / any
anyone / anyone
anytwo / anytwo
ANY TEXT: Hello World / BASE ANY: Hello, World
ONE TEXT: Hello World / ONE ANY: Hello, World
TWO TEXT: Hello World / TWO ANY: Hello, World
", $vars);

process_ok("[% USE view( prefix => 'my_', item => 'thing' ) -%]
[% view.view('thingy', [ 'foo', 'bar'] ) %]
[% BLOCK my_thingy %]thingy: [ [% thing.join(', ') %] ][%END %]" => "thingy: [ foo, bar ]
", $vars);

process_ok("[% USE view -%]
[% view.map.\${'Template::View'} = 'myview' -%]
[% view.print(view) %]
[% BLOCK myview %]MYVIEW[% END%]" => "MYVIEW
", $vars);

process_ok("[% USE view -%]
[% view.include('greeting', msg => 'Hello World!') %]
[% BLOCK greeting %]msg: [% msg %][% END -%]" => "msg: Hello World!
", $vars);

process_ok("[% USE view( prefix=\"my_\" )-%]
[% view.include('greeting', msg => 'Hello World!') %]
[% BLOCK my_greeting %]msg: [% msg %][% END -%]" => "msg: Hello World!
", $vars);

process_ok("[% USE view( prefix=\"my_\" )-%]
[% view.include_greeting( msg => 'Hello World!') %]
[% BLOCK my_greeting %]msg: [% msg %][% END -%]" => "msg: Hello World!
", $vars);

process_ok("[% USE view( prefix=\"my_\" )-%]
[% INCLUDE \$view.template('greeting')
   msg = 'Hello World!' %]
[% BLOCK my_greeting %]msg: [% msg %][% END -%]" => "msg: Hello World!
", $vars);

process_ok("[% USE view( title=\"My View\" )-%]
[% view.title %]" => "My View", $vars);

process_ok("[% USE view( title=\"My View\" )-%]
[% newview = view.clone( col = 'Chartreuse') -%]
[% newerview = newview.clone( title => 'New Title' ) -%]
[% view.title %]
[% newview.title %]
[% newview.col %]
[% newerview.title %]
[% newerview.col %]" => "My View
My View
Chartreuse
New Title
Chartreuse", $vars);

###----------------------------------------------------------------###

### VIEW directive usage

process_ok("[% VIEW fred prefix='blat_' %]
This is the view
[% END -%]
[% BLOCK blat_foo; 'This is blat_foo'; END -%]
[% fred.view_foo %]" => "This is blat_foo", $vars);

process_ok("[% VIEW fred %]
This is the view
[% view.prefix = 'blat_' %]
[% END -%]
[% BLOCK blat_foo; 'This is blat_foo'; END -%]
[% fred.view_foo %]" => "This is blat_foo", $vars);

process_ok("[% VIEW fred %]
This is the view
[% view.prefix = 'blat_' %]
[% view.thingy = 'bloop' %]
[% fred.name = 'Freddy' %]
[% END -%]
[% fred.prefix %]
[% fred.thingy %]
[% fred.name %]" => "blat_
bloop
Freddy", $vars);

process_ok("[% VIEW fred prefix='blat_'; view.name='Fred'; END -%]
[% fred.prefix %]
[% fred.name %]
[% TRY;
     fred.prefix = 'nonblat_';
   CATCH;
     error;
   END
%]
[% TRY;
     fred.name = 'Derek';
   CATCH;
     error;
   END
%]" => "blat_
Fred
view error - cannot update config item in sealed view: prefix
view error - cannot update item in sealed view: name", $vars);

process_ok("[% VIEW foo prefix='blat_' default=\"default\" notfound=\"notfound\"
     title=\"fred\" age=23 height=1.82 %]
[% view.other = 'another' %]
[% END -%]
[% BLOCK blat_hash -%]
[% FOREACH key = item.keys.sort -%]
   [% key %] => [% item.\$key %]
[% END -%]
[% END -%]
[% foo.print(foo.data) %]" => "   age => 23
   height => 1.82
   other => another
   title => fred
", $vars);

process_ok("[% VIEW foo %]
[% BLOCK hello -%]
Hello World!
[% END %]
[% BLOCK goodbye -%]
Goodbye World!
[% END %]
[% END -%]
[% TRY; INCLUDE foo; CATCH; error; END %]
[% foo.include_hello %]" => qr{^\Qfile error - foo: not found
Hello World!
\E}, $vars);

process_ok("[% title = \"Previous Title\" -%]
[% VIEW foo 
     include_naked = 1
     title = title or 'Default Title'
     copy  = 'me, now'
-%]

[% view.bgcol = '#ffffff' -%]

[% BLOCK header -%]
Header:  bgcol: [% view.bgcol %]
         title: [% title %]
    view.title: [% view.title %]
[%- END %]

[% BLOCK footer -%]
&copy; Copyright [% view.copy %]
[%- END %]

[% END -%]
[% title = 'New Title' -%]
[% foo.header %]
[% foo.header(bgcol='#dead' title=\"Title Parameter\") %]
[% foo.footer %]
[% foo.footer(copy=\"you, then\") %]
" => "Header:  bgcol: #ffffff
         title: New Title
    view.title: Previous Title
Header:  bgcol: #ffffff
         title: Title Parameter
    view.title: Previous Title
&copy; Copyright me, now
&copy; Copyright me, now
", $vars);

process_ok("[% VIEW foo 
    title  = 'My View' 
    author = 'Andy Wardley'
    bgcol  = bgcol or '#ffffff'
-%]
[% view.arg1 = 'argument #1' -%]
[% view.data.arg2 = 'argument #2' -%]
[% END -%]
 [% foo.title %]
 [% foo.author %]
 [% foo.bgcol %]
 [% foo.arg1 %]
 [% foo.arg2 %]
[% bar = foo.clone( title='New View', arg1='New Arg1' ) %]cloned!
 [% bar.title %]
 [% bar.author %]
 [% bar.bgcol %]
 [% bar.arg1 %]
 [% bar.arg2 %]
originals:
 [% foo.title %]
 [% foo.arg1 %]

" => " My View
 Andy Wardley
 #ffffff
 argument #1
 argument #2
cloned!
 New View
 Andy Wardley
 #ffffff
 New Arg1
 argument #2
originals:
 My View
 argument #1

", $vars);

process_ok("[% VIEW basic title = \"My Web Site\" %]
  [% BLOCK header -%]
  This is the basic header: [% title or view.title %]
  [%- END -%]
[% END -%]

[%- VIEW fancy 
      title = \"<fancy>\$basic.title</fancy>\"
      basic = basic 
%]
  [% BLOCK header ; view.basic.header(title = title or view.title) %]
  Fancy new part of header
  [%- END %]
[% END -%]
===
[% basic.header %]
[% basic.header( title = \"New Title\" ) %]
===
[% fancy.header %]
[% fancy.header( title = \"Fancy Title\" ) %]" => "===
  This is the basic header: My Web Site
  This is the basic header: New Title
===
  This is the basic header: <fancy>My Web Site</fancy>
  Fancy new part of header
  This is the basic header: Fancy Title
  Fancy new part of header", $vars);

process_ok("[% VIEW baz  notfound='lost' %]
[% BLOCK lost; 'lost, not found'; END %]
[% END -%]
[% baz.any %]" => "lost, not found", $vars);

process_ok("[% VIEW woz  prefix='outer_' %]
[% BLOCK wiz; 'The inner wiz'; END %]
[% END -%]
[% BLOCK outer_waz; 'The outer waz'; END -%]
[% woz.wiz %]
[% woz.waz %]" => "The inner wiz
The outer waz", $vars);

process_ok("[% VIEW foo %]

   [% BLOCK file -%]
      File: [% item.name %]
   [%- END -%]

   [% BLOCK directory -%]
      Dir: [% item.name %]
   [%- END %]

[% END -%]
[% foo.view_file({ name => 'some_file' }) %]
[% foo.include_file(item => { name => 'some_file' }) %]
[% foo.view('directory', { name => 'some_dir' }) %]" => "      File: some_file
      File: some_file
      Dir: some_dir", $vars);

process_ok("[% BLOCK parent -%]
This is the base block
[%- END -%]
[% VIEW super %]
   [%- BLOCK parent -%]
   [%- INCLUDE parent FILTER replace('base', 'super') -%]
   [%- END -%]
[% END -%]
base: [% INCLUDE parent %]
super: [% super.parent %]" => "base: This is the base block
super: This is the super block", $vars);

process_ok("[% BLOCK foo -%]
public foo block
[%- END -%]
[% VIEW plain %]
   [% BLOCK foo -%]
<plain>[% PROCESS foo %]</plain>
   [%- END %]
[% END -%]
[% VIEW fancy %]
   [% BLOCK foo -%]
   [%- plain.foo | replace('plain', 'fancy') -%]
   [%- END %]
[% END -%]
[% plain.foo %]
[% fancy.foo %]" => "<plain>public foo block</plain>
<fancy>public foo block</fancy>", $vars);

process_ok("[% VIEW foo %]
[% BLOCK Blessed_List -%]
This is a list: [% item.as_list.join(', ') %]
[% END -%]
[% END -%]
[% foo.print(blessed_list) %]" => "This is a list: Hello, World
", $vars);

process_ok("[% VIEW my.foo value=33; END -%]
n: [% my.foo.value %]" => "n: 33", $vars);

process_ok("[% VIEW parent -%]
[% BLOCK one %]This is base one[% END %]
[% BLOCK two %]This is base two[% END %]
[% END -%]

[%- VIEW child1 base=parent %]
[% BLOCK one %]This is child1 one[% END %]
[% END -%]

[%- VIEW child2 base=parent %]
[% BLOCK two %]This is child2 two[% END %]
[% END -%]

[%- VIEW child3 base=child2 %]
[% BLOCK two %]This is child3 two[% END %]
[% END -%]

[%- FOREACH child = [ child1, child2, child3 ] -%]
one: [% child.one %]
[% END -%]
[% FOREACH child = [ child1, child2, child3 ] -%]
two: [% child.two %]
[% END %]
" => "one: This is child1 one
one: This is base one
one: This is base one
two: This is base two
two: This is child2 two
two: This is child3 two

", $vars);

process_ok("[% VIEW my.view.default
        prefix = 'view/default/'
        value  = 3.14;
   END
-%]
value: [% my.view.default.value %]" => "value: 3.14", $vars);

process_ok("[% VIEW my.view.default
        prefix = 'view/default/'
        value  = 3.14;
   END;
   VIEW my.view.one
        base   = my.view.default
        prefix = 'view/one/';
   END;
   VIEW my.view.two
	base  = my.view.default
        value = 2.718;
   END;
-%]
[% BLOCK view/default/foo %]Default foo[% END -%]
[% BLOCK view/one/foo %]One foo[% END -%]
0: [% my.view.default.foo %]
1: [% my.view.one.foo %]
2: [% my.view.two.foo %]
0: [% my.view.default.value %]
1: [% my.view.one.value %]
2: [% my.view.two.value %]" => "0: Default foo
1: One foo
2: Default foo
0: 3.14
1: 3.14
2: 2.718", $vars);

process_ok("[% VIEW foo number = 10 sealed = 0; END -%]
a: [% foo.number %]
b: [% foo.number = 20 %]
c: [% foo.number %]
d: [% foo.number(30) %]
e: [% foo.number %]" => "a: 10
b: 
c: 20
d: 30
e: 30", $vars);

process_ok("[% VIEW foo number = 10 silent = 1; END -%]
a: [% foo.number %]
b: [% foo.number = 20 %]
c: [% foo.number %]
d: [% foo.number(30) %]
e: [% foo.number %]" => "a: 10
b: 
c: 10
d: 10
e: 10", $vars);

###----------------------------------------------------------------###
print "### DONE ############################################ $is_compile_perl\n";
} # end of for
