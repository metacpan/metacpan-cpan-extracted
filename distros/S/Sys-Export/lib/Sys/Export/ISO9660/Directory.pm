package Sys::Export::ISO9660::Directory;

our $VERSION = '0.005'; # VERSION
# ABSTRACT: Represents a case-folded directory in ISO9660

use v5.26;
use warnings;
use experimental qw( signatures );
use parent 'Sys::Export::VFAT::Directory';


sub new($class, %attrs) {
   my $joliet_file= delete $attrs{joliet_file};
   my $self= $class->next::method(%attrs);
   $self->{joliet_file}= $joliet_file if defined $joliet_file;
   $self;
}

sub is_valid_name($self, $name) {
   Sys::Export::ISO9660::is_valid_joliet_name($name)
}
sub is_valid_shortname($self, $name) {
   Sys::Export::ISO9660::is_valid_shortname($name)
}
sub remove_invalid_shortname_chars($self, $name, $repl) {
   Sys::Export::ISO9660::remove_invalid_shortname_chars($name, $repl)
}


sub joliet_file { $_[0]{joliet_file} }

require Sys::Export::ISO9660;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Export::ISO9660::Directory - Represents a case-folded directory in ISO9660

=head1 CONSTRUCTORS

=head2 new

  $file= Sys::Export::ISO9660::Directory->new(%attributes);

Represents file (or directory) data to be encoded into the ISO image.

=head1 ATTRIBUTES

=head2 joliet_file

Unlike Files, Directories get encoded twice, once with a short filename and again with a long
unicode filename.  The directory short-name encoding is stored in C<file> and the joliet
encoding is stored in C<joliet_file>.

=head1 VERSION

version 0.005

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
