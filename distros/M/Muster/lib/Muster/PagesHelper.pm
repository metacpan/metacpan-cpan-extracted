package Muster::PagesHelper;
$Muster::PagesHelper::VERSION = '0.62';
#ABSTRACT: Muster::PagesHelper - helping with pages
=head1 NAME

Muster::PagesHelper - helping with pages

=head1 VERSION

version 0.62

=head1 SYNOPSIS

    use Muster::PagesHelper;

=head1 DESCRIPTION

Content management system; getting and showing pages.

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Carp;
use Muster::MetaDb;
use common::sense;
use Text::NeatTemplate;
use YAML::Any;
use File::Basename 'basename';
use Mojo::URL;
use HTML::LinkList;

=head1 REGISTER

=cut

sub register {
    my ( $self, $app, $conf ) = @_;

    $self->_init($app,$conf);

    $app->helper( 'muster_sidebar' => sub {
        my $c        = shift;
        my %args = @_;

        return $self->_sidebar($c,%args);
    } );
    $app->helper( 'muster_rightbar' => sub {
        my $c        = shift;
        my %args = @_;

        return $self->_rightbar($c,%args);
    } );

    $app->helper( 'muster_total_pages' => sub {
        my $c        = shift;
        my %args = @_;

        return $self->_total_pages($c,%args);
    } );

    $app->helper( 'muster_page_related_list' => sub {
        my $c        = shift;
        my %args = @_;

        return $self->_make_page_related_list($c,%args);
    } );
    $app->helper( 'muster_page_attachments_list' => sub {
        my $c        = shift;
        my %args = @_;

        return $self->_make_page_attachments_list($c,%args);
    } );

    $app->helper( 'muster_pagelist' => sub {
        my $c        = shift;
        my %args = @_;

        return $self->_pagelist($c,%args);
    } );
}

=head1 Helper Functions

These are functions which are NOT exported by this plugin.

=cut

=head2 _init

Initialize.

=cut
sub _init {
    my $self = shift;
    my $app = shift;
    my $conf = shift;

    $self->{metadb} = Muster::MetaDb->new(%{$app->config});
    $self->{metadb}->init();
    $self->{hookmaster} = Muster::Hooks->new();
    $self->{hookmaster}->init($app->config);
    return $self;
} # _init

=head2 _sidebar

Fill in the sidebar.
I have decided, for the sake of speed, to "hardcode" the contents of the sidebar,
considering that for some pages it too 2.5 seconds to load the page with an external sidebar,
and only .6 seconds when using the internal default.

=cut

sub _sidebar {
    my $self  = shift;
    my $c  = shift;

    my $pagename = $c->param('cpath');
    $pagename =~ s!/$!!; # remove trailing slash

    my $out = $self->_make_page_related_list($c);
    return "<nav>$out</nav>\n";
} # _sidebar

=head2 _rightbar

Fill in the rightbar.
I have decided, for the sake of speed, to "hardcode" the contents of the rightbar also.

=cut

sub _rightbar {
    my $self  = shift;
    my $c  = shift;

    my $pagename = $c->param('cpath');
    $pagename =~ s!/$!!; # remove trailing slash

    my $src_dest_url = $c->url_for("/_src/$pagename/");
    my $src_dest_label = 'Source';
    my $current_url = $c->req->url->to_abs;
    if ($current_url =~ /_src/) # we're already looking at Source
    {
        $src_dest_url =~ s/_src\///;
        $src_dest_label = "Dest";
    }
    my $meta_dest_url = $c->url_for("/_meta/$pagename/");
    my $meta_dest_label = 'Meta';
    if ($current_url =~ /_meta/) # we're already looking at Meta
    {
        $meta_dest_url =~ s/_meta\///;
        $meta_dest_label = "Page";
    }
    my $total = $self->_total_pages($c);
    my $atts = $self->_make_page_attachments_list($c);
    my $out=<<EOT;
<p class="total">$total pages</p>
<p class="srcdest"><a href="$src_dest_url">$src_dest_label</a></p>
<p class="metadest"><a href="$meta_dest_url">$meta_dest_label</a></p>
$atts
EOT
        return $out;
} # _rightbar

=head2 _total_pages

Return the total number of records in this db

=cut

sub _total_pages {
    my $self  = shift;
    my $c  = shift;

    my $total = $self->{metadb}->total_pages();
    if (!defined $total)
    {
        $c->render(template => 'apperror',
            errormsg=>"UNKNOWN");
        return undef;
    }
    return $total;
} # _total_pages

=head2 _make_page_attachments_list

Make a list of related pages to this page.

=cut

sub _make_page_attachments_list {
    my $self  = shift;
    my $c  = shift;

    my $pagename = $c->param('cpath');
    $pagename =~ s!/$!!; # remove trailing slash

    my $info = $self->{metadb}->page_or_file_info($pagename);
    my $att_list = '';
    if ($info and $info->{attachments})
    {
        my @att = ();
        my %labels = ();
        # just link to the basenames, since this should be relative
        foreach my $att (@{$info->{attachments}})
        {
            my $bn = basename($att);
            push @att, $bn;
            $labels{$bn} = $bn;
        }
        $att_list = HTML::LinkList::link_list(
            urls=>\@att,
            labels=>\%labels,
        );
        $att_list = "<div><p><b>Attachments:</b></p>$att_list</div>" if $att_list;
    }
    
    return $att_list;
} # _make_page_attachments_list

=head2 _make_page_related_list

Make a list of related pages to this page.

=cut

sub _make_page_related_list {
    my $self  = shift;
    my $c  = shift;

    my $pagename = $c->param('cpath') || 'index';
    $pagename =~ s!/$!!; # remove trailing slash
    my $info = $self->{metadb}->page_or_file_info($pagename);
    my $current_url = $info->{pagelink};

    # get the links to the pages
    my @paths = $self->{metadb}->allpagelinks();

    my $link_list = HTML::LinkList::nav_tree(
        current_url=>$current_url,
        paths=>\@paths,
    );

    return $link_list;
} # _make_page_related_list

=head2 _pagelist

Make a pagelist

=cut

sub _pagelist {
    my $self  = shift;
    my $c  = shift;

    my $location = $c->url_for('pagelist');
    # get the links to the pages
    my @paths = $self->{metadb}->allpagelinks();

    my $link_list = HTML::LinkList::full_tree(
        current_url=>$location,
        paths=>\@paths,
    );
    return $link_list;
} # _pagelist

1; # End of Muster::PagesHelper
__END__
