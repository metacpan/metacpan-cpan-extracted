#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::View;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::View - The template processing system.

=head1 SYNOPSIS
        
    # get view home.html in current active theme
    my $view = $self->app->view("home");
    # get view home.html in specific arabic theme
    my $view = $app->view("home", "arabic");
    
    # set view variables
    $view->var(
        fname       =>  'Ahmed',
        lname       =>  'Elsheshtawy',
        email       =>  'ahmed@mewsoft.com',
        website     =>  'http://www.mewsoft.com',
        singleline  =>  'Single line variable <b>Good</b>',
        multiline   =>  'Multi line variable <b>Nice</b>',
       );
    
    # set variable
    $view->set('email', 'sales@mewsoft.com');

    # get variable
    $email = $view->get('email');

    # automatic getter/setter for variables
    $view->email('sales@mewsoft.com');
    $view->website('http://www.mewsoft.com');
    $email = $view->email;
    $website = $view->website;

    # replace marked blocks or iterators
    $view->block("first", "1st Block New Content ");
    $view->block("six", "6th Block New Content ");
    
    # process variables and blocks and text language variables
    $view->process;

    # get the output
    $content = $view->out;

=head1 DESCRIPTION

Nile::View - The template processing system.

Templates or views are pure html files with special xml tags which can be used to insert
the application dynamic output. These xml sepcial tags also can be used to pass
parameters to the plugins.

Templates also has special comment tags to mark blocks and iterators.

Since the framework supports multi lingual, the template can contain the language
variables names instead of the actual text surrounded by the Curly braces C<{> and C<}>.
Templates also allow embedded Perl code.

=head1 TEMPLATE LANGUAGE VARIABLES

The template can contain the language variables names instead of the actual text 
surrounded by the Curly braces C<{> and C<}>.

    {first_name} <input type="text" name="fname" id="fname" value="" />
    {last_name} <input type="text" name="lname" id="lname" value="" />
    {phone} <input type="text" name="phone" id="phone" value="" />

The language variables {first_name}, {last_name}, and {phone} will be replaced
by their actual text from the loaded langauge file. So after processing the template,
this code will look like this:

    Your first name: <input type="text" name="fname" id="fname" value="" />
    Your second name: <input type="text" name="lname" id="lname" value="" />
    Your phone numger: <input type="text" name="phone" id="phone" value="" />

If the language variables is not found in the loaded language files, it will not be processed so
you can add it to the correct language file.

=head1 TEMPLATE VARS TAGS

The template xml tag used to insert dynamic output and to pass parameters to the plugin or module has
the following format:

    <vars type="plugin" method="Plugin->method" arg1="value_1" arg2="value_2" argxx="value_xx" />
    <vars type="module" method="Module->method" arg1="value_1" arg2="value_2" argxx="value_xx" />

The xml tag name is fixed `vars`. The attribute C<type> defines the type of the action to be called to handle
this tag.

The rest of the attributes is optional parameters which will be passed to the action called.

The first type or the C<vars> tags is the B<var> in the form C<type="var">.
These var tags are used to insert dynamic variables when processing the view:

    <vars name="website"/>
    <vars type="var" name='email' />

If the vars tag type attribute is empty or omitted, it means this tag is a type C<var>, type="var", so the 
following are the same:

    <vars name="email"/>
    <vars type="var" name='email' />

To replace these variables when working with the view, just do it like this:
    
    $view = $self->app->view("home");
    $view->set("email", 'sales@mewsoft.com');
    $view->set("website", 'http://mewsoft.com');

Then when processing the template, these variables will replace the vars xml tags.

The second type or the C<vars> tags is the C<plugin> and C<module> in the form C<type="plugin"> and <type="module">.

Use these tags to call plugins and modules methods and insert their output to the template. You can also
pass any number of optional parameters to the plugin and module method through these tags

