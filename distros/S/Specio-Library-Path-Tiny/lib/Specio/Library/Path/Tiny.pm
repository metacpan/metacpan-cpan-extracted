## no critic (Modules::ProhibitExcessMainComplexity)
package Specio::Library::Path::Tiny;

use strict;
use warnings;

our $VERSION = '0.04';

use overload ();
use Path::Tiny 0.087;
use Scalar::Util qw( blessed );
use Specio 0.29 ();
use Specio::Declare;
use Specio::Library::Builtins;
use Specio::PartialDump qw( partial_dump );

use parent 'Specio::Exporter';

my $not_blessed = sub {
    return blessed $_[0] ? q{} : "$_[1] is not an object";
};

my $not_path_tiny = sub {
    return $_[0]->isa('Path::Tiny')
        ? q{}
        : "$_[1] is not a Path::Tiny object";
};

my $not_absolute = sub {
    return $_[0]->is_absolute ? q{} : "$_[0] is not an absolute path";
};

my $not_real = sub {
    return $_[0]->realpath eq $_[0] ? q{} : "$_[0] is not a real path";
};

my $not_file = sub {
    return $_[0]->is_file ? q{} : "$_[0] is not a file on disk";
};

my $not_dir = sub {
    return $_[0]->is_dir ? q{} : "$_[0] is not a directory on disk";
};

declare(
    'Path',
    parent            => object_isa_type('Path::Tiny'),
    message_generator => sub {
        my $dump = partial_dump( $_[1] );
        return $not_blessed->( $_[1], $dump )
            || $not_path_tiny->( $_[1], $dump );
    },
);

declare(
    'AbsPath',
    parent => t('Path'),
    inline => sub {
        return sprintf(
            '( %s && %s->is_absolute )',
            $_[0]->parent->inline_check( $_[1] ),
            $_[1]
        );
    },
    message_generator => sub {
        my $dump = partial_dump( $_[1] );
        return
               $not_blessed->( $_[1], $dump )
            || $not_path_tiny->( $_[1], $dump )
            || $not_absolute->( $_[1], $dump );
    },
);

declare(
    'RealPath',
    parent => t('Path'),
    inline => sub {
        return sprintf(
            '( %s && %s->realpath eq %s )',
            $_[0]->parent->inline_check( $_[1] ),
            $_[1], $_[1]
        );
    },
    message_generator => sub {
        my $dump = partial_dump( $_[1] );
        return
               $not_blessed->( $_[1], $dump )
            || $not_path_tiny->( $_[1], $dump )
            || $not_real->( $_[1], $dump );
    },
);

declare(
    'File',
    parent => t('Path'),
    inline => sub {
        return sprintf(
            '( %s && %s->is_file )',
            $_[0]->parent->inline_check( $_[1] ),
            $_[1]
        );
    },
    message_generator => sub {
        my $dump = partial_dump( $_[1] );
        return
               $not_blessed->( $_[1], $dump )
            || $not_path_tiny->( $_[1], $dump )
            || $not_file->( $_[1], $dump );
    },
);

declare(
    'AbsFile',
    parent => t('Path'),
    inline => sub {
        return sprintf(
            '( %s && %s->is_file && %s->is_absolute )',
            $_[0]->parent->inline_check( $_[1] ),
            $_[1], $_[1]
        );
    },
    message_generator => sub {
        my $dump = partial_dump( $_[1] );
        return
               $not_blessed->( $_[1], $dump )
            || $not_path_tiny->( $_[1], $dump )
            || $not_file->( $_[1], $dump )
            || $not_absolute->( $_[1], $dump );
    },
);

declare(
    'RealFile',
    parent => t('Path'),
    inline => sub {
        return sprintf(
            '( %s && %s->is_file && %s->realpath eq %s )',
            $_[0]->parent->inline_check( $_[1] ),
            $_[1], $_[1], $_[1]
        );
    },
    message_generator => sub {
        my $dump = partial_dump( $_[1] );
        return
               $not_blessed->( $_[1], $dump )
            || $not_path_tiny->( $_[1], $dump )
            || $not_file->( $_[1], $dump )
            || $not_real->( $_[1], $dump );
    },
);

declare(
    'Dir',
    parent => t('Path'),
    inline => sub {
        return sprintf(
            '( %s && %s->is_dir )',
            $_[0]->parent->inline_check( $_[1] ),
            $_[1]
        );
    },
    message_generator => sub {
        my $dump = partial_dump( $_[1] );
        return
               $not_blessed->( $_[1], $dump )
            || $not_path_tiny->( $_[1], $dump )
            || $not_dir->( $_[1], $dump );
    },
);

declare(
    'AbsDir',
    parent => t('Path'),
    inline => sub {
        return sprintf(
            '( %s && %s->is_dir && %s->is_absolute )',
            $_[0]->parent->inline_check( $_[1] ),
            $_[1], $_[1],
        );
    },
    message_generator => sub {
        my $dump = partial_dump( $_[1] );
        return
               $not_blessed->( $_[1], $dump )
            || $not_path_tiny->( $_[1], $dump )
            || $not_dir->( $_[1], $dump )
            || $not_absolute->( $_[1], $dump );
    },
);

