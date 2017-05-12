package Net::Posterous::Media::Local;

use strict;
use base qw(Net::Posterous::Object);
use Class::Accessor "antlers";
use URI::file;

=head1 NAME

Net::Posterous::Media::Local - represent local media files

=head1 METHODS

=cut

=head2 new

Create a new local file

=cut

sub new {
    my $class = shift;
    my %opts = @_;
    my $file = delete $opts{file};
    my $self = bless \%opts, $class;
    $self->file($file) if $file;
    return $self;
}

=head2 url

Get or set the url to this local media files

=cut

has url => ( is => "rw", isa => "Str" );

=head2 file 

Get or set the path to this file.

=cut
sub file {
    my $self = shift;
    # keep url() in sync
    if (@_) {
        $self->url("".URI::file->new(shift));
    }
    my $uri = URI->new($self->url);
    return undef unless 'file' eq $uri->scheme;
    return $uri->path;
}

sub _to_params {
    my $self = shift;
    return { type => 'local', url => $self->url };
}
1;