Example to insert dynamic plugins and modules output when processing the view:

    <vars type="plugin" method="Date->date" format="%a, %d %b %Y %H:%M:%S" /><br>
    <vars type="plugin" method="Date->time" format="%A %d, %B %Y  %T %p" /><br>
    <vars type="plugin" method="Date::now" capture="1" format="%B %d, %Y  %r" /><br>

    <vars type="module" method="Home::Home->welcome" message="Welcome back!" />

These vars tags of type C<plugin> is used to call the plugins in the C<method> attribute and will pass the
parameter C<format> to the plugin method, the vars of the type module will pass the parameter c<message>
to the module c<Home::Home> method c<welcome>.

If the attribute C<capture> is set to any value, the output of the print statements of the method
will be captured and will ignore any returns.

The third type or the C<vars> tags is the C<Perl> tags which is used to execute Perl code and capture
the output and insert it in the template.

Example to insert embedded Perl code output when processing the view:

    <vars type="perl">print $self->app->VERSION; return;</vars>

You can run any Perl code in this tag, here is example to call a system function and display its results:

    <vars type="perl">system ('dir c:\\*.bat');</vars>

You can also include your Perl code in an CDATA like this:

    <vars type="perl"><![CDATA[ 
        say "";
        say "<br>active language: " . $self->app->var->get("lang");
        say "<br>active theme: " . $self->app->var->get("theme");
        say "<br>app path: " . $self->app->var->get("path");
        say "<br>";
    ]]></vars>

The fourth type or the C<vars> tags is the C<widget> tags which is used to include small templates
or widgets in the template. Widgets are small templates and have the same structure as the templates.
Widgets are used for the repeated template blocks like dividing your template to sections say header,
footer, top_navigation, bottom_navigation, left, right, top_banner, etc. Then you just insert
the widget tag inside the templates you want to use these widgets instead of repeating the same code
in every template.

Widgets templates files should be located in the theme C<widget> folder with the default C<.html> extension.

You can pass any number of parameters to the widgets and it will be replaced when processed.

Example to insert the widget header in your templates:

    <vars type="widget" name="header" charset_name="UTF-8" lang_name="en" />

If you insert the above tag in your template, it will load the contents of the widget file "header.html" and 
insert it to the template and will replace the variables passed C<charset_name> and C<lang_name> by their
values. Variables can be of different values from call to call based on your need.

=head1 TEMPLATE BLOCKS AND ITERATORS

Sometimes you need to replace a block of code in your templates by some other contents. For example
you may want to show a block of template code if user if logged in and another block of template code
if the user is not logged in.

In this case use the block comment tag in the following form to handle this:

    <!--block:user_login-->
        <span style="color: green;">
            {user_login_message}
        </span>
    <!--endblock-->

    <!--block:user_logout-->
        <span style="color: red;">
            {user_logout_message}
        </span>
    <!--endblock-->

Inside the plugin code, you can access these blocks simply like this
    
    # get the block user_login hash ref
    $login_block = $view->block("user_login");
    say $login_block->{content};
    say $login_block->{match};
    
    # set the block user_login new content
    $view->block("user_login", "Login Block New Content ");
    
    # set the block user_logout new content
    $view->block("user_logout", "Logout Block New Content ");

    # or 
    if (user_is_loggedin()) {
        # hide or clear the logout block
        $view->block("user_logout", "");
    }
    else {
        # hide or clear the login block
        $view->block("user_login", "");
    }

Calling $view->block() method without any block name will return the entire hash tree of all the template
blocks.

