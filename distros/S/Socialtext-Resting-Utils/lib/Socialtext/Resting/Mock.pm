package Socialtext::Resting::Mock;
use strict;
use warnings;
use HTTP::Response;

=head1 NAME

Socialtext::Resting::Mock - Fake rester

=head1 SYNOPSIS

  my $rester = Socialtext::Resting::Mock->(file => 'foo');

  # returns content of 'foo'
  $rester->get_page('bar');

=cut

our $VERSION = '0.04';

=head1 FUNCTIONS

=head2 new( %opts )

Create a new fake rester object.  Options:

=over 4

=item file

File to return the contents of.

=back

=cut

sub new {
    my ($class, %opts) = @_;
    if ($opts{file}) {
        die "not a file: $opts{file}" unless -f $opts{file};
    }
    my $self = \%opts;
    bless $self, $class;
    return $self;
}

=head2 server( $new_server )

Get or set the server.

=cut

sub server {
    my $self = shift;
    my $server = shift;
    $self->{server} = $server if $server;
    return $self->{server};
}

=head2 username( $new_username )

Get or set the username.

=cut

sub username {
    my $self = shift;
    my $username = shift;
    $self->{username} = $username if $username;
    return $self->{username};
}

=head2 password( $new_password )

Get or set the password.

=cut

sub password {
    my $self = shift;
    my $password = shift;
    $self->{password} = $password if $password;
    return $self->{password};
}

=head2 workspace( $new_workspace )

Get or set the workspace.

=cut

sub workspace {
    my $self = shift;
    my $workspace = shift;
    $self->{workspace} = $workspace if $workspace;
    return $self->{workspace};
}

=head2 get_page( $page_name )

Returns the content of the specified file or the page stored 
locally in the object.

=cut

sub get_page {
    my $self = shift;
    my $page_name = shift;

    if ($self->{file}) {
        warn "Mock rester: returning content of $self->{file} for page ($page_name)\n";
        open(my $fh, $self->{file}) or die "Can't open $self->{file}: $!";
        local $/;
        my $page = <$fh>;
        close $fh;
        return $page;
    }
    my $text = shift @{ $self->{page}{$page_name} };
    unless (defined $text) {
        $text = "$page_name not found";
    }
    return $text;
}

=head2 get_pages

Retrieve a list of pages in the current workspace.

=cut

sub get_pages {
    my ($self) = @_;
    return $self->{_get_pages} if $self->{_get_pages}; # testing shortcut
    return keys %{ $self->{page} };
}


=head2 put_page( $page_name )

Stores the page content in the object.

=cut

sub put_page {
    my ($self, $page, $content) = @_;
    die delete $self->{die_on_put} if $self->{die_on_put};
    push @{ $self->{page}{$page} }, $content;
}

=head2 put_pagetag( $page, $tag )

Stores the page tags in the object.

=cut

sub put_pagetag {
    my ($self, $page, $tag) = @_;
    push @{$self->{page_tags}{$page}}, $tag;
}

=head2 get_pagetags( $page )

Retrieves page tags stored in the object.

=cut

sub get_pagetags {
    my ($self, $page) = @_;
    my $tags = $self->{page_tags}{$page} || [];
    return @$tags if wantarray;
    return join ' ', @$tags;
}

=head2 die_on_put( $rc )

Tells the next put_page() to die with the supplied return code.

=cut

sub die_on_put {
    my $self = shift;
    my $rc = shift;

    $self->{die_on_put} = $rc;
}

=head2 accept( $mime_type )

Stores the requested mime type.

=cut

sub accept {
    my $self = shift;
    $self->{accept} = shift;
}

=head2 order( $order )

Stores the requested order.

=cut

sub order {
    my $self = shift;
    $self->{order} = shift;
}

=head2 get_taggedpages( $tag )

Retrieves the taggedpages stored in the object.

=cut

sub get_taggedpages {
    my $self = shift;
    my $tag = shift;

    # makes testing easier
    my $mock_return = $self->{taggedpages}{$tag};
    return $mock_return if defined $mock_return;

    my @taggedpages;
    for my $page (keys %{$self->{page_tags}}) {
        my $tags = $self->{page_tags}{$page};
        next unless grep { $_ eq $tag } @$tags;
        push @taggedpages, $page;
    }
    return @taggedpages if wantarray;
    return join ' ', @taggedpages;
}

=head2 set_taggedpages( $tag, $return )

Store the taggedpages return value in the object.

This is not a real function, but it can make testing easier.

=cut

sub set_taggedpages {
    my $self = shift;
    my $tag = shift;
    $self->{taggedpages}{$tag} = shift;
}

=head2 json_verbose

Set the json_verbose flag.

=cut

sub json_verbose { $_[0]->{json_verbose} = $_[1] }

=head2 response

Retrieve a fake response object.

=cut

sub response {
    my $self = shift;
    $self->{response} = shift if @_;
    $self->{response} ||= HTTP::Response->new(200);
    return $self->{response};
}

=head1 AUTHOR

Luke Closs, C<< <luke.closs at socialtext.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Luke Closs, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
