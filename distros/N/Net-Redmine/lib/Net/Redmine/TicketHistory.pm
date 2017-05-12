package Net::Redmine::TicketHistory;
use Any::Moose;
use DateTime::Format::DateParse;
use Net::Redmine::Ticket;
use Net::Redmine::User;
use URI;

has connection => (
    is => "rw",
    isa => "Net::Redmine::Connection",
    required => 1
);

has id               => (is => "rw", isa => "Int", required => 1);
has ticket_id        => (is => "rw", isa => "Int", required => 1);
has date             => (is => "rw", isa => "DateTime", lazy_build => 1);
has note             => (is => "rw", isa => "Str", lazy_build => 1);
has property_changes => (is => "rw", isa => "HashRef", lazy_build => 1);
has author           => (is => "ro", isa => "Maybe[Net::Redmine::User]", lazy_build => 1);

has _ticket_page_html => (is => "rw", isa => "Str", lazy_build => 1);

has ticket => (
    is => "ro",
    isa => "Net::Redmine::Ticket",
    lazy_build => 1
);

use pQuery;

sub _build__ticket_page_html {
    my ($self) = @_;
    return $self->connection->get_issues_page($self->ticket_id)->mechanize->content;
}

sub _build_property_changes {
    my ($self)           = @_;
    my $property_changes = {};

    my $find_property_changes = sub {
        my ($cb) = @_;
        return sub {
            pQuery($_)->find("ul:eq(0) li")->each(
                sub {
                    my $li   = pQuery($_);
                    my $name = lc( $li->find("strong")->text );
                    my $from = $li->find("i")->eq(0)->text;
                    my $to   = $li->find("i")->eq(1)->text;

                    $cb->( $name, $from, $to );
                }
            )
        }
    };

    my $p = pQuery( $self->_ticket_page_html );
    my $journals = $p->find(".journal");

    if ( $self->id == 0 ) {
        $journals->each(
            $find_property_changes->(
                sub {
                    my ( $name, $from, $to ) = @_;
                    $property_changes->{$name} = { from => "", to => $from }
                        unless exists $property_changes->{$name};
                }
            )
        );
    }
    else {
        $journals->eq( $self->id - 1 )->each(
            $find_property_changes->(
                sub {
                    my ( $name, $from, $to ) = @_;
                    $property_changes->{$name} = { from => $from, to => $to };
                }
            )
        );
    }

    return $property_changes;
}

sub _build_ticket {
    my ($self) = @_;
    return Net::Redmine::Ticket->load(id => $self->ticket_id, connection => $self->connection);
}

use HTML::WikiConverter;
use Encode;

sub _build_note {
    my ($self) = @_;

    if ($self->id == 0) {
        return "";
    }

    my $p = pQuery($self->_ticket_page_html);
    my $note_html = $p->find(".journal")->eq($self->id - 1)->find(".wiki")->html;
    if ($note_html) {
        my $converter = HTML::WikiConverter->new(dialect => "Markdown");
        my $note_text = $converter->html2wiki( Encode::encode_utf8($note_html) );
        return $note_text;
    }
    return "";
}

sub _build_date {
    my ($self) = @_;

    if ($self->id == 0) {
        # TODO: get the real ticket creation date
        return DateTime::Format::DateParse->parse_datetime("1970/01/01 00:00:01");
    }

    my $p = pQuery($self->_ticket_page_html);
    my $date_str = $p->find(".journal")->eq($self->id - 1)->find("a")->get(3)->attr("title");
    return DateTime::Format::DateParse->parse_datetime($date_str);
}

sub _build_author {
    my $self = shift;
    my $p = pQuery($self->_ticket_page_html);
    my $user_uri = URI->new($p->find(".journal")->eq($self->id - 1)->find("a")->get(2)->getAttribute("href"));
    if ($user_uri->path =~ m{/account/show/(\d+)$}) {
        return Net::Redmine::User->load(id => $1, connection => $self->connection);
    }
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
