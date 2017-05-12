package MouseX::Types::URI;

use 5.008_001;
use strict;
use warnings;
use Scalar::Util ();
use URI;
use URI::file;
use URI::data;
use URI::WithBase;
use URI::FromHash ();
use Mouse::Util::TypeConstraints;
use MouseX::Types -declare => [qw(Uri FileUri DataUri)]; # export types
use MouseX::Types::Mouse qw(Str ScalarRef HashRef);
use MouseX::Types::Path::Class qw(File Dir);

our $VERSION = '0.03';

type 'URI', # doesn't use class_type 'URI'
    where { Scalar::Util::blessed($_) and ($_->isa('URI') or $_->isa('URI::WithBase')) };

class_type 'URI::file';
class_type 'URI::data';

subtype Uri,     as 'URI';
subtype FileUri, as 'URI::file';
subtype DataUri, as 'URI::data';

for my $type ( 'URI', Uri ) {
    coerce($type,
        from Str,                 via { URI->new($_) },
        from ScalarRef,           via { my $u = URI->new('data:'); $u->data($$_); $u },
        from HashRef,             via { URI::FromHash::uri(%$_) },
        from File,                via { URI::file->new($_) },
        from Dir,                 via { URI::file->new($_) },
        from 'Path::Class::Dir',  via { URI::file->new($_) },
        from 'Path::Class::File', via { URI::file->new($_) },
    );
}

for my $type ( 'URI::file', FileUri ) {
    coerce($type,
        from Str,                 via { URI::file->new($_) },
        from File,                via { URI::file->new($_) },
        from Dir,                 via { URI::file->new($_) },
        from 'Path::Class::Dir',  via { URI::file->new($_) },
        from 'Path::Class::File', via { URI::file->new($_) },
    );
}

for my $type ( 'URI::data', DataUri ) {
    coerce($type,
        from Str, via {
            /^data:/ ? URI->new($_) : do { my $u = URI->new('data:'); $u->data($_); $u }
        },
        from ScalarRef, via {
            $$_ =~ /^data:/ ? URI->new($$_) : do { my $u = URI->new('data:'); $u->data($$_); $u }
        },
    );
}

1;

=head1 NAME

MouseX::Types::URI - A URI type library for Mouse

=head1 SYNOPSIS

=head2 CLASS TYPES

  package MyApp;
  use Mouse;
  use MouseX::Types::URI;

  has 'uri' => (
      is     => 'rw',
      isa    => 'URI',
      coerce => 1,
  );

  has 'data' => (
      is     => 'rw',
      isa    => 'URI::data',
      coerce => 1,
  );

  has 'file' => (
      is     => 'rw',
      isa    => 'URI::file',
      coerce => 1,
  );

=head2 CUSTOM TYPES

  package MyApp;
  use Mouse;
  use MouseX::Types::URI qw(Uri DataUri FileUri);

  has 'uri' => (
      is     => 'rw',
      isa    => Uri,
      coerce => 1,
  );

  has 'data' => (
      is     => 'rw',
      isa    => DataUri,
      coerce => 1,
  );

  has 'file' => (
      is     => 'rw',
      isa    => FileUri,
      coerce => 1,
  );

=head1 DESCRIPTION

MouseX::Types::URI creates common L<Mouse> types,
coercions and option specifications useful for dealing
with L<URI>s as L<Mouse> attributes.

Coercions (see L<Mouse::Util::TypeConstraints>) are made from
C<Str>, C<ScalarRef>, C<HashRef>,
L<Path::Class::Dir> and L<Path::Class::File> to
L<URI>, L<URI::data> and L<URI::file> objects.

=head1 TYPES

=head2 Uri

=over 4

Either L<URI> or L<URI::WithBase>.

Coerces from C<Str> via L<URI/new>.

Coerces from L<Path::Class::File> and L<Path::Class::Dir> via L<URI::file/new>.

Coerces from C<ScalarRef> via L<URI::data/new>.

Coerces from C<HashRef> using L<URI::FromHash>.

=back

=head2 DataUri

=over 4

A URI whose scheme is C<data>.

Coerces from C<Str> and C<ScalarRef> via L<URI::data/new>.

=back

=head2 FileUri

=over 4

A L<URI::file> class type.

Coerces from C<Str>, L<Path::Class::File> and L<Path::Class::Dir> via L<URI::file/new>

=back

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 THANKS TO

Yuval Kogman, L<MooseX::Types::URI/AUTHOR>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Mouse>, L<MouseX::Types>,

L<URI>, L<URI::data>, L<URI::file>, L<URI::WithBase>, L<URI::FromHash>,

L<MooseX::Types::URI>

=cut