declare(
    'RealDir',
    parent => t('Path'),
    inline => sub {
        return sprintf(
            '( %s && %s->is_dir && %s->realpath eq %s )',
            $_[0]->parent->inline_check( $_[1] ),
            $_[1], $_[1], $_[1]
        );
    },
    message_generator => sub {
        my $dump = partial_dump( $_[1] );
        return
               $not_blessed->( $_[1], $dump )
            || $not_path_tiny->( $_[1], $dump )
            || $not_dir->( $_[1], $dump )
            || $not_real->( $_[1], $dump );
    },
);

for my $type ( map { t($_) } qw( Path File Dir ) ) {
    coerce(
        $type,
        from   => t('Str'),
        inline => sub {"Path::Tiny::path( $_[1] )"},
    );

    coerce(
        $type,
        from   => t('ArrayRef'),
        inline => sub {"Path::Tiny::path( \@{ $_[1] } )"},
    );
}

for my $type ( map { t($_) } qw( AbsPath AbsFile AbsDir ) ) {
    coerce(
        $type,
        from   => t('Path'),
        inline => sub { sprintf( '%s->absolute', $_[1] ) },
    );

    coerce(
        $type,
        from => t('Str'),
        inline =>
            sub { sprintf( 'Path::Tiny::path( %s )->absolute', $_[1] ) },
    );

    coerce(
        $type,
        from => t('ArrayRef'),
        inline =>
            sub { sprintf( 'Path::Tiny::path( @{ %s } )->absolute', $_[1] ) },
    );
}

for my $type ( map { t($_) } qw( RealPath RealFile RealDir ) ) {
    coerce(
        $type,
        from   => t('Path'),
        inline => sub { sprintf( '%s->realpath', $_[1] ) },
    );

    coerce(
        $type,
        from => t('Str'),
        inline =>
            sub { sprintf( 'Path::Tiny::path( %s )->realpath', $_[1] ) },
    );

    coerce(
        $type,
        from => t('ArrayRef'),
        inline =>
            sub { sprintf( 'Path::Tiny::path( @{ %s } )->realpath', $_[1] ) },
    );
}

1;

# ABSTRACT: Path::Tiny types and coercions for Specio

__END__

=pod

=encoding UTF-8

=head1 NAME

Specio::Library::Path::Tiny - Path::Tiny types and coercions for Specio

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  use Specio::Library::Path::Tiny;

  has path => ( isa => t('Path') );

=head1 DESCRIPTION

This library provides a set of L<Path::Tiny> types and coercions for
L<Specio>. These types can be used with L<Moose>, L<Moo>,
L<Params::ValidationCompiler>, and other modules.

=head1 TYPES

This library provides the following types:

=head2 Path

A L<Path::Tiny> object.

Will be coerced from a string or arrayref via C<Path::Tiny::path>.

=head2 AbsPath

A L<Path::Tiny> object where C<< $path->is_absolute >> returns true.

Will be coerced from a string or arrayref via C<Path::Tiny::path> followed by
call to C<< $path->absolute >>.

=head2 RealPath

A L<Path::Tiny> object where C<< $path->realpath eq $path >>.

Will be coerced from a string or arrayref via C<Path::Tiny::path> followed by
call to C<< $path->realpath >>.

=head2 File

A L<Path::Tiny> object which is a file on disk according to C<< $path->is_file
>>.

Will be coerced from a string or arrayref via C<Path::Tiny::path>.

=head2 AbsFile

A L<Path::Tiny> object which is a file on disk according to C<< $path->is_file
>> where C<< $path->is_absolute >> returns true.

Will be coerced from a string or arrayref via C<Path::Tiny::path> followed by
call to C<< $path->absolute >>.

=head2 RealFile

A L<Path::Tiny> object which is a file on disk according to C<< $path->is_file
>> where C<< $path->realpath eq $path >>.

Will be coerced from a string or arrayref via C<Path::Tiny::path> followed by
call to C<< $path->realpath >>.

=head2 Dir

A L<Path::Tiny> object which is a directory on disk according to C<<
$path->is_dir >>.

Will be coerced from a string or arrayref via C<Path::Tiny::path>.

=head2 AbsDir

A L<Path::Tiny> object which is a directory on disk according to C<<
$path->is_dir >> where C<< $path->is_absolute >> returns true.

Will be coerced from a string or arrayref via C<Path::Tiny::path> followed by
call to C<< $path->absolute >>.

=head2 RealDir

A L<Path::Tiny> object which is a directory on disk according to C<<
$path->is_dir >> where C<< $path->realpath eq $path >>.

Will be coerced from a string or arrayref via C<Path::Tiny::path> followed by
call to C<< $path->realpath >>.

=head1 CREDITS

The vast majority of the code in this distribution comes from David Golden's
L<Types::Path::Tiny> distribution.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|http://rt.cpan.org/Public/Dist/Display.html?Name=Specio-Library-Path-Tiny>
(or L<bug-specio-library-path-tiny@rt.cpan.org|mailto:bug-specio-library-path-tiny@rt.cpan.org>).

I am also usually active on IRC as 'drolsky' on C<irc://irc.perl.org>.

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

This software is Copyright (c) 2016 by Dave Rolsky.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
