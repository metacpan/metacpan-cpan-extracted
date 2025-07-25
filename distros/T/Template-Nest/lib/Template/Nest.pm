package Template::Nest;

use strict;
use warnings;
use File::Spec;
use Carp;
use Data::Dumper;

our $VERSION = '0.12';

sub new{
	my ($class,%opts) = @_;


    # defaults:
    my $self = {
        comment_delims => [ '<!--','-->' ],
        token_delims => [ '<%','%>' ],
        name_label => 'NAME',
        template_dir => '',
        template_ext => '.html',
        show_labels => 0,
        defaults => {},
        defaults_namespace_char => '.',
        fixed_indent => 0,
        die_on_bad_params => 1,
        escape_char => "\\",
        token_placeholder => '',
    };

	bless $self,$class;

    if ( %opts ){
        for my $k (keys %opts){
            confess "$k is not a valid option" unless defined $self->can($k);
            $self->$k( $opts{$k} );
        }
    }

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


sub defaults{
    my ($self,$defaults) = @_;

    if ( $defaults ){

        confess "defaults should be a hashref" unless ref $defaults eq ref {};
        $self->{defaults} = $defaults;

    }

    return $self->{defaults};
}

sub token_placeholder{
    my ($self,$token) = @_;

    if (defined $token){
        $self->{token_placeholder} = $token;
    }
    return $self->{token_placeholder};
}

sub defaults_namespace_char{
    my ($self,$char) = @_;

    if ( defined $char ){
        if ( $char eq '' ){
            $self->{defaults_namespace_char} = '';
        } else {
            confess "defaults_namespace_char should be a single character or ''" unless $char =~ /./;
            $self->{defaults_namespace_char} = $char;
        }
    }

    return $self->{defaults_namespace_char};
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

        if ( ref $delim1 eq ref [] ){
            ($delim1,$delim2) = @$delim1;
        }

        $delim2 ||= '';
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


sub fixed_indent{
    my ($self,$indent) = @_;

    if ( defined $indent ){
        confess "Expected 0 or 1 but got $indent" unless $indent == 0 or $indent == 1;
        $self->{fixed_indent} = $indent;
    }

    return $self->{fixed_indent};
}


sub die_on_bad_params{
    my ($self,$should_die) = @_;

    if ( defined $should_die ){
        confess "Expected 0 or 1 but got $should_die" unless $should_die == 0 or $should_die == 1;
        $self->{die_on_bad_params} = $should_die;
    }

    return $self->{die_on_bad_params};
}



sub escape_char{
    my ($self,$char) = @_;

    if (defined $char){
        confess "escape_char should be a single character or ''" unless $char eq '' or $char =~ /./;
        $self->{escape_char} = $char;
    }

    return $self->{escape_char};
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
    confess "Expected an array. Instead got a ".ref($arr) unless ref($arr) =~ /array/i;
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
        open $fh,'<',$filename or confess "Could not open file $filename: $!";

        my $text = '';
        while( my $line = <$fh> ){
            $template.=$line;
        }

    }

    $template =~ s/\n$//;
    return $template;
}




sub params{
    my ($self,$template_name) = @_;

    my $esc = $self->{escape_char};
    my $template = $self->_get_template( $template_name );
    my @frags = split( /\Q$esc$esc\E/, $template );
    my $tda = $self->{token_delims}[0];
    my $tdb = $self->{token_delims}[1];

    my %rem;
    for my $i (0..$#frags){
        my @f = $frags[$i] =~ m/(?<!\Q$esc\E)\Q$tda\E(.*?)\Q$tdb\E/g;
        for my $f ( @f ){
            $f =~ s/^\s*//;
            $f =~ s/\s*$//;
            $rem{$f} = 1;
        }
    }

    my @params = sort(keys %rem);
    return \@params;
}



sub _token_regex{
    my ($self,$param_name) = @_;

    my $esc = $self->{escape_char};
    my $tda = $self->{token_delims}[0];
    my $tdb = $self->{token_delims}[1];

    $param_name = '.*?' unless defined $param_name;

    my $token_regex = qr/\Q$tda\E\s+$param_name\s+\Q$tdb\E/;
    if ( $esc ){
        $token_regex = qr/(?<!\Q$esc\E)($token_regex)/;
    }
    return $token_regex;
}


sub _fill_in{
    my ($self,$template_name,$template,$params) = @_;

    my $esc = $self->{escape_char};
    my @frags;

    if ( $esc ){
        @frags = split( /\Q$esc$esc\E/, $template );
    } else {
        @frags = ( $template );
    }

    foreach my $param_name (keys %$params){

        my $param_val = $params->{$param_name};

        my $replaced = 0;

        if ( $self->{fixed_indent} ){ #if fixed_indent we need to add spaces during the replacement
            for my $i (0..$#frags){
                my $rx = $self->_token_regex( $param_name );
                my @spaces_repl = $frags[$i] =~ m/([^\S\r\n]*)$rx/g;

                while(@spaces_repl){
                    my $sp = shift @spaces_repl;
                    my $repl = shift @spaces_repl;
                    my $param_out = $param_val;
                    $param_out =~ s/\n/\n$sp/g;

                    if ( $esc ){
                        $replaced = 1 if $frags[$i] =~ s/(?<!\Q$esc\E)\Q$repl\E/$param_out/;
                    } else {
                        $replaced = 1 if $frags[$i] =~ s/\Q$repl\E/$param_out/;
                    }
                }
            }
        } else {
            for my $i (0..$#frags){
                my $rx = $self->_token_regex( $param_name );
                $replaced = 1 if $frags[$i] =~ s/$rx/$param_val/g;
            }
        }

        if ( $self->{die_on_bad_params} && $replaced == 0 ){
            confess "Could not replace template param '$param_name': token does not exist in template '$template_name'";
        }
    }

    for my $i (0..$#frags){

        if ( %{$self->{defaults}} ){
            my @rem = $self->_params_in( $frags[$i] );
            my $char = $self->defaults_namespace_char;
            for my $name ( @rem ){
                my @parts = ( $name );
                @parts = split( /\Q$char\E/, $name ) if $char;

                my $val = $self->_get_default_val( $self->{defaults}, @parts );
                my $rx = $self->_token_regex( $name );
                $frags[$i] =~ s/$rx/$val/g;
            }
        }

        # Handle unmatched parameters, if token_placeholder is set then
        # we replace these parameters with the placeholder.
        if ($self->{token_placeholder}) {
            my $param_rx = $self->_token_regex("param_name");

            my @rem = $self->_params_in( $frags[$i] );
            for my $name ( @rem ) {
                my @parts = ( $name );

                my $placeholder = $self->{token_placeholder};
                $placeholder =~ s/$param_rx/$name/g;

                my $rx = $self->_token_regex( $name );
                $frags[$i] =~ s/$rx/$placeholder/g;
            }
        }

        my $rx = $self->_token_regex;
        $frags[$i] =~ s/$rx//g;
    }

    if ( $esc ){
        for my $i (0..$#frags){
            $frags[$i] =~ s/\Q$esc\E//gs;
        }
    }

    my $text = $esc? join($esc,@frags): $frags[0];
    return $text;
}


sub _params_in{
    my ( $self, $text ) = @_;

    my $esc = $self->{escape_char};
    my $tda = $self->token_delims->[0];
    my $tdb = $self->token_delims->[1];

    my @rem;
    if ( $esc ){
        @rem = $text =~ m/(?<!\Q$esc\E)\Q$tda\E\s+(.*?)\s+\Q$tdb\E/g;
    } else {
        @rem = $text =~ m/\Q$tda\E\s+(.*?)\s+\Q$tdb\E/g;
    }

    my %rem;
    for my $name (@rem){
        $rem{$name} = 1
    }

    return keys %rem;
}



sub _get_default_val{
    my ($self,$ref,@parts) = @_;

    if ( @parts == 1 ){
        my $val = $ref->{$parts[0]} || '';
        return $val;
    } else {
        my $ref_name = shift @parts;
        my $new_ref = $ref->{ $ref_name };
        return '' unless $new_ref;
        return $self->_get_default_val( $new_ref, @parts );
    }
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
		template_dir => '/html/templates/dir',
        fixed_indent => 1
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

There are a wide number of templating options out there, and many are far more longstanding than L<Template::Nest>. However, his module takes a different approach to many other systems, and in the author's opinion this results in a better separation of "control" from "view".

The philosophy behind this module is simple: don't allow any processing of any kind in the template. Treat templates as dumb pieces of text which only have holes to be filled in. No template loops, no template ifs etc. Regard ifs and loops as control processing, which should be in your main code and not in your templates.

One effect of this is to make your templates language independent. If you use L<Text::Template> then you embed Perl inside your template, which would make using the same templates on e.g. a Java based system impossible. If you use one of the many modules that have invented their own templating "language" - such as Template Toolkit - you are going to have to learn that language I<as well as> having the language dependence problem.

Worse than that, if you can have processing inside your template, how do you decide which goes where? Exactly what criteria do you use to decide what should be "template processing" and what should be "program processing"? How easy is it then going to be for a newcomer to understand how your system works with logic spread all over the place?

Lets go one step further to hammer home the point. Say you use Template Toolkit to template HTML. What kind of file is your template? Well, it's a C<.tt2>. What is that exactly? Well it's not an .html file, and nor is it a program. If you want visibility on what's in it, you're going to have to pick your way through the code, because you can't run it standalone, and it won't display in a browser.

Indeed if templates have any kind of processing at all on board, I put it to you that they B<aren't templates> at all. (You wouldn't call a PHP script a template, would you?)

The L<Template::Nest> philosophy is that if you are templating something, your templates should be little chunks of that something, and nothing more. So when templating html, each template should be a standalone chunk of html, you can save it with file extension .html, and you can go ahead and display it standalone in a browser.

Personally I have never liked complex templating systems like Mason, Template Toolkit etc. - I am forced to put up with them because of their near-ubiquity, but in my experience their usage often leads to some truly outrageous messes. I don't think this is surprising, because with processing in your template, how can you really have MVC? "Control" and "View" are not separate.


=head2 L<Template::Nest> vs L<HTML::Template::Nest> vs L<HTML::Template>

I initially chose L<HTML::Template> for my own projects because it can be used simply with the C<TMPL_VAR> tag. Slot all your templates together in your code, fill in the template parameters, and you have a straightforward templating system which doesn't violate MVC.

So I originally wrote L<HTML::Template::Nest> as a wrapper around L<HTML::Template>. But since L<HTML::Template::Nest> only uses the C<TMPL_VAR> tag (and not C<TMPL_LOOP>, C<TMPL_IF> etc.) why bother with the L<HTML::Template> dependency at all? So L<Template::Nest> was born.

(It is not recommended to use the old L<HTML::Template::Nest> module any more.)


=head1 WHAT'S NEW IN v0.05?

=head2 Preloading of defaults

I want to keep this module lightweight and simple, but one minor irritation with C<v0.04> and below is lack of any means to provide defaults. Often you have template parameters you want to take directly from some centralised config, so in C<v0.04> and below you would need to do:

    my $config = get_config_from_somewhere();

    my $output1 = $nest->render({
        'NAME' => 'some_template',
        'config.variable1' => $config->{variable1},
        'config.variable2' => $config->{variable2}
    });

    my $output2 = $nest->render({
        'NAME' => 'some_template',
        'config.variable1' => $config->{variable1},  # same crap all over again
        'config.variable2' => $config->{variable2}   # and it was annoying enough
    });                                              # the first time

Obviously this is tedious and a deal-breaker for a larger project. So C<v0.05> allows you to preload config variables thus:

    my $config = get_config_from_somewhere();

    $nest->defaults( $config );

    my $output1 = $nest->render({
        NAME => 'some_template'

        # no need for anything here

    });

    # ... etc.

See C<defaults> below for more details.


=head2 Maintaining indent

In C<v0.04> if you had:

 # template_1
 <div>
      <% contents %>
 </div>

 # template_2

 <strong>
      TO INFINITY AND BEYOND!
 </strong>

and then you did

 $nest->render({
    NAME => 'template_1',
    contents => {
        NAME => 'template_2'
    }
 });

You would get:

 <div>
      <strong>
     TO INFINITY AND BEYOND
 </strong>
 </div>

Note the indenting. Not pretty! (However this is completely accurate in terms of replacing the C<contents> token; no extra characters are added or removed during the replacement)

So now you can

 $nest->fixed_indent(1);

with the result:

 <div>
     <strong>
          TO INFINITY AND BEYOND!
     </strong>
 </div>

Be aware this involves left padding nested templates so that each new line in the nested template gets the same spacing as the token it was replacing. ie space characters are added in during the replacement.


=head2 Inspect template parameters

L<HTML::Template> allows you to ask what parameters are in a template. L<Template::Nest> now has the same capability via the C<params> method.


=head2 better escaping

C<v0.04> assumed you wanted to use a backslash as an escape character. In v<0.05> you can choose a different character, or switch off escaping altogether. See the L<escape_char> method.


=head2 allow parameters which don't exist

L<Template::Nest> C<v0.04> assumes you want to drop out with an error if you try and populate a template with a parameter (name) that doesn't exist. In C<v0.05> you can set it to ignore parameters that don't exist. See L<die_on_bad_params>.



=head1 AN EXAMPLE

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




=head1 METHODS


=head2 comment_delims

Use this in conjunction with show_labels. Get/set the delimiters used to define comment labels. Expects a 2 element arrayref. E.g. if you were templating javascript you could do:

    $nest->comment_delims( '/*', '*/' );

Now your output will have labels like

    /* BEGIN my_js_file */
    ...
    /* END my_js_file */


You can set the second comment token as an empty string if the language you are templating does not use one. E.g. for Perl:

    $nest->comment_delims([ '#','' ]);


=head2 defaults

Provide a hashref of default values to have L<Template::Nest> auto-fill matching parameters (no matter where they are found in the template tree). For example:

    my $nest = Template::Nest->new(
        token_delims => ['<!--%','%-->']
    });

    # box.html:
    <div class='box'>
        <!--% contents %-->
    </div>

    # link.html:
    <a href="<--% soup_website_url %-->">Soup of the day is <!--% todays_soup %--> !</a>

    my $page = {
        NAME => 'box',
        contents => {
            NAME => 'link',
            todays_soup => 'French Onion Soup'
        }
    };

    my $html = $nest->render( $page );

    print "$html\n";

    # prints:

    <div class='box'>
        <a href="">Soup of the day is French Onion Soup !</a>
    </div>

    # Note the blank "href" value - because we didn't pass it as a default, or specify it explicitly
    # Now lets set some defaults:

    $nest->defaults({
        soup_website_url => 'http://www.example.com/soup-addicts',
        some_other_url => 'http://www.example.com/some-other-url' #any default that doesn't appear
    });                                                           #in any template is simply ignored

    $html = $nest->render( $page );

    # this time "href" is populated:

    <div class='box'>
        <a href="http://www.example.com/soup-addicts">Soup of the day is French Onion Soup</a>
    </div>

    # Alternatively provide the value explicitly and override the default:

    $page = {
        NAME => 'box',
        contents => {
            NAME => 'link',
            todays_soup => 'French Onion Soup',
            soup_website_url => 'http://www.example.com/soup-url-override'
        }
    };

    $html = $nest->render( $html );

    # result:

    <div class='box'>
        <a href='http://www.example.com/soup-url-override'
    </div>

