package Path::Tiny::Rule;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.02';

use Path::Tiny qw( path );

use parent 'Path::Iterator::Rule';

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _iter {
    my $self = shift;

    my $iter = $self->SUPER::_iter(@_);

    return sub {
        my $item = $iter->();
        return unless $item;
        return path($item);
    };
}

1;

# ABSTRACT: Path::Iterator::Rule subclass that returns Path::Tiny objects

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Tiny::Rule - Path::Iterator::Rule subclass that returns Path::Tiny objects

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Path::Tiny::Rule;

  my $iter = Path::Tiny::Rule->new->name(qr/\.t$/)->iter('t');

  while ( my $test_file = $iter->() ) {
      print $test_file->basename, "\n";
  }

=head1 DESCRIPTION

This module is a very thin wrapper around L<Path::Iterator::Rule> that always
returns L<Path::Tiny> objects instead of strings. It should otherwise be a
drop-in replacement for L<Path::Iterator::Rule>, and any deviation from that
is a bug.

This module has no public API that is not provided by L<Path::Iterator::Rule>.

It exists because I got really tired of writing this:

  while ( my $path = $iter->() ) {
      $path = path($path);
      ...;
  }

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/Path-Tiny-Rule/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Path-Tiny-Rule can be found at L<https://github.com/houseabsolute/Path-Tiny-Rule>.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at L<http://www.urth.org/~autarch/fs-donation.html>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 - 2019 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
