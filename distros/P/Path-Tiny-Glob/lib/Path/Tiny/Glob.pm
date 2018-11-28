package Path::Tiny::Glob;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: File globbing utility 
$Path::Tiny::Glob::VERSION = '0.0.1';

use strict;
use warnings;

use Path::Tiny; 

use Path::Tiny::Glob::Visitor;

use parent 'Exporter::Tiny';

our @EXPORT = qw/ pathglob /;

use experimental qw/ signatures postderef /;

sub pathglob( $glob ) {

    # let's figure out which type of path we have
    my( $head, $rest ) = split '/', $glob, 2;

    my $dir;

    if ( $head =~ /^~/ ) {
        $dir = path($head);
        $glob = $rest;
    }
    elsif( $head eq '' ) {
        $dir = Path::Tiny->rootdir;
        $glob = $rest;
    }
    else {
        $dir = path('.');
    }

    return Path::Tiny::Glob::Visitor->new(
        path => $dir, 
        globs => [ $glob ],
    )->as_list;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Tiny::Glob - File globbing utility 

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

    use Path::Tiny::Glob;

    my $dzil_files = pathglob( '~/work/perl-modules/*/dist.ini' );

    while( my $file = $dzil_files->next ) {
        say "found a Dist::Zilla project at ", $file->parent;
    }

=head1 DESCRIPTION

This module exports a single function, C<pathglob>. 

=head1 EXPORTED FUNCTIONS 

=head2 C<pathglob>

    my $list = pathglob( $glob );

This function takes in 
a shell-like file glob, and returns a L<Lazy::List> of L<Path::Tiny> objects
matching it.

Caveat: backtracking paths using C<..> don't work.

=head3 Supported globbing patterns

=over

=item C<*>

Matches zero or more characters.

=item C<?>

Matches zero or one character.

=item C<**>

Matches zero or more directories.

Note that C<**> only matches directories. If you want to glob all files in a directory and its subdirectories, you 
have to do `**/*`.

=back

=head1 SEE ALSO

L<File::Wildcard>

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
