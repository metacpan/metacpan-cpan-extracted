package MojoX::Plugin::PODRenderer;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Asset::File;
use Mojo::ByteStream 'b';
use Mojo::DOM;
use Mojo::Util qw(slurp url_escape class_to_path xml_escape);
use Pod::Simple::HTML;
use Pod::Simple::Search;
use boolean;
use Class::MOP;
use File::Find;

our $VERSION = '0.01';

# Paths to search
my @PATHS = map { $_, "$_/pods" } @INC;

sub register {
    my ($self, $app, $conf) = @_;

    my $preprocess = $conf->{preprocess} || 'ep';
    $app->renderer->add_handler(
        $conf->{name} || 'pod' => sub {
            my ($renderer, $c, $output, $options) = @_;

            # Preprocess and render
            my $handler = $renderer->handlers->{$preprocess};
            return undef unless $handler->($renderer, $c, $output, $options);
            $$output = _pod_to_html($$output);
            return 1;
        }
    );

    # Perldoc browser
    return $app->routes->any(
        '/perldoc/*module' => {module => 'DocIndex'} => \&_perldoc
    );
}

# ------------------------------------------------------------------------------ 

sub _process_found_file {
    my ($name2path, $path2name) = @_;

    warn "2path %s - 2name %s \n",  $name2path, $path2name;
}

# ------------------------------------------------------------------------------ 

sub _generateIndex {
    my $self = shift;

    my ($lib) = grep "script\/\.\.\/lib", @INC;

    my ($name2path, $path2name) = ({},{}); # It's an owl!

    find(
        {
            wanted => sub {
                            return unless $_ =~ /\.(pm|pl|pod)$/;
                            my $path = $File::Find::name;
                            my $name = $path;
                            $name =~ s/^$lib\/?//;
                            $name =~ s/\.(pm|pl|pod)$//g;
                            $name =~ s!/!::!g;

                            $path2name->{$path} = $name;
                            $name2path->{$name} = $path;
                      },
        },
        $lib
    );

    my $guides  = [];
    my $modules = {};

    foreach my $path (sort keys %$path2name) {
        my $name = $path2name->{$path};
        if ($path =~ /\.pod$/) { # guide
            (my $url = '/perldoc/'.class_to_path($name)) =~ s/\.pm$/\.pod/;

            push @{$guides}, { name => $name, has_doc => true, path => $url };
        }
        else { # module
            (my $url = '/perldoc/'.class_to_path($name)) =~ s/\.pm//;

            # Check whether it actually has pod
            my $search = Pod::Simple::Search->new();
            my $has_pod = $search->contains_pod($path);

            my $section = 'other';

            if (   $name =~ /::Role::/)        { $section = 'roles'       }
            elsif ($name =~ /::Models::/)      { $section = 'models'      }
            elsif ($name =~ /::Controllers::/) { $section = 'controllers' }
            elsif ($name =~ /::Adapter::/)     { $section = 'adapters'    }
            elsif ($name =~ /::Plugins?::/)    { $section = 'plugins'     }
            
            push @{$modules->{$section}}, { name => $name, has_doc => $has_pod?true:false, path => $url };
        }
    }


    my ($template, undef) = $self->app->renderer->render(
        $self,
        { 
            template    => 'perldoc/perldocindex',
            partial     => 1, 
            handler     => 'ep', 
            title       => "Index",
            guides      => $guides,
            modules     => $modules,
        }
    );
    $self->render(inline => $template);
    $self->res->headers->content_type('text/html;charset="UTF-8"');

    return;
}

# ------------------------------------------------------------------------------ 

