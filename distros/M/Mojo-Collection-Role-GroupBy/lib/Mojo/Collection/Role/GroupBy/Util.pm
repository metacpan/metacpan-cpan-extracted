package Mojo::Collection::Role::GroupBy::Util;
use Exporter 'import';
our @EXPORT_OK = qw/pack_array unpack_array/;

sub unpack_array {
    local $_ = shift; local @_;
    while ($_) {
	push @_, substr($_, 2, unpack("n", substr($_, 0, 2)));
	substr($_, 0, 2 + length($_[-1]), '');
    };
    @_;
}

sub pack_array { join '', map { pack("na*", (length $_), $_) } @_ }

1;
