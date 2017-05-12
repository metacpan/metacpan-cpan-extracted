package Net::Redmine::Connection;
use Any::Moose;
use URI;
use Params::Validate;

has url      => ( is => "rw", isa => "Str", required => 1 );
has user     => ( is => "rw", isa => "Str", required => 1 );
has password => ( is => "rw", isa => "Str", required => 1 );

has is_logined => ( is => "rw", isa => "Int");

has _live_ticket_objects => (
    is => "rw",
    isa => "HashRef",
    default => sub { {} }
);

has mechanize => (
    is => "rw",
    isa => "WWW::Mechanize",
    lazy_build => 1,
);

use WWW::Mechanize;

sub _build_mechanize {
    my ($self) = @_;
    my $mech = WWW::Mechanize->new(autocheck => 0);
    return $mech;
}

sub get_login_page {
    my $self= shift;

    my $uri = URI->new($self->url);
    $uri->path("/login");

    $self->mechanize->get( $uri->as_string );

    return $self;
}

sub assert_login {
    my $self = shift;
    return if $self->is_logined;

    my $mech = $self->get_login_page->mechanize;

    my $form_n = 0;
    my @forms = $mech->forms;
    for (@forms) {
        if ($_->method eq 'POST' && $_->action eq $mech->uri) {
            last;
        }
        $form_n++;
    }

    if ($form_n >= @forms) {
        die "There is no login form on the login page. (@{[ $mech->uri ]})";
    }

    my $res = $mech->submit_form(
        form_number => $form_n,
        fields => {
            username => $self->user,
            password => $self->password
        }
    );

    if ( $res->content =~ /<div class="flash error">/ ) {
        die "Can't login, invalid login or password !";
    }
    $self->is_logined(1);
}

sub get_project_overview {
    my ($self) = @_;
    $self->assert_login;

    $self->mechanize->get( $self->url );
    return $self;
}

sub get_issues_page {
    my ($self, $id) = @_;
    $self->get_project_overview;
    my $mech = $self->mechanize;

    if ($id) {
        $mech->submit_form(form_number => 1, fields => { q => "#" . $id });
        die "Failed to get the ticket(id = $id)\n" unless $mech->response->is_success;
        die "No such ticket id = $id\n" unless $mech->uri =~ m[/issues/(?:show/)?${id}$];
    }
    else {
        $mech->follow_link( url_regex => qr[/issues$] );
        die "Failed to get the ticket overview page\n" unless $mech->response->is_success;
    }

    return $self;
}

sub get_new_issue_page {
    my ($self) = @_;

    my $mech = $self->get_project_overview->mechanize;
    $mech->follow_link( url_regex => qr[/issues/new$] );

    die "Failed to get the 'New Issue' page\n" unless $mech->response->is_success;

    return $self;
}

sub get_user_page {
    my $self = shift;
    validate(@_, { id => 1 });

    my %args = @_;
    my $mech = $self->mechanize;

    my $uri = URI->new($mech->uri);

    $uri->path("/users/$args{id}");
    $mech->get($uri->as_string);

    unless ($mech->response->is_success) {
        $uri->path("/account/show/$args{id}");
        $mech->get($uri->as_string);

        unless ($mech->response->is_success) {
            die "Fail to guess user page on this redmine server.\n"
        }
    }

    return $self;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;

__END__

=head1 NAME

Net::Redmine::Connection

=head1 SYNOPSIS

    # Initialize a redmien connection object
    my $redmine = Net::Redmine::Connection->new(
        url => 'http://redmine.example.com/projects/show/fooproject'
        user => 'hiro',
        password => 'yatta'
    );

    # Passed it to other classes
    my $ticket = Net::Redmine::Ticket->new(connection => $redmine);

=head1 DESCRIPTION



=cut