sub _perldoc {
    my $self = shift;

    my $module = $self->param('module');
    $module =~ s/\.pod$//;

    if ($module eq 'DocIndex') {
        return _generateIndex($self);
    }

    my $path = Pod::Simple::Search->new->find($module, @PATHS) || '';

    # Check whether the file we're dealing with is a perl module with embedded
    # pod or whether it's a pure pod doc.
    # If the extension is "pod" then it's a standalone. If it's "pm" then there
    # will be source code.
    my $extension = ($path =~ /\.(pm|pod)$/)[0];

    # Convert the full module name to a perl package
    my $package =  $module;
       $package =~ s!/!::!g;



    my $file_name = ($module =~ /(\w+)(\.(pm|pod))?$/)[0];

    # If we're looking at perl source then we want to know if we're expecting the
    # doc view or the source view.
    my $is_perl_source   = false;
    my $linked_file_name = '';
    if ($extension && $extension eq 'pm') {
        # We know if we're viewing the source as the extension of the module name
        # passed in will have the pm extension.
        $is_perl_source = true if $module =~ /\.pm$/;

        if ($is_perl_source) {
            $linked_file_name = $file_name;
        }
        else {
            $linked_file_name = $file_name . '.pm'; # Link is source
        }
    }
    
    my $html = undef;

    if (!-e $path) {
        # Redirect to the index page
        return _generateIndex($self);
    }
    else {
        my $slurped = slurp $path;
        $html = $is_perl_source ? "<pre>".xml_escape($slurped)."</pre>" : _pod_to_html($slurped);

        # Ensure % gets escaped before going into the template
        # for perl source files.
        $html =~ s/^( *)\%/$1<%='%'%>/gm;
    }


    # TODO ATTRIBUTES ==== TODO Autoinsert
    # Introspect the class to find the attributes
    _parse_attributes(\$html, $package, $module) if !$is_perl_source && ($html =~ /\[\[ATTRIBUTES\]\]/);
  

    # Rewrite links
    my $dom     = Mojo::DOM->new("$html");
    my $perldoc = $self->url_for('/perldoc/');
    $dom->find('a[href]')->each(
        sub {
            my $attrs = shift->attrs;
            $attrs->{href} =~ s!%3A%3A!/!gi
            if $attrs->{href} =~ s!^http://search\.cpan\.org/perldoc\?!$perldoc!;
        }
    );

    
    # Rewrite code blocks for syntax highlighting
    $dom->find('pre')->each(
        sub {
            my $e = shift;
            return if $e->all_text =~ /^\s*\$\s+/m;

            my $attrs = $e->attrs;
            my $class = $attrs->{class};
            $attrs->{class} = defined $class ? "$class prettyprint" : 'prettyprint';
        }
    );

    # Rewrite headers
    my $url = $self->req->url->clone;
    my (%anchors, @parts);
    $dom->find('h1, h2, h3')->each(
        sub {
            my $e = shift;

            # Anchor and text
            my $name = my $text = $e->all_text;
            $name =~ s/\s+/_/g;
            $name =~ s/[^\w\-]//g;
            my $anchor = $name;
            my $i      = 1;
            $anchor = $name . $i++ while $anchors{$anchor}++;

            # Rewrite
            push @parts, [] if $e->type eq 'h1' || !@parts;

            my $link_text = $text;
               $link_text =~ s/\[.*\]//;
               $link_text =~ s/\(.*\)//;

            push @{$parts[-1]}, $text, $url->fragment($anchor)->to_abs;

            $e->replace_content(
                $self->link_to(
                    $text => $url->fragment('toc')->to_abs,
                    class => 'mojoscroll',
                    id    => $anchor
                )
            );
        }
    );

    # Format h2's if they're method names
    $dom->find('h2')->each(
        sub {
            my $e = shift;
            my $text = $e->all_text;

            if ($text !~ /\[(.+)\] *(\w+) *\((.*)\)/) {
                return;
            }

            my ($type, $name, $args) = ($text =~ /\[(.+)\] *(\w+) *\((.*)\)/);
            $e->replace_content(
                    '<span class="code">'
                    .'<span class="return-type">['.$type.']</span> '
                    ."$name "
                    .'<span class="arg-list">('.$args.')</span>'
                    .'</span>'
                );
        }
    );

    # Reformat PRE blocks (again - need to combine this possibly with the mojo written one above)
    if (!$is_perl_source) {
        $dom->find('pre')->each(
            sub {
                my $e = shift;
    
                my $re             = qr/\@(param|returns|named|throws) (.+)/;
                my $context        = 'before';
                my $has_seen_tags  = false;
    
                my %parts     = (
                    before => [[]], after   => [[]],
                    param  => [],   returns => [], 
                    named  => [],   throws  => [],
                );
    
                if ($e->all_text =~ $re) {
                    foreach my $line (split "\n", $e->all_text) {
                        
                        if ($line =~ /^ *$/) { # Blank lines switch 
                            $context = $has_seen_tags ? 'after' : 'before';
                        }
    
                        if ($line =~ $re) {
                            $context       = $1; # One of the tag contexts
                            $line          = $2;
                            $has_seen_tags = true;
                            push @{$parts{$context}},[]; # Create a new array for the new context
                        }
    
                        if (defined $context) {
                            # Get the last item of this type, and add to it.
                            $line  =~ s/^ *// if ($context !~ /before|after/);
                            push @{$parts{ $context }->[-1]}, $line;
                            next;
                        }
    
                    }
    
                    # Output the parts - we do this by appending to the original element
                    # in reverse order and then removing the original.

                    # Output AFTER
                    if (scalar @{$parts{after}->[0]}) {
                        $e->append('<pre>' . join(" ",@{$parts{after}->[0]}) . '</pre>');
                    }
    
                    if (@{$parts{returns}} || @{$parts{param}} || @{$parts{named}}) {
                        my $block = '<div class="tag-table-block">';
        
                        # Output Parameters
                        if (scalar @{$parts{param}}) {
                            $block .= __start_table( 'parameters', '3' );
                            foreach my $param (@{$parts{param}}) {
                                (my $whole_line = join ' ',@$param ) =~ /(\S+) +\[([^\]]+)\] +(.+)/;
                                $block .= qq|<tr><td class="code">$1</td><td class="italic">$2</td><td>$3</td></tr>|;
                            }
                            $block .= '</table>';
                        }
    
                        # Output Named Parameters
                        if (scalar @{$parts{named}}) {
                            $block .= __start_table( 'named parameters', '3' );
                            foreach my $param (@{$parts{named}}) {
                                (my $whole_line = join ' ',@$param ) =~ /(\S+) +\[([^\]]+)\] +(.+)/;
                                $block .= qq|<tr><td class="code">$1</td><td class="italic">$2</td><td>$3</td></tr>|;
                            }
                            $block .= '</table>';
                        }
    
                        # Output Return
                        if (scalar @{$parts{returns}}) {
                            $block .= __start_table( 'returns', '1' );
                            my $whole_line = join ' ', @{$parts{returns}->[0]};
                            $block .= qq|<tr><td>$whole_line</td></tr>|;
                            $block .= '</table>';
                        }
                        
                        # Output Throws
                        if (scalar @{$parts{throws}}) {
                            $block .= __start_table( 'throws', '1' );
                            foreach my $param (@{$parts{throws}}) {
                                my $whole_line = join ' ', @{$parts{throws}->[0]};
                                $block .= qq|<tr><td>$whole_line</td></tr>|;
                            }
                            $block .= '</table>';
                        }
                        $block .= '</div>';
                        $e->append( $block );
                    }
    
                    # Output BEFORE
                    if (scalar @{$parts{before}->[0]}) {
                        $e->append( '<pre class="prettyprint">' . join(" ",@{$parts{before}->[0]}) . '</pre>');
                    }
                  
                    # Remove the original element
                    $e->remove;
                }
            }
        );
    }

    # Try to find a title
    my $title = 'Perldoc';
    $dom->find('h1 + p')->first(sub { $title = shift->text });

    # Combine everything to a proper response
    $self->content_for(perldoc => "$dom");

    my $template_name    = $is_perl_source ? 'perlsource' : 'perldoc';

    my ($template, undef) = $self->app->renderer->render(
        $self,
        { 
            template    => 'perldoc/'.$template_name,
            partial     => 1, 
            handler     => 'ep', 
            title       => $title,
            linked_file => $linked_file_name,
            parts       => \@parts,
        }
    );
    $self->render(inline => $template);
    $self->res->headers->content_type('text/html;charset="UTF-8"');
    return;
}