Blocks can be nested to any levels, for example:

    html content 1-5 top
    <!--block:first-->
        <table border="1" style="color:red;">
        <tr class="lines">
            <td align="left" valign="<--valign-->">
                <b>bold</b><a href="http://www.mewsoft.com">mewsoft</a>
                <!--hello--> <--again--><!--world-->
                some html content here 1 top
                <!--block:second-->
                    some html content here 2 top
                    <!--block:third-->
                        some html content here 3 top
                        <!--block:fourth-->
                        some html content here 4 top
                            <!--block:fifth-->
                                some html content here 5a
                                some html content here 5b
                            <!--endblock-->
                        <!--endblock-->
                        some html content here 3a
                    some html content here 3b
                <!--endblock-->
            some html content here 2 bottom
            </tr>
        <!--endblock-->
        some html content here 1 bottom
    </table>
    <!--endblock-->
    html content 1-5 bottom

    html content 6-8 top
    <!--block:six-->
        some html content here 6 top
        <!--block:seven-->
            some html content here 7 top
            <!--block:eight-->
                some html content here 8a
                some html content here 8b
            <!--endblock-->
            some html content here 7 bottom
        <!--endblock-->
        some html content here 6 bottom
    <!--endblock-->
    html content 6-8 bottom

You can get and access these nested blocks in many ways:

    $fifth = $view->block("first/second/third/fourth/fifth");
    $fifth = $view->block->{first}->{second}->{third}->{fourth}->{fifth};
    $all = $view->block;
    $fifth = $all->{first}->{second}->{third}->{fourth}->{fifth};

Blocks also used for iterators, if you want to build a table or data for example, then you get the bock of the
repeated table row and process it then replace the entire data with the block in the view.

=cut

