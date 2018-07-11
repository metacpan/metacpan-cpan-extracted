package Template::Nest;

use strict;
use warnings;
use File::Spec;
use Carp;
use Data::Dumper;

our $VERSION = '0.04';

sub new{
	my ($class,%opts) = @_;
	my $self = {%opts};

	#defaults
    $self->{comment_delims} = [ '<!--','-->' ] unless $self->{comment_delims};
    $self->{token_delims} = [ '<%','%>' ] unless $self->{token_delims};
	$self->{name_label} = 'NAME' unless $self->{name_label};
    $self->{template_dir} = '' unless defined $self->{template_dir};
	$self->{template_ext} = '.html' unless defined $self->{template_ext};
	$self->{show_labels} = 0 unless defined $self->{show_labels};

	bless $self,$class;
	return $self;
}


sub template_dir{
	my($self,$dir) = @_;
	confess "Expected a scalar directory name but got a ".ref($dir) if $dir && ref($dir);
	$self->{template_dir} = $dir if $dir;
	return $self->{template_dir};
}


sub template_hash{
    my ($self,$template_hash) = @_;

    $self->{template_hash} = $template_hash if $template_hash;
    return $self->{template_hash};
}
	

sub comment_delims{
    my ($self,$delim1,$delim2) = @_;
    if (defined $delim1 ){
        $delim2 = $delim2 || '';
        $self->{'comment_delims'} = [ $delim1, $delim2 ];
    }
    return $self->{'comment_delims'};
}


sub token_delims{
    my ($self,$delim1,$delim2) = @_;
    
    if (defined $delim1 ){
        $delim2 = $delim2 || '';
        $self->{'token_delims'} = [ $delim1, $delim2 ];
    }
    return $self->{'token_delims'};
}


sub show_labels{
	my ($self,$show) = @_;
	confess "Expected a boolean but got $show" if $show && ! ( $show == 0 || $show == 1 );
	$self->{show_labels} = $show if defined $show;
	return $self->{show_labels};
}


sub template_ext{
	my ($self,$ext) = @_;
	confess "Expected a scalar extension name but got a ".ref($ext) if defined $ext && ref($ext);
	$self->{template_ext} = $ext if defined $ext;
	return $self->{template_ext};
}
	

sub name_label{
	my ($self,$label) = @_;
	confess "Expected a scalar name label but got a ".ref($label) if defined $label && ref($label);
	$self->{name_label} = $label if $label;
	return $self->{name_label};
}


sub render{
    my ($self,$comp) = @_;

    my $html;
    if ( ref($comp) =~ /array/i ){
        $html = $self->_render_array( $comp );
    } elsif( ref( $comp ) =~ /hash/i ){
        $html = $self->_render_hash( $comp );
    } else {
		$html = $comp;
    }

    return $html;
}



sub _render_hash{
    my ($self,$h) = @_;

    confess "Expected a hashref. Instead got a ".ref($h) unless ref($h) =~ /hash/i;

    my $template_name = $h->{ $self->name_label };

    confess 'Encountered hash with no name_label ("'.$self->name_label.'"): '.Dumper( $h ) unless $template_name;

    my $param = {};

    foreach my $k ( keys %$h ){
        next if $k eq $self->name_label;
        $param->{$k} = $self->render( $h->{$k} );
    }

    my $template = $self->_get_template( $template_name );
    my $html = $self->_fill_in( $template_name, $template, $param );

	if ( $self->show_labels ){

        my $ca = $self->{comment_delims}->[0];
        my $cb = $self->{comment_delims}->[1];

		$html = "$ca BEGIN $template_name $cb\n$html\n$ca END $template_name $cb\n";
	}

    return $html;

}




sub _render_array{

    my ($self, $arr, $delim) = @_;
    die "Expected an array. Instead got a ".ref($arr) unless ref($arr) =~ /array/i;
    my $html = '';
    foreach my $comp (@$arr){
        $html.= $delim if ($delim && $html);
        $html.= $self->render( $comp );
    }
    return $html;

}


