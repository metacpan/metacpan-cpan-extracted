package Muster::Assemble;
$Muster::Assemble::VERSION = '0.92';
#ABSTRACT: Muster::Assemble - page rendering
=head1 NAME

Muster::Assemble - page rendering

=head1 VERSION

version 0.92

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
use File::LibMagic;
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

    $self->{file_magic} = File::LibMagic->new();

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

    # If a page is requested, there ought to be a trailing slash in the cpath.
    # If there isn't, either this isn't canonical, or it isn't a page request.
    # However, pagenames don't have a trailing slash.
    # Yes, this is confusing.
    # So why do we care if a URL is canonical? Because if it isn't canonical,
    # it messes up relative page links. Ugh.
    my $pagename = $c->param('cpath') // 'index';
    my $has_trailing_slash = 0;
    my $is_source_file_request = 0;
    if ($pagename =~ m!/$!)
    {
        $has_trailing_slash = 1;
        $pagename =~ s!/$!!;
    }
    elsif ($pagename =~ m!(.*)\.\w+$!) # source-file or file requests have .ext suffixes
    {
        $pagename = $1;
        $is_source_file_request = 1;
    }

    # now we need to find if this page exists, and what type it is
    my $info = $self->{metadb}->page_or_file_info($pagename);
    unless (defined $info and defined $info->{filename} and -f -r $info->{filename})
    {
        $c->reply->not_found;
        return;
    }

    if ($is_source_file_request)
    {
        return $self->_serve_file(controller=>$c, meta=>$info);
    }
    elsif (!$has_trailing_slash and $pagename ne 'index') # non-canonical
    {
        my $redir = "/${pagename}/";
        return $c->redirect_to($redir);
    }

    # Make sure that "head_append" is defined
    $c->stash('head_append' => "");

    my $leaf = $self->_create_and_process_leaf(controller=>$c,meta=>$info);

    my $html = $leaf->html();
    unless (defined $html)
    {
        say STDERR "404: html not rendered for '$pagename'";
        $c->reply->not_found;
        return;
    }
    my $filtered_html = $self->{hookmaster}->run_filters(
        html=>$html,
        controller=>$c,
        phase=>$Muster::Hooks::PHASE_FILTER);

    $c->stash('title' => $leaf->title);
    $c->stash('pagename' => $pagename);
    $c->stash('content' => $filtered_html);
    $c->render(template => 'page',
        format => ($info->{render_format} ? $info->{render_format} : 'html'));
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

=head1 Helper Functions

=head2 _serve_file

Serve a file rather than a page.
    
    $self->_serve_file(controller=>$c, meta=>$meta);

=cut

sub _serve_file {
    my $self = shift;
    my %args = @_;
    my $c = $args{controller};
    my $meta = $args{meta};

    my $filename = $meta->{filename};
    if (!-f $filename)
    {
        # not found
        return;
    }
    # Figure out the correct mime-type to give
    my $file_info = $self->{file_magic}->info_from_filename($filename);
    $c->res->headers->content_type($file_info->{mime_type});
    $c->reply->file($filename);

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
        pagesrcname=>$meta->{pagesrcname},
        parent_page=>$meta->{parent_page},
        grandparent_page=>$meta->{grandparent_page},
        filename=>$meta->{filename},
        filetype=>$meta->{filetype},
        is_binary=>$meta->{is_binary},
        extension=>$meta->{extension},
        bald_name=>$meta->{bald_name},
        hairy_name=>$meta->{hairy_name},
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
