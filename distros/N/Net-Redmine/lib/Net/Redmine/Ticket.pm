package Net::Redmine::Ticket;
use Any::Moose;
use Net::Redmine::TicketHistory;
use Net::Redmine::User;
use DateTimeX::Easy;

has connection => (
    is => "rw",
    isa => "Net::Redmine::Connection",
    required => 1,
    weak_ref => 1,
);

has id          => (is => "rw", isa => "Int");
has subject     => (is => "rw", isa => "Str");
has description => (is => "rw", isa => "Str");
has status      => (is => "rw", isa => "Str");
has priority    => (is => "rw", isa => "Str");
has author      => (is => "rw", isa => "Maybe[Net::Redmine::User]");
has created_at  => (is => "rw", isa => "DateTime");
has note        => (is => "rw", isa => "Str");
has histories   => (is => "rw", isa => "ArrayRef", lazy_build => 1);

sub create {
    my ($class, %attr) = @_;

    my $self = $class->new(%attr);

    my $mech = $self->connection->get_new_issue_page()->mechanize;
    $mech->form_id("issue-form");
    $mech->field("issue[subject]" => $self->subject);
    $mech->field("issue[description]" => $self->description);
    $mech->submit;

    unless ($mech->response->is_success) {
        die "Failed to create a new ticket\n";
    }

    if ($mech->uri =~ m[/issues(?:/show)?/(\d+)$]) {
        my $id = $1;
        $self->id($id);
        return $self;
    }
}

# use IO::All;
use pQuery;
use HTML::WikiConverter;
use Encode;

sub load {
    my ($class, %attr) = @_;
    die "should specify ticket id when loading it." unless defined $attr{id};
    die "should specify connection object when loading tickets." unless defined $attr{connection};

    my $live = $attr{connection}->_live_ticket_objects;
    my $id = $attr{id};
    return $live->{$id} if exists $live->{$id};

    my $self = $class->new(%attr);
    $self->refresh or return;

    $live->{$self->id} = $self;
    return $self;
}

sub refresh {
    my ($self) = @_;
    die "Cannot lookup ticket histories without id.\n" unless $self->id;

    my $id = $self->id;
    eval '$self->connection->get_issues_page($id)';
    if ($@) { warn $@; return }

    my $p = pQuery($self->connection->mechanize->content);
    my $wc = new HTML::WikiConverter( dialect => 'Markdown' );
    my $description = $wc->html2wiki( Encode::encode_utf8($p->find(".issue .wiki")->html) );
    my $subject = $p->find(".issue h3")->text;
    my $status = $p->find(".issue .status")->eq(1)->text;

    $self->subject($subject);
    $self->description($description);
    $self->status($status);

    $self->created_at(DateTimeX::Easy->new( $p->find(".issue .author a")->get(1)->getAttribute("title") ));

    my $author_page_uri = $p->find(".issue .author a")->get(0)->getAttribute("href");
    if ($author_page_uri =~ m[/(?:account/show|users)/(\d+)$]) {
        $self->author(Net::Redmine::User->load(id => $1, connection => $self->connection));
    }

    return $self;
}

sub save {
    my ($self) = @_;
    die "Cannot save a ticket without id.\n" unless $self->id;

    my $mech = $self->connection->get_issues_page($self->id)->mechanize;
    $mech->follow_link( url_regex => qr[/issues/\d+/edit$] );

    $mech->form_id("issue-form");
    $mech->set_fields(
        'issue[status_id]' => $self->status,
        'issue[description]' => $self->description,
        'issue[subject]' => $self->subject
    );

    if ($self->note) {
        $mech->set_fields(notes => $self->note);
    }

    $mech->submit;
    die "Ticket save failed (ticket id = @{[ $self->id ]})\n"
        unless $mech->response->is_success;

    return $self;
}

sub destroy {
    my ($self) = @_;
    die "Cannot delete the ticket without id.\n" unless $self->id;

    my $id = $self->id;

    $self->connection->get_issues_page($id);

    my $mech = $self->connection->mechanize;
    my $link = $mech->find_link(url_regex => qr[/issues/${id}/destroy$]);

    die "Your cannot delete the ticket $id.\n" unless $link;

    my $html = $mech->content;
    my $delete_form = "<form name='net_redmine_delete_issue' method=\"POST\" action=\"@{[ $link->url_abs ]}\"><input type='hidden' name='_method' value='post'></form>";
    $html =~ s/<body>/<body>${delete_form}/;
    $mech->update_html($html);

    $mech->form_number(1);
    $mech->submit;

    die "Failed to delete the ticket\n" unless $mech->response->is_success;

    $self->id(-1);

    my $live = $self->connection->_live_ticket_objects;
    delete $live->{$id};

    return $self;
}

sub _build_histories {
    my ($self) = @_;
    die "Cannot lookup ticket histories without id.\n" unless $self->id;
    my $mech = $self->connection->get_issues_page($self->id)->mechanize;

    my $p = pQuery($mech->content);

    my $n = $p->find(".journal")->size;

    return [
        map {
            Net::Redmine::TicketHistory->new(
                connection => $self->connection,
                id => $_,
                ticket_id => $self->id
            )
        } (0..$n)
    ];
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;

__END__

=head1 NAME

Net::Redmine::Ticket - Represents a ticket.

=head1 SYNOPSIS



=head1 DESCRIPTION



=cut
