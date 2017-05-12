package Plucene::SearchEngine::Index::URL;
use base "Plucene::SearchEngine::Index::Base";

use strict;
use Carp;
use Time::Piece;
use File::Temp;
use URI;
use Date::Parse;
use HTTP::Request;
use LWP::UserAgent;
use File::Basename;
use File::Temp qw(tempfile);

=head1 NAME

Plucene::SearchEngine::Index::URL - File reader for web URLs

=head1 DESCRIPTION

This frontend module takes a URL, downloads its content, extracts its metadata
and passes the file onto a backend. The frontend registers the following
Plucene fields:

=over 3

=item mimetype

The MIME type of the data.

=item filename

The basename of the URL's filename.

=item id

The URL given.

=item modified

A Plucene date field representing the last modified date of the file

=item language

The ISO language identifier of the content

=item encoding

The original character set. (before conversion to UTF-8)

=back

=head2 METHODS

    Plucene::SearchEngine::Index::URL->examine($url);

This downloads and examines a file on the filesystem for the above metadata,
before handling it to a backend. 

=cut

sub examine {
    my ($class, $url) = @_;
    my $ua = LWP::UserAgent->new;
    my $response = $ua->get($url);
    return unless $response->is_success;

    my $encoding = "";
    my $filename = basename($url); # Hack, hack
    my $mime = $response->header("Content-Type");
    $mime =~ s/;\s+(.*)//;
    my $rest = $1;
    my $self = $class->handler_for($filename, $mime)->new();
    my $lm = $response->header("Last-Modified");
    if ($rest =~ /charset=([\w\-]+)/) { $encoding = $1; }

    if (my $language =$response->header("Content-Language")) {
        $self->add_data("language", "Keyword", $language);
    }

    $self->add_data("mimetype", "Keyword", $mime);
    $self->add_data("id", "Keyword", $url);
    $self->add_data("filename", "Keyword", $filename);
    $self->add_data("modified", "Date", Time::Piece->new(str2time($lm)));

    my ($fh, $tmpfile) = tempfile();
    if ($encoding) { 
        require Encode;
        binmode $fh, ":utf8";
        print $fh Encode::decode($encoding, $response->content);
    } else { 
        print $fh $response->content;
    }
    close $fh;
    my @docs = $self->gather_data_from_file($tmpfile);
    if (@docs <2) { @docs = ($self) }
    if ($encoding) { 
        $_->add_data("encoding", "Text", $encoding) for @docs;
    }
    unlink $tmpfile;
    if (wantarray) { return @docs } 
    else { 
        carp "Using ->examine in scalar context is deprecated";
        return $docs[0]; 
    }
}

1;
