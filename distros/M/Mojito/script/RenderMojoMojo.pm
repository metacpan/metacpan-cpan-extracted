use strictures 1;
package RenderMojoMojo;
use Web::Simple;
use MojoMojo::Schema;
use Mojito;
use Time::HiRes qw/ time /;
use Data::Dumper::Concise;

with ('Mojito::Role::Config');

=head1 Name

RenderMojoMojo - a mini-app to render MojoMojo pages

=cut

sub dispatch_request {
    my $begin = time();

    sub (GET + /**) {
        my ($self, $path) = @_;
        
        my @parts = split '/', $path;
        my $page_name = $parts[-1];
        my $page_struct = $self->build_page_struct($page_name);
        my $body = $self->mojito->render_body($page_struct);
        my $output = $self->mojito->wrap_page($body, $page_struct->{title});
        warn "dispatch time: ", time - $begin if $ENV{MOJITO_DEBUG};
        [ 200, [ 'Content-type', 'text/html' ], [$output] ];
      },
       sub () {
        [ 405, [ 'Content-type', 'text/plain' ], ['Method not allowed'] ];
      },
}

sub build_page_struct {
    my ($self, $page_name) = @_;

    my $page = $self->page_rs->search({ name => $page_name })->first;
    return if not $page;
    my $sections = [ { content => $page->content->body, class => 'Implicit' } ];
    my $datetime = $page->content->created;
    my $title    = join ' ', map { ucfirst } split '_', $page->name;

    my $page_struct = {
        sections       => $sections,
        page_source    => $page->content->body,
        created        => $datetime->epoch,
        default_format => $self->wiki_format,
        title          => $title,
    };
    
    return $page_struct;
}

has schema => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_schema',
);

sub _build_schema {
    my $self = shift;
    warn "BUILD SCHEMA" if $ENV{DEBUG};
    my ($dsn, $user, $pass) = @{$self->config}{qw(mojomojo_dsn mojomojo_db_user mojomojo_db_password)};
    my $schema = MojoMojo::Schema->connect($dsn, $user, $pass)
      or die "Failed to connect to database";
    return $schema;
}

has page_rs => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_page_rs',
);

sub _build_page_rs {
    my $self = shift;
    warn "BUILD PAGE ResultSet" if $ENV{DEBUG};
    return $self->schema->resultset('Page');
}

has preference_rs => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_preference_rs',
);

sub _build_preference_rs {
    my $self = shift;
    return $self->schema->resultset('Preference');
}

has wiki_format => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_wiki_format',
);

sub _build_wiki_format {
    my $self = shift;
    my $module =
      $self->preference_rs->find({ prefkey => 'main_formatter' })->prefvalue;
    my ($format) = $module =~ m/::([^:]*)$/;
    return lc $format;
}

has mojito => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        Mojito->new(
            config   => $self->config,
            base_url => '/'
        );
    }
);

sub page_lineage {
    my ($self, $page) = @_;
    my $lineage;
    while (my $parent = $page->parent) {
        if ($parent->id == 1) {
            return '/' . $lineage;
        }
        else {
            $lineage = $parent->name . '/' . $lineage;
            $page    = $parent;
        }
    }
    die
"Should not get HERE.  Means we found page that doesn't have the root page (id = 1) as an ancestor";
}

RenderMojoMojo->run_if_script;
