package Net::RFC::Search;
=head1 NAME

Net::RFC::Search - search for RFC's and dump RFC's content either to a variable or to a file.

=head1 SYNOPSIS

Net::RFC::Search provides 2 methods:

B<search_by_header('keyword')> is for searching for a RFC index number by given 'keyword' (through RFC index text file).

B<get_by_index($index_number)> is for dumping RFC's content either to a variable or to a file.

    use Net::RFC::Search;

    my $rfc = Net::RFC::Search->new;

    # This will return array of RFC indices with "websocket" keyword in their headers.
    my @found = $rfc->search_by_header('WebSocket');

    # This will dump content of RFC 6455 into $rfc_text variable.
    my $rfc_text = $rfc->get_by_index(6455);

    # Dumps RFC 6455 into /tmp/6455.txt file
    $rfc->get_by_index(6455, '/tmp/6455.txt');

=head1 VERSION

Version 0.02

=head1 DESCRIPTION

Net::RFC::Search is a module aimed to be a simple tool to search and dump RFC's.

=head1 CONSTRUCTOR

=over 4

=item new(%options)

Create instance of C<Net::RFC::Search>.

B<%options> are optional parameters:

C<indexpath> - a file name to store RFC index file into. Defaults to ~/.rfcindex

C<rfcbaseurl> - URL of the RFC site/mirror where index file and RFC's are going to be downloaded from.

=back

=head1 METHODS

=over 4

=item search_by_header("keyword")

Returns array of RFC index numbers "keyword" has been found in.

Search occurs in RFC header names (i.e. through RFC index file).

=item get_by_index($index [, $filename ]);

Downloads RFC of index number C<$index> and returns downloaded content.

By providing optional C<$filename> content will be dumped into C<$filename>.

=back

=head1 TODO

=over 4

=item add caching facilities

=item do not rely on LWP::UserAgent only, add lynx/curl as optional methods to retrieve RFC's

=back

=head1 ACKNOWLEDGEMENTS

This module is heavily based on rfc.pl script written by **Derrick Daugherty** (http://www.dewn.com/rfc/)

=head1 AUTHOR

Nikolay Aviltsev, C<< navi@cpan.org >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Nikolay Aviltsev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

use 5.006;
use strict;

use LWP::UserAgent;
use IO::File;
use Carp;
use File::HomeDir;

our $VERSION = '0.02';
my $ua;

sub new {
    my ($class, %params) = @_;

    my $self = {};
    $self->{indexpath} = $params{indexpath} || File::HomeDir->my_home . "/.rfcindex";

    $self->{rfcbaseurl} = $params{rfcbaseurl} || 'http://www.ietf.org/rfc/';
    $self->{rfcbaseurl} =~ s/\s//g;
    $self->{rfcbaseurl} .= '/' unless substr($self->{rfcbaseurl}, -1) eq '/';

    bless $self, $class;
    return $self;
}

sub _ua {
    my $self = shift;
    return $ua if $ua;

    $ua = LWP::UserAgent->new(timeout => 10);
}

sub _make_index {
    my $self = shift;
    my $indexpath = $self->{indexpath};

    # system ("lynx -dump www.ietf.org/download/rfc-index.txt > $indexpath");
    my $response = $self->_ua->get('http://www.ietf.org/download/rfc-index.txt');
    if ($response->is_success) {
        my $fh = IO::File->new($indexpath, 'w');
        print $fh $response->decoded_content;
        undef $fh;
    }
    else {
        confess "Could not get rfc-index.txt, please try again later";
    }
}

sub search_by_header {
    my ($self, $string) = @_;
    $self->_make_index unless -e $self->{indexpath};

    my $fh = IO::File->new($self->{indexpath}, "r");

    my ($thing, @found_indices);
    my $found = 0;

    for my $line(<$fh>) {
        if ($line !~ /^\s*$/) {
            $thing .= $line;
            $found = 1 if ($line =~ /$string/i);
        }
        else {
            $thing =~ /^(\d+)/ if $thing;
            push @found_indices, $1 if ($1 && $found);

            $found = 0;
            $thing = '';
        }
    }

    undef $fh;
    return @found_indices;
}

sub get_by_index {
    my ($self, $index, $dump_to) = @_;
    $self->_make_index unless -e $self->{indexpath};

    my $rfc;
    if ($index) {
        my $response = $self->_download_rfc_by_index($index);
        $rfc = $response->{error} ? $response->{error_message} : $response->{content};
    }

    if ($dump_to) {
        my $fh = IO::File->new($dump_to, "w");
        print $fh $rfc;
    }

    return $rfc;
}

sub _download_rfc_by_index {
    my ($self, $index) = @_;
    if (length $index < 4) {
        $index = '0' . $index;
    }

    my $rfcbaseurl = $self->{rfcbaseurl};
    my $url = $self->{rfcbaseurl} . "rfc" . $index . ".txt";

    # `lynx -dump ${rfcbaseurl}rfc$index.txt`;
    my $response = $self->_ua->get($url);

    return $response->is_success ?
        { error => 0, content => $response->decoded_content } :
        { error => 1, error_code => $response->code, error_message => $response->status_line };
}

1;
