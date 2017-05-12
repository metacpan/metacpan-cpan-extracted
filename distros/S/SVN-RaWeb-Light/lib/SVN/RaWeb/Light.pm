package SVN::RaWeb::Light;

use strict;
use warnings;

use 5.008;
use vars qw($VERSION);

$VERSION = '0.60005';

use CGI ();
use IO::Scalar;

require SVN::Core;
require SVN::Ra;

use base 'Class::Accessor';

use SVN::RaWeb::Light::Help;

__PACKAGE__->mk_accessors(qw(cgi dir_contents esc_url_suffix path rev_num),
    qw(should_be_dir svn_ra url_suffix));

# Preloaded methods go here.

# We alias _escape() to CGI::escapeHTML().
*_escape = \&CGI::escapeHTML;

sub new
{
    my $self = {};
    my $class = shift;
    bless $self, $class;
    $self->_init(@_);
    return $self;
}

sub _init
{
    my $self = shift;

    my %args = (@_);

    my $cgi = CGI->new();
    $self->cgi($cgi);

    my $svn_ra =
        SVN::Ra->new(
            'url' => $args{'url'},
        );

    $self->svn_ra($svn_ra);

    my $url_translations = $args{'url_translations'} || [];
    $self->{'url_translations'} = $url_translations;

    return $self;
}