ie. C<defaults> allows you to preload your C<$nest> with any values which you expect to remain constant throughout your project.



You can also B<namespace> your default values. Say you think it's a better idea to differentiate parameters coming from config from those you are expecting to explicitly pass in. You can do something like this:

    # link.html:
    <a href="<--% config.soup_website_url %-->">Soup of the day is <!--% todays_soup %--> !</a>

ie you are reserving the C<config.> prefix for parameters you are expecting to come from the config. To set the defaults in this case you could do this:

    my $defaults = {
        'config.soup_website_url' => 'http://www.example.com/soup-addicts',
        'config.some_other_url' => 'http://www.example.com/some-other-url'

        #...
    };

    $nest->defaults( $defaults );

but writing 'config.' repeatedly is a bit effortful, so L<Template::Nest> allows you to do the following:

    my $defaults = {

        config => {

            soup_website_url => 'http://www.example.com/soup-addicts',
            some_other_url => 'http://www.example.com/some-other-url'

            #...
        },

        some_other_namespace => {

            # other params?

        }

    };


    $nest->defaults( $defaults );
    $nest->defaults_namespace_char('.'); # not actually necessary, as '.' is the default

    # Now L<Template::Nest> will replace C<config.soup_website_url> with what
    # it finds in

    $defaults->{config}{soup_website_url}

