package Pod::Readme::Types;

use v5.10.1;

use feature 'state';

use strict;
use warnings;

{
    use version 0.77;
    $Pod::Readme::Types::VERSION = version->declare('v1.1.2');
}

use Exporter qw/ import /;
use IO qw/ Handle /;
use Path::Tiny;
use Scalar::Util qw/ blessed /;
use Type::Tiny;
use Types::Standard qw/ FileHandle Str /;

our @EXPORT_OK =
  qw/ Dir File Indentation IO ReadIO WriteIO HeadingLevel TargetName DistZilla /;

=head1 NAME

Pod::Readme::Types - Types used by Pod::Readme

=head1 SYNOPSIS

  use Pod::Readme::Types qw/ Indentation /;

  has verbatim_indent => (
    is      => 'ro',
    isa     => Indentation,
    default => 2,
  );

=head1 DESCRIPTION

This module provides types for use with the modules in L<Pod::Readme>.

It is intended for internal use, although some of these may be useful
for writing plugins (see L<Pod::Readme::Plugin>).

=head1 EXPORTS

None by default. All functions must be explicitly exported.

=head2 C<Indentation>

The indentation level used for verbatim text. Must be an integer
greater than or equal to 2.

=cut

sub Indentation {
    state $type = Type::Tiny->new(
        name       => 'Indentation',
        constraint => sub { $_ =~ /^\d+$/ && $_ >= 2 },
        message => sub { 'must be an integer >= 2' },
    );
    return $type;
}

=head2 C<HeadingLevel>

A heading level, used for plugin headings.

Must be either 1, 2 or 3. (Note that C<=head4> is not allowed, since
some plugins use subheadings.)

=cut

sub HeadingLevel {
    state $type = Type::Tiny->new(
        name       => 'HeadingLevel',
        constraint => sub { $_ =~ /^[123]$/ },
        message    => sub { 'must be an integer between 1 and 3' },
    );
    return $type;
}

=head2 C<TargetName>

A name of a target, e.g. "readme".

=cut

sub TargetName {
    state $type = Type::Tiny->new(
        name       => 'TargetName',
        constraint => sub { $_ =~ /^\w+$/ },
        message    => sub { 'must be an alphanumeric string' },
    );
    return $type;
}

=head2 C<Dir>

A directory. Can be a string or L<Path::Tiny> object.

=cut

sub Dir {
    state $type = Type::Tiny->new(
        name       => 'Dir',
        constraint => sub {
            blessed($_)
              && $_->isa('Path::Tiny')
              && -d $_;
        },
        message => sub { "$_ must be be a directory" },
    );
    return $type->plus_coercions( Str, sub { path($_) }, );
}

=head2 C<File>

A file. Can be a string or L<Path::Tiny> object.

=cut

sub File {
    state $type = Type::Tiny->new(
        name       => 'File',
        constraint => sub {
            blessed($_)
              && $_->isa('Path::Tiny');
        },
        message => sub { "$_ must be be a file" },
    );
    return $type->plus_coercions( Str, sub { path($_) }, );
}

=head2 C<IO>

An L<IO::Handle> or L<IO::String> object.

=cut

sub IO {
    state $type = Type::Tiny->new(
        name       => 'IO',
        constraint => sub {
            blessed($_)
              && ( $_->isa('IO::Handle') || $_->isa('IO::String') );
        },
        message => sub { 'must be be an IO::Handle or IO::String' },
    );
    return $type;
}

=head2 C<ReadIO>

=head2 C<WriteIO>

L</IO> types, which coerce filehandles to read/write L<IO:Handles>,
respectively.

=cut

sub ReadIO {
    state $type = IO->plus_coercions(    #
        FileHandle, sub { IO::Handle->new_from_fd( $_, 'r' ) },
    );
    return $type;
}

sub WriteIO {
    state $type = IO->plus_coercions(    #
        FileHandle, sub { IO::Handle->new_from_fd( $_, 'w' ) },
    );
    return $type;
}

=head2 C<DistZilla>

A L<Dist::Zilla> object.

=cut

sub DistZilla {
    state $type = Type::Tiny->new(
        name       => 'DistZilla',
        constraint => sub {
            blessed($_)
              && $_->isa('Dist::Zilla');
        },
        message => sub { "$_ must be be a Dist::Zilla object" },
    );
    return $type;
}

1;
