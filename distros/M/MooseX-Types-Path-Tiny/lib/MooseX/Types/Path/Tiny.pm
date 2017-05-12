use strict;
use warnings;
package MooseX::Types::Path::Tiny; # git description: v0.011-21-g8796f45
# ABSTRACT: Path::Tiny types and coercions for Moose
# KEYWORDS: moose type constraint path filename directory
# vim: set ts=8 sts=4 sw=4 tw=115 et :

our $VERSION = '0.012';

use Moose 2;
use MooseX::Types::Stringlike qw/Stringable/;
use MooseX::Types::Moose qw/Str ArrayRef/;
use MooseX::Types -declare => [qw/
    Path AbsPath
    File AbsFile
    Dir AbsDir
    Paths AbsPaths
/];
use Path::Tiny ();
use if MooseX::Types->VERSION >= 0.42, 'namespace::autoclean';

#<<<
subtype Path,    as 'Path::Tiny';
subtype AbsPath, as Path, where { $_->is_absolute };

subtype File,    as Path, where { $_->is_file }, message { "File '$_' does not exist" };
subtype Dir,     as Path, where { $_->is_dir },  message { "Directory '$_' does not exist" };

subtype AbsFile, as AbsPath, where { $_->is_file }, message { "File '$_' does not exist" };
subtype AbsDir,  as AbsPath, where { $_->is_dir },  message { "Directory '$_' does not exist" };

subtype Paths,   as ArrayRef[Path];
subtype AbsPaths, as ArrayRef[AbsPath];
#>>>

for my $type ( 'Path::Tiny', Path, File, Dir ) {
    coerce(
        $type,
        from Str()        => via { Path::Tiny::path($_) },
        from Stringable() => via { Path::Tiny::path($_) },
        from ArrayRef()   => via { Path::Tiny::path(@$_) },
    );
}

for my $type ( AbsPath, AbsFile, AbsDir ) {
    coerce(
        $type,
        from 'Path::Tiny' => via { $_->absolute },
        from Str()        => via { Path::Tiny::path($_)->absolute },
        from Stringable() => via { Path::Tiny::path($_)->absolute },
        from ArrayRef()   => via { Path::Tiny::path(@$_)->absolute },
    );
}

coerce(
    Paths,
    from Path()       => via { [ $_ ] },
    from Str()        => via { [ Path::Tiny::path($_) ] },
    from Stringable() => via { [ Path::Tiny::path($_) ] },
    from ArrayRef()   => via { [ map { Path::Tiny::path($_) } @$_ ] },
);

coerce(
    AbsPaths,
    from AbsPath()    => via { [ $_ ] },
    from Str()        => via { [ Path::Tiny::path($_)->absolute ] },
    from Stringable() => via { [ Path::Tiny::path($_)->absolute ] },
    from ArrayRef()   => via { [ map { Path::Tiny::path($_)->absolute } @$_ ] },
);


# optionally add Getopt option type (adapted from MooseX::Types:Path::Class)
if (eval { require MooseX::Getopt; 1 }) {
    for my $type (
        'Path::Tiny',
        Path ,
        AbsPath,
        File ,
        AbsFile,
        Dir ,
        AbsDir,
        Paths ,
        AbsPaths,
    ) {
        MooseX::Getopt::OptionTypeMap->add_option_type_to_map( $type, '=s', );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Types::Path::Tiny - Path::Tiny types and coercions for Moose

=head1 VERSION

version 0.012

=head1 SYNOPSIS

  ### specification of type constraint with coercion

  package Foo;

  use Moose;
  use MooseX::Types::Path::Tiny qw/Path Paths AbsPath/;

  has filename => (
    is => 'ro',
    isa => Path,
    coerce => 1,
  );

  has directory => (
    is => 'ro',
    isa => AbsPath,
    coerce => 1,
  );

  has filenames => (
    is => 'ro',
    isa => Paths,
    coerce => 1,
  );

  ### usage in code

  Foo->new( filename => 'foo.txt' ); # coerced to Path::Tiny
  Foo->new( directory => '.' ); # coerced to path('.')->absolute
  Foo->new( filenames => [qw/bar.txt baz.txt/] ); # coerced to ArrayRef[Path::Tiny]

=head1 DESCRIPTION

This module provides L<Path::Tiny> types for L<Moose>.  It handles
two important types of coercion:

=over 4

=item *

coercing objects with overloaded stringification

=item *

coercing to absolute paths

=back

It also can check to ensure that files or directories exist.

=for stopwords coercions

=head1 SUBTYPES

=for stopwords SUBTYPES subtype subtypes

This module uses L<MooseX::Types> to define the following subtypes.

=for stopwords AbsPath AbsFile AbsDir

=head2 Path

C<Path> ensures an attribute is a L<Path::Tiny> object.  Strings and
objects with overloaded stringification may be coerced.

=head2 AbsPath

C<AbsPath> is a subtype of C<Path> (above), but coerces to an absolute path.

=head2 File, AbsFile

These are just like C<Path> and C<AbsPath>, except they check C<-f> to ensure
the file actually exists on the filesystem.

=head2 Dir, AbsDir

These are just like C<Path> and C<AbsPath>, except they check C<-d> to ensure
the directory actually exists on the filesystem.

=head2 Paths, AbsPaths

These are arrayrefs of C<Path> and C<AbsPath>, and include coercions from
arrayrefs of strings.

=head1 CAVEATS

=head2 Path vs File vs Dir

C<Path> just ensures you have a L<Path::Tiny> object.

C<File> and C<Dir> check the filesystem.  Don't use them unless that's really
what you want.

=head2 Usage with File::Temp

Be careful if you pass in a L<File::Temp> object. Because the argument is
stringified during coercion into a L<Path::Tiny> object, no reference to the
original L<File::Temp> argument is held.  Be sure to hold an external reference to
it to avoid immediate cleanup of the temporary file or directory at the end of
the enclosing scope.

A better approach is to use L<Path::Tiny>'s own C<tempfile> or C<tempdir>
constructors, which hold the reference for you.

    Foo->new( filename => Path::Tiny->tempfile );

=head1 SEE ALSO

=over 4

=item *

L<Path::Tiny>

=item *

L<Moose::Manual::Types>

=item *

L<Types::Path::Tiny>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Types-Path-Tiny>
(or L<bug-MooseX-Types-Path-Tiny@rt.cpan.org|mailto:bug-MooseX-Types-Path-Tiny@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Toby Inkster Demian Riccardi Gregory Oschwald

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Toby Inkster <mail@tobyinkster.co.uk>

=item *

Demian Riccardi <dde@ornl.gov>

=item *

Gregory Oschwald <goschwald@maxmind.com>

=back

=head1 COPYRIGHT AND LICENCE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