sub _get_template{
    my ($self,$template_name) = @_;

    my $template = '';
    if ( $self->{template_hash} ){
        $template = $self->{template_hash}{$template_name};
    } else {

        my $filename = File::Spec->catdir(
            $self->template_dir,
            $template_name.$self->template_ext
        );

        my $fh;
        open $fh,'<',$filename or die "Could not open file $filename: $!";

        my $text = '';
        while( my $line = <$fh> ){
            $template.=$line;
        }

    }

    return $template;
}





sub _fill_in{
    my ($self,$template_name,$template,$param) = @_;


    my @frags = split( /\\\\/, $template );
    my $tda = $self->{token_delims}[0];
    my $tdb = $self->{token_delims}[1];

    foreach my $param_name (keys %$param){

        my $param_val = $param->{$param_name};
        
        my $replaced = 0;
        for my $i (0..$#frags){

            $replaced = 1 if $frags[$i] =~ s/(?<!\\)$tda\s*$param_name\s*$tdb/$param_val/g;

        }
        confess "Could not replace template param '$param_name': token does not exist in template '$template_name'" unless $replaced;

    }

    # replace any params that weren't specified with ''
    for my $i (0..$#frags){

        $frags[$i] =~ s/(?<!\\)$tda.*?$tdb//g;

    }

    for my $i (0..$#frags){
        $frags[$i] =~ s/\\//gs;
    }

    my $text = join('\\',@frags);

    return $text;

}

    
    




1;
__END__

=head1 NAME

Template::Nest - manipulate a generic template structure via a perl hash

=head1 SYNOPSIS

	page.html:
	<html>
		<head>
			<style>
				div { 
					padding: 20px;
					margin: 20px;
					background-color: yellow;
				}
			</style>
		</head>

		<body>
			<% contents %>
		</body>
	</html>
	 


	box.html:
	<div>
		<% title %>
	</div>


	use Template::Nest;

	my $page = {
		NAME => 'page',
		contents => [{
			NAME => 'box',
			title => 'First nested box'
		}]
	};

	push @{$page->{contents}},{
		NAME => 'box',
		title => 'Second nested box'
	};

	my $nest = Template::Nest->new(
		template_dir => '/html/templates/dir'
	);

	print $nest->render( $page );
  
	
	# output:

    <html>
	    <head>
		    <style>
			    div { 
				    padding: 20px;
				    margin: 20px;
				    background-color: yellow;
			    }
		    </style>
	    </head>

	    <body>	    
            <div>
	            First nested box
            </div>
            <div>
	            Second nested box
            </div>
	    </body>
    </html>

=head1 DESCRIPTION

This is L<HTML::Template::Nest>, but the dependency on C<HTML::Template> is dropped, and the module is made generic (ie not specific to C<HTML>) for the following reasons:

=over

=item 1

Given L<HTML::Template::Nest> only uses the C<TMPL_VAR> parameter from L<HTML::Template>, hauling around the rest of L<HTML::Template> is unnecessary baggage

=item 2

There's no reason to restrict this to C<HTML> either in name or function - this is a system of combining templates, which can be of any arbitrary format

=back


Let me take a moment to explain why I think L<Template::Nest> is the I<only> templating system that makes any sense.

The description for L<Text::Template> says the following in the C<Philosophy> section:

"When people make a template module like this one, they almost always start by inventing a special syntax for substitutions. For example, they build it so that a string like %%VAR%% is replaced with the value of $VAR. Then they realize the need extra formatting, so they put in some special syntax for formatting. Then they need a loop, so they invent a loop syntax. Pretty soon they have a new little template language.

This approach has two problems: First, their little language is crippled. If you need to do something the author hasn't thought of, you lose. Second: Who wants to learn another language? You already know Perl, so why not use it?"

These paragraphs agree with the philosophy of L<Template::Nest>, in that you shouldn't need to invent a new language to fill in templates. However, the L<Text::Template> description continues:

