package Statocles::Command::bundle;
our $VERSION = '0.094';
# ABSTRACT: Copy a default theme to this site to make changes

use Statocles::Base 'Command';
use File::Share qw( dist_dir );

sub run {
    my ( $self, @argv ) = @_;
    my $what = $argv[0];
    if ( $what eq 'theme' ) {
        my $theme_name = $argv[1];
        if ( !$theme_name ) {
            say STDERR "ERROR: No theme name!";
            say STDERR "\nUsage:\n\tstatocles bundle theme <name>";
            return 1;
        }

        my $dest_dir = $self->site->theme->store->path;
        $self->bundle_theme( $theme_name, $dest_dir, @argv[2..$#argv] );
        say qq{Theme "$theme_name" written to "$dest_dir"};
    }
    return 0;
}

sub bundle_theme {
    my ( $class, $name, $dir, @files ) = @_;
    my $theme_dest = Path::Tiny->new( $dir );
    my $theme_root = Path::Tiny->new( dist_dir( 'Statocles' ), 'theme', $name );

    if ( !@files ) {
        my $iter = $theme_root->iterator({ recurse => 1 });
        while ( my $path = $iter->() ) {
            next unless $path->is_file;
            my $relative = $path->relative( $theme_root );
            push @files, $relative;
        }
    }
    else {
        @files = map { Path::Tiny->new( $_ ) } @files;
    }

    for my $path ( @files ) {
        my $abs_path = $path->absolute( $theme_root );
        my $dest = $theme_dest->child( $path );
        # Don't overwrite site-customized hooks
        next if ( $abs_path->stat->size == 0 && $dest->exists );
        Statocles->log( debug => sprintf 'Copying theme file "%s" to "%s"', $path, $dest );
        $dest->remove if $dest->exists;
        $dest->parent->mkpath;
        $abs_path->copy( $dest );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::Command::bundle - Copy a default theme to this site to make changes

=head1 VERSION

version 0.094

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