sub _get_user_url_translations
{
    my $self = shift;

    my @transes = $self->cgi()->param('trans_user');

    my @ret;
    for my $i (0 .. $#transes)
    {
        my $elem = $transes[$i];
        push @ret,
            (($elem =~ /^([^:,]*),(.*)$/) ?
                { 'label' => $1, 'url' => $2, } :
                { 'label' => ("UserDef" . ($i+1)), 'url' => $elem, }
            );
    }
    return \@ret;
}

# TODO :
# Create a way for the user to specify one extra url translation of his own.
sub _get_url_translations
{
    my $self = shift;

    my (%args) = (@_);

    my $cgi = $self->cgi();

    my $is_list_item = $args{'is_list_item'};

    if ($is_list_item && $cgi->param('trans_no_list'))
    {
        return [];
    }

    return [
        ($cgi->param('trans_hide_all') ?
            () :
            (@{$self->{'url_translations'}})
        ),
        @{$self->_get_user_url_translations()},
    ];
}

sub _get_mode
{
    my $self = shift;

    my $mode = $self->cgi()->param("mode");

    return (defined($mode) ? $mode : "view");
}

# This function must be called before rev_num() and url_suffix() are valid.
sub _calc_rev_num
{
    my $self = shift;

    my $rev_param = $self->cgi()->param('rev');

    my ($rev_num, $url_suffix);

    # If a revision is specified - get the tree out of it, and persist with
    # it throughout the browsing session. Otherwise, get the latest revision.
    if (defined($rev_param))
    {
        $rev_num = abs(int($rev_param));
    }
    else
    {
        $rev_num = $self->svn_ra()->get_latest_revnum();
    }

    $self->rev_num($rev_num);
    $self->url_suffix($self->_get_url_suffix_with_extras());
    $self->esc_url_suffix(_escape($self->url_suffix()));
}

# Gets the URL suffix calculated with optional extra components.
sub _get_url_suffix_with_extras
{
    my $self = shift;
    my $components = shift;

    my $query_string = $self->cgi->query_string();
    if ($query_string eq "")
    {
        if (defined($components))
        {
            return "?" . $components;
        }
        else
        {
            return "";
        }
    }
    else
    {
        if (defined($components))
        {
            return "?" . $query_string . ";" . $components;
        }
        else
        {
            return "?" . $query_string;
        }
    }
}

sub _calc_path
{
    my $self = shift;

    my $path = $self->cgi()->path_info();
    if ($path eq "")
    {
        die +{
            'callback' =>
            sub {
                $self->cgi()->script_name() =~ m{([^/]+)$};
                print $self->cgi()->redirect("./$1/");
            },
        };
    }
    if ($path =~ /\/\//)
    {
        die +{ 'callback' => sub { $self->_multi_slashes(); } };
    }

    $path =~ s!^/!!;

    $self->should_be_dir(($path eq "") || ($path =~ s{/$}{}));
    $self->path($path);
}

sub _get_correct_node_kind
{
    my $self = shift;
    return $self->should_be_dir() ? $SVN::Node::dir : $SVN::Node::file;
}

sub _get_escaped_path
{
    my $self = shift;
    return _escape($self->path());
}

sub _check_node_kind
{
    my $self = shift;
    my $node_kind = shift;

    if (($node_kind eq $SVN::Node::none) || ($node_kind eq $SVN::Node::unknown))
    {
        die +{
            'callback' =>
                sub {
                    print $self->cgi()->header();
                    print "<html><head><title>Does not exist!</title></head>";
                    print "<body><h1>Does not exist!</h1></body></html>";
                },
        };
    }
    elsif ($node_kind ne $self->_get_correct_node_kind())
    {
        die +{
            'callback' =>
                sub {
                    $self->path() =~ m{([^/]+)$};
                    print $self->cgi()->redirect(
                        ($node_kind eq $SVN::Node::dir) ?
                            "./$1/" :
                            "../$1"
                        );
                },
        };
    }
}

sub _get_esc_item_url_translations
{
    my $self = shift;

    if (!exists($self->{'escaped_item_url_translations'}))
    {
        $self->{'escaped_item_url_translations'} =
        [
        (
            map {
            +{
                'url' => _escape($_->{'url'}),
                'label' => _escape($_->{'label'}),
            }
            }
            @{$self->_get_url_translations('is_list_item' => 1)}
        )
        ];
    }
    return $self->{'escaped_item_url_translations'};
}

sub _render_list_item
{
    my ($self, $args) = (@_);

    return
        qq(<li><a href="$args->{link}) .
        qq(@{[$self->esc_url_suffix()]}">$args->{label}</a>) .
        join("",
        map
        {
            " [<a href=\"$_->{url}$args->{path_in_repos}\">$_->{label}</a>]"
        }
        @{$self->_get_esc_item_url_translations()}
        ) .
        "</li>\n";
}

sub _get_esc_up_path
{
    my $self = shift;

    $self->path() =~ /^(.*?)[^\/]+$/;

    return _escape($1);
}

sub _real_render_up_list_item
{
    my $self = shift;
    return $self->_render_list_item(
        {
            'link' => "../",
            'label' => "..",
            'path_in_repos' => $self->_get_esc_up_path(),
        }
    );
}

# The purpose of this function ios to get the list item of the ".." directory
# that goes one level up in the repository.
sub _render_up_list_item
{
    my $self = shift;
    # If the path is the root - then we cannot have an upper directory
    if ($self->path() eq "")
    {
        return ();
    }
    else
    {
        return $self->_real_render_up_list_item();
    }
}

# This method gets the escaped path along with a potential trailing slash
# (if it isn't empty)
sub _get_normalized_path
{
    my $self = shift;

    my $url = $self->path();
    if ($url ne "")
    {
        $url .= "/";
    }
    return $url;
}

sub _render_regular_list_item
{
    my ($self, $entry) = @_;

    my $escaped_name = _escape($entry);
    if ($self->dir_contents->{$entry}->kind() eq $SVN::Node::dir)
    {
        $escaped_name .= "/";
    }

    return $self->_render_list_item(
        {
            (map { $_ => $escaped_name } qw(link label)),
            'path_in_repos' =>
                (_escape($self->_get_normalized_path()).$escaped_name),
        }
    );
}

sub _render_top_url_translations_text
{
    my $self = shift;

    my $top_url_translations =
        $self->_get_url_translations('is_list_item' => 0);
    my $ret = "";
    if (@$top_url_translations)
    {
        $ret .= "<table border=\"1\">\n";
        foreach my $trans (@$top_url_translations)
        {
            my $url = $self->_get_normalized_path();
            my $escaped_url = _escape($trans->{'url'} . $url);
            my $escaped_label = _escape($trans->{'label'});
            $ret .= "<tr><td><a href=\"$escaped_url\">$escaped_label</a></td></tr>\n";
        }
        $ret .= "</table>\n";
    }
    return $ret;
}

sub _render_dir_header
{
    my $self = shift;

    my $title = "Revision ". $self->rev_num() . ": /" .
        $self->_get_escaped_path();
    my $ret = "";
    $ret .= $self->cgi()->header();
    $ret .= "<html><head><title>$title</title></head>\n";
    $ret .= "<body>\n";
    $ret .="<h2>$title</h2>\n";

    return $ret;
}

sub _get_items_list_items_order
{
    my $self = shift;
    return [ sort { $a cmp $b } keys(%{$self->dir_contents()}) ];
}

sub _get_items_list_regular_items
{
    my $self = shift;
    return
        [map
        {
            $self->_render_regular_list_item($_)
        }
        (@{$self->_get_items_list_items_order()})
        ];
}

sub _get_items_list_items
{
    my $self = shift;
    return
    [
        $self->_render_up_list_item(),
        @{$self->_get_items_list_regular_items()},
    ];
}

sub _print_items_list
{
    my ($self) = @_;
    print "<ul>\n";

    print @{$self->_get_items_list_items()};
    print "</ul>\n";
}

sub _print_control_section
{
    my $self = shift;
    print "<ul>\n" .
        "<li><a href=\"./?mode=help\">Show Help Screen</a></li>\n" .
        "<li><a href=\"./" . _escape($self->_get_url_suffix_with_extras("panel=1")) . "\">Show Control Panel</a></li>\n" .
        "</ul>\n";
}

sub _get_dir
{
    my $self = shift;

    my ($dir_contents, $fetched_rev) =
        $self->svn_ra()->get_dir($self->path(), $self->rev_num());
    $self->dir_contents($dir_contents);
}

sub _process_dir
{
    my $self = shift;
    $self->_get_dir();
    print $self->_render_dir_header();
    print $self->_render_top_url_translations_text();
    $self->_print_items_list();
    $self->_print_control_section();
    print "</body></html>\n";
}

sub _process_file
{
    my $self = shift;

    my $buffer = "";
    my $fh = IO::Scalar->new(\$buffer);
    my ($fetched_rev, $props)
        = $self->svn_ra()->get_file($self->path(), $self->rev_num(), $fh);
    print $self->cgi()->header(
        -type => ($props->{'svn:mime-type'} || 'text/plain')
        );
    print $buffer;
}

sub _process_help
{
    my $self = shift;

    print $self->cgi()->header();
    SVN::RaWeb::Light::Help::print_data();
}

sub _real_run
{
    my $self = shift;
    my $cgi = $self->cgi();

    if ($self->_get_mode() eq "help")
    {
        return $self->_process_help();
    }
    if ($cgi->param("panel"))
    {
        print $cgi->header();
        print <<"EOF";
<html><body><h1>Not Implemented Yet</h1>
<p>Sorry but the control panel is not implemented yet.</p>
</body>
</html>
EOF
        return 0;
    }

    $self->_calc_rev_num();
    $self->_calc_path();

    my $node_kind =
        $self->svn_ra()->check_path($self->path(), $self->rev_num());

    $self->_check_node_kind($node_kind);

    if ($node_kind eq $SVN::Node::dir)
    {
        return $self->_process_dir();
    }
    # This means $node_kind eq $SVN::Node::file
    else
    {
        return $self->_process_file();
    }
}

sub run
{
    my $self = shift;

    my @ret;
    eval {
        @ret = $self->_real_run();
    };

    if ($@)
    {
        if ((ref($@) eq "HASH") && (exists($@->{'callback'})))
        {
            return $@->{'callback'}->();
        }
        else
        {
            die $@;
        }
    }
    else
    {
        return @ret;
    }
}

sub _multi_slashes
{
    my $self = shift;
    print $self->cgi()->header();
    print "<html><head><title>Wrong URL!</title></head>";
    print "<body><h1>Wrong URL - Multiple Adjacent Slashes (//) in the URL." .
        "</h1></body></html>";
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;


__END__


=head1 NAME

SVN::RaWeb::Light - Lightweight and Fast Browser for a URLed Subversion
repository similar to the default Subversion http:// hosting.

=head1 SYNOPSIS

    #!/usr/bin/perl

    use SVN::RaWeb::Light;

    my $app = SVN::RaWeb::Light->new(
        'url' => "svn://myhost.net/my-repos-path/",
    );

    $app->run();


=head1 DESCRIPTION

SVN::RaWeb::Light is a class implementing a CGI script for browsing
a Subversion repository given as a URL, and accessed through the Subversion
Repository-Access layer. Its interface emulates that of the default
Subversion http://-interface, with some improvements.

To use it, install the module (using CPAN or by copying it to your path) and
write the CGI script given in the SYNOPSIS with the URL to the repository
passed as the C<'url'> parameter to the constructor.

To use it just fire up a web-browser to the URL of the script.

=head2 URL Translations

URL translations are a method to translate the current path of the script to
to a URL. The latter is usually a URL of the Subversioned resource, which can
be manipulated directly using the C<svn> client and other clients.

One can specify pre-defined URL translations, inside the value of the
C<'url_translations'> argument:

    #!/usr/bin/perl -w

    use SVN::RaWeb::Light;

    my $app = SVN::RaWeb::Light->new(
        'url' => "svn://svn.berlios.de/web-cpan/",
        'url_translations' =>
        [
            {
                'label' => "Read/Write URL",
                'url' => "svn+ssh://svn.berlios.de/svnroot/repos/web-cpan/",
            },
            {
                'label' => "Read URL",
                'url' => "svn://svn.berlios.de/web-cpan/",
            },
        ],
    );

    $app->run();

C<label> specifies the label as would appear on the page. C<url> is the URL
relative to the script's base directory. The complete path would be the
URL in the URL translation appended by the path that the script points to.

=head1 METHODS

=head2 my $app = SVN::RaWeb::Light->new(...)

Initialises a new application.

=head2 $app->run();

Runs it in the current process.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Shlomi Fish

This library is free software; you can redistribute it and/or modify
it under the terms of the MIT/X11 license.

=cut