"Text::Template templates are programmed in Perl. You embed Perl code in your template, with { at the beginning and } at the end."

At this point the philosophy behind L<Text::Template> and L<Template::Nest> part ways. In the L<Template::Nest> philosophy I<templates are not "programmed" at all>. There should never be any code "embedded" in any template. Furthermore I<it is not a template if it has processing embedded in it>.

The L<Template::Nest> philosophy has the following:

=over

=item 1

Templates are nothing other than dull, inanimate pieces of text with holes in them to fill in, similar to children's colouring templates

=item 2

Templates have no intelligence and are not capable of formatting text, testing conditions or performing loops. This stuff is I<control> processing and should not occur in the template. Given that you already have text formatting, conditional processing and loops in the body of your code, why have any in your "template"? And how do you decide which of this processing goes in your template and which in the body of your code?

=item 3

By virtue of the above points, templates should be I<language independent>. They should not care which language is used to fill them in. You should be able to port your template library over from perl to python to java etc. without needing to rewrite anything in the library, such that they combine together in the same way to give the original output.

=back

I suggest that I<there is only one way> to solve the problem which adheres to points 1 to 3 (above). The overall template structure I<must> be provided to a builder which recursively fills in the template variables I<from the outside>. 

Just like a database, there must be only one particular "schema" of templates which suits a given situation (it must satisfy similar logical rules, such as "one table has many table rows" etc). And there is no room for variation within the templates, since they contain no processing. Thus there is only one way to solve the problem.

Thus C<Template::Nest> is the I<only templating system which makes sense>.

=over

=item *

Specify the structure including conditionals, loops, formatting in I<the code>.

=item *

Create all the templates that are needed so they can be repeated where necessary and filled in recursively

=back

=head2 An example

Lets say you have a template for a letter (if you can remember what that is!), and a template for an address. Using L<HTML::Template> you might do something like this:

    # in letter.html

    <TMPL_INCLUDE NAME="address.html">

    Dear <TMPL_VAR NAME=username>

    ....


However, in L<Template::Nest> there's no such thing as a C<TMPL_INCLUDE>, there are only tokens to fill in, so you would have

    # letter.html:

    <% address %>

    Dear <% username %>

    ...


I specify that I want to use C<address.html> when I fill out the template, thus:

    my $letter = {
        NAME => 'letter',
        username => 'billy',
        address => {
            NAME => 'address', # this specifies "address.html" 
                               # provided template_ext=".html"
            
            # variables in 'address.html'
        }
    };

    $nest->render( $letter );

This is much better, because now C<letter.html> is not hard-coded to use C<address.html>. You can decide to use a different address template without needing to change the letter template.

Commonly used template structures can be labelled (C<main_page> etc.) stored in your code in subs, hashes, Moose attributes or whatever method seems the most convenient.

=head2 Another example

The idea of a "template loop" comes from the need to e.g. fill in a table with an arbitrary number of rows. So using L<HTML::Template> you might do something like: 

    # in the template

    <table>
        <tr>
            <th>Name</th><th>Job</th>
        <tr>

        <TMPL_LOOP NAME=EMPLOYEE_INFO>
            <tr>
                <td><TMPL_VAR NAME=NAME></td>
                <td><TMPL_VAR NAME=JOB></td>
            </tr>
       </TMPL_LOOP>
    </table>

    # in the perl 

    $template->param(
        EMPLOYEE_INFO => [
            {name => 'Sam', job => 'programmer'}, 
            {name => 'Steve', job => 'soda jerk'}
        ]
    );
    print $template->output();

    # output 

    <table>

        <tr>
            <th>Name</th><th>Job</th>
        </tr>
        <tr>
            <td>Sam</td><td>programmer</td>
        </tr>
        <tr>
            <td>Steve</td><td>soda jerk</td>
        </tr>

    </table>

