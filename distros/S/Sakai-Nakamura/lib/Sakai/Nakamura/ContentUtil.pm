#!/usr/bin/perl -w

package Sakai::Nakamura::ContentUtil;

use 5.008001;
use strict;
use warnings;
use Carp;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.13';

#{{{sub add_file_metadata_setup

sub add_file_metadata_setup {
    my ( $base_url, $content_path, $content_filename, $content_fileextension ) =
      @_;
    if ( !defined $base_url ) { croak 'No base url defined to add against!'; }
    if ( !defined $content_path ) {
        croak 'No content path to add file meta data to!';
    }
    if ( !defined $content_filename ) {
        croak 'No content filename provided when attempting to add meta data!';
    }
    if ( !defined $content_fileextension ) {
        croak
'No content file extension provided when attempting to add meta data!';
    }
    my $post_variables =
"\$post_variables = ['requests','[{\"url\":\"$content_path\",\"method\":\"POST\",\"parameters\":{\"sakai:pooled-content-file-name\":\"$content_filename\",\"sakai:description\":\"\",\"sakai:permissions\":\"public\",\"sakai:copyright\":\"creativecommons\",\"sakai:allowcomments\":\"true\",\"sakai:showcomments\":\"true\",\"sakai:fileextension\":\"$content_fileextension\",\"_charset_\":\"utf-8\"},\"_charset_\":\"utf-8\"},{\"url\":\"$content_path.save.json\",\"method\":\"POST\",\"_charset_\":\"utf-8\"}]']";
    return "post $base_url/system/batch $post_variables";
}

#}}}

#{{{sub add_file_metadata_eval

sub add_file_metadata_eval {
    my ($res) = @_;
    return ( ${$res}->code eq '200' );
}

#}}}

#{{{sub add_file_perms_setup

sub add_file_perms_setup {
    my ( $base_url, $content_path ) = @_;
    if ( !defined $base_url ) { croak 'No base url defined to add against!'; }
    if ( !defined $content_path ) {
        croak 'No content path to add file perms to!';
    }
    my $post_variables =
"\$post_variables = ['requests','[{\"url\":\"$content_path.members.html\",\"method\":\"POST\",\"parameters\":{\":viewer\":[\"everyone\",\"anonymous\"]}},{\"url\":\"$content_path.modifyAce.html\",\"method\":\"POST\",\"parameters\":{\"principalId\":[\"everyone\"],\"privilege\@jcr:read\":\"granted\"}},{\"url\":\"$content_path.modifyAce.html\",\"method\":\"POST\",\"parameters\":{\"principalId\":[\"anonymous\"],\"privilege\@jcr:read\":\"granted\"}}]']";
    return "post $base_url/system/batch $post_variables";
}

#}}}

#{{{sub add_file_perms_eval

sub add_file_perms_eval {
    my ($res) = @_;
    return ( ${$res}->code eq '200' );
}

#}}}

#{{{sub comment_add_setup

sub comment_add_setup {
    my ( $base_url, $content_path, $comment ) = @_;
    if ( !defined $base_url ) { croak 'No base url defined to add against!'; }
    if ( !defined $content_path ) {
        croak 'No content path to add comments to!';
    }
    if ( !defined $comment ) {
        croak 'No comment provided to add!';
    }
    my $post_variables = "\$post_variables = ['comment','$comment']";
    return "post $base_url/$content_path.comments $post_variables";
}

#}}}

#{{{sub comment_add_eval

sub comment_add_eval {
    my ($res) = @_;
    return ( ${$res}->code eq '201' );
}

#}}}

1;

__END__

=head1 NAME

Sakai::Nakamura::ContentUtil Methods to generate and check HTTP requests required for manipulating content.

=head1 ABSTRACT

Utility library returning strings representing Rest queries that perform
content related actions in the system.

=head1 METHODS

=head2 add_file_metadata_setup

Returns a textual representation of the request needed to manipulate content meta
data.

=head2 add_file_metadata_eval

Verify whether the attempt to manipulate content metadata succeeded.

=head2 add_file_perms_setup

Returns a textual representation of the request needed to manipulate content
permissions.

=head2 add_file_perms_eval

Verify whether the attempt to manipulate content permissions succeeded.

=head1 USAGE

use Sakai::Nakamura::ContentUtil;

=head1 DESCRIPTION

ContentUtil perl library essentially provides the request strings needed to
interact with content functionality exposed over the system rest interfaces.

Each interaction has a setup and eval method. setup provides the request,
whilst eval interprets the response to give further information about the
result of performing the request.

=head1 REQUIRED ARGUMENTS

None required.

=head1 OPTIONS

n/a

=head1 DIAGNOSTICS

n/a

=head1 EXIT STATUS

0 on success.

=head1 CONFIGURATION

None required.

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Daniel David Parry <perl@ddp.me.uk>

=head1 LICENSE AND COPYRIGHT

LICENSE: http://dev.perl.org/licenses/artistic.html

COPYRIGHT: (c) 2012 Daniel David Parry <perl@ddp.me.uk>
