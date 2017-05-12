#!/usr/bin/perl

use strict ;
use warnings ;
use lib '../lib' ;

use File::Slurp ;

=head1 Template::Simple Cookbook

This cookbook contains examples of idioms and best practices when
using the Template::Simple module. It will illustrate all the the
features of this module and show various combinations of code to get
the job done. Send any requests for more examples to
E<lt>template@stemsystems.comE<gt>. Read the source code to see the
working examples or you can run this script to see all the
output. Each example has its title printed and rendered templates are
printed with a KEY: prefix and delimited with [].

By combining these techniques you can create and built complex
template applications that can do almost any task other templaters can
do. You will be able to share more code logic and templates as they
are totally isolated and independent from each other.

=head2 Use Scalar References

When passing text either as templates or in data tree elements, it is
generally faster to use scalar references than plain scalars. T::S can
accept text either way so you choose the style you like best. Most of
the examples here will use scalar references. Note that passing a
scalar reference to the new() constructor as the template will force
that to be a template and not a template name so no lookup will
occur. T::S always treats all text values as read only and never
modifies incoming data.

=cut

use Template::Simple ;
my $ts = Template::Simple->new() ;
my $template ;


=head1 Token Expansion

The simplest use of templates is replacing single tokens with
values. This is vry similar to interpolation of scalar variables in a
double quoted string. The difference is that the template text can
come from outside the program whereas double quoted strings must be in
the code (eval STRING doesn't count).

To replace tokens all you need is a template with token markups
(e.g. C<[% foo %]>) and a hash with those tokens as keys and the
values with which to replace them. Remember the top level template is
treated as an unnamed chunk so you can pass a hash reference to
render.

=cut

print "\n******************\nToken Expansion\n******************\n\n" ;

$template = <<TMPL ;
This [% token %] will be replaced as will [%foo%] and [% bar %]
TMPL

my $token_expansion = $ts->render( $template,
	{
	token	=> 'markup',
	foo	=> 'this',
	bar	=> 'so will this',
	}
) ;

print "TOKEN EXPANSION: [${$token_expansion}]\n" ;

=head1 Token Deletion

Sometimes you want to delete a token and not replace it with text. All
you need to do is use the null string for its data. Altenatively if
you are rendering a chunk with a hash (see below for more examples)
you can just not have any data for the token and it will also be
deleted. Both styles are shown in this example.

=cut

print "\n******************\nToken Deletion\n******************\n\n" ;

$template = <<TMPL ;
This [% token %]will be deleted as will [%foo%]
TMPL

my $token_deletion = $ts->render( $template,
	{
	token	=> '',
	}
) ;

print "TOKEN DELETION: [${$token_deletion}]\n" ;


=head1 Named Templates

You can pass a template directly to the C<render> method or pass in
its name. A named template will be searched for in the object cache
and then in the C<template_paths> directories. Templates can be loaded
into the cache with in the new() call or added later with the
C<add_templates> method.

=cut

print "\n******************\nNamed Templates\n******************\n\n" ;

$ts = Template::Simple->new(
	templates	=> {
		foo	=> <<FOO,
We have some foo text here with [% data %]
FOO
	}
) ;

my $foo_template = $ts->render( 'foo', { data => 'lots of foo' } ) ;

$ts->add_templates( { bar => <<BAR } ) ;
We have some bar text here with [% data %]
BAR

my $bar_template = $ts->render( 'bar', { data => 'some bar' } ) ;

print "FOO TEMPLATE: [${$foo_template}]\n" ;
print "BAR TEMPLATE: [${$bar_template}]\n" ;

=head1 Include Expansion

You can build up templates by including other templates. This allows a
template to be reused and shared by other templates. What makes this
even better, is that by passing different data to the included
templates in different renderings, you can get different results. If
the logic was embedded in the template you can't change the rendering
as easily. You include a template by using the C<[%include name%]>
markup. The name is used to locate a template by name and its text
replaces the markup. This example shows a single include in the top
level template.

=cut

print "\n******************\nInclude Expansion\n******************\n\n" ;

$ts = Template::Simple->new(
	templates	=> {
		top	=> <<TOP,
This top level template includes this <<[% include other %]>>text
TOP
		other	=> <<OTHER,
This is the included text
OTHER
} ) ;

my $include_template = $ts->render( 'top', {} ) ;

print "INCLUDE TEMPLATE: [${$include_template}]\n" ;

=head1 Template Paths

You can search for templates in files with the C<search_dirs> option
to the constructor. If a named template is not found in the object
cache it will be searched for in the directories listed in the
C<search_dirs> option. If it is found there, it will be loaded into
the object cache so future uses of it by name will be faster. The
default value of C<search_dirs> option is C<templates>. Templates must
have a suffix of C<.tmpl>. This example makes a directory called
'templates' and a template file named C<foo.tmpl>. The second example
makes a directory called C<cookbook> and puts a template in there and
sets. Note that the option value must be an array reference.

=cut

print "\n******************\nSearch Dirs\n******************\n\n" ;

my $tmpl_dir = 'templates' ;
mkdir $tmpl_dir ;
write_file( "$tmpl_dir/foo.tmpl", <<FOO ) ;
This template was loaded from the dir [%dir%]
FOO

$ts = Template::Simple->new() ;
my $foo_file_template = $ts->render( 'foo', { dir => 'templates' } ) ;

print "FOO FILE TEMPLATE: [${$foo_file_template}]\n" ;

unlink "$tmpl_dir/foo.tmpl" ;
rmdir $tmpl_dir ;

######

my $cook_dir = 'cookbook' ;
mkdir $cook_dir ;
write_file( "$cook_dir/bar.tmpl", <<BAR ) ;
This template was loaded from the $cook_dir [%dir%]
BAR

$ts = Template::Simple->new( search_dirs => [$cook_dir] ) ;
my $bar_file_template = $ts->render( 'bar', { dir => 'directory' } ) ;

print "BAR FILE TEMPLATE: [${$bar_file_template}]\n" ;

unlink "$cook_dir/bar.tmpl" ;
rmdir $cook_dir ;

=head1 Named Chunk Expansion

The core markup in T::S is called a chunk. It is delimited by paired
C<start> and C<end> markups and the text in between them is the
chunk. Any chunk can have multiple chunks inside it and they are named
for the name in the C<start> and C<end> markups. That name is used to
match the chunk with the data passed to render. This example uses the
top level template (which is always an unnamed chunk) which contains a
nested chunk which has a name. The data passed in is a hash reference
which has a key with the chunk name and its value is another hash
reference. So the nested chunk match up to the nested hashes.

=cut

print "\n******************\nNested Chunk Expansion\n******************\n\n" ;

$ts = Template::Simple->new(
	templates	=> {
		top	=> <<TOP,
This top level template includes this <<[% include nested %]>> chunk
TOP
		nested	=> <<NESTED,
[%START nested %]This included template just has a [% token %] and another [% one %][%END nested %]
NESTED
	}
) ;

my $nested_template = $ts->render( 'top',
	{
	nested => {
		token	=> 'nested value',
		one	=> 'value from the data',
	}
} ) ;

print "NESTED TEMPLATE: [${$nested_template}]\n" ;

=head2 Boolean Chunk

The simplest template decision is when you want to show some text or
nothing.  This is done with an empty hash reference or a null string
value in the data tree. The empty hash reference will cause the text
to be kept as is with all markups removed (replaced by the null
string). A null string (or a reference to one) will cause the text
chunk to be deleted.

=cut

print "\n******************\nBoolean Text\n******************\n\n" ;

$template = \<<TMPL ;
[% START boolean %]This is text to be left or deleted[% END boolean %]
TMPL

my $boolean_kept = $ts->render( $template, { boolean => {} } ) ;
my $deleted = $ts->render( $template, { default => \'' } ) ;

print "KEPT: [${$boolean_kept}]\n" ;
print "DELETED: [${$deleted}]\n" ;

=head2 Default vs. Overwrite Text

The next step up from boolean text is overwriting a default text with
another when rendering. This is done with an empty hash reference or a
scalar value for the chunk in the data tree. The empty hash reference
will cause the default text to be kept as is with all markups removed
(replaced by the null string). A scalar value (or a scalar reference)
will cause the complete text chunk to be replaced by that value.

=cut

print "\n******************\nDefault vs. Overwrite Text\n******************\n\n" ;

$template = \<<TMPL ;
[% START default %]This is text to be left or replaced[% END default %]
TMPL

my $default_kept = $ts->render( $template, { default => {} } ) ;
my $overwrite = $ts->render( $template, { default => \<<OVER } ) ;
This text will overwrite the default text
OVER

print "DEFAULT: [${$default_kept}]\n" ;
print "OVERWRITE: [${$overwrite}]\n" ;

=head2 Conditional Text

Instead of having the overwrite text in the data tree, it is useful to
have it in the template itself. This is a conditional where one text
or the other is rendered. This is done by wrapping each text in its
own chunk with unique names. The data tree can show either one by
passing an empty hash reference for that data and a null string for
the other one. Also you can just not have a value for the text not to
be rendered and that will also delete it. Both styles are shown here.

=cut

print "\n******************\nConditional Text\n******************\n\n" ;

$template = \<<TMPL ;
[% START yes_text %]This text shown when yes[% END yes_text %]
[% START no_text %]This text shown when no[% END no_text %]
TMPL

my $yes_shown = $ts->render( $template, { yes_text => {} } ) ;
my $no_shown = $ts->render( $template, {
	yes_text => '',
	no_text => {}
} ) ;

print "YES: [${$yes_shown}]\n" ;
print "NO: [${$no_shown}]\n" ;

=head1 List Chunk Expansion

T::S has no list markup because of the unique way it handles data
during rendering. When an array reference is matched to a chunk, the
array is iterated and the chunk is then rendered with each element of
the array. This list of rendered texts is concatenated and replaces
the original chunk in the template. The data and the logic that
creates the data controls when a template chunk is repeated. This
example shows the top level (unnamed) template being rendered with an
array of hashes. Each hash renders the chunk one time. Note that the
different results you get based on the different hashes in the array.

=cut

print "\n******************\nList Chunk Expansion\n******************\n\n" ;

$ts = Template::Simple->new(
	templates => {
		top_array => <<TOP_ARRAY,

This is the [%count%] chunk.
[%start maybe%]This line may be shown[%end maybe%]
This is the end of the chunk line
TOP_ARRAY
} ) ;

my $top_array = $ts->render( 'top_array', [
	{
		count	=> 'first',
		maybe	=> {},
	},
	{
		count	=> 'second',
	},
	{
		count	=> 'third',
		maybe	=> {},
	},
] ) ;

print "TOP_ARRAY: [${$top_array}]\n" ;


=head1 Separated List Expansion

A majorly used variation of data lists are list with a separator but
not one after the last element. This can be done easily with T::S and
here are two techniques. The first one uses a token for the separator
in the chunk and passes in a hash with the delimiter string set in all
but the last element. This requires the code logic to know and set the
delimiter. The other solution lets the template set the delimiter by
enclosing it in a chunk of its own and passing an empty hash ref for
the places to keep it and nothing for the last element. Both examples
use the same sub to do this work for you and all you need to do is
pass it the token for the main value and the seperator key and
optionally its value. You can easily make a variation that puts the
separator before the element and delete it from the first element.  If
your chunk has more tokens or nested chunks, this sub could be
generalized to modify a list of hashes instead of generating one.

=cut

print "\n******************\nSeparated List Expansion\n******************\n\n" ;


sub make_separated_data {
 	my( $token, $data, $delim_key, $delim ) = @_ ;

# make the delim set from the template (in a chunk) if not passed in
# an empty hash ref keeps the chunk text as is.

	$delim ||= {} ;

	my @list = map +{ $token => $_, $delim_key => $delim, }, @{$data} ;

# remove the separator from the last element

	delete $list[-1]{$delim_key} ;

	return \@list ;
}

my @data = qw( one two three four ) ;

$ts = Template::Simple->new(
	templates	=> {
		sep_tmpl	=> <<SEP_TMPL,
Number [%count%][%sep%]
SEP_TMPL
		sep_data	=> <<SEP_DATA,
Number [%count%][%start sep%],[%end sep%]
SEP_DATA
} ) ;

my $sep_tmpl = $ts->render( 'sep_tmpl',
	make_separated_data( 'count', \@data, 'sep', '--' ) ) ;

my $sep_data = $ts->render( 'sep_data',
	make_separated_data( 'count', \@data, 'sep', {} ) ) ;

print "SEP_DATA: [${$sep_data}]\n" ;
print "SEP_DATA: [${$sep_data}]\n" ;

exit ;
