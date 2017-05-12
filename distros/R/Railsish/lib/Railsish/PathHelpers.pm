package Railsish::PathHelpers;
our $VERSION = '0.21';

use strict;
use warnings;
our @HELPERS = ();

sub install_helpers {
    my $to = caller;
    for(@HELPERS) {
	no strict;
	*{$to . "::" . $_} = *{__PACKAGE__ . "::" . $_};
    }
}

sub hash_for_helpers {
    my $ret = {};
    for (@HELPERS) {
	no strict;
	$ret->{$_} = \&{__PACKAGE__ . "::" . $_};
    }
    return $ret;
}

*as_hash = *hash_for_helpers;

1;

__END__
=head1 NAME

Railsish::PathHelpers

=head1 VERSION

version 0.21

=head1 AUTHOR

  Liu Kang-min <gugod@gugod.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Liu Kang-min <gugod@gugod.org>.

This is free software, licensed under:

  The MIT (X11) License

