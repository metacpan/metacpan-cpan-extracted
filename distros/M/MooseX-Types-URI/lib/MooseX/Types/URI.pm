use strict;
use warnings;
package MooseX::Types::URI; # git description: v0.09-3-ge61243d
# ABSTRACT: URI related types and coercions for Moose
# KEYWORDS: moose types constraints coercions uri path web

our $VERSION = '0.10';

use Scalar::Util qw(blessed);

use URI;
use URI::QueryParam;
use URI::WithBase;

use MooseX::Types::Moose qw{Str ScalarRef HashRef};

use MooseX::Types 0.40 -declare => [qw(Uri _UriWithBase _Uri FileUri DataUri)];
use if MooseX::Types->VERSION >= 0.42, 'namespace::autoclean';

my $uri = Moose::Meta::TypeConstraint->new(
    name   => Uri,
    parent => Moose::Meta::TypeConstraint::Union->new(
        name => join("|", _Uri, _UriWithBase),
        type_constraints => [
            class_type( _Uri,         { class => "URI" } ),
            class_type( _UriWithBase, { class => "URI::WithBase" } ),
        ],
    ),
    inline_as => sub { 'local $@; blessed('.$_[1].') && ( '.$_[1].'->isa("URI") || '.$_[1].'->isa("URI::WithBase") )' },
);

register_type_constraint($uri);

coerce( Uri,
    from Str                 , via { URI->new($_) },
    eval { +require MooseX::Types::Path::Class; 1 }
      ? (
        from "Path::Class::File", via { require URI::file; URI::file::->new($_) },
        from "Path::Class::Dir" , via { require URI::file; URI::file::->new($_) },
        from MooseX::Types::Path::Class::File() , via { require URI::file; URI::file::->new($_) },
        from MooseX::Types::Path::Class::Dir()  , via { require URI::file; URI::file::->new($_) },
      ) : (),
    from ScalarRef           , via { my $u = URI->new("data:"); $u->data($$_); $u },
    from HashRef             , via { require URI::FromHash; URI::FromHash::uri_object(%$_) },
);

class_type FileUri, { class => "URI::file", parent => $uri };

coerce( FileUri,
    from Str                 , via { require URI::file; URI::file::->new($_) },
    eval { +require MooseX::Types::Path::Class; 1 }
      ? (
        from MooseX::Types::Path::Class::File() , via { require URI::file; URI::file::->new($_) },
        from MooseX::Types::Path::Class::Dir()  , via { require URI::file; URI::file::->new($_) },
        from "Path::Class::File" , via { require URI::file; URI::file::->new($_) },
        from "Path::Class::Dir"  , via { require URI::file; URI::file::->new($_) },
      ) : (),
);

class_type DataUri, { class => "URI::data" };

coerce( DataUri,
    from Str       , via { my $u = URI->new("data:"); $u->data($_);  $u },
    from ScalarRef , via { my $u = URI->new("data:"); $u->data($$_); $u },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Types::URI - URI related types and coercions for Moose

=head1 VERSION

version 0.10

=head1 SYNOPSIS

	use MooseX::Types::URI qw(Uri FileUri DataUri);

=head1 DESCRIPTION

This package provides Moose types for fun with L<URI>s.

=head1 TYPES

The types are with C<ucfirst> naming convention so that they don't mask the
L<URI> class.

=head2 C<Uri>

Either L<URI> or L<URI::WithBase>

Coerces from C<Str> via L<URI/new>.

Coerces from L<Path::Class::File> and L<Path::Class::Dir> via L<URI::file/new> (but only if
L<MooseX::Types::Path::Class> is installed)

Coerces from C<ScalarRef> via L<URI::data/new>.

Coerces from C<HashRef> using L<URI::FromHash>.

=head2 C<DataUri>

A URI whose scheme is C<data>.

Coerces from C<Str> and C<ScalarRef> via L<URI::data/new>.

=head2 C<FileUri>

A L<URI::file> class type.

Has coercions from C<Str> (and optionally L<Path::Class::File> and L<Path::Class::Dir>) via L<URI::file/new>

=for stopwords DWIMier ducktyping

It has slightly DWIMier types than the L<URI> classes have due to
implementation details, so the types should be more forgiving when ducktyping
will work anyway (e.g. L<URI::WithBase> does not inherit L<URI>).

=for stopwords TODO

=head1 TODO

Think about L<Path::Resource> integration of some sort

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Types-URI>
(or L<bug-MooseX-Types-URI@rt.cpan.org|mailto:bug-MooseX-Types-URI@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Florian Ragwitz Olivier Mengué Daniel Pittman MORIYA Masaki (gardejo) Shawn M Moore

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Olivier Mengué <dolmen@cpan.org>

=item *

Daniel Pittman <daniel@rimspace.net>

=item *

MORIYA Masaki (gardejo) <moriya@ermitejo.com>

=item *

Shawn M Moore <sartak@gmail.com>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2008 by יובל קוג'מן (Yuval Kogman).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
