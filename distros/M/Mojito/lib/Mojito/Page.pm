use strictures 1;
package Mojito::Page;
$Mojito::Page::VERSION = '0.25';
use Moo;
use Sub::Quote qw(quote_sub);

=head1 Name

Mojito::Page - the page delegator class

=head1 Description

An object to delegate to the Page family of objects.

=cut

=head1 Synopsis

    use Mojito::Page;
    my $page_source = $params->{content};
    my $pager = Mojito::Page->new( page_source => $page_source);
    my $web_page = $pager->render_page;

=cut

# delegates
use Mojito::Page::Parse;
use Mojito::Page::Render;
use Mojito::Page::CRUD;
use Mojito::Page::Git;
use Mojito::Page::Publish;
use Mojito::Template;
use Mojito::Model::Link;
use Mojito::Collection::CRUD;

with 'Mojito::Role::Config';

# roles

has parser => (
    is      => 'ro',
    isa     => sub { die "Need a PageParse object.  Have ref($_[0]) instead." unless $_[0]->isa('Mojito::Page::Parse') },
    lazy    => 1,
    handles => [
        qw(
          page_structure
          )
    ],
    writer => '_build_parse',
    default => sub { Mojito::Page::Parse->new }
);

has render => (
    is      => 'ro',
    isa     => sub { die "Need a PageRender object" unless $_[0]->isa('Mojito::Page::Render') },
    handles => [
        qw(
          render_page
          render_body
          intro_text
          )
    ],
    writer => '_build_render',
);

has editer => (
    is      => 'ro',
    isa     => sub { die "Need a PageEdit object" unless $_[0]->isa('Mojito::Page::CRUD') },
    handles => [
        qw(
            create
            read
            update
            delete
            db
            collection
          )
    ],
    writer => '_build_edit',
);

has collector => (
    is      => 'ro',
    isa     => sub { die "Need a Collection::CRUD object" unless $_[0]->isa('Mojito::Collection::CRUD') },
    handles => [ qw( ) ],
    writer => '_build_collect',
);

has tmpl => (
    is      => 'ro',
    isa     => sub { die "Need a Template object" unless $_[0]->isa('Mojito::Template') },
    handles => [
        qw(
          template
          home_page
          recent_links
          collect_page_form
          collections_index
          collection_page
          sort_collection_form
          fillin_create_page
          fillin_edit_page
          calendar_month_page
          wrap_page
          )
    ],
    writer => '_build_template',
);

has linker => (
    is      => 'ro',
    isa     => sub { die "Need a Link Model object" unless $_[0]->isa('Mojito::Model::Link') },
    handles => [
        qw(
            get_recent_links
            get_feed_links
            view_collections_index
            view_collection_nav
            get_atom_feed
          )
    ],
    writer => '_build_link',
);

has gitter => (
    is      => 'ro',
    isa     => sub { die "Need a PageGit object" unless $_[0]->isa('Mojito::Page::Git') },
    handles => [
        qw(
            commit_page
            rm_page
            diff_page
            search_word
            get_author_for
          )
    ],
    writer => '_build_git',
);

has publisher => (
    is      => 'ro',
    isa     => sub { die "Need a PagePublish object" unless $_[0]->isa('Mojito::Page::Publish') },
    handles => [ qw( ) ],
    writer => '_build_publish',
);

=head1 Methods

=head2 BUILD

Create the handler objects

=cut

sub BUILD {
    my $self                  = shift;
    my $constructor_args_href = shift;
    
    # Pass the config to the delegatees so they don't have to build it.
    $constructor_args_href->{config} = $self->config;

    # pass the options into the subclasses
    $self->_build_parse(Mojito::Page::Parse->new($constructor_args_href));
    $self->_build_render(Mojito::Page::Render->new($constructor_args_href));
    $self->_build_edit(Mojito::Page::CRUD->new($constructor_args_href));
    $self->_build_collect(Mojito::Collection::CRUD->new($constructor_args_href));
    $self->_build_git(Mojito::Page::Git->new($constructor_args_href));
    $self->_build_template(Mojito::Template->new($constructor_args_href));
    $self->_build_link(Mojito::Model::Link->new($constructor_args_href));
    $self->_build_publish(Mojito::Page::Publish->new($constructor_args_href));
}

1
