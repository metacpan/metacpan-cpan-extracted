package Template::Simple ;

use warnings ;
use strict ;

use Carp ;
use Data::Dumper ;
use Scalar::Util qw( reftype blessed ) ;
use File::Slurp ;

our $VERSION = '0.06';

my %opt_defaults = (

	pre_delim	=> qr/\[%/,
	post_delim	=> qr/%\]/,
	token_re	=> qr/\w+?/,
	greedy_chunk	=> 0,
#	upper_case	=> 0,
#	lower_case	=> 0,
	search_dirs	=> [ qw( templates ) ],
) ;

sub new {

	my( $class, %opts ) = @_ ;

	my $self = bless {}, $class ;

# get all the options or defaults into the object

# support the old name 'include_paths' ;

	$opts{search_dirs} ||= delete $opts{include_paths} ;

	while( my( $name, $default ) = each %opt_defaults ) {

		$self->{$name} = defined( $opts{$name} ) ? 
				$opts{$name} : $default ;
	}

	croak "search_dirs is not an ARRAY reference" unless
		ref $self->{search_dirs} eq 'ARRAY' ;

# make up the regexes to parse the markup from templates

# this matches scalar markups and grabs the name

	$self->{scalar_re} = qr{
		$self->{pre_delim}
		\s*			# optional leading whitespace
		($self->{token_re})	# grab scalar name
		\s*			# optional trailing whitespace
		$self->{post_delim}
	}xi ;				# case insensitive

#print "RE <$self->{scalar_re}>\n" ;

# this grabs the body of a chunk in either greedy or non-greedy modes

	my $chunk_body = $self->{greedy_chunk} ? qr/.+/s : qr/.+?/s ;

# this matches a marked chunk and grabs its name and text body

	$self->{chunk_re} = qr{
		$self->{pre_delim}
		\s*			# optional leading whitespace
		START			# required START token
		\s+			# required whitespace
		($self->{token_re})	# grab the chunk name
		\s*			# optional trailing whitespace
		$self->{post_delim}
		($chunk_body)		# grab the chunk body
		$self->{pre_delim}
		\s*			# optional leading whitespace
		END			# required END token
		\s+			# required whitespace
		\1			# match the grabbed chunk name
		\s*			# optional trailing whitespace
		$self->{post_delim}
	}xi ;				# case insensitive

#print "RE <$self->{chunk_re}>\n" ;

# this matches a include markup and grabs its template name

	$self->{include_re} = qr{
		$self->{pre_delim}
		\s*			# optional leading whitespace
		INCLUDE			# required INCLUDE token
		\s+			# required whitespace
		($self->{token_re})	# grab the included template name
		\s*			# optional trailing whitespace
		$self->{post_delim}
	}xi ;				# case insensitive

# load in any templates

	$self->add_templates( $opts{templates} ) ;

	return $self ;
}

sub compile {

	my( $self, $template_name ) = @_ ;

	my $tmpl_ref = eval {
		 $self->_get_template( $template_name ) ;
	} ;

#print Dumper $self ;

	croak "Template::Simple $@" if $@ ;

	my $included = $self->_render_includes( $tmpl_ref ) ;

# compile a copy of the template as it will be destroyed

	my $code_body = $self->_compile_chunk( '', "${$included}", "\t" ) ;

	my $source = <<CODE ;
no warnings ;

sub {
	my( \$data ) = \@_ ;

	my \$out ;

	use Scalar::Util qw( reftype ) ;

$code_body
	return \\\$out ;
}
CODE

#print $source ;

	my $code_ref = eval $source ;

#print $@ if $@ ;

	$self->{compiled_cache}{$template_name} = $code_ref ;
	$self->{source_cache}{$template_name} = $source ;
}