See L<defaults_namespace_char>.




=head2 defaults_namespace_char

Allows you to provide a "namespaced" defaults hash rather than just a flat one. ie instead of doing this:

    $nest->defaults({
        variable1 => 'value1',
        variable2 => 'value2',

        # ...

    });

You can do this:

    $nest->defaults({
        namespace1 => {
            variable1 => 'value1',
            variable2 => 'value2'
        },

        namespace2 => {
            variable1 => 'value3',
            variable2 => 'value4
        }
    });

Specify your C<defaults_namespace_char> to tell L<Template::Nest> how to match these defaults in your template:

    $nest->defaults_namespace_char('-');

so now the token

    <% namespace1-variable1 %>

will be replaced with C<value2>. Note the default C<defaults_namespace_char> is a fullstop (period) character.


=head2 die_on_bad_params

The name of this method is stolen from L<HTML::Template>, because it basically does the same thing. If you attempt to populate a template with a parameter that doesn't exist (ie the name is not found in the template) then this normally results in an error. This default behaviour is recommended in most circumstances as it guards against typos and sloppy code. However, there may be circumstances where you want processing to carry on regardless. In this case set C<die_on_bad_params> to 0:

    $nest->die_on_bad_params(0);


=head2 escape_char

On rare occasions you may actually want to use the exact character string you are using for your token delimiters in one of your templates. e.g. say you are using token_delims C<[%> and C<%]>, and you have this in your template:

    Hello [% name %],

        did you know we are using token delimiters [% and %] in our templates?

    lots of love
    Roger