use Nile::Base;
use Capture::Tiny ();
use IO::Compress::Gzip qw(gzip $GzipError);
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub AUTOLOAD {
    my ($self) = shift or return undef; # ignore functions call like Nile::View::xxx();
    my ($class, $method) = our $AUTOLOAD =~ /^(.*)::(\w+)$/;
    
    if ($self->can($method)) {
        return $self->$method(@_);
    }

    if (@_) {
        $self->{var}->{$method} = $_[0];
    }
    else {
        return $self->{var}->{$method};
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub main { # our sub new{...}, called automatically after the constructor new
    my ($self, $view, $theme) = @_; 
    $self->{theme} = $theme if ($theme);
    $self->view($view) if ($view);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 view()

    my $view =  $self->app->view([$view, $theme]);

Creates new view object or returns the current view name. The first option is the view name with or without file extension $view, the default 
view extension is B<html>. The second optional argument is the theme name, if not supplied the current default theme will be used.

=cut

sub view {
    my ($self, $view, $theme) = @_; 
    
    my $app = $self->app;

    if ($view) {
        $view .= ".html" unless ($view =~ /\.html$/i);
        $theme ||= $self->{theme} ||= $app->var->get("theme");
        my $file = $app->file->catfile($app->var->get("themes_dir"), $theme, "view", $view);
        $self->{content} = $app->file->get($file);
        $self->{file} = $file;
        $self->{view} = $view;
        $self->{lang} ||= $app->var->get("lang");
        $self->{theme} = $theme;
        $self->parse;
        return $self;
    }

    $self->{view};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 lang()
    
    $view->lang('en-US');
    my $lang = $view->lang();

Sets or returns the language for processing the template text. Language must be already installed in the lang folder.

=cut

sub lang {
    my ($self, $lang) = @_;
    if ($lang) {
        $self->{lang} = $lang;
        return $self;
    }
    $self->{lang};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 theme()
    
    $view->theme('arabic');
    my $theme = $view->theme();

Sets or returns the theme for loading template file. Theme must be already installed in the theme folder.

=cut

sub theme {
    my ($self, $theme) = @_;
    if ($theme) {
        $self->{theme} = $theme;
        return $self;
    }
    $self->{theme};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 var() and set()
    
    $view->var(email=>'nile@cpan.org');
    $view->var(%vars);

    $view->var(
            fname           =>  'Ahmed',
            lname           =>  'Elsheshtawy',
            email           =>  'sales@domain.com',
            website     =>  'http://www.mewsoft.com',
            htmlnode        =>  'html code variable <b>Nile</b>',
        );

Sets one of more template variables. This method can be chained.

=cut

sub var {
    my ($self, %vars) = @_;
    map {$self->{vars}->{$_} = $vars{$_}} keys %vars;
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 set()

    $view->set(email=>'nile@cpan.org');
    $view->set(%vars);

Same as method var() above.

=cut

sub set {
    my ($self, %vars) = @_;
    map {$self->{vars}->{$_} = $vars{$_}} keys %vars;
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 get()

    $email = $view->get("email");
    @user = $view->get(qw(fname lname email website));

Returns one or more template variables values.

=cut

sub get {
    my ($self, @name) = @_;
    #@{ $h{'a'} }{ @keys }
    @{ $self->{vars} }{@name};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 content()
    
    # get current template content
    $content = $view->content;

    # set current template content direct
    $view->content($content);

Get or set current template content.

=cut

sub content {
    my ($self) = shift;
    if (@_) {
        $self->{content} = $_[0];
        return $self;
    }
    $self->{content};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parse_vars {
    
    my ($self) = @_;
    
    my ($match, $attrs, $content, $cdata, $cdata_content, $closing, %attr, $type, $k, $v);
    my $tag = "vars";
    
    $self->{tag} = +{};
    my $counter = 0;
    
    #(<$tag(\s+[^\!\?\s<>](?:"[^"]*"|'[^']*'|[^"'<>])*)/>([^<]*)(<\!\[CDATA\[(.*?)\]\]>)?(</$tag>)?)
    while ( $self->{content} =~ m{
        (<$tag(\s+[^\!\?\s<>](?:"[^"]*"|'[^']*'|[^"'<>])*)/>)|(<$tag(\s+[^\!\?\s<>](?:"[^"]*"|'[^']*'|[^"'<>\/])*)>(.*?)<\/$tag>)
    }sxgi ) {
        
        if ($1) {
            ($match, $attrs, $content) = ($1, $2, undef);
        }
        else {
            ($match, $attrs, $content) = ( $3, $4, $5);
            if ($content =~ /<\!\[CDATA\[(.*?)\]\]>/is) {
                $content = $1;
            }
        }
        #print "match:\n$match \nattrs: $attrs\nvalue: $value\n";
    
        # parse attributes to key and value pairs
        %attr = ();
         
        #while ( $attrs =~ /\G(?:\s+([^=]+)=(?:"([^"]*)"|'([^']*)'|(\S+))|(.+))/sg ) {
         while ( $attrs =~ m{([^\s\=\"\']+)\s*=\s*(?:(")(.*?)"|'(.*?)')}sxg ) {
            $attr{$1} = ( $2 ? $3 : $4 );
        }

        if ($attr{name}) {
            $type = (exists $attr{type} and $attr{type} ne "")? $attr{type} : "var";
            $self->{tag}->{$type}->{$attr{name}} = {attr=>{%attr}, match=>$match, content=>$content};
        }
        elsif (exists $attr{type} and $attr{type} ne "") {
            # handle    <vars type="perl">print "Hello world";</vars>
            #               <vars type="plugin" method="Date->date" />
            $counter++;
            $attr{name} = $tag."_".$counter;
            $type = $attr{type};
            #say "$attr{name}: $attr{method}, $attr{type}";
            $self->{tag}->{$type}->{$attr{name}} = {attr=>{%attr}, match=>$match, content=>$content};
        }

        #print "\n";
    }
    
    #$self->app->dump($self->{tag});

    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parse_blocks {
    my ($self) = @_;
    $self->{block} = +{};
    $self->parse_nest_blocks($self->{block}, $self->{content});
    return $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parse_nest_blocks {

    my ($self, $aref, $core) = @_;

    my ($k, $v);
    
    #The (?<xxx> syntax requires perl 5.10 or above: http://perldoc.perl.org/perl5100delta.html#Named-Capture-Buffers
    #while ($core =~ /(<!--block:(.*?)-->((?:(?:(?!<!--block:(?:.*?)-->).)|(?R))*?)<!--endblock-->|((?:(?!<!--.*?-->).)+))/igsx )
    #while ( $core =~ /(?is)(<!--block:(.*?)-->((?:(?:(?!<!--block:(?:.*?)-->).)|(?R))*?)<!--endblock-->|((?:(?!<!--block:.*?-->).)+))/g )
    
    while ( $core =~ /(?is)(?:((?&content))|(?><!--block:(.*?)-->)((?&core)|)<!--endblock-->|(<!--(?:block:.*?|endblock)-->))(?(DEFINE)(?<core>(?>(?&content)|(?><!--block:.*?-->)(?:(?&core)|)<!--endblock-->)+)(?<content>(?>(?!<!--(?:block:.*?|endblock)-->).)+))/g )
    {
        if (defined $2) {
            # CORE
           $k = $2; $v = $3;
           $aref->{$k} = +{};
           $aref->{$k}->{content} = $v;
           $aref->{$k}->{match} = $&;
          # print "1:{{$1}}\n2:[[$2]]\n";
           my $curraref = $aref->{$k};
           my $ret = $self->parse_nest_blocks($aref->{$k}, $v);
           if (defined $ret) {
               $curraref->{'#next'} = $ret;
           }
        }
        elsif (defined $1) {
            # CONTENT
            #$aref->{$k}->{content} .= $1;
            #say "CONTENT: $1";
        }
        else {
            # ERRORS
            #say "Error in View->parse_nest_blocks. Unbalanced '$4' at position = ", $-[0];
            #$IsError = 1;
            # Decide to continue here ..
            # If BailOnError is set, just unwind recursion. 
            #if ($BailOnError) {last;}
       }
    }
    return $k;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 block()
    
    # get all blocks as a hashref
    $blocks = $view->block;

    # get one block as a hashref
    $block = $view->block("first");
    
    # set a block new content
    $view->block("first", "1st Block New Content ");

Get and set blocks. Blocks or iterators are a block of the template code marked or processing and replacing with
dynamic content. For example you can use blocks to  show or hide a part of the template based on conditions. Another
example is using nested blocks as iterators for displaying lists or tables of repeated rows.

=cut

sub block {
    my ($self) = shift;
    if (@_ == 1) {
        # return one block by its complete path like first/second/third/fourth
        my $path = shift;
        #---------------------------------------
        if ($path !~ /\//) {
            return $self->{block}->{$path};
        }
        #---------------------------------------
        $path =~ s/^\/+|\/+$//g;
        my @path = split /\//, $path;
        my $v = $self->{block};
        
        while (my $k = shift @path) {
            if (!exists $v->{$k}) {
                return;
            }
             $v = $v->{$k};
        }

        return $v;
    }
    elsif (@_ > 1) {
        #set blocks
        my %blocks = @_;
        while (my($k, $v) = each %blocks) {
            #say "[($k, $v)] " .$self->block($k);
            $self->block($k)->{content} = $v;
        }
        #return all blocks hash object
        $self->{block};
    }
    else {
        #return all blocks hash object
        $self->{block};
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub process_blocks {
    my ($self) = $_[0];
    my ($name, $var, $match);
    #say "Pass...";
    # process root blocks
    while (($name, $var) = each %{$self->{block}}) {
        #say "block: $name";
        #$self->{block}->{first} = {match=>, content=>, #next=>};
        $match = $var->{match};
        $self->{content} =~ s/\Q$match\E/$var->{content}/gex;
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 replace()
    
    $view->replace('find text' => 'replaced text');
    $view->replace(%vars);

Replace some template text or code with another one. This method will replace all instances of the found text. This method can be chained.

=cut

sub replace {
    my ($self, %vars) = @_;
    while (my ($k, $v) = each %vars) {
        $self->{content} =~ s/\Q$k\E/$v/g;
    }
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 replace_once()
    
    $view->replace_once('find text' => 'replaced text');
    $view->replace_once(%vars);

Replace some template text or code with another one. This method will replace only one instance of the found text. This method can be chained.

=cut

sub replace_once {
    my ($self, %vars) = @_;
    while (my ($k, $v) = each %vars) {
        $self->{content} =~ s/\Q$k\E/$v/;
    }
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 translate()
    
    # scan and replace the template language variables for the default 2 times
    $view->translate;

    # scan and replace the template language variables for 3 times
    $view->translate(3);

This method normally used internally when processing the template. It scans the template for the langauge variables
surrounded by the curly braces B<{var_name}> and replaces them with their values from the loaded language files. 
This method can be chained.

=cut

sub translate {
    my ($self, $passes) = @_;
    $passes += 0;
    $passes ||= 2;
    $self->app->lang->translate(\$self->{content}, $self->{lang}, $passes);
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 process_vars()
    
    $view->process_vars;

This method normally used internally when processing the template. This method can be chained.

=cut

sub process_vars {

    my ($self) = $_[0];
    my ($name, $var, $match);
    
    my $vars = $self->{vars};
    
    # get a hash reference to the global variables
    my $shared = $self->app->var->vars();

    while (($name, $var) = each %{$self->{tag}->{var}}) {
        #$self->{tag}->{$type}->{$attr{name}} = {attr=>{%attr}, match=>$match, content=>$content};
        if (exists $vars->{$name}) {
            $match = $var->{match};
            $self->{content} =~ s/\Q$match\E/$vars->{$name}/gex;
        }
        elsif (exists $shared->{$name}) {
            $match = $var->{match};
            $self->{content} =~ s/\Q$match\E/$shared->{$name}/gex;
        }
    }
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 process_perl()
    
    $view->process_perl;

This method normally used internally when processing the template. This method can be chained.

=cut

sub process_perl {
    my ($self) = $_[0];
    my ($name, $var, $match);
    
    while (($name, $var) = each %{$self->{tag}->{perl}}) {
        #$self->{tag}->{$type}->{$attr{name}} = {attr=>{%attr}, match=>$match, content=>$content};
        $match = $var->{match};
        $self->{content} =~ s/\Q$match\E/$self->capture($var->{content})/gex;
    }
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 capture()
    
    $result = $view->capture($perl_code);

This method normally used internally when processing the template.

=cut

sub capture {

    my ($self, $code) = @_;
    
    undef $@;
    my ($merged, @result) = Capture::Tiny::capture_merged {eval $code};
    #$merged .= join "", @result;
    if ($@) {
        $merged  = "Embeded Perl code error: $@\n $code\n $merged\n";
    }

    return $merged;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 get_widget()
    
    $view->get_widget($widget, $theme);

This method normally used internally when processing the template. Returns the widget file content.

=cut

sub get_widget {
    
    my ($self, $view, $theme) = @_;
        
    $view .= ".html" unless ($view =~ /\.html$/i);
    $theme ||= $self->{theme} ||= $self->app->var->get("theme");
    my $file = $self->app->file->catfile($self->app->var->get("themes_dir"), $theme, "widget", $view);

    if (exists $self->{cash}->{$file}) {
        return $self->{cash}->{$file};
    }

    my $content = $self->app->file->get($file);
    $self->{cash}->{$file} = $content;
    return $content;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 process_widgets()
    
    $view->process_widgets;

This method normally used internally when processing the template. This method can be chained.

=cut

sub process_widgets {

    my ($self) = $_[0];
    my ($name, $var, $match, $content, $k, $v);
    
    while (($name, $var) = each %{$self->{tag}->{widget}}) {
        #$self->{tag}->{$type}->{$attr{name}} = {attr=>{%attr}, match=>$match, content=>$content};
        $match = $var->{match};
        $content = $self->get_widget($name);
        # replace widget args named as [:name:]
        while (($k, $v) = each %{$var->{attr}}) {
            $content =~ s/\[:$k:\]/$v/g;
        }
        $self->{content} =~ s/\Q$match\E/$content/g;
    }
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 process_plugins()
    
    $view->process_plugins ;

This method normally used internally when processing the template. This method can be chained.

=cut

sub process_plugins {

    my ($self) = $_[0];

    my ($app, $name, $var, $match, $content, $k, $v, $class, $plugin, $vars, %attr);
    my ($tags, $type, $method, $object, $meta, $capture, $merged, @result);

    $app = $self->app;
    
    $self->{tag}->{plugin} ||= +{};
    $self->{tag}->{module} ||= +{};
    
    foreach $tags($self->{tag}->{plugin}, $self->{tag}->{module}) {

        while (($vars, $var) = each %$tags ) {
            
            %attr = %{$var->{attr}};
            #$self->{tag}->{$type}->{$attr{name}} = {attr=>{%attr}, match=>$match, content=>$content};
            
            $content = "";
            $name = $attr{method};
            $match = $var->{match};
            $type = lc($attr{type});

            # delete the attr keys used by the vars tag itself
            delete $attr{$_} for (qw(type method));
            $capture = delete $attr{capture};
            
            $name =~ s/->/::/;
            my ($plugin, $method) = $name =~ /^(.*)::(\w+)$/;

            $plugin = ucfirst($plugin);

            $class = "Nile::" .ucfirst($type) ."::".$plugin;

            if (exists $self->{class_object}->{$class}) {
                $object = $self->{class_object}->{$class};
            }
            else {
                if (!$app->is_loaded($class)) {
                    eval "use $class;";
                    if ($@) {
                        $content = " View Error: $type $plugin\->$method does not exist method $name";
                        $self->{content} =~ s/\Q$match\E/$content/gex;
                        undef $@;
                        next;
                    }
                }

                $object = $class->new();
                $self->{class_object}->{$class} = $object;
                $meta = $object->meta;

                # add method "me" or one of its alt
                $self->app->add_object_context($object, $meta);
            }
        
            if ($object->can($method)) {
                if ($capture) {
                    ($merged, @result) = Capture::Tiny::capture_merged {eval {$object->$method(%attr)}};
                    #$merged .= join "", @result;
                }
                else {
                    $merged = eval {$object->$method(%attr)};
                }
                
                if ($@) {
                    $content  = "View error: $type method='$name' $@\n $class->$method. $merged\n";
                }
                else {
                    $content = $merged; 
                }
            }
            else {
                $content = " View error: $type '$class' does not have subroutine '$method' method='$name'. ";
            }

            $self->{content} =~ s/\Q$match\E/$content/gex;
        } # while
    }# for

    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 parse()
    
    $view->parse;

This method normally used internally when processing the template. This method can be chained.

=cut

sub parse {
    my ($self) = @_;
    $self->parse_vars;
    $self->parse_blocks;
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 process_pass()
    
    $view->process_pass;

This method normally used internally when processing the template. This method can be chained.

=cut

sub process_pass {
    my ($self) = @_;
    $self->process(1);
    $self->parse;
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 process()
    
    $view->process;
    $view->process($passes);

Process the template. This method can be chained.

=cut

sub process {
    
    my ($self, $passes) = @_;
    
    $passes += 0;
    $passes ||= 3;
    
    for my $pass(1..$passes) {
        $self->translate;
        $self->process_widgets;
        $self->process_blocks;
        $self->process_plugins;
        $self->process_perl;
        $self->process_vars;
        if ($pass < $passes) {
            $self->parse;
        }
    }

    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 out()
    
    $view->out;

Process the template and return the content.

=cut

sub out {
    my ($self) = $_[0];
    $self->process();
    return $self->{content};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 object()
    
    # get a new view object
    #my $view1 = $view->object;
    
Returns a new view object.

=cut

sub object {
    my $self = shift;
    $self->app->object(__PACKAGE__, @_);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub DESTROY {
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