sub _compile_chunk {

	my( $self, $chunk_name, $template, $indent ) = @_ ;

	return '' unless length $template ;

# generate a lookup in data for this chunk name (unless it is the top
# level). this descends down the data tree during rendering

	my $data_init = $chunk_name ? "\$data->{$chunk_name}" : '$data' ;

	my $code = <<CODE ;
${indent}my \@data = $data_init ;
${indent}while( \@data ) {

${indent}	my \$data = shift \@data ;
${indent}	if ( reftype \$data eq 'ARRAY' ) {
${indent}		push \@data, \@{\$data} ;
${indent}		next ;
${indent}	}

CODE

	$indent .= "\t" ;

# loop all nested chunks and the text separating them

	while( my( $parsed_name, $parsed_body ) =
		$template =~ m{$self->{chunk_re}} ) {

		my $chunk_left_index = $-[0] ;
		my $chunk_right_index = $+[0] ;

# get the pre-match text and compile its scalars and text. append to the code

		$code .= $self->_compile_scalars(
			substr( $template, 0, $chunk_left_index ), $indent ) ;

# print "CHUNK: [$1] BODY [$2]\n\n" ;
# print "TRUNC: [", substr( $template, 0, $chunk_right_index ), "]\n\n" ;
# print "PRE: [", substr( $template, 0, $chunk_left_index ), "]\n\n" ;

# chop off the pre-match and the chunk

		substr( $template, 0, $chunk_right_index, '' ) ;

# print "REMAIN: [$template]\n\n" ;

# compile the nested chunk and append to the code

		$code .= $self->_compile_chunk(
				$parsed_name, $parsed_body, $indent
		) ;
	}

# compile trailing text for scalars and append to the code

	$code .= $self->_compile_scalars( $template, $indent ) ;

	chop $indent ;

# now we end the loop for this chunk
	$code .= <<CODE ;
$indent}
CODE

	return $code ;
}

sub _compile_scalars {

	my( $self, $template, $indent ) = @_ ;

# if the template is empty return no parts

	return '' unless length $template ;

	my @parts ;

	while( $template =~ m{$self->{scalar_re}}g ) {

# get the pre-match text before the scalar markup and generate code to
# access the scalar

		push( @parts,
			_dump_text( substr( $template, 0, $-[0] ) ),
			"\$data->{$1}"
		) ;

# truncate the matched text so the next match starts at begining of string

		substr( $template, 0, $+[0], '' ) ;
	}

# keep any trailing text part

	push @parts, _dump_text( $template ) ;

	my $parts_code = join( "\n$indent.\n$indent", @parts ) ;

	return <<CODE ;

${indent}\$out .= reftype \$data ne 'HASH' ? \$data :
${indent}$parts_code ;

CODE
}


# internal sub to dump text for the template compiler.  the output is
# a legal perl double quoted string without any leading text before
# the opening " and no trailing newline or ;