Clearly in this case we are a bit stuck because L<Template::Nest> is going to think C<[% and %]> is a token to be replaced. Not to worry, we can I<escape> the opening token delimiter:

    Hello [% name %],

        did you know we are using token delimiters \[% and %] in our templates?

    lots of love
    Roger

In the output the backslash will be removed, and the C<[% and %]> will get printed verbatim.

C<escape_char> is set to be a backslash by default. This means if you want an actual backslash to be printed, you would need a double backslash in your template.

You can change the escape character if necessary:

    $nest->escape_char('X');

or you can turn it off completely if you are confident you'll never want to escape anything. Do so by passing in the empty string to C<escape_char>:

    $nest->escape_char('');


=head2 fixed_indent

Intended to improve readability when inspecting nested templates. Consider the following example:

    my $nest = Template::Nest->new(
        token_delims => ['<!--%','%-->']
    });

    # box.html
    <div class='box'>
        <!--% contents %-->
    </div>

    # photo.html
    <div>
        <img src='/some_image.jpg'>
    </div>

    $nest->render({
        NAME => 'box',
        contents => 'image'
    });

    # Output:

    <div class='box'>
        <div>
        <img src='/some_image.jpg'>
    </div>
    </div>

Note the ugly indenting. In fact this is completely correct behaviour in terms of faithfully replacing the token

    <!--% contents %-->

