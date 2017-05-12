package Net::GoogleDrive;

use common::sense;
use JSON;
use Mouse;
use LWP::UserAgent;
use HTTP::Request::Common;
use URI;

=head1 NAME

Net::GoogleDrive - A Google Drive API interface

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Google Drive API is basd on OAuth. I try to abstract as much away as
possible so you should not need to know too much about it.  Kudos to
Net::Dropbox::API.

This is how it works:

    use Net::GoogleDrive;

    my $gdrive = Net::GoogleDrive->new();
    my $login_link = $gdrive->login_link();

    ... Time passes and the login link is clicked ...

    my $gdrive = Net::GoogleDrive->new();

    # $code will come from CGI or somesuch: Google gives it to you
    $gdrive->token($code);

    my $files = $gdrive->files();

    foreach my $f (@{ $files->{items} }) {
        if ($f->{downloadUrl}) {
            open(my $fh, ">", "file.dl") or die("file.dl: $!\n");
            print($fh $gdrive->downloadUrl($f));
            close($fh);
        }
    }

=head1 FUNCTIONS

=cut

has 'ua' => (is => 'rw', isa => 'LWP::UserAgent', default => sub { LWP::UserAgent->new() });
has 'debug' => (is => 'rw', isa => 'Bool', default => 0);
has 'error' => (is => 'rw', isa => 'Str', predicate => 'has_error');
has 'scope' => (is => 'rw', isa => 'Str', required => 'Str');
has 'redirect_uri' => (is => 'rw', isa => 'Str', required => 'Str');
has 'client_id' => (is => 'rw', isa => 'Str', required => 'Str');
has 'client_secret' => (is => 'rw', isa => 'Str');
has 'access_token' => (is => 'rw', isa => 'Str');

=head2 login_link

This returns the login URL. This URL has to be clicked by the user and the user then has
to accept the application in Google Drive. 

Google Drive then redirects back to the callback URI defined with
C<$self-E<gt>redirect_uri>.

=cut

sub login_link
{
    my $self = shift;

    my $uri = URI->new('https://accounts.google.com/o/oauth2/auth');

    $uri->query_form (
        response_type => "code",
        client_id => $self->client_id(),
        redirect_uri => $self->redirect_uri(),
        scope => $self->scope(),
    );

    return($uri->as_string());
}

=head2 token

This returns the Google Drive access token. This is needed to 
authorize with the API.

=cut

sub token
{
    my $self = shift;
    my $code = shift;

    my $req = &HTTP::Request::Common::POST(
        'https://accounts.google.com/o/oauth2/token',
        [
            code => $code,
            client_id => $self->client_id(),
            client_secret => $self->client_secret() || die("no client_secret given"),
            redirect_uri => $self->redirect_uri(),
            grant_type => 'authorization_code',
        ]
    );

    my $ua = $self->ua();
    my $res = $ua->request($req);

    if ($res->is_success()) {
        my $token = JSON::from_json($res->content());
        $self->access_token($token->{access_token});

        print "Got Access Token ", $res->access_token(), "\n" if $self->debug();
    }
    else {
        $self->error($res->status_line());
        warn "Something went wrong: ".$res->status_line();
    }
}

=head2 files

This returns a files Resource object from JSON.

=cut

sub files
{
    my $self = shift;

    my $req = HTTP::Request->new(
        GET => 'https://www.googleapis.com/drive/v2/files',
        HTTP::Headers->new(Authorization => "Bearer " . $self->access_token())
    );

    my $res = $self->ua()->request($req);

    if ($res->is_success()) {
        my $list = JSON::from_json($res->content());

        return($list);
    }
    else {
        $self->error($res->status_line());
        warn "Something went wrong: ".$res->status_line();
        return(undef);
    }
}

=head2 downloadUrl

This returns the binary data from a file.

=cut

sub downloadUrl
{
    my $self = shift;
    my $file = shift;

    my $req = HTTP::Request->new(
        GET => $$file{downloadUrl},
        HTTP::Headers->new(Authorization => "Bearer " . $self->access_token())
    );

    my $res = $self->ua()->request($req);

    if ($res->is_success()) {
        return($res->content());
    }
    else {
        $self->error($res->status_line());
        warn "Something went wrong: ".$res->status_line();
        return(undef);
    }
}

=head2 FUTURE

More can be added if there is interest.

=cut

=head1 AUTHOR

Brian Medley, C<< <bpmedley at cpan.org> >>

=head1 BUGS

There are plenty.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::GoogleDrive

=head1 COPYRIGHT & LICENSE

Copyright 2012 Brian Medley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
