package Sword::Key;
BEGIN {
  $Sword::Key::VERSION = '0.102800';
}
use strict;
use warnings;

require XSLoader;
XSLoader::load('Sword', $Sword::Key::VERSION);

# ABSTRACT: Sword keys may be used to lookup module entries

1;



=pod

=head1 NAME

Sword::Key - Sword keys may be used to lookup module entries

=head1 VERSION

version 0.102800

=head1 SYNOPSIS

  use Sword;

  my $library = Sword::Manager->new;

  my $module = $library->get_module('KJV');
  my $key = $module->create_key;

  $key->set_text('James 1:5');

  $module->set_key($key);

=head1 DESCRIPTION

This Perl module provides access to the C<SWKey> class from the Sword Engine API.

This documentation should cover everything that you can do with it. If something is wrong or missing, please report a bug.

=head1 METHODS

=head2 clone

  my $new_key = $key->clone;

Clones the key to create a new identical key.

=head2 set_text

  $key->set_text($key_string);

Sets the key string text.

=head2 get_text

  my $key_string = $key->get_text;

Retrieve the key string text.

=head2 get_short_text

  my $key_string = $key->get_short_text;

Retrieve a shortened key string text.

=head2 get_range_text

  my $range_string = $key->get_range_text;

Retrieve teh key string range text.

=head2 compare

  my $comparison = $key->compare($other_key);

Performs a comparison between keys. Returns positive if C<$key> is ahead of C<$other_key>. Returns 0 if they are equal. Returns negative if C<$key> is behind C<$other_key>.

=head2 equals

  my $equals = $key->equals($other_key);

Returns true if the two keys refer to the same position.

=head2 increment

=head2 decrement

  $key->increment;
  $key->increment($steps);
  $key->decrement;
  $key->decrement($steps);

Use C<increment> to select a key one or more steps forward of the current. Use C<decrement> to select a key backward. If C<$steps> is omitted, the increment/decrement defaults to 1.

=head2 top

=head2 bottom

  $key->top
  $key->bottom

These set the key to the beginning or end position, respectively.

These are analogous to:

  key->setPosition(TOP);
  key->setPosition(BOTTOM);

in the C++ API.

=head2 index

  my $index = $key->index;
  $key->index($new_index);

Retrieve the index into a module that this key represents.

=head1 SEE ALSO

L<Sowrd::Module>

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

