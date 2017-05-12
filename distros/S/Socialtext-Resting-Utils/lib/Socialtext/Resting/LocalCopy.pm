package Socialtext::Resting::LocalCopy;
use strict;
use warnings;
use JSON::XS;

=head1 NAME

Socialtext::Resting::LocalCopy - Maintain a copy on disk of a workspace

=head1 SYNOPSIS

Socialtext::Resting::LocalCopy allows one to copy a workspace into files
on the local disk, and to update a workspace from files on disk.

=cut

our $VERSION = '0.01';

=head1 METHODS

=head2 new

Create a new LocalCopy object.  Requires a C<rester> parameter, which should
be a Socialtext::Rester-like object.

=cut

sub new {
    my $class = shift;
    my $self = { @_ };

    die 'rester is mandatory' unless $self->{rester};
    bless $self, $class;
    return $self;
}

=head2 pull

Reads a workspace and pulls all of the pages into files in the specified
directory.  Options are passed in as a list of named options:

=over 4

=item dir - The directory the files should be saved to.

=item tag - an optional tag.  If specified, only tagged files will be pulled.

=back

=cut

sub pull {
    my $self = shift;
    my %opts = @_;
    my $dir  = $opts{dir};
    my $tag  = $opts{tag};
    my $r    = $self->{rester};

    $r->accept('text/plain');
    my @pages = $tag ? $r->get_taggedpages($tag) : $r->get_pages();
    $r->accept('application/json');
    $r->json_verbose(1);
    for my $p (@pages) {
        print "Saving $p ...\n";
        my $obj = decode_json($r->get_page($p));

        # Trim the content
        my %to_keep = map { $_ => 1 } $self->_keys_to_keep;
        for my $k (keys %$obj) {
            delete $obj->{$k} unless $to_keep{$k};
        }

        my $wikitext_file = "$dir/$obj->{page_id}";
        open(my $fh, ">$wikitext_file") or die "Can't open $wikitext_file: $!";
        binmode $fh, ':utf8';
        print $fh delete $obj->{wikitext};
        close $fh or die "Can't write $wikitext_file: $!";

        my $json_file = "$wikitext_file.json";
        open(my $jfh, ">$json_file") or die "Can't open $json_file: $!";
        print $jfh encode_json($obj);
        close $jfh or die "Can't write $json_file: $!";
    }
}

sub _keys_to_keep { qw/page_id name wikitext tags/ }

=head2 push

Reads a directory and pushes all the files in that directory up to
the specified workspace.  Options are passed in as a list of named options:

=over 4

=item dir - The directory the files should be saved to.

=item tag - an optional tag.  If specified, only tagged files will be pushed.

Note - tag is not yet implemented.

=back

=cut

sub push {
    my $self = shift;
    my %opts = @_;
    my $dir  = $opts{dir};
    my $tag  = $opts{tag};
    my $r    = $self->{rester};

    die "Sorry - push by tag is not yet implemented!" if $tag;

    my @files = glob("$dir/*.json");
    for my $f (@files) {
        open(my $fh, $f) or die "Can't open $f: $!";
        local $/ = undef;
        my $obj = decode_json(<$fh>);
        close $fh;

        (my $wikitext_file = $f) =~ s/\.json$//;
        open(my $wtfh, $wikitext_file) or die "Can't open $wikitext_file: $!";
        $obj->{wikitext} = <$wtfh>;
        close $wtfh;

        print "Putting $obj->{page_id} ...\n";
        $r->put_page($obj->{name}, $obj->{wikitext});
        $r->put_pagetag($obj->{name}, $_) for @{ $obj->{tags} };
    }
}

=head1 BUGS

Attachments are not yet supported.
Push by tag is not yet supported.

=head1 AUTHOR

Luke Closs, C<< <luke.closs at socialtext.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Luke Closs, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