That's great - but why have the loop inside the template? If the table row is going to be repeated an arbitrary number of times, doesn't it make sense that this row should have its own template? In the L<Template::Nest> scheme, this would look like:

    # table.html:

    <table>
        <tr>
            <th>Name</th><th>Job</th>
        </tr>

        <!--% rows %-->

    </table>


    # table_row.html:

    <tr>
        <td><!--% name %--></td>
        <td><!--% job %--></td>
    </tr>


    # and in the Perl:

    my $table = {
        NAME => 'table',
        rows => [{
            NAME => 'table_row',
            name => 'Sam',
            job => 'programmer'
        }, {
            NAME => 'table_row',
            name => 'Steve',
            job => 'soda jerk'
        }]
    };

    my $nest = Template::Nest->new(
        token_delims => ['<!--%','%-->']
    );

    print $nest->render( $table );

Now the processing is entirely in the Perl. Of course, if you need to fill in your table rows using a loop, this is easy:

    my $rows = [];

    foreach my $item ( @data ){

        push @$rows, {
            NAME => 'table_row',
            name => $item->name,
            job => $item->job
        };

    }

    my $table = {

        NAME => 'table',
        rows => $rows

    };

    my $nest = Template::Nest->new(
        token_delims => ['<!--%','%-->']
    );

    print $nest->render( $table );


C<Template::Nest> is far simpler, and makes far more sense!


=head2 Some differences from L<HTML::Template::Nest>

=over

=item *

L<Template::Nest> introduces the ability to specify templates via a hashref, rather than assuming templates are stored in files in a specific directory. This could be useful if your templates are defined programmatically, or extracted from database fields etc. See the L<template_hash> method for more information.

=item *

L<Template::Nest> allows the tokens (to be replaced) to be specified in arbitrary format. ie. you can have tokens of format C<<% token_name %>>, C<[% token_name %]> - or whatever token delimiters suit your project.

=item *

The ugly C<TMPL_VAR> format of token used in L<HTML::Template> is abandoned - it is unnecessary since the other C<TMPL_IF>, C<TMPL_LOOP> etc. token types are not used. Token delimiters now default to the mason style delimiters (C<<%> and C<%>>) - but any arbitrary token delimiters can be set - see L<token_delims>.

=item *

Some minor renaming has taken place. In C<Html::Template::Nest> there were C<comment_tokens>. Moving forward I want to refer to C<tokens> as the things being replaced in the template. So C<comment_tokens> has become C<comment_delims> (and C<token_delims> has been introduced as above).

=item *

the method C<to_html> has been replaced by C<render> since L<Template::Nest> does not specifically deal with C<html> any more

=back

=head1 METHODS

=head2 new

constructor for a Template::Nest object. 

    my $nest = Template::Nest->new( %opts );

%opts can contain any of the methods Template::Nest accepts. For example you can do:

    my $nest = Template::Nest->new( template_dir => '/my/template/dir' );

or equally:

    my $nest = Template::Nest->new();
    $nest->template_dir( '/my/template/dir' );


=head2 name_label

The default is NAME (all-caps, case-sensitive). Of course if NAME is interpreted as the filename of the template, then you can't use NAME as one of the variables in your template. ie

    <% NAME %>

will never get populated. If you really are adamant about needing to have a template variable called 'NAME' - or you have some other reason for wanting an alternative label point to your template filename, then you can set name_label:

    $nest->name_label( 'GOOSE' );

    #and now

    my $component = {
        GOOSE => 'name_of_my_component'
        ...
    };


=head2 show_labels

Get/set the show_labels property. This is a boolean with default 0. Setting this to 1 results in adding comments to the output so you can identify which template output text came from. This is useful in development when you have many templates. E.g. adding 

    $nest->show_labels(1);

to the example in the synopsis results in the following:

    <!-- BEGIN page -->
    <html>
        <head>
            <style>
                div { 
                    padding: 20px;
                    margin: 20px;
                    background-color: yellow;
                }
            </style>
        </head>

        <body>
            
    <!-- BEGIN box -->
    <div>
        First nested box
    </div>
    <!-- END box -->

    <!-- BEGIN box -->
    <div>
        Second nested box
    </div>
    <!-- END box -->

        </body>
    </html>
    <!-- END page -->

