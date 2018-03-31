package Statocles::Command::build;
our $VERSION = '0.092';
# ABSTRACT: Build the site in a directory

use Statocles::Base 'Command';

sub run {
    my ( $self, @argv ) = @_;
    my %build_opt;
    GetOptionsFromArray( \@argv, \%build_opt,
        'date|d=s',
    );

    my $path = Path::Tiny->new( $argv[0] // '.statocles/build' );
    $path->mkpath;

    my $store = StoreType->coercion->( $path );
    #; say "Building site at " . $store->path;

    # Remove all pages from the build directory first
    $_->remove_tree for $store->path->children;

    my @pages = $self->site->pages( %build_opt );
    for my $page ( @pages ) {
        $store->write_file( $page->path, $page->render );
    }

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::Command::build - Build the site in a directory

=head1 VERSION

version 0.092

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