with the C<photo.html> template - the nested template starts exactly from where the token was placed, and each character is printed verbatim, including the new lines.

However, a lot of the time we really want output that looks like this:

    <div class='box'>
        <div>
            <image src='/some_image.jpg'>  # the indent is maintained
        </div>                             # for every line in the child
    </div>                                 # template

To get this more readable output, then set C<fixed_indent> to 1:

    $nest->fixed_indent(1);

Bear in mind that this will result in extra space characters being inserted into the output.


=head2 token_placeholder

If specified, any tokens whose value is not specified in template hash will be replaced by the string in token_placeholder.

For example:

    <table><% body %></table>

becomes

    <table>MISSING_TOKEN</table>

if token_placeholder's value is "MISSING_TOKEN", one can also use the token "param_name" within token_placeholder to add param name to the replacement string.

For example:

    <table><% body %></table>

becomes

    <table>PUT body HERE</table>

if token_placeholder's value is "PUT <% param_name %> HERE", token delims must be used here.


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



=head2 new

constructor for a Template::Nest object.

    my $nest = Template::Nest->new( %opts );

%opts can contain any of the methods Template::Nest accepts. For example you can do:

    my $nest = Template::Nest->new( template_dir => '/my/template/dir' );

or equally:

    my $nest = Template::Nest->new();
    $nest->template_dir( '/my/template/dir' );



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

Template::Nest will then prepend NAME with template_dir, append template_ext and look in that location for the file. So in our example if C<template_dir = '/my/template/dir'> and C<template_ext = '.html'> then the template file will be expected to exist at

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



=head2 token_delims

Get/set the delimiters that define a token (to be replaced). token_delims is a 2 element arrayref - corresponding to the opening and closing delimiters. For example

    $nest->token_delims( '[%', '%]' );

would mean that L<Template::Nest> would now recognise and interpolate tokens in the format

    [% token_name %]

The default token_delims are the mason style delimiters C<<%> and C<%>>. Note that for C<HTML> the token delimiters C<<!--%> and C<%-->> make a lot of sense, since they allow raw templates (ie that have not had values filled in) to render as good C<HTML>.


=head1 SEE ALSO

L<HTML::Template::Nest> L<HTML::Template> L<Text::Template> L<Mason> L<Template::Toolkit>

=head1 AUTHOR

Tom Gracey tomgracey@gmail.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Tom Gracey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
