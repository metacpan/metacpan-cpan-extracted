package Net::Rackspace::Notes;
use Moose;

our $VERSION = '1.0000'; # VERSION

#use Data::Dump;
use HTTP::Request;
use JSON qw(to_json from_json);
use LWP::UserAgent;
use Parallel::ForkManager;

has email    => ( is => 'ro', isa => 'Str', required => 1);
has password => ( is => 'ro', isa => 'Str', required => 1);

has agent => (
    is => 'ro',
    isa => 'LWP::UserAgent',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $agent = LWP::UserAgent->new();
        $agent->credentials('apps.rackspace.com:80', 'webmail',
            $self->email, $self->password);
        $agent->default_header(Accept => 'application/json');
        return $agent;
    },
    handles => [qw(get request)],
);

has base_uri => (
    is => 'ro',
    isa => 'Str',
    default => 'http://apps.rackspace.com/api/',
);

has base_uri_notes => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    builder => '_build_base_uri_notes',
);

has notes => (
    is => 'ro',
    isa => 'ArrayRef[HashRef[Str]]',
    lazy => 1,
    builder => '_build_notes',
    auto_deref => 1,
);

sub _build_base_uri_notes {
    my ($self) = @_;

    my ($response, $data);

    #$response = $self->agent->get($self->base_uri);
    #dd from_json $response->content;
    #exit;

    #$response = $self->agent->get($data->{versions}[0]);
    $response = $self->agent->get($self->base_uri . "/0.9.0");
    my $status = $response->status_line;
    die "Response was $status.\nCheck your email and password.\n"
        unless $status =~ /^2\d\d/;
    $data = from_json $response->content;

    $response = $self->agent->get($data->{usernames}[0]);
    $data = from_json $response->content;

    return $data->{data_types}{notes}{uri};
}

sub _build_notes {
    my ($self) = @_;
    my $response = $self->get($self->base_uri_notes);
    my $data = from_json($response->content);
    #dd $self->base_uri_notes, $response->headers; exit;
    #dd $data; exit;

    my @notes;
    my $pm = new Parallel::ForkManager(30);
    $pm->run_on_finish (sub {
        my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $note) = @_;
        push @notes, $note;
    });

    foreach my $uri (map $_->{uri}, @{$data->{notes}}) {
        $pm->start and next;
        my $response = $self->agent->get($uri);
        #dd $response->headers;
        #dd from_json $response->content;
        my $note = from_json($response->content)->{note};
        $note->{uri} = $uri;
        $note->{last_modified} = $response->last_modified;
        $pm->finish(0, $note);
    };
    $pm->wait_all_children;

    #return [ sort { $a->{subject} cmp $b->{subject} } @notes ];
    return [ sort { $b->{last_modified} cmp $a->{last_modified} } @notes ];
}

sub add_note {
    my ($self, $subject, $body) = @_;
    my $req = HTTP::Request->new(POST => $self->base_uri_notes);
    $req->header(Content_Type => 'application/json');
    my $json = to_json {
        note => {
            subject => $subject,
            content => $body,
        }
    };
    $req->content($json);
    my $response = $self->agent->request($req);
    return $response;
}

sub put_note {
    my ($self, $content, $num) = @_;
    my $orig_note = $self->notes->[$num];
    my $req = HTTP::Request->new(PUT => $orig_note->{uri});
    $req->header(Content_Type => 'application/json');
    my $json = to_json({
        note => {
            subject => $orig_note->{subject},
            content => $content,
        }
    });
    $req->content($json);
    my $response = $self->agent->request($req);
    return $response;
}

sub delete_note {
    my ($self, $num) = @_;
    my $note = $self->notes->[$num];
    return "Note $num does not exist." unless $note;
    my $req = HTTP::Request->new(DELETE => $note->{uri});
    $req->header(Content_Type => 'application/json');
    my $response = $self->agent->request($req);
    splice(@{$self->notes}, $num, 1) if $response->is_success;
    return $response;
}

1;

# ABSTRACT: An interface to Rackspace Email Notes.


__END__
=pod

=head1 NAME

Net::Rackspace::Notes - An interface to Rackspace Email Notes.

=head1 VERSION

version 1.0000

=head1 SYNOPSIS

This class implements the functionality needed to 
interact with the Rackspace Email Notes API.
Most likely, the racknotes script will be what you want to use instead of this.

Example usage:

    use Net::Rackspace::Notes;
    my $racknotes = Net::Rackspace::Notes->new(
        email    => $email,
        password => $password,
    );

    for my $note ($racknotes->notes) {
        print "$note->{subject}: $note->{content}\n";
    }

    # Add a new note with the given subject and content
    $racknotes->add_note('some subject', 'some important note');

    # Delete notes()->[3]
    $racknotes->delete_note(3);

=head1 METHODS

=head2 add_note($subject, $content)

Add a new note with the given subject and content.

=head2 delete_note($num)

Delete the note at $notes->[$num].

=head2 notes()

Returns an arrayref of all the notes.  Returns a list in list context.

=head2 put_note($content, $num)

Replace the contents of notes->[$num] with $content.

=head1 AUTHOR

Naveed Massjouni <naveedm9@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Naveed Massjouni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

