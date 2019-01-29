use strict;
use warnings;
package Open::This;

our $VERSION = '0.000015';

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
    maybe_get_url_from_parsed_text
    editor_args_from_parsed_text
    parse_text
    to_editor_args
);

use Module::Runtime qw(
    is_module_name
    module_notional_filename
    require_module
);
use Path::Tiny qw( path );
use Try::Tiny qw( try );
use URI qw();

## no critic (Subroutines::ProhibitExplicitReturnUndef)

sub parse_text {
    my $text = join q{ }, @_;

    return undef if !$text;
    my $file_name;
    my %parsed = ( original_text => $text );

    $parsed{line_number} = _maybe_extract_line_number( \$text );
    $parsed{sub_name}    = _maybe_extract_subroutine_name( \$text );

    # Is this is an actual file.
    $parsed{file_name} = $text if -e path($text);

    $parsed{is_module_name} = is_module_name($text);

    if ( !$parsed{file_name} && $parsed{is_module_name} ) {
        $parsed{file_name} = _maybe_find_local_file($text);
    }

    # This is a loadable module.  Have this come after the local module checks
    # so that we don't default to installed modules.
    if ( !$parsed{file_name} && $parsed{is_module_name} ) {
        my $found = _module_to_filename($text);
        if ($found) {
            $parsed{file_name} = $found;
        }
    }

    if ( !$parsed{line_number} ) {
        $parsed{line_number} = _maybe_extract_line_number_via_sub_name(
            $parsed{file_name},
            $parsed{sub_name}
        );
    }

    my %return = map { $_ => $parsed{$_} }
        grep { defined $parsed{$_} && $parsed{$_} ne q{} } keys %parsed;

    return $return{file_name} ? \%return : undef;
}

sub maybe_get_url_from_parsed_text {
    require Git::Helpers;

    my $parsed = shift;
    return undef unless $parsed && $parsed->{file_name};

    my $url = Git::Helpers::https_remote_url();
    return undef unless $url && $url->can('host');
    $parsed->{remote_url} = $url;

    my $clone = $url->clone;
    my @parts = $clone->path_segments;
    push(
        @parts, 'blob', Git::Helpers::current_branch_name(),
        $parsed->{file_name}
    );
    $clone->path( join '/', @parts );
    if ( $parsed->{line_number} ) {
        $clone->fragment( 'L' . $parsed->{line_number} );
    }

    $parsed->{remote_file_url} = $clone;
    return $clone;
}

sub _module_to_filename {
    my $name = shift;
    return undef unless ( defined $name && is_module_name($name) );
    try { require_module($name) };

    my $notional = module_notional_filename($name);

    return exists $INC{$notional} ? $INC{$notional} : undef;
}

sub to_editor_args {
    return editor_args_from_parsed_text( parse_text(@_) );
}

sub editor_args_from_parsed_text {
    my $parsed = shift;
    return unless $parsed;

    return (
        ( $parsed->{line_number} ? '+' . $parsed->{line_number} : () ),
        $parsed->{file_name}
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
    if ( $$text =~ s{(\w):(\d+)\b}{$1} ) {
        return $2;
    }

    # Github links: foo/bar.go#L100
    if ( $$text =~ s{(\w)#L(\d+)\b}{$1} ) {
        return $2;
    }

    # git-grep contextual match
    # lib/Open/This.pm-17-
    if ( $$text =~ s{(\w)-(\d+)\-{0,1}}{$1} ) {
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

sub _maybe_extract_line_number_via_sub_name {
    my $file_name = shift;
    my $sub_name  = shift;

    if ( $file_name && $sub_name && open( my $fh, '<', $file_name ) ) {
        my $line_number = 1;
        while ( my $line = <$fh> ) {
            if ( $line =~ m{sub $sub_name\b} ) {
                return $line_number;
            }
            ++$line_number;
        }
    }
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

version 0.000015

=head1 DESCRIPTION

This module powers the L<ot> command line script, which tries to do the right
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

Copy/pasting a partial GitHub URL.

    ot lib/Foo/Bar.pm#L100 # vim +100 Foo/Bar.pm

Open a local file on the GitHub web site in your web browser.  From within a
checked out copy of https://github.com/oalders/open-this

    ot -b Foo::Bar

Open a local file at the correct line on the GitHub web site in your web
browser.  From within a checked out copy of
https://github.com/oalders/open-this:

    ot -b Open::This line 50
    # https://github.com/oalders/open-this/blob/master/lib/Open/This.pm#L50

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
    #     file_name     => 't/lib/Foo/Bar.pm',
    #     line_number   => 3,
    #     original_text => 't/lib/Foo/Bar.pm:32',
    #     sub_name      => 'do_something',
    # };

=head2 to_editor_args

Given a scalar value, this calls C<parse_text()> and returns an array of values
which can be passed at the command line to an editor.

    my @args = to_editor_args('Foo::Bar::do_something()');
    # @args = ( '+3', 't/lib/Foo/Bar.pm' );

=head2 editor_args_from_parsed_text

If you have a C<hashref> from the C<parse_text> function, you can get editor
args via this function.  (The faster way is just to call C<to_editor_args>
directly.)

    my @args
        = editor_args_from_parsed_text( parse_text('t/lib/Foo/Bar.pm:32') );

=head2 maybe_get_url_from_parsed_text

Tries to return an URL to a Git repository for a checked out file.  The URL
will be built using the C<origin> remote and the name of the current branch.  A
line number will be attached if it can be parsed from the text.  This has only
currently be tested with GitHub URLs and it assumes you're working on a branch
which has already been pushed to your remote.

    my $url = maybe_get_url_from_parsed_text( parse_text('t/lib/Foo/Bar.pm:32'));
    # $url might be something like: https://github.com/oalders/open-this/blob/master/lib/Open/This.pm#L32

=head1 ENVIRONMENT VARIABLES

By default, C<ot> will search your C<lib> and C<t/lib> directories for local
files.  You can override this via the C<$ENV{OPEN_THIS_LIBS}> variable.  It
accepts a comma-separated list of libs.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
