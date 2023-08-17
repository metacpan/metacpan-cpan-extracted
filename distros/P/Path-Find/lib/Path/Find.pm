package Path::Find;

use 5.00405;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw();

$VERSION = '0.02';

use Carp;
use File::Spec;
use IO::Dir;
use Scalar::Util qw( blessed );
use Text::Glob qw( glob_to_regex );

use Exporter qw( import );
our @EXPORT = qw( path_find );
our @EXPORT_OK = qw( path_find matchable );

sub path_find
{
    my( $dir, $dirglob, $fileglob ) = @_;
    if( 2==@_ ) {
        $fileglob = $dirglob;
        $dirglob = "*";
    }

    __path_find( $dir, matchable( $dirglob ), matchable( $fileglob ), 0 );
}

sub __path_find
{
    my( $dir, $dirmatch, $filematch, $depth ) = @_;

    my @ret;

    my $dh = IO::Dir->new( $dir ); 
    $dh or return;
    my $entry;
    while( defined( $entry = $dh->read ) ) {
        next if $entry eq '.' or $entry eq '..';
        my $full = File::Spec->catfile( $dir, $entry );
        if( -d $full ) {
            push @ret, __path_find( $full, $dirmatch, $filematch, $depth+1 ) if $dirmatch->( $entry, $dir, $full, $depth );
        }
        elsif( $filematch->( $entry, $dir, $full, $depth ) ) {
            push @ret, $full;
        }
    }
    return @ret;
}

# Turn a glob into a coderef
sub matchable
{
    my( $glob ) = @_;
    $glob = '*' unless defined $glob;
    return $glob if 'CODE' eq ref $glob;
    return sub { $_[0] =~ $glob } if 'Regexp' eq ref $glob;
    if( blessed $glob ) {
        confess ref( $glob ), " object doesn't have method 'match'" unless $glob->can( 'match' );
        return sub { $glob->match( @_ ) };
    }
    confess "Can't convert $glob into a matchable" if ref $glob;
    $glob = '*' unless defined $glob;
    my $re = glob_to_regex( $glob );
    # warn "glob=$glob re=$re";
    return sub { $_[0] =~ $re };
}

1;

__END__

=head1 NAME

Path::Find - Easily find files in a directory tree

=head1 SYNOPSIS

    use Path::Find;

    # Recursively find all PNG files
    my @list = path_find( $dir, "*.png" );

    # Find all the jpegs, ignoring case
    @list = path_find( $dir, qr/\.jpe?g$/i );

    # Find all .cnf files in .directories
    @list = path_find( $dir, qr(/^\./), qr/\.cnf$/ );

=head1 DESCRIPTION

Path::Find is the simplest way to recursively list all the files in a
directory and its subdirectories.

=head1 FUNCTIONS


=head2 path_find

    @list = find_path( $dir );
    @list = find_path( $dir, $fileglob );
    @list = find_path( $dir, $dirglob, $fileglob );

Recurses $dir and all subdirectories that match C<$dirglob>, returning a
list of all files that match C<$filegob>.

=over 4

=item $dir

Top directory to search.

=item $fileglob

Glob or other thing to select which files are returned.  Passed to
L</matchable>.  Defaults to C<*>.

=item $dirglob

Glob or other thing to select which subdirectories are recursed.  Passed to
L</matchable>.  Defaults to C<*>.

=back

Returns the list of files, with C<$dir> prepended.

The globs (C<$fileglob> and C<$dirglob> maybe a string containing a BSD-style glob:
    
    @list = path_find( "/some-dir", "*.png" );

They may be a regex:

    @list = path_find( "/other-dir", qr(\.png$) );

They may be a coderef:

    @list = path_find( $TOP, sub { $DIRS{$_[0]} }, sub { 1 } );

They may be an object:

    my $dirmatch = My::DirMatch->new;
    my $filematch = My::FileMatch->new;
    @list = path_find( $TOP, $dirmatch, $filematch );


=head2 matchable

Convert a glob or other thing into a coderef useful for matching a file or
directory.
    my $sub = matchable( $glob );

Convert a glob into a coderef useful for matching a file or directory. 
C<$glob> may be one of the following:

=head3 Glob string

    my $sub = matchable( "*.txt" );

Uses L<Text::Glob> to convert the string into a regex, then builds a
subroutine from that.  Not that a leading C<*> does not match a leading
C<.>, eg C<*.txt> will not match C<.foo.txt>.

=head3 Regexp

    my $sub = matchable( qr(^honk.+txt$) );

Builds a subroutine that matches the directory entry to the given regex. 
Note that you must anchor the regex if this is important.

=head3 CODE

    my $sub = matchable( sub { 
            my( $entry, $directory, $fullname, $depth ) = @_;
            return 1 if length( $entry ) > 3;
            return;
        } );

Returns the coderef as-is.  L</find_path> will invoke the subref with the following parameters:

=over 4

=item $entry

Current directory entry being matched.  If the file or directory is called C</some/dir/entry> then
C<$entry> will be just C<"entry">.

=item $directory

Full path of the directory that the current entry being matched.  If the file or directory is
called C</some/dir/entry> then C<$directory> C</some/dir>.

=item $fullname

Full path of the directory entry being matched.  If the file or directory is
called C</some/dir/entry> then C<$fullname> is the just that, C</some/dir/entry>.

=item $depth

Number of subdirectories between the current C<$directory> and the top directory
passed to C<find_path>.  Invocations in the top directory have C<$depth=0>.

=back

=head3 Object

    my $object = MyClass->new;
    my $sub = matchable( $object );

    package MyClass;

    sub new { return bless {}, shift }

    sub match 
    {
        my( $self, $entry, $directory, $fullname ) = @_;
        return 1 if $entry eq 'yes';
        return;
    }

Builds a subroutine that calls object method C<match> for each directory
entry.  The parameters are the same as C<CODE> invocations, but with the
object being first parameter, as is customary.

=head1 SEE ALSO

L<Text::Glob/glob_to_regex>

=head1 AUTHOR

Philip Gwyn, E<lt>gwyn -AT- cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023 by Philip Gwyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
