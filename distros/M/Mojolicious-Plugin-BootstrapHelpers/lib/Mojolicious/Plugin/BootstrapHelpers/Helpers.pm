use 5.20.0;
use warnings;

package Mojolicious::Plugin::BootstrapHelpers::Helpers;

# ABSTRACT: Supporting module
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0206';

use List::Util qw/uniq/;
use Mojo::ByteStream;
use Mojo::Util 'xml_escape';
use Scalar::Util 'blessed';
use String::Trim;
use String::Random;
use experimental qw/postderef signatures/;

sub bootstraps_bootstraps {
    my $c = shift;
    my $arg = shift;

    my $bs_version = '3.4.1';

    my $css   = qq{<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/$bs_version/css/bootstrap.min.css">};
    my $theme = qq{<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/$bs_version/css/bootstrap-theme.min.css">};
    my $js    = qq{<script src="https://maxcdn.bootstrapcdn.com/bootstrap/$bs_version/js/bootstrap.min.js"></script>};
    my $jq    = q{<script src="https://code.jquery.com/jquery-2.2.4.min.js"></script>};

    return out(
          !defined $arg  ? $css
        : $arg eq 'css'  ? join "\n" => $css, $theme
        : $arg eq 'js'   ? join "\n" => $js
        : $arg eq 'jsq'  ? join "\n" => $jq, $js
        : $arg eq 'all'  ? join "\n" => $css, $theme, $js
        : $arg eq 'allq' ? join "\n" => $css, $theme, $jq, $js
        :                  ''
    );
}

sub bootstrap_panel {
    my($c, $title, $callback, $content, $attr) = parse_call(@_);

    $attr = add_classes($attr, 'panel', { panel => 'panel-%s', panel_default => 'default'});

    my $body = qq{
            <div class="panel-body">
                } . contents($callback, $content) . qq{
            </div>
    };

    return create_panel($c, $title, $body, $attr);

}
#-header => [buttongroup => ['Scan', ['#'], data => { bind => 'click: scanDatabases'}]]
sub create_panel {
    my $c = shift;
    my $title = shift;
    my $body = shift;
    my $attr = shift;

    my $header_attr = exists $attr->{'-header'} ? delete($attr->{'-header'}) : [];
    my $header_button_groups = '';
    if(scalar keys @$header_attr) {
        for my $attr (shift @$header_attr) {
            if($attr eq 'buttongroup') {
                $header_button_groups .= bootstrap_buttongroup($c, class => 'pull-right', (shift @$header_attr)->@*);
            }
        }
    }

    my $tag = qq{
        <div class="$attr->{'class'}">
        } . (defined $title ? qq{
            <div class="panel-heading">
                <h3 class="panel-title">$header_button_groups$title</h3>
            </div>
        } : '') . qq{
            $body
        </div>
    };

    return out($tag);
}

sub bootstrap_table {
    my $c = shift;
    my $callback = ref $_[-1] eq 'CODE' ? pop : undef;
    my $title = scalar @_ % 2 ? shift : undef;
    my $attr = parse_attributes(@_);

    $attr = add_classes($attr, 'table', { table => 'table-%s' });
    my $html = htmlify_attrs($attr);

    my $table = qq{
        <table class="$attr->{'class'}"$html>
        } . $callback->() . qq{
        </table>
    };

    if(defined $title) {
        $attr->{'panel'} = add_classes($attr->{'panel'}, 'panel', { panel => 'panel-%s', panel_default => 'default'});
    }

    return defined $title ? create_panel($c, $title, $table, $attr->{'panel'}) : out($table);
}

sub htmlify_attrs {
    my $attr = shift;
    return '' if !defined $attr;
    $attr = cleanup_attrs({$attr->%*}); #* Make a copy

    my $html = join ' ' => map { qq{$_="$attr->{ $_ }"} } grep { length $attr->{ $_ } } sort keys $attr->%*;
    return ' ' . $html if defined $html;
    return '';
}

sub bootstrap_formgroup {
    my $c = shift;
    my $title = ref $_[-1] eq 'CODE' ? pop
              : scalar @_ % 2        ? shift
              :                        undef;
    my $attr = parse_attributes(@_);

    $attr->{'column_information'} = delete $attr->{'cols'} if ref $attr->{'cols'} eq 'HASH';

    my($id, $input) = fix_input($c, $attr);
    my $label = defined $title ? fix_label($c, $id, $title, $attr) : '';

    $attr = add_classes($attr, 'form-group', { size => 'form-group-%s'});
    $attr = cleanup_attrs($attr);


    my $tag = qq{
        <div class="$attr->{'class'}">
            $label
            $input
        </div>
    };

    return out($tag);
}

sub bootstrap_button {
    my $c = shift;
    my $content = ref $_[-1] eq 'CODE' ? pop : shift;
    $content = '' if !defined $content;

    my @url = shift->@* if ref $_[0] eq 'ARRAY';
    my $attr = parse_attributes(@_);

    my $caret = exists $attr->{'__caret'} && $attr->{'__caret'} ? (length $content ? ' ' : '') . q{<span class="caret"></span>} : '';

    $attr->{'type'} = 'button' if !scalar @url && !exists $attr->{'type'};
    $attr = add_classes($attr, 'btn', { size => 'btn-%s', button => 'btn-%s', button_default => 'default' });
    $attr = add_classes($attr, 'active') if $attr->{'__active'};
    $attr = add_classes($attr, 'block') if $attr->{'__block'};
    $attr = add_disabled($attr, scalar @url);
    $attr = cleanup_attrs($attr);

    # We have an url
    if(scalar @url) {
        $attr->{'href'} = url_for($c, \@url);

        my $html = htmlify_attrs($attr);
        return out(qq{<a$html>} . content_single($content) . qq{$caret</a>});
    }
    else {
        my $html = htmlify_attrs($attr);
        return out(qq{<button$html>} . content_single($content) . qq{$caret</button>});
    }

}

sub bootstrap_submit {
    push @_ => (type => 'submit');
    return bootstrap_button(@_);
}

sub bootstrap_context_menu {
    my $c = shift;
    my %args = @_;
    my $items = delete $args{'items'};
    my $list = make_dropdown_list($c, \%args, $items);

    return out($list);
}

sub bootstrap_dropdown {
    my $meat = make_dropdown_meat(shift, shift->@*);

    my $dropdown = qq{
        <div class="dropdown">
            $meat
        </div>
    };
    return out($dropdown);
}

sub make_dropdown_meat {
    my $c = shift;

    my $button_text = shift;
    my @url = ref $_[0] eq 'ARRAY' ? shift->@* : ();
    my $attr = parse_attributes(@_);

    my $items = delete $attr->{'items'} || [];
    my $ulattr = { __right => exists $attr->{'__right'} ? delete $attr->{'__right'} : 0 };
    my $listhtml = make_dropdown_list($c, $ulattr, $items);

    $attr = add_classes($attr, 'dropdown-toggle');
    $attr->{'data-toggle'} = 'dropdown';
    $attr->{'type'} = 'button';
    my $button = bootstrap_button($c, $button_text, @url, $attr->%*);

    my $out = qq{
        $button
        $listhtml
    };
    return out($out);
}

sub make_dropdown_list {
    my $c = shift;
    my $attr = shift;
    my $items = shift;

    $attr = add_classes($attr, 'dropdown-menu');
    $attr = add_classes($attr, 'dropdown-menu-right') if $attr->{'__right'};
    my $attrhtml = htmlify_attrs($attr);
    my $menuitems = '';

    ITEM:
    foreach my $item ($items->@*) {
        if(ref $item eq '') {
            $menuitems .= qq{<li class="dropdown-header">$item</li>};
        }
        next ITEM if ref $item ne 'ARRAY';
        if(!scalar $item->@*) {
            $menuitems .= q{<li class="divider"></li>} ;
        }
        else {
            $menuitems .= create_dropdown_menuitem($c, $item->@*);
        }

    }
    my $out = qq{
        <ul$attrhtml>
            $menuitems
        </ul>
    };
    return out($out);
}

sub create_dropdown_menuitem {
    my $c = shift;
    my $item_text = iscoderef($_[-1]) ? pop : shift;
    my @url = shift->@*;

    my $attr = parse_attributes(@_);
    $attr = add_classes($attr, 'menuitem');
    my $liattr = { __disabled => exists $attr->{'__disabled'} ? delete $attr->{'__disabled'} : 0 };
    $liattr = add_disabled($liattr, 1);
    $attr->{'tabindex'} ||= -1;
    $attr->{'href'} = url_for($c, \@url);

    my $html = htmlify_attrs($attr);
    my $lihtml = htmlify_attrs($liattr);

    my $tag = qq{<li$lihtml><a$html>$item_text</a></li>};

    return out($tag);
}

sub bootstrap_buttongroup {
    my $c = shift;

    #* Shortcut for one button menus
    if(ref $_[0] eq 'ARRAY') {
        my $meat = make_dropdown_meat($c, $_[0]->@*);
        my $menu = qq{<div class="btn-group">$meat</div>};
        return out($menu);
    }
    my($buttons, $html) = make_buttongroup_meat($c, @_);

    my $tag = qq{
        <div$html>
            $buttons
        </div>};

    return out($tag);
}

sub make_buttongroup_meat {
    my $c = shift;

    my $attr = parse_attributes(@_);
    my $buttons_info = delete $attr->{'buttons'};

    my $button_group_class = delete $attr->{'__vertical'} ? 'btn-group-vertical' : 'btn-group';
    my $justified_class = delete $attr->{'__justified'} ? 'btn-group-justified' : ();

    $attr = add_classes($attr, { size => 'btn-group-%s' });

    #* For the possible inner btn-group, use the same base classes (except justified/vertical/pull-right).
    #* We add possible .dropup in the loop
    my $inner_attr = add_classes({ class => $attr->{'class'} }, 'btn-group');
    $inner_attr->{'class'} =~ s{\bpull-right\b}{};

    #* These must come after the inner button group has been given the classes.
    $attr = add_classes($attr, $button_group_class, $justified_class);
    my $html = htmlify_attrs($attr);


    my $buttons = '';

    BUTTON:
    foreach my $button ($buttons_info->@*) {
        next BUTTON if ref $button ne 'ARRAY';

        my $button_text = shift $button->@*;
        my @url = ref $button->[0] eq 'ARRAY' ? shift $button->@* : ();
        my $button_attr = parse_attributes($button->@*);
        my $items = delete $button_attr->{'items'} || [];

        if(!scalar $items->@*) {
            my $bootstrap_button = bootstrap_button($c, $button_text, @url, $button_attr->%*);

            #* Justified + No url -> button -> must nest
            if(length $justified_class && !scalar @url) {
                $buttons .= qq{<div class="btn-group">$bootstrap_button</div>};
            }
            else {
                $buttons .= $bootstrap_button;
            }
            next BUTTON;
        }

        my $dropup_class = delete $button_attr->{'__dropup'} ? 'dropup' : ();
        $inner_attr = add_classes($inner_attr, $dropup_class);
        my $inner_html = htmlify_attrs($inner_attr);
        my $meat = make_dropdown_meat($c, $button_text, (scalar @url ? \@url : ()), $button_attr->%*, items => $items);
        $buttons .= qq{
            <div$inner_html>
                $meat
            </div>
        };

    }
    return ($buttons, $html);
}

sub bootstrap_toolbar {
    my $c = shift;

    my $attr = parse_attributes(@_);
    my $groups = delete $attr->{'groups'};

    $attr = add_classes($attr, 'btn-toolbar');
    my $html = htmlify_attrs($attr);

    my $toolbar = '';
    foreach my $group ($groups->@*) {
        $toolbar .= bootstrap_buttongroup($c, $group->%*);
    }

    my $tag = qq{
        <div$html>
            $toolbar
        </div>
    };

    return out($tag);
}

sub bootstrap_navbar {
    my $c = shift;

    my($possible_toggler_id, $navbar_header) = ();

    my $content_html = '';
    my $has_inverse = 0;
    my $container = 'fluid';

    while(scalar @_) {
        my $key = shift;
        my @arguments = ($c, shift);

        $content_html .= $key eq 'nav'    ?   make_navbar_nav(@arguments)
                       : $key eq 'form'   ?   make_navbar_form(@arguments)
                       : $key eq 'button' ?   make_navbar_button(@arguments)
                       : $key eq 'p'      ?   make_navbar_p(@arguments)
                       :                      ''
                       ;
        if($key eq 'header') {
            ($possible_toggler_id, $navbar_header) = make_navbar_header(@arguments);
        }
        if($key eq '__inverse') {
            $has_inverse = 1;
        }
        if($key eq 'container') {
            $container = $arguments[1];
        }

    }
    $container = $container eq 'normal' ? 'container' : 'container-fluid';

    my $attr = $has_inverse ? { __inverse => 1 } : {};
    $attr = add_classes($attr, 'navbar', { navbar => 'navbar-%s', navbar_default => 'default' });
    my $html = htmlify_attrs($attr);
    if(length $content_html) {
        $content_html = qq{
            <div class="collapse navbar-collapse" id="$possible_toggler_id">
                $content_html
            </div>
        };
    }

    my $tag = qq{
        <nav$html>
            <div class="$container">
                $navbar_header
                $content_html
            </div>
        </nav>
    };

    return out($tag);

}
sub make_navbar_header {
    my($c, $header, $html_header) = @_;

    return (undef, $html_header) if $html_header;

    my $brand = shift $header->@*;
    my $url = url_for($c, shift $header->@* || []);
    my $header_attr = parse_attributes($header->@*);
    my $toggler_id = delete $header_attr->{'toggler'} || 'collapsable-' . String::Random->new->randregex('[a-z]{20}');
    my $has_hamburger = delete $header_attr->{'__hamburger'};
    my $hamburger = $has_hamburger ? get_hamburger($toggler_id) : '';
    $header_attr = add_classes($header_attr, 'navbar-brand');

    my $brand_html = defined $brand ? qq{<a class="navbar-brand" href="$url">$brand</a>} : '';

    my $navbar_header = qq{
        <div class="navbar-header">
            $hamburger
            $brand_html
        </div>
    };

    return ($toggler_id, $navbar_header);

}

sub make_navbar_nav {
    my $c = shift;
    my $nav = shift;

    my $attr = parse_attributes($nav->@*);
    my $items = delete $attr->{'items'};
    $attr = add_classes($attr, 'nav', 'navbar-nav', { direction => 'navbar-%s' });
    my $html = htmlify_attrs($attr);

    my $tag = "<ul$html>";
    $tag .= make_nav_meat($c, $items);

    $tag .= '</ul>';
    return $tag;
}

sub make_navbar_form {
    my $c = shift;
    my $form = shift;
    my $args = shift $form->@*;
    my $contents = shift $form->@*;
    my $url = shift $args->@*;

    my $attr = parse_attributes($args->@*);

    $attr = add_classes($attr, 'navbar-form', { direction => 'navbar-%s', direction_default => 'left' });
    $attr = cleanup_attrs($attr);

    my $tag = '';
    for (my $index = 0; $index < scalar $contents->@*; $index += 2) {
        my $key = $contents->[$index];
        my @arguments = ($c, $contents->[$index + 1]->@*);

        if($key eq 'formgroup') {
            $tag .= bootstrap_formgroup(@arguments);
        }
        elsif($key eq 'submit_button') {
            $tag .= bootstrap_submit(@arguments);
        }
        elsif($key eq 'button') {
            $tag .= bootstrap_button(@arguments)
        }
        elsif($key eq 'input') {
            $tag .= bootstrap_input(@arguments);
        }
    }

    $tag = Mojolicious::Plugin::TagHelpers::_form_for($c, $url->@*, $attr->%*, sub { $tag });
    return out($tag);

}

sub make_navbar_button($c, $arg) {
    my $text = shift $arg->@*;
    my $url = shift $arg->@*;
    my $attr = parse_attributes($arg->@*);
    $attr = add_classes($attr, 'navbar-btn', { direction => 'navbar-%s' });
    return bootstrap_button($c, $text, $url, $attr->%*);
}

sub make_navbar_p($c, $arg) {
    my $text = shift $arg->@*;
    my $attr = parse_attributes($arg->@*);
    $attr = add_classes($attr, 'navbar-text', { direction => 'navbar-%s' });
    my $html = htmlify_attrs($attr);

    return out(qq{<p$html>$text</p>});
}

sub get_hamburger {
    my $toggler_id = shift;

    my $tag = qq{
        <button class="collapsed navbar-toggle" data-target="#$toggler_id" data-toggle="collapse" type="button">
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
        </button>
    };
    return $tag;
}

sub make_nav_meat {
    my $c = shift;
    my $contents = shift;

    my $tag = '';
    CONTENT:
    foreach my $content ($contents->@*) {
        next CONTENT if ref $content ne 'ARRAY';

        my $text = shift $content->@*;
        my $url = url_for($c, shift $content->@*);
        my $attr = parse_attributes($content->@*);

        my $items = delete $attr->{'items'} || [];
        #* No sub menu
        if(!scalar $items->@*) {
            my $active = delete $attr->{'__active'};
            my $disabled = delete $attr->{'__disabled'};
            my $li_attr = exists $attr->{'-li'} ? parse_attributes(delete($attr->{'-li'})->@*) : {};
            $li_attr = add_classes($li_attr, $active ? 'active' : (), $disabled ? 'disabled' : ());
            my $li_html = htmlify_attrs($li_attr);

            my $a_attr = htmlify_attrs($attr);

            my $link_html = qq{<a href="$url"$a_attr>$text</a>};
            $tag .= qq{<li$li_html>$link_html</li>};
            next CONTENT;
        }
        else {
            $attr = add_classes($attr, 'dropdown-toggle');
            $attr->{'data-toggle'} = 'dropdown';
            $attr->{'href'} = $url;
            my $caret = delete $attr->{'__caret'} ? ' <span class="caret"></span>' : '';
            my $button_arg = htmlify_attrs($attr);
            my $button_html = qq{<a$button_arg>$text$caret</a>};

            my $lis = '';
            ITEM:
            foreach my $item ($items->@*) {
                if(!scalar $item->@*) {
                    $lis .= q{<li class="divider"></li>};
                    next ITEM;
                }
                my $text = shift $item->@*;
                my $url = url_for($c, shift $item->@*);
                my $a_attr = parse_attributes($item->@*);
                $a_attr->{'href'} = $url;
                my $a_html = htmlify_attrs($a_attr);
                $lis .= qq{<li><a$a_html>$text</a></li>};
            }
            $tag .= qq{
                <li class="dropdown">
                    $button_html
                    <ul class="dropdown-menu">
                        $lis
                    </ul>
                </li>
            };
        }
    }
    return $tag;
}

sub bootstrap_nav {
    my $c = shift;
    my $attr = parse_attributes(@_);
    my $pills = delete $attr->{'pills'};
    my $tabs = delete $attr->{'tabs'};

    my $which = $pills ? 'nav-pills'
              : $tabs  ? 'nav-tabs'
              :          ()
              ;
    my $justified = delete $attr->{'__justified'} ? 'nav-justified' : ();
    $attr = add_classes($attr, 'nav', $which, $justified);
    my $html = htmlify_attrs($attr);
    my $either = $pills || $tabs;

    my $tag = make_nav_meat($c, $either);
    $tag = qq{<ul$html>$tag</ul>};

    return out($tag);
}

sub bootstrap_badge {
    my $c = shift;
    my $content = iscoderef($_[-1]) ? pop : shift;
    my $attr = parse_attributes(@_);

    $attr = add_classes($attr, 'badge', { direction => 'pull-%s' });
    my $html = htmlify_attrs($attr);

    my $badge = defined $content && length $content ? qq{<span$html>$content</span>} : '';

    return out($badge);
}

sub bootstrap_icon {
    my $c = shift;
    my $icon = shift;

    my $icon_class = $c->config->{'Plugin::BootstrapHelpers'}{'icons'}{'class'};
    my $formatter = $c->config->{'Plugin::BootstrapHelpers'}{'icons'}{'formatter'};

    my $this_icon = sprintf $formatter => $icon;
    my $attr = parse_attributes(@_);
    $attr = add_classes($attr, $icon_class, $this_icon);
    my $html = htmlify_attrs($attr);

    return '' if !defined $icon || !length $icon;
    return out(qq{<span$html></span>});
}

sub bootstrap_input {
    my $c = shift;
    my $attr = parse_attributes(@_);

    my $prepend = delete $attr->{'prepend'};
    my $append = delete $attr->{'append'};

    my(undef, $input_tag) = fix_input($c, (delete $attr->{'input'}) );
    $attr = add_classes($attr, 'input-group', { size => 'input-group-%s' });
    my $html = htmlify_attrs($attr);

    my($prepend_tag, $append_tag) = undef;

    if($prepend) {
        $prepend_tag = fix_input_ender($c, $prepend);
    }
    if($append) {
        $append_tag = fix_input_ender($c, $append);
    }

    my $tag = qq{
        <div$html>
            } . ($prepend_tag || '') . qq{
            $input_tag
            } . ($append_tag || '') . qq{
        </div>
    };

    return out($tag);

}

sub fix_input_ender {
    my $c = shift;
    my $ender = shift;
    my $where = shift;

    if(ref $ender eq '') {
        return qq{<span class="input-group-addon">$ender</span>};
    }

    my $key = (keys $ender->%*)[0];
    my $tag = undef;
    if($key eq 'check_box' || $key eq 'radio_button') {
        my $type = $key eq 'check_box' ? 'checkbox' : 'radio';
        my $extra_input = Mojolicious::Plugin::TagHelpers::_input($c, $ender->{ $key }->@*, type => $type);
        $tag = qq{
            <span class="input-group-addon">$extra_input</span>
        };
    }
    elsif($key eq 'button') {
        my $button = bootstrap_button($c, $ender->{ $key }->@*);
        $tag = qq{
            <span class="input-group-btn">$button</span>
        };
    }
    elsif($key eq 'buttongroup') {
        return '' if ref $ender->{ $key } ne 'ARRAY';
        my($button_group) = scalar $ender->{ $key }->@* == 1 ? make_dropdown_meat($c, $ender->{ $key }[0]->@*)
                         :                                   make_buttongroup_meat($c, $ender->{ $key }->@*)
                         ;
        $tag = qq{
            <div class="input-group-btn">$button_group</div>
        }
    }
    else { $tag = $key; }

    return $tag;
}

sub iscoderef {
    return ref shift eq 'CODE';
}
sub url_for {
    my $c = shift;
    my $url = shift;
    return '' if ref $url ne 'ARRAY';
    return $url->[0] if scalar $url->@* == 1 && substr ($url->[0], 0, 1) eq '#';
    return $c->url_for($url->@*)->to_string;
}

sub fix_input {
    my $c = shift;
    my $attr = shift;

    my $tagname;
    my $info;

    if((grep { exists $attr->{"${_}_field"} } qw/date datetime month time week color email number range search tel text url password/)[0]) {
        $tagname = (grep { exists $attr->{"${_}_field"} } qw/date datetime month time week color email number range search tel text url password/)[0];
        $info = $attr->{"${tagname}_field"};
    }
    elsif(exists $attr->{'text_area'}) {
        $tagname = 'textarea';
        $info = $attr->{'text_area'};
    }
    my $id = shift $info->@*;

    # if odd number of elements, the first one is the value (shortcut to avoid having to: value => 'value')
    if($info->@* % 2) {
        push $info->@* => (value => shift $info->@*);
    }
    my $tag_attr = { $info->@* };

    my @column_classes = get_column_classes($attr->{'column_information'}, 1);
    $tag_attr = add_classes($tag_attr, 'form-control', { size => 'input-%s' });

    $tag_attr->{'id'} = $id if defined $id && !exists $tag_attr->{'id'};
    my $name_attr = defined $id ? $id =~ s{-}{_}rg : undef;

    $tag_attr = cleanup_attrs($tag_attr);

    my $horizontal_before = scalar @column_classes ? qq{<div class="} . (trim join ' ' => @column_classes) . '">' : '';
    my $horizontal_after = scalar @column_classes ? '</div>' : '';
    my $input = exists $attr->{'text_area'} ? Mojolicious::Plugin::TagHelpers::_text_area($c, $name_attr, delete $tag_attr->{'value'}, $tag_attr->%*)
              :                               Mojolicious::Plugin::TagHelpers::_input($c, $name_attr, $tag_attr->%*, type => $tagname)
              ;

    return ($id => $horizontal_before . $input . $horizontal_after);

}

sub fix_label {
    my $c = shift;
    my $for = shift;
    my $title = shift;
    my $attr = shift;

    my @column_classes = get_column_classes($attr->{'column_information'}, 0);
    my @args = (class => trim join ' ' => ('control-label', @column_classes));
    ref $title eq 'CODE' ? push @args => $title : unshift @args => $title;

    return Mojolicious::Plugin::TagHelpers::_label_for($c, $for, @args);
}

sub parse_call {
    my $c = shift;
    my $title = shift;
    my $callback = ref $_[-1] eq 'CODE' ? pop : undef;
    my $content = scalar @_ % 2 ? pop : '';
    my $attr = parse_attributes(@_);

    return ($c, $title, $callback, $content, $attr);
}

sub parse_attributes {
    my %attr = @_;
    if($attr{'data'} && ref $attr{'data'} eq 'HASH') {
        while(my($key, $value) = each %{ $attr{'data'} }) {
            $key =~ tr/_/-/;
            $attr{ lc("data-$key") } = $value;
        }
        delete $attr{'data'};
    }
    return \%attr;
}

sub get_column_classes {
    my $attr = shift;
    my $index = shift;

    my @classes = ();
    foreach my $key (keys $attr->%*) {
        my $correct_name = get_size_for($key);
        if(defined $correct_name) {
            push @classes => sprintf "col-%s-%d" => $correct_name, $attr->{ $key }[ $index ];
        }
    }
    return sort @classes;
}

sub add_classes {
    my $attr = shift;
    my $formatter = ref $_[-1] eq 'HASH' ? pop : undef;

    no warnings 'uninitialized';

    my @classes = ($attr->{'class'}, @_);

    if($formatter) {
        if(exists $formatter->{'size'}) {
            push @classes => sprintfify_class($attr, $formatter->{'size'}, $formatter->{'size_default'}, _sizes());
        }
        if(exists $formatter->{'button'}) {
            push @classes => sprintfify_class($attr, $formatter->{'button'}, $formatter->{'button_default'}, _button_contexts());
        }
        if(exists $formatter->{'panel'}) {
            push @classes => sprintfify_class($attr, $formatter->{'panel'}, $formatter->{'panel_default'}, _panel_contexts());
        }
        if(exists $formatter->{'table'}) {
            push @classes => sprintfify_class($attr, $formatter->{'table'}, $formatter->{'table_default'}, _table_contexts());
        }
        if(exists $formatter->{'direction'}) {
            push @classes => sprintfify_class($attr, $formatter->{'direction'}, $formatter->{'direction_default'}, _direction_contexts());
        }
        if(exists $formatter->{'navbar'}) {
            push @classes => sprintfify_class($attr, $formatter->{'navbar'}, $formatter->{'navbar_default'}, _navbar_contexts());
        }
    }

    my %uniqs = ();
    $attr->{'class'} = trim join ' ' => uniq sort @classes;

    return $attr;

}

sub sprintfify_class {
    my $attr = shift;
    my $format = shift;
    my $possibilities = pop;
    my $default = shift;

    my @founds = (grep { exists $attr->{ $_ } } (keys $possibilities->%*));

    return if !scalar @founds && !defined $default;
    push @founds => $default if !scalar @founds;

    return map { sprintf $format => $possibilities->{ $_ } } @founds;

}

sub add_disabled {
    my $attr = shift;
    my $add_as_class = shift; # if false, add as attribute

    if(exists $attr->{'__disabled'} && $attr->{'__disabled'}) {
        if($add_as_class) {
            $attr = add_classes($attr, 'disabled');
        }
        else {
            $attr->{'disabled'} = 'disabled';
        }
    }
    return $attr;
}

sub contents {
    my $callback = shift;
    my $content = shift;

    return defined $callback ? $callback->() : xml_escape($content);
}

sub content_single {
    my $content = shift;

    return ref $content eq 'CODE' ? $content->() : xml_escape($content);
}

sub cleanup_attrs {
    my $hash = shift;

    #* delete all shortcuts (-> __*)
    map { delete $hash->{ $_ } } grep { substr($_, 0, 2) eq '__' } keys $hash->%*;

    #* delete all keys whose value is not a string
    map { delete $hash->{ $_ } } grep { $_ ne 'data' && ref $hash->{ $_ } ne '' } keys $hash->%*;

    return $hash;
}

sub get_size_for {
    my $input = shift;

    return _sizes()->{ $input };
}

sub _sizes {
    return {
        __xsmall => 'xs', xsmall => 'xs', xs => 'xs',
        __small  => 'sm', small  => 'sm', sm => 'sm',
        __medium => 'md', medium => 'md', md => 'md',
        __large  => 'lg', large  => 'lg', lg => 'lg',
    }
}

sub _button_contexts {
    return { map { ("__$_" => $_, $_ => $_) } qw/default primary success info warning danger link/ };
}
sub _panel_contexts {
    return { map { ("__$_" => $_, $_ => $_) } qw/default primary success info warning danger/ };
}
sub _table_contexts {
    return { map { ("__$_" => $_, $_ => $_) } qw/striped bordered hover condensed responsive/ };
}
sub _direction_contexts {
    return { map { ("__$_" => $_, $_ => $_) } qw/right block vertical justified dropup left/ };
}
sub _menu_contexts {
    return { map { ("__$_" => undef, $_ => undef) } qw/caret hamburger/ };
}
sub _misc_contexts {
    return { map { ("__$_" => $_, $_ => $_) } qw/active disabled/ };
}
sub _navbar_contexts {
    return { map { ("__$_" => $_, $_ => $_) } qw/default inverse/ };
}

sub out {
    my $tag = shift;
    return Mojo::ByteStream->new($tag);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::BootstrapHelpers::Helpers - Supporting module

=head1 VERSION

Version 0.0206, released 2019-06-24.

=head1 SOURCE

L<https://github.com/Csson/p5-mojolicious-plugin-bootstraphelpers>

=head1 HOMEPAGE

L<https://metacpan.org/release/Mojolicious-Plugin-BootstrapHelpers>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Bootstrap itself is (c) Twitter. See L<their license information|http://getbootstrap.com/getting-started/#license-faqs>.

L<Mojolicious::Plugin::BootstrapHelpers> is third party software, and is not endorsed by Twitter.

=cut