What if you're not templating html, and you still want labels? Then you should set L<comment_delims> to whatever is appropriate for the thing you are templating.


=head2 token_delims

Get/set the delimiters that define a token (to be replaced). token_delims is a 2 element arrayref - corresponding to the opening and closing delimiters. For example

    $nest->token_delims( '[%', '%]' );

would mean that L<Template::Nest> would now recognise and interpolate tokens in the format

    [% token_name %]

The default token_delims are the mason style delimiters C<<%> and C<%>>. Note that for C<HTML> the token delimiters C<<!--%> and C<%-->> make a lot of sense, since they allow raw templates (ie that have not had values filled in) to render as good C<HTML>.


=head2 comment_delims

Use this in conjunction with show_labels. Get/set the delimiters used to define comment labels. Expects a 2 element arrayref. E.g. if you were templating javascript you could do:

    $nest->comment_delims( '/*', '*/' );
    
Now your output will have labels like

    /* BEGIN my_js_file */
    ...
    /* END my_js_file */


You can set the second comment token as an empty string if the language you are templating does not use one. E.g. for Perl:

    $nest->comment_delims([ '#','' ]);



=head2 template_dir

Get/set the dir where Template::Nest looks for your templates. E.g.

    $nest->template_dir( '/my/template/dir' );

Now if I have

    my $component = {
        NAME => 'hello',
        ...
    }

and template_ext = '.html', we'll expect to find the template at

    /my/template/dir/hello.html


Note that if you have some kind of directory structure for your templates (ie they are not all in the same directory), you can do something like this:

    my $component = {
        NAME => '/my/component/location',
        contents => 'some contents or other'
    };

Template::Nest will then prepend NAME with template_dir, append template_ext and look in that location for the file. So in our example if template_dir = '/my/template/dir' and template_ext = '.html' then the template file will be expected to exist at

/my/template/dir/my/component/location.html


Of course if you want components to be nested arbitrarily, it might not make sense to contain them in a prescriptive directory structure. 


=head2 template_ext

Get/set the template extension. This is so you can save typing your template extension all the time if it's always the same. The default is '.html' - however, there is no reason why this templating system could not be used to construct any other type of file (or why you could not use another extension even if you were producing html). So e.g. if you are wanting to manipulate javascript files:

    $nest->template_ext('.js');

then

    my $js_file = {
        NAME => 'some_js_file'
        ...
    }

So here HTML::Template::Nest will look in template_dir for 

some_js_file.js


If you don't want to specify a particular template_ext (presumably because files don't all have the same extension) - then you can do

    $nest->template_ext('');

In this case you would need to have NAME point to the full filename. ie

    $nest->template_ext('');

    my $component = {
        NAME => 'hello.html',
        ...
    }


=head2 render

Convert a template structure to output text. Expects a hashref containing hashrefs/arrayrefs/plain text.

e.g.

    widget.html:
    <div class='widget'>
        <h4>I am a widget</h4>
        <div>
            <!-- TMPL_VAR NAME=widget_body -->
        </div>
    </div>


    widget_body.html:
    <div>
        <div>I am the widget body!</div>    
        <div><!-- TMPL_VAR NAME=some_widget_property --></div>
    </div>


    my $widget = {
        NAME => 'widget',
        widget_body => {
            NAME => 'widget_body',
            some_widget_property => 'Totally useless widget'
        }
    };


    print $nest->render( $widget );


    #output:
    <div class='widget'>
        <h4>I am a widget</h4>
        <div>
            <div>
                <div>I am the widget body!</div>    
                <div>Totally useless widget</div>
            </div>
        </div>
    </div>


=head1 SEE ALSO

L<HTML::Template::Nest> L<HTML::Template> L<Text::Template>

=head1 AUTHOR

Tom Gracey tomgracey@gmail.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Tom Gracey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.

=cut




















