package TestHelpers;
use Mojo::Base -strict;
use Mojo::Date;
use Mojo::Asset::File;
use Mojo::Util ();
use FindBin;

our @ISA    = qw(Exporter);
our @EXPORT = qw/etag last_modified/;

sub etag {
    my $md5  = Mojo::Util::md5_sum(ref $_[0] ? _mtime(shift, shift) : _mtime(shift));
    my $etag = qq{"$md5"};
    return wantarray ? ($etag, map {qq{"$md5-$_"}} @_) : $etag;
}

sub last_modified { Mojo::Date->new(_mtime(@_))->to_string }

sub _mtime {
    ref $_[0]
        ? shift->file(shift)->mtime
        : Mojo::Asset::File->new(path => "$FindBin::Bin/public/@{[shift]}")->mtime;
}

1;
