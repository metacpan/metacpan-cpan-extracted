package Net::Redmine::User;
use Any::Moose;
use URI::Escape;

has connection => (
    is => "rw",
    isa => "Net::Redmine::Connection",
    required => 1,
    weak_ref => 1,
);

has id => (
    is => "rw",
    isa => "Num",
    required => 1
);

has email => (
    is => "rw",
    isa => "Str",
    lazy_build => 1,
);

has page_html => (
    is => "rw",
    isa => "Str",
    lazy_build => 1,
);

sub _build_email {
    my $self = shift;

    my $html = $self->page_html;

    if ($html =~ m[<li>Email: <script type="text/javascript">eval\(decodeURIComponent\('(.+?)'\)\)</script></li>]) {
        my $docwrite = uri_unescape($1);
        my ($email) = $docwrite =~ m["mailto:(.+)">];
        return $email;
    }
}

sub _build_page_html {
    my $self = shift;
    $self->connection->get_user_page(id => $self->id)->mechanize->content
}

sub load {
    my $class = shift;
    my %attr = @_;
    die "should specify user id when loading it." unless defined $attr{id};
    die "should specify connection object when loading tickets." unless defined $attr{connection};

    my $self = $class->new(%attr);
    $self->refresh or return;

    return $self;
}

sub refresh {
    my $self = shift;
    $self->clear_page_html;
    return $self;
}


__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
