package Path::Tiny::Glob;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: File globbing utility
$Path::Tiny::Glob::VERSION = '0.2.0';

use strict;
use warnings;

use Path::Tiny;

use Path::Tiny::Glob::Visitor;

use parent 'Exporter::Tiny';

our @EXPORT = qw/ pathglob /;
our @EXPORT_OK = qw/ is_globby /;

use experimental qw/ signatures postderef /;

sub _generate_pathglob {
    my( $class, undef, $args ) = @_;

    return sub(@) { return _pathglob(@_)->all }
        if $args && $args->{all};

    return \&_pathglob;
}

sub _pathglob( $glob ) {

    my @glob = ref $glob eq 'ARRAY' ? @$glob : ($glob);

    @glob = map {
        ref ? $_ : split '/', $_, -1;
    } @glob;

    my $dir;

    if ( $glob[0] =~ /^~/ ) {
        $dir = path(shift @glob);
    }
    elsif( $glob[0] eq '' ) {
        $dir = Path::Tiny->rootdir;
        shift @glob;
    }
    else {
        $dir = path('.');
    }

    unless( ref $glob[-1] ) {

    }

    return Path::Tiny::Glob::Visitor->new(
        path => $dir,
        globs => [ \@glob ],
    )->as_list;
}

sub is_globby($string) {
    return $string =~ /[?*]/;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Tiny::Glob - File globbing utility

=head1 VERSION

version 0.2.0

=head1 SYNOPSIS

    use Path::Tiny::Glob;

    my $dzil_files = pathglob( '~/work/perl-modules/**/dist.ini' );

    while( my $file = $dzil_files->next ) {
        say "found a Dist::Zilla project at ", $file->parent;
    }

=head1 DESCRIPTION

This module exports a single function by default, C<pathglob>.

=head1 EXPORTED FUNCTIONS

=head2 C<pathglob>

    $list = pathglob( $glob );
    $list = pathglob( \@path_segments );

This function takes in
a shell-like file glob, and returns a L<Lazy::List> of L<Path::Tiny> objects
matching it.

If you prefer to get all the globbed files in one go instead of
L<Lazy::List>ed, you can import C<pathglob> with the flag C<all>:

    use Path::Tiny::Glob pathglob => { all => 1 };

    # now behaves like pathglob( '/foo/**' )->all;
    my @files = pathglob( '/foo/**' );

The function can also take an arrayref of path segments.
The segments can be strings, in which case they are obeying
the same globbing patterns as the stringy C<$glob>.

    $list = pathglob( [ 'foo', 'bar', '*', 'README.md' ] );

    # equivalent to

    $list = pathglob( 'foo/bar/*/README.md' );

The segments, however, can also be coderefs, which will
be passed  L<Path::Tiny> objects both as their argument and
as C<$_>, and are expected to return C<true> if the path
is matching.

    $big_files = pathglob( [ 'foo/bar/**/', sub { -f $_ and -s $_ > 1E6 } );

The segments can also be regexes, in which case they will be
compared to the paths' current C<basename>.

    @readmes = pathglob( [ 'foo/bar/**/', /^readme\.(md|mkd|txt)$/i );

Known limitation: backtracking paths using C<..> doesn't work.

=head3 Supported globbing patterns

=over

=item C<*>

Matches zero or more characters.

=item C<?>

Matches zero or one character.

=item C<**>

Matches zero or more directories.

If C<**> is the last segment of the path, it'll return
all descendent files.

=back

=head2 C<is_globby>

    my $globby = is_globby( './foo/*/bar' );

Returns C<true> if the argument contains any glob character (so C<?> or C<*>).
Can be useful to determine if the input was an explicit path or a glob.

Not exported by default.

=head1 SEE ALSO

L<File::Wildcard>

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
