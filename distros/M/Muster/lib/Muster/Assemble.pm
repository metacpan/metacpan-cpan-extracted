package Muster::Assemble;
$Muster::Assemble::VERSION = '0.62';
#ABSTRACT: Muster::Assemble - page rendering
=head1 NAME

Muster::Assemble - page rendering

=head1 VERSION

version 0.62

=head1 SYNOPSIS

    use Muster::Assemble;

=head1 DESCRIPTION

Content Management System - page rendering

=cut
use Mojo::Base -base;

use Carp;
use Muster::MetaDb;
use Muster::LeafFile;
use Muster::Hooks;
use File::Slurper 'read_binary';
use YAML::Any;
use Module::Pluggable search_path => ['Muster::Hook'], instantiate => 'new';

=head1 Methods

=head2 init

Initialize.

=cut
sub init {
    my $self = shift;
    my $c = shift;
    my $app = $c->app;

    if (!$self->{metadb})
    {
        $self->{metadb} = Muster::MetaDb->new(%{$app->config});
        $self->{metadb}->init();
    }
    $self->{hookmaster} = Muster::Hooks->new();
    $self->{hookmaster}->init($app->config);

    return $self;
} # init

=head2 serve_page

Serve one page (or a file)

=cut
sub serve_page {
    my $self = shift;
    my $c = shift;
    my $app = $c->app;

    $self->init($c);

    # If this is a page, there ought to be a trailing slash in the cpath.
    # If there isn't, either this isn't canonical, or it isn't a page.
    # However, pagenames don't have a trailing slash.
    # Yes, this is confusing.
    my $pagename = $c->param('cpath') // 'index';
    my $has_trailing_slash = 0;
    if ($pagename =~ m!/$!)
    {
        $has_trailing_slash = 1;
        $pagename =~ s!/$!!;
    }

    # now we need to find if this page exists, and what type it is
    my $info = $self->{metadb}->page_or_file_info($pagename);
    unless (defined $info and defined $info->{filename} and -f -r $info->{filename})
    {
        $c->reply->not_found;
        return;
    }
    if (!$info->{is_page}) # a non-page
    {
        return $self->_serve_file($c, $info->{filename});
    }
    elsif (!$has_trailing_slash and $pagename ne 'index') # non-canonical
    {
        return $c->redirect_to("/${pagename}/");
    }

    my $leaf = $self->_create_and_process_leaf(controller=>$c,meta=>$info);

    my $html = $leaf->html();
    unless (defined $html)
    {
        $c->reply->not_found;
        return;
    }

    $c->stash('title' => $leaf->title);
    $c->stash('pagename' => $pagename);
    $c->stash('content' => $html);
    $c->render(template => 'page',
        format => ($info->{page_format} ? $info->{page_format} : 'html'));
} # serve_page

=head2 serve_meta

Serve the meta-data for a page (for debugging purposes)

=cut
sub serve_meta {
    my $self = shift;
    my $c = shift;
    my $app = $c->app;

    $self->init($c);

    my $pagename = $c->param('cpath') // 'index';
    $pagename =~ s!/$!!; # remove trailing slash

    my $info = $self->{metadb}->page_or_file_info($pagename);
    unless (defined $info)
    {
        $c->reply->not_found;
        return;
    }

    my $html = "<pre>\n" . Dump($info) . "\n</pre>\n";

    $c->stash('title' => $info->{title});
    $c->stash('pagename' => $pagename);
    $c->stash('content' => $html);
    $c->render(template => 'page');
}

=head2 serve_source

Serve the source-content for a page (for debugging purposes)
Only works for page-files. (We don't want to be sending a binary file!)

=cut
sub serve_source {
    my $self = shift;
    my $c = shift;
    my $app = $c->app;

    $self->init($c);

    # If this is a page, there ought to be a trailing slash in the cpath.
    # If there isn't, either this isn't canonical, or it isn't a page.
    # However, pagenames don't have a trailing slash.
    # Yes, this is confusing.
    my $pagename = $c->param('cpath') // 'index';
    my $has_trailing_slash = 0;
    if ($pagename =~ m!/$!)
    {
        $has_trailing_slash = 1;
        $pagename =~ s!/$!!;
    }

    # now we need to find if this page exists, and what type it is
    my $info = $self->{metadb}->page_or_file_info($pagename);
    unless (defined $info and defined $info->{filename} and -f -r $info->{filename})
    {
        $c->reply->not_found;
        return;
    }
    if (!$info->{is_page}) # a non-page
    {
        $c->reply->not_found;
        return;
    }

    my $leaf = $self->_create_and_process_leaf(controller=>$c,meta=>$info);

    my $content = $leaf->raw();
    unless (defined $content)
    {
        $c->reply->not_found;
        return;
    }

    $c->stash('title' => $leaf->title);
    $c->stash('pagename' => $pagename);
    $c->stash('content' => "<pre>$content</pre>");
    $c->render(template => 'page');
} # serve_source

=head1 Helper Functions

=head2 _serve_file

Serve a file rather than a page.
    
    $self->_serve_file($filename);

=cut

sub _serve_file {
    my $self = shift;
    my $c = shift;
    my $filename = shift;

    if (!-f $filename)
    {
        # not found
        return;
    }
    # extenstion is format (exclude the dot)
    my $ext = '';
    if ($filename =~ /\.(\w+)$/)
    {
        $ext = $1;
    }
    # read the image
    my $bytes = read_binary($filename);

    # now display the logo
    $c->render(data => $bytes, format => $ext);
} # _serve_file

=head2 _create_and_process_leaf

Create and process a leaf (which contains meta-data and content).
This leaf data comes from the database (apart from the content).
    
    $leaf = $self->_create_and_process_leaf(controller=>$c,meta=>$meta);

=cut

sub _create_and_process_leaf {
    my $self = shift;
    my %args = @_;
    my $c = $args{controller};
    my $meta = $args{meta};

    my $leaf = Muster::LeafFile->new(
        pagename=>$meta->{pagename},
        parent_page=>$meta->{parent_page},
        filename=>$meta->{filename},
        filetype=>$meta->{filetype},
        is_page=>$meta->{is_page},
        extension=>$meta->{extension},
        name=>$meta->{name},
        title=>$meta->{title},
        date=>$meta->{date},
        meta=>$meta,
    );
    $leaf = $leaf->reclassify();
    if (!$leaf)
    {
        croak "ERROR: leaf did not reclassify\n";
    }

    return $self->{hookmaster}->run_hooks(leaf=>$leaf,
        controller=>$c,
        phase=>$Muster::Hooks::PHASE_BUILD);
} # _create_and_process_leaf
1;
# end of Muster::Assemble
