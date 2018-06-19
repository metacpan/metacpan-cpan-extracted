use strict;
use warnings;
package Open::This;

our $VERSION = '0.000008';

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(parse_text to_editor_args);

use Module::Runtime
    qw( is_module_name module_notional_filename require_module );
use Path::Tiny qw( path );
use Try::Tiny qw( try );

## no critic (Subroutines::ProhibitExplicitReturnUndef)

sub parse_text {
    my $text = join q{ }, @_;

    return undef if !$text;
    my $file_name;
    my $orig;

    my $line_number = _maybe_extract_line_number( \$text );

    # Is this is an actual file.
    $file_name = $text if -e path($text);

    my $sub_name       = _maybe_extract_subroutine_name( \$text );
    my $is_module_name = is_module_name($text);

    if ( !$file_name && $is_module_name ) {
        $file_name = _maybe_find_local_file($text);
    }

    # This is a loadable module.  Have this come after the local module checks
    # so that we don't default to installed modules.
    if ( !$file_name && $is_module_name ) {
        my $found = _module_to_filename($text);
        if ($found) {
            $file_name = $found;
        }
    }

    if ( $file_name && $sub_name && $^O ne 'MSWin32' ) {
        my $grep = `grep -n "sub $sub_name" $file_name`;
        my @results = split m{:}, $grep;
        $line_number = shift @results;
    }

    return $file_name
        ? {
        file_name => $file_name,
        $line_number ? ( line_number => $line_number ) : (),
        $sub_name    ? ( sub_name    => $sub_name )    : (),
        }
        : undef;
}

sub _module_to_filename {
    my $name = shift;
    return undef unless is_module_name($name);
    try { require_module($name) };

    my $notional = module_notional_filename($name);

    return exists $INC{$notional} ? $INC{$notional} : undef;
}

sub to_editor_args {
    my $text = join q{ }, @_;
    return unless $text;

    my $found = parse_text($text);

    # Maybe this file is just being created
    return unless $found;

    return (
        ( $found->{line_number} ? '+' . $found->{line_number} : () ),
        $found->{file_name}
    );
}

sub _maybe_extract_line_number {
    my $text = shift;    # scalar ref

    # Find a line number
    #  lib/Foo/Bar.pm line 222.

    if ( $$text =~ s{ line (\d+).*}{} ) {
        return $1;
    }

    # git-grep (don't match on ::)
    # lib/Open/This.pm:17
    if ( $$text =~ s{(\w):(\d*)\b}{$1} ) {
        return $2;
    }

    # git-grep contextual match
    # lib/Open/This.pm-17-
    if ( $$text =~ s{(\w)-(\d*)-}{$1} ) {
        return $2;
    }
    return undef;
}

sub _maybe_extract_subroutine_name {
    my $text = shift;    # scalar ref

    if ( $$text =~ s{::(\w+)\(.*\)}{} ) {
        return $1;
    }
    return undef;
}

sub _maybe_find_local_file {
    my $text          = shift;
    my $possible_name = module_notional_filename($text);
    my @dirs
        = exists $ENV{OPEN_THIS_LIBS}
        ? split m{,}, $ENV{OPEN_THIS_LIBS}
        : ( 'lib', 't/lib' );

    for my $dir (@dirs) {
        my $path = path( $dir, $possible_name );
        if ( $path->is_file ) {
            return "$path";
        }
    }
    return undef;
}

# ABSTRACT: Try to Do the Right Thing when opening files
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Open::This - Try to Do the Right Thing when opening files

=head1 VERSION

version 0.000008

=head1 DESCRIPTION

This module powers the C<ot> command line script, which tries to do the right
thing when opening a file.  Imagine your C<$ENV{EDITOR}> is set to C<vim>.
(This should also work for C<emacs> and C<nano>.)  The following examples
demonstrate how your input is translated when launching your editor.

    ot Foo::Bar # vim lib/Foo/Bar.pm
    ot Foo::Bar # vim t/lib/Foo/Bar.pm

Imagine this module has a C<sub do_something> at line 55.

    ot "Foo::Bar::do_something()" # vim +55 lib/Foo/Bar.pm

Or, when copy/pasting from a stack trace.  (Note that you do not need quotes in
this case.)

    ot Foo::Bar line 36 # vim +36 lib/Foo/Bar.pm

Copy/pasting a C<git-grep> result.

    ot lib/Foo/Bar.pm:99 # vim +99 Foo/Bar.pm

=head1 FUNCTIONS

=head2 parse_text

Given a scalar value or an array of scalars, this function will try to extract
useful information from it.  Returns a hashref on success.  Returns undef on
failure.  C<file_name> is the only hash key which is guaranteed to be in the
hash.

    use Open::This qw( parse_text );
    my $parsed = parse_text('t/lib/Foo/Bar.pm:32');

    # $parsed = { file_name => 't/lib/Foo/Bar.pm', line_number => 32, }

    my $with_sub_name = parse_text( 'Foo::Bar::do_something()' );

    # $with_sub_name = {
    #     file_name   => 't/lib/Foo/Bar.pm',
    #     line_number => 3,
    #     sub_name    => 'do_something',
    # };

=head2 to_editor_args

Given a scalar value, this calls C<parse_text()> and returns an array of values
which can be passed at the command line to an editor.

    my @args = to_editor_args('Foo::Bar::do_something()');
    # @args = ( '+3', 't/lib/Foo/Bar.pm' );

=head1 ENVIRONMENT VARIABLES

By default, C<ot> will search your C<lib> and C<t/lib> directories for local files.  You can override this via the C<$ENV{OPEN_THIS_LIBS}> variable.  It accepts a comma-separated list of libs.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
