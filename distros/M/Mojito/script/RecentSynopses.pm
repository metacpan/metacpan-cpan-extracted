package RecentSynopses;
use strictures 1;
use Web::Simple;
use Mojito::Model::MetaCPAN;
use Mojito::Template;
use Mojito::Filter::MojoMojo::Converter;

with('Mojito::Role::Config');

=head1 Name

RecentSynopses - a mini-app that show recent CPAN synopses

=cut

has converter => (
    is   => 'ro',
    lazy => 1,
    default =>
      sub { Mojito::Filter::MojoMojo::Converter->new(content => 'yet to come') }
    ,
);

has metacpan => (
    is      => 'ro',
    lazy    => 1,
    default => sub { Mojito::Model::MetaCPAN->new },
);
has tmpl => (
    is      => 'ro',
    lazy    => 1,
    default => sub { Mojito::Template->new(config => $_[0]->config) },
);

sub dispatch_request {
    my ($self, $env) = @_;

    sub (GET + /**) {
        my ($self, $path) = @_;
        my $amount               = $self->determine_amount_from_path($path);
        my $recent_synopses_page = $self->create_recent_synopses_page($amount);
        [ 200, [ 'Content-type', 'text/html' ], [$recent_synopses_page] ];
      },

}

sub create_recent_synopses_page {
    my ($self, $amount) = @_;

    my $body = $self->metacpan->get_recent_synopses($amount);
    $body = '<h1>CPAN Recent SYNOPSES</h1> {{toc 2-}} ' . $body;
    $self->converter->content($body);
    $self->converter->toc;
    return $self->tmpl->wrap_page($self->converter->content,
        'Recent CPAN SYNOPSES');
}

sub determine_amount_from_path {
    my ($self, $path) = @_;

    # Default to 10
    my $amount = 10;

    # See if we got some digits at the end of the path (being leanient)
    if ($path && (my ($trailing_digits) = $path =~ m|(\d+)/?$|)) {
        $amount = $trailing_digits;
    }

    # Let's set some limit max limit of what "recent' means.
    my $max = 100;
    $amount = ($amount > $max) ? $max : $amount;
    return $amount;
}

sub BUILD {
    my ($self, $args) = @_;

# Fork off a process that will collect and cache the recent synopsis data
# This is to keep the data fresh and have the page respond rapidement.
    my $pid = fork;
    if (not $pid) {

        # code executed only by the child ...
        while (1) {
            $self->metacpan->get_recent_synopses;
            sleep 60;
        }
    }
    else {
        warn "Parent has born a child with PID: $pid!";
    }
}

RecentSynopses->run_if_script;
