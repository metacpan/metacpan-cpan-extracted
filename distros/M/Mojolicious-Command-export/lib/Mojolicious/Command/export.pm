package Mojolicious::Command::export;
our $VERSION = '0.007';
# ABSTRACT: Export a Mojolicious website to static files

#pod =head1 SYNOPSIS
#pod
#pod   Usage: APPLICATION export [OPTIONS] [PAGES]
#pod
#pod     ./myapp.pl export
#pod     ./myapp.pl export /perldoc --to /var/www/html
#pod     ./myapp.pl export /perldoc --base /url
#pod
#pod   Options:
#pod     -h, --help        Show this summary of available options
#pod         --to <path>   Path to store the static pages. Defaults to '.'.
#pod         --base <url>  Rewrite internal absolute links to prepend base
#pod     -q, --quiet       Silence report of dirs/files modified
#pod
#pod =head1 DESCRIPTION
#pod
#pod Export a Mojolicious webapp to static files.
#pod
#pod =head2 Configuration
#pod
#pod Default values for the command's options can be specified in the
#pod configuration using one of Mojolicious's configuration plugins.
#pod
#pod     # myapp.conf
#pod     {
#pod         export => {
#pod             # Configure the default pages to export
#pod             pages => [ '/', '/hidden' ],
#pod             # The directory to export to
#pod             to => '/var/www/html',
#pod             # Rewrite URLs to include base directory
#pod             base => '/',
#pod         }
#pod     }
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Mojolicious>, L<Mojolicious::Commands>
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Command';
use Mojo::Util qw( getopt );

has description => 'Export site to static files';
has usage => sub { shift->extract_usage };

sub run {
    my ( $self, @args ) = @_;
    my $app = $self->app;
    if ( !$app->can( 'export' ) ) {
        $app->plugin( 'Export' );
    }

    getopt( \@args, \my %opt,
        'to=s',
        'base=s',
        'quiet|q',
    );
    $opt{quiet} //= 0;
    if ( $opt{quiet} ) {
        $self->quiet( 1 );
    }

    if ( @args ) {
        $opt{pages} = \@args;
    }

    $app->export->export( \%opt );
}

1;

__END__

=pod

=head1 NAME

Mojolicious::Command::export - Export a Mojolicious website to static files

=head1 VERSION

version 0.007

=head1 SYNOPSIS

  Usage: APPLICATION export [OPTIONS] [PAGES]

    ./myapp.pl export
    ./myapp.pl export /perldoc --to /var/www/html
    ./myapp.pl export /perldoc --base /url

  Options:
    -h, --help        Show this summary of available options
        --to <path>   Path to store the static pages. Defaults to '.'.
        --base <url>  Rewrite internal absolute links to prepend base
    -q, --quiet       Silence report of dirs/files modified

=head1 DESCRIPTION

Export a Mojolicious webapp to static files.

=head2 Configuration

Default values for the command's options can be specified in the
configuration using one of Mojolicious's configuration plugins.

    # myapp.conf
    {
        export => {
            # Configure the default pages to export
            pages => [ '/', '/hidden' ],
            # The directory to export to
            to => '/var/www/html',
            # Rewrite URLs to include base directory
            base => '/',
        }
    }

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Commands>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