sub _dump_text {

	my( $text ) = @_ ;

	return unless length $text ;

	local( $Data::Dumper::Useqq ) = 1 ;

	my $dumped = Dumper $text ;

	$dumped =~ s/^[^"]+// ;
	$dumped =~ s/;\n$// ;

	return $dumped ;
}

sub get_source {

	my( $self, $template_name ) = @_ ;

	return $self->{source_cache}{$template_name} ;
}

sub render {

	my( $self, $template_name, $data ) = @_ ;

	my $tmpl_ref = ref $template_name eq 'SCALAR' ? $template_name : '' ;

	unless( $tmpl_ref ) {

# render with cached code and return if we precompiled this template

		if ( my $compiled = $self->{compiled_cache}{$template_name} ) {

			return $compiled->($data) ;
		}

# not compiled so try to get this template by name or
# assume the template name are is the actual template

		$tmpl_ref =
			eval{ $self->_get_template( $template_name ) } ||
			\$template_name ;
	}

	my $rendered = $self->_render_includes( $tmpl_ref ) ;

#print "INC EXP <$rendered>\n" ;

	$rendered = eval {
		 $self->_render_chunk( $rendered, $data ) ;
	} ;

	croak "Template::Simple $@" if $@ ;

	return $rendered ;
}

sub _render_includes {

	my( $self, $tmpl_ref ) = @_ ;

# make a copy of the initial template so we can render it.

	my $rendered = ${$tmpl_ref} ;

# loop until we can render no more include markups

	1 while $rendered =~
		 s{$self->{include_re}}{ ${ $self->_get_template($1) }}e ;

	return \$rendered ;
}

my %renderers = (

	SCALAR	=> sub { return $_[2] },
	''	=> sub { return \$_[2] },
	HASH	=> \&_render_hash,
	ARRAY	=> \&_render_array,
	CODE	=> \&_render_code,
# if no ref then data is a scalar so replace the template with just the data
) ;


sub _render_chunk {

	my( $self, $tmpl_ref, $data ) = @_ ;

#print "T ref [$tmpl_ref] [$$tmpl_ref]\n" ;
#print "CHUNK ref [$tmpl_ref] TMPL\n<$$tmpl_ref>\n" ;

#print Dumper $data ;

	return \'' unless defined $data ;

# get the type of this data. handle blessed types

	my $reftype = blessed( $data ) ;

#print "REF $reftype\n" ;

# handle the case of a qr// which blessed returns as Regexp

	if ( $reftype ) {

		$reftype = reftype $data unless $reftype eq 'Regexp' ;
	}
	else {
		$reftype = ref $data ;
	}

#print "REF2 $reftype\n" ;

# now render this chunk based on the type of data

	my $renderer = $renderers{ $reftype || ''} ;

#print "EXP $renderer\nREF $reftype\n" ;

	croak "unknown template data type '$data'\n" unless defined $renderer ;

	return $self->$renderer( $tmpl_ref, $data ) ;
}

sub _render_hash {

	my( $self, $tmpl_ref, $href ) = @_ ;

	return $tmpl_ref unless keys %{$href} ;

# we need a local copy of the template to render

	my $rendered = ${$tmpl_ref}	 ;

# recursively render all top level chunks in this chunk

	$rendered =~ s{$self->{chunk_re}}
		      {
			# print "CHUNK $1\nBODY\n----\n<$2>\n\n------\n" ;
#			print "CHUNK $1\nBODY\n----\n<$2>\n\n------\n" ;
#			print "pre CHUNK [$`]\n" ;
			${ $self->_render_chunk( \"$2", $href->{$1} ) }
		      }gex ;

# now render scalars

#print "HREF: ", Dumper $href ;

	$rendered =~ s{$self->{scalar_re}}
		      {
			 # print "SCALAR $1 VAL $href->{$1}\n" ;
			 defined $href->{$1} ? $href->{$1} : ''
		      }ge ;

#print "HASH REND3\n<$rendered>\n" ;

	return \$rendered ;
}

sub _render_array {

	my( $self, $tmpl_ref, $aref ) = @_ ;

# render this $tmpl_ref for each element of the aref and join them

	my $rendered ;

#print "AREF: ", Dumper $aref ;

	$rendered .= ${$self->_render_chunk( $tmpl_ref, $_ )} for @{$aref} ;

	return \$rendered ;
}

sub _render_code {

	my( $self, $tmpl_ref, $cref ) = @_ ;

	my $rendered = $cref->( $tmpl_ref ) ;

	croak <<DIE if ref $rendered ne 'SCALAR' ;
data callback to code didn't return a scalar or scalar reference
DIE

	return $rendered ;
}

sub add_templates {

	my( $self, $tmpls ) = @_ ;

#print Dumper $tmpls ;
	return unless defined $tmpls ;

 	ref $tmpls eq 'HASH' or croak "templates argument is not a hash ref" ;

# copy all the templates from the arg hash and force the values to be
# scalar refs

	while( my( $name, $tmpl ) = each %{$tmpls} ) {

		defined $tmpl or croak "undefined template value for '$name'" ;

# cache the a scalar ref of the template

		$self->{tmpl_cache}{$name} = ref $tmpl eq 'SCALAR' ?
			\"${$tmpl}" : \"$tmpl"
	}

#print Dumper $self->{tmpl_cache} ;

	return ;
}

sub delete_templates {

	my( $self, @names ) = @_ ;

# delete all the cached stuff or just the names passed in

	@names = keys %{$self->{tmpl_cache}} unless @names ;

#print "NAMES @names\n" ;
# clear out all the caches
# TODO: reorg these into a hash per name

	delete @{$self->{tmpl_cache}}{ @names } ;
	delete @{$self->{compiled_cache}}{ @names } ;
	delete @{$self->{source_cache}}{ @names } ;

# also remove where we found it to force a fresh search

	delete @{$self->{template_paths}}{ @names } ;

	return ;
}

sub _get_template {

	my( $self, $tmpl_name ) = @_ ;

#print "INC $tmpl_name\n" ;

	my $tmpls = $self->{tmpl_cache} ;

# get the template from the cache and send it back if it was found there

	my $template = $tmpls->{ $tmpl_name } ;
	return $template if $template ;

# not found, so find, slurp in and cache the template

	$template = $self->_find_template( $tmpl_name ) ;
	$tmpls->{ $tmpl_name } = $template ;

	return $template ;
}

sub _find_template {

	my( $self, $tmpl_name ) = @_ ;

#print "FIND $tmpl_name\n" ;
	foreach my $dir ( @{$self->{search_dirs}} ) {

		my $tmpl_path = "$dir/$tmpl_name.tmpl" ;

#print "PATH: $tmpl_path\n" ;

		next if $tmpl_path =~ /\n/ ;
		next unless -r $tmpl_path ;

# cache the path to this template

		$self->{template_paths}{$tmpl_name} = $tmpl_path ;

# slurp in the template file and return it as a scalar ref

#print "FOUND $tmpl_name\n" ;

		return read_file( $tmpl_path, scalar_ref => 1 ) ;
	}

#print "CAN'T FIND $tmpl_name\n" ;

	croak <<DIE ;
can't find template '$tmpl_name' in '@{$self->{search_dirs}}'
DIE

}

1; # End of Template::Simple

__END__

=head1 NAME

Template::Simple - A simple and very fast template module

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Template::Simple;

    my $tmpl = Template::Simple->new();

  # here is a simple template store in a scalar
  # the header and footer templates will be included from the cache or files.

    my $template_text = <<TMPL ;
[%INCLUDE header%]
[%START row%]
	[%first%] - [%second%]
[%END row%]
[%INCLUDE footer%]
TMPL

  # this is data that will be used to render that template the keys
  # are mapped to the chunk names (START & END markups) in the
  # template the row is an array reference so multiple rows will be
  # rendered usually the data tree is generated by code instead of
  # being pure data.

    my $data = {
	header	=> {
		date	=> 'Jan 1, 2008',
		author	=> 'Me, myself and I',
	},
	row	=> [
		{
			first	=> 'row 1 value 1',
			second	=> 'row 1 value 2',
		},
		{
			first	=> 'row 2 value 1',
			second	=> 'row 2 value 2',
		},
	],
	footer	=> {
		modified	=> 'Aug 31, 2006',
	},
    } ;

  # this call renders the template with the data tree

    my $rendered = $tmpl->render( \$template_text, $data ) ;

  # here we add the template to the cache and give it a name

    $tmpl->add_templates( { demo => $template_text } ) ;

  # this compiles and then renders that template with the same data
  # but is much faster

    $tmpl->compile( 'demo' ) ;
    my $rendered = $tmpl->render( 'demo', $data ) ;


=head1 DESCRIPTION

Template::Simple is a very fast template rendering module with a
simple markup. It can do almost any templating task and is extendable
with user callbacks. It can render templates directly or compile them
for more speed.

=head1 CONSTRUCTOR

=head2	new
 
You create a Template::Simple by calling the class method new:

	my $tmpl = Template::Simple->new() ;

All the arguments to C<new()> are key/value options that change how
the object will render templates.

=head2	pre_delim

This option sets the string or regex that is the starting delimiter
for all markups. You can use a plain string or a qr// but you need to
escape (with \Q or \) any regex metachars if you want them to be plain
chars. The default is qr/\[%/.

	my $tmpl = Template::Simple->new(
		pre_delim => '<%',
	);

	my $rendered = $tmpl->render( '<%FOO%]', 'bar' ) ;

=head2	post_delim

This option sets the string or regex that is the ending delimiter
for all markups. You can use a plain string or a qr// but you need to
escape (with \Q or \) any regex metachars if you want them to be plain
chars. The default is qr/%]/.

	my $tmpl = Template::Simple->new(
		post_delim => '%>',
	);

	my $rendered = $tmpl->render( '[%FOO%>', 'bar' ) ;

=head2  token_re

This option overrides the regular expression that is used match a
token or name in the markup. It should be a qr// and you may need to
escape (with \Q or \) any regex metachars if you want them to be plain
chars. The default is qr/\w+?/.

	my $tmpl = Template::Simple->new(
		token_re => qr/[\w-]+?/,
	);

	my $rendered = $tmpl->render(
		'[% id-with-hyphens %]',
		{ 'id-with-hyphens' => 'bar' }
	) ;

=head2	greedy_chunk

This boolean option will cause the regex that grabs a chunk of text
between the C<START/END> markups to become greedy (.+). The default is
a not-greedy grab of the chunk text. (UNTESTED)

=head2	templates

This option lets you load templates directly into the cache of the
Template::Simple object. See <TEMPLATE CACHE> for more on this.

	my $tmpl = Template::Simple->new(
		templates	=> {
			foo	=> <<FOO,
[%baz%] is a [%quux%]
FOO
			bar	=> <<BAR,
[%user%] is not a [%fool%]
BAR
		},
	);

=head2	search_dirs, include_paths

This option lets you set the directory paths to search for template
files. Its value is an array reference with the paths. Its default is
'templates'.

	my $tmpl = Template::Simple->new(
			search_dirs => [ qw(
				templates
				templates/deeper
			) ],
	) ;

NOTE: This option was called C<include_paths> but since it is used to
locate named templates as well as included ones, it was changed to
C<search_dirs>. The older name C<include_paths> is still supported
but new code should use C<search_dirs>.

=head1 METHODS

=head2 render

This method is passed a template and a data tree and it renders it and
returns a reference to the resulting string.

If the template argument is a scalar reference, then it is the
template text to be rendered. A scalar template argument is first
assumed to be a template name which is searched for in the template
cache and the compiled template caches. If found in there it is used
as the template. If not found there, it is searched for in the
directories of the C<search_dirs>. Finally if not found, it will be
used as the template text.

The data tree argument can be any value allowed by Template::Simple
when rendering a template. It can also be a blessed reference (Perl
object) since C<Scalar::Util::reftype> is used instead of C<ref> to
determine the data type.

Note that the author recommends against passing in an object as this
breaks encapsulation and forces your object to be (most likely) a
hash. It would be better to create a simple method that copies the
object contents to a hash reference and pass that. But other current
templaters allow passing in objects so that is supported here as well.

    my $rendered = $tmpl->render( $template, $data ) ;

=head2 compile

This method takes a template and compiles it to make it run much
faster. Its only argument is a template name and that is used to
locate the template in the object cache or it is loaded from a file
(with the same search technique as regular rendering). The compiled
template is stored in its own cache and can be rendered by a call to
the render method and passing the name and the data tree.

    $tmpl->compile( 'foo' ) ;
    my $rendered = $tmpl->render( 'foo', $data ) ;

There are a couple of restrictions to compiled templates. They don't
support code references in the data tree (that may get supported in
the future). Also since the include expansion happens one time during
the compiling, any changes to the template or its includes will not be
detected when rendering a compiled template. You need to re-compile a
template to force it to use changed templates. Note that you may need
to delete templates from the object cache (with the delete_templates
method) to force them to be reloaded from files.

=head2 add_templates

This method adds templates to the object cache. It takes a list of
template names and texts just like the C<templates> constructor
option. These templates are located by name when compiling or
rendering.

	$tmpl->add_templates( 
		{
			foo	=> \$foo_template,
			bar	=> '[%include bar%]',
		}
	) ;

=head2 delete_templates

This method takes a list of template names and will delete them from
the template cache in the object. If you pass no arguments then all
the cached templates will be deleted. This can be used when you know
a template file has been updated and you want to get it loaded back
into the cache. 

    # this deletes only the foo and bar templates from the object cache

	$tmpl->delete_templates( qw( foo bar ) ;

    # this deletes all of templates from the object cache

	$tmpl->delete_templates() ;

=head2 get_source

	$tmpl->get_source( 'bar' ) ;

This method is passed a compiled template name and returns the
generated Perl source for a compiled template. You can compile a
template and paste the generated source (a single sub per template)
into another program. The sub can be called and passed a data tree and
return a rendered template. It saves the compile time for that
template but it still needs to be compiled by Perl. This method is
also useful for debugging the template compiler.

=head1 TEMPLATE CACHE

This cache is stored in the object and will be searched to find any
template by name. It is initially loaded via the C<templates> option
to new and more can be added with the C<add_templates> method. You can
delete templates from the cache with the C<delete_templates>
method. Compiled templates have their own cache in the
module. Deleting a template also deletes it from the compiled cache.

=head1 INCLUDE EXPANSION

Before a template is either rendered or compiled it undergoes include
expansion. All include markups are replaced by a templated located in
the cache or from a file. Included templates can include other
templates. This expansion keeps going until no more includes are
found.

=head1 LOCATING TEMPLATES 

When a template needs to be loaded by name (when rendering, compiling
or expanding includes) it is first searched for in the object cache
(and the compiled cache for compiled templates). If not found there,
the C<templates_paths> are searched for files with that name and a
suffix of .tmpl. If a file is found, it used and also loaded into the
template cache in the object with the searched for name as its key.

=head1 MARKUP

All the markups in Template::Simple use the same delimiters which are
C<[%> and C<%]>. You can change the delimiters with the C<pre_delim>
and C<post_delim> options in the C<new()> constructor.

=head2 Tokens

A token is a single markup with a C<\w+> Perl word inside. The token
can have optional whitespace before and after it. A token is replaced
by a value looked up in a hash with the token as the key. The hash
lookup keeps the same case as parsed from the token markup. You can
override the regular expression used to match a token with the
C<token_re> option.

    [% foo %] [%BAR%]

Those will be replaced by C<$href->{foo}> and C<$href->{BAR}> assuming
C<$href> is the current data for this rendering. Tokens are only
parsed out during hash data rendering so see Hash Data for more.

=head2 Chunks

Chunks are regions of text in a template that are marked off with a
start and end markers with the same name. A chunk start marker is
C<[%START name%]> and the end marker for that chunk is C<[%END
name%]>. C<name> is matched with C<\w+?> and that is the name of this
chunk. The whitespace between C<START/END> and C<name> is required and
there is optional whitespace before C<START/END> and after the
C<name>. C<START/END> are case insensitive but the C<name>'s case is
kept.  Chunks are the primary way to markup templates for structures
(sets of tokens), nesting (hashes of hashes), repeats (array
references) and callbacks to user code.  By default a chunk will be a
non-greedy grab but you can change that in the constructor by enabling
the C<greedy_chunk> option.  You can override the regular expression
used to match the chunk name with the C<token_re> option.

    [%Start FOO%]
	[% START bar %]
		[% field %]
	[% end bar %]
    [%End FOO%]

=head2 Includes

When a markup C<[%include name%]> is seen, that text is replaced by
the template of that name. C<name> is matched with C<\w+?> which is
the name of the template. You can override the regular expression used
to match the include C<name> with the C<token_re> option.

See C<INCLUDE EXPANSION> for more on this.

=head1 RENDERING RULES

Template::Simple has a short list of rendering rules and they are easy
to understand. There are two types of renderings, include rendering
and chunk rendering. In the C<render> method, the template is an
unnamed top level chunk of text and it first gets its C<INCLUDE>
markups rendered. The text then undergoes a chunk rendering and a
scalar reference to that rendered template is returned to the caller.

=head2 Include Rendering

All include file rendering happens before any other rendering is
done. After this phase, the rendered template will not have
C<[%include name%]> markups in it.

=head2 Chunk Rendering

A chunk is the text found between matching C<START> and C<END> markups
and it gets its name from the C<START> markup. The top level template
is considered an unamed chunk and also gets chunk rendered.

The data for a chunk determines how it will be rendered. The data can
be a scalar or scalar reference or an array, hash or code
reference. Since chunks can contain nested chunks, rendering will
recurse down the data tree as it renders the chunks.  Each of these
renderings are explained below. Also see the IDIOMS and BEST PRACTICES
section for examples and used of these renderings.

=over 4

=item Hash Data Rendering

If the current data for a chunk is a hash reference then two phases of
rendering happen, nested chunk rendering and token rendering. First
nested chunks are parsed of of this chunk along with their names. Each
parsed out chunk is rendered based on the value in the current hash
with the nested chunk's name as the key.

If a value is not found (undefined), then the nested chunk is replaced
by the empty string. Otherwise the nested chunk is rendered according
to the type of its data (see chunk rendering) and it is replaced by
the rendered text.

Chunk name and token lookup in the hash data is case sensitive.

Note that to keep a plain text chunk or to just have the all of its
markups (chunks and tokens) be deleted just pass in an empty hash
reference C<{}> as the data for the chunk. It will be rendered but all
markups will be replaced by the empty string.

The second phase is token rendering. Markups of the form [%token%] are
replaced by the value of the hash element with the token as the
key. If a token's value is not defined it is replaced by the empty
string. This means if a token key is missing in the hash or its value
is undefined or its value is the empty string, the [%token%] markup
will be deleted in the rendering.

=item Array Data Rendering

If the current data for a chunk is an array reference it will do a
full chunk rendering for each value in the array. It will replace the
original chunk text with the concatenated list of rendered
chunks. This is how you do repeated sections in Template::Simple and
why there is no need for any loop markups. Note that this means that
rendering a chunk with $data and [ $data ] will do the exact same
thing. A value of an empty array C<[]> will cause the chunk to be
replaced by the empty string.

=item Scalar Data Rendering

If the current data for a chunk is a scalar or scalar reference, the
entire chunk is replaced by the scalar's value. This can be used to
overwrite one default section of text with from the data tree.

=item Code Data Rendering

If the current data for a chunk is a code reference (also called
anonymous sub) then the code reference is called and it is passed a
scalar reference to the that chunk's text. The code must return a
scalar or a scalar reference and its value replaces the chunk's text
in the template. If the code returns any other type of data it is a
fatal error. Code rendering is how you can do custom renderings and
plugins. A key idiom is to use closures as the data in code renderings
and keep the required outside data in the closure.

=back

=head1 DESIGN GOALS

=over 4

=item * High speed

When using compiled templates T::S is one of the fastest template
tools around. There is a benchmark script in the extras/ directory
comparing it to Template `Toolkit and Template::Teeny

=item * Support most common template operations

It can recursively include other templates, replace tokens (scalars),
recursively render nested chunks of text and render lists. By using
simple idioms you can get conditional renderings.

=item * Complete isolation of template from program code

Template design and programming the data logic can be done by
different people. Templates and data logic can be mixed and matched
which improves reuse and flexibility.

=item * Very simple template markup (only 4 markups)

The only markups are C<INCLUDE>, C<START>, C<END> and C<token>. See
MARKUP for more.

=item * Easy to follow rendering rules

Rendering of templates and chunks is driven from a data tree. The type
of the data element used in an rendering controls how the rendering
happens.  The data element can be a scalar, scalar reference, or an
array, hash or code reference.

=item * Efficient template rendering

Rendering is very simple and uses Perl's regular expressions
efficiently. Because the markup is so simple less processing is needed
than many other templaters. You can precompile templates for even
faster rendering but with some minor restrictions in flexibility

=item * Easy user extensions

User code can be called during an rendering so you can do custom
renderings and plugins. Closures can be used so the code can have its
own private data for use in rendering its template chunk.

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-template-simple at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Simple>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Simple>

=back

=head1 ACKNOWLEDGEMENTS

I wish to thank Turbo10 for their support in developing this module.

=head2 LICENSE

  Same as Perl.

=head1 COPYRIGHT

Copyright 2011 Uri Guttman, all rights reserved.

=head2 SEE ALSO

An article on file slurping in extras/slurp_article.pod. There is
also a benchmarking script in extras/slurp_bench.pl.

=head1 AUTHOR

Uri Guttman, E<lt>uri@stemsystems.comE<gt>

=cut