# ------------------------------------------------------------------------------ 

sub __start_table {
    my ($name, $span) = @_;
    return qq|<table class="tag-table"><tr><th colspan="$span">$name</th></tr>|;
}

# ------------------------------------------------------------------------------ 

sub _pod_to_html {
    return undef unless defined(my $pod = shift);

    # Block
    $pod = $pod->() if ref $pod eq 'CODE';

    my $parser = Pod::Simple::HTML->new;
    $parser->force_title('');
    $parser->html_header_before_title('');
    $parser->html_header_after_title('');
    $parser->html_footer('');
    $parser->output_string(\(my $output));
    return $@ unless eval { $parser->parse_string_document("$pod"); 1 };

    # Filter
    $output =~ s!<a name='___top' class='dummyTopAnchor'\s*?></a>\n!!g;
    $output =~ s!<a class='u'.*?name=".*?"\s*>(.*?)</a>!$1!sg;

    return $output;
}

# ------------------------------------------------------------------------------ 

sub _parse_attributes {
    my ($html_r, $package, $module) = @_;
    
    $module =~ s/\.pm$//;

    require "$module.pm";

    my $meta = Class::MOP::Class->initialize($package);

    my %local_attributes = ();
    my %inherited_attributes = ();

    if ($meta->can("get_attribute_list")) {
        foreach my $attr ($meta->get_attribute_list) {
            $local_attributes{$attr} = 1;
        }
    }
    
    if ($meta->can("get_all_attributes")) {
        foreach my $attr ($meta->get_all_attributes) {
            if (!exists $local_attributes{$attr->name}) {
                $inherited_attributes{$attr->name} = 1;
            }
        }
    }

    my $replace = '';

    my $local     = join(", ", sort keys %local_attributes);
    my $inherited = join(", ", sort keys %inherited_attributes);

    if ($local and $inherited) { $local .= ', ' };

    if ($local or $inherited) {
        $replace = qq|<div class="code">$local<em>$inherited</em></div><br>|;
    }
    $$html_r =~ s/\[\[ATTRIBUTES\]\]/$replace/;
    return;
}

# ============================================================================== 

1;

=head1 NAME

MojoX::Plugin::PODRenderer

=head1 SYNOPSIS

  use MojoX::Plugin::PODRenderer;

  $self->plugin( 'MojoX::Plugin::PODRenderer' );

=head1 DESCRIPTION

Perl pod rendering plugin. Based on the original Mojo::PODRenderer.

=head1 METHODS

=head2 [void] register( $app, $conf )

Called by Mojo app to register the plugin

    @param  app     [mojo application]  ref to the mojo application
    @param  conf    [hash]              configuration hash

=cut
