package Statocles::App::Basic;
our $VERSION = '0.096';
# ABSTRACT: Build Markdown and collateral files

use Statocles::Base 'Class';
use Statocles::Document;
use Statocles::Util qw( run_editor read_stdin );
with 'Statocles::App::Role::Store';

#pod =attr store
#pod
#pod The L<store path|Statocles::Store> containing this app's documents and files.
#pod Required.
#pod
#pod =cut

#pod =method command
#pod
#pod     my $exitval = $app->command( $app_name, @args );
#pod
#pod Run a command on this app. Commands allow creating, editing, listing, and
#pod viewing pages.
#pod
#pod =cut

my $USAGE_INFO = <<'ENDHELP';
Usage:
    $name help -- This help file
    $name edit <path> -- Edit a page, creating it if necessary
ENDHELP

sub command {
    my ( $self, $name, @argv ) = @_;

    if ( !$argv[0] ) {
        say STDERR "ERROR: Missing command";
        say STDERR eval "qq{$USAGE_INFO}";
        return 1;
    }

    if ( $argv[0] eq 'help' ) {
        say eval "qq{$USAGE_INFO}";
        return 0;
    }

    if ( $argv[0] eq 'edit' ) {
        $argv[1] =~ s{^/}{};
        my $path = Path::Tiny->new(
            $argv[1] =~ /[.](?:markdown|md)$/ ? $argv[1] : "$argv[1]/index.markdown",
        );

        # Read post content on STDIN
        if ( my $content = read_stdin() ) {
            my $doc = Statocles::Document->parse_content(
                path => $path.'',
                store => $self->store,
                content => $content,
            );
            $self->store->write_file( $path => $doc );
        }
        elsif ( !$self->store->has_file( $path ) ) {
            my $doc = Statocles::Document->new(
                content => "Markdown content goes here.\n",
            );
            $self->store->write_file( $path => $doc );
        }

        my $full_path = $self->store->path->child( $path );
        if ( my $content = run_editor( $full_path ) ) {
            $full_path->spew_utf8( $content );
        }
        else {
            say "New page at: $full_path";
        }

    }
    else {
        say STDERR qq{ERROR: Unknown command "$argv[0]"};
        say STDERR eval "qq{$USAGE_INFO}";
        return 1;
    }

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::App::Basic - Build Markdown and collateral files

=head1 VERSION

version 0.096

=head1 SYNOPSIS

    my $app = Statocles::App::Basic->new(
        url_root => '/',
        store => 'share/root',
    );
    my @pages = $app->pages;

=head1 DESCRIPTION

This application builds basic pages based on L<Markdown documents|Statocles::Document> and
other files. Use this to have basic informational pages like "About Us" and "Contact Us".

=head1 ATTRIBUTES

=head2 store

The L<store path|Statocles::Store> containing this app's documents and files.
Required.

=head1 METHODS

=head2 command

    my $exitval = $app->command( $app_name, @args );

Run a command on this app. Commands allow creating, editing, listing, and
viewing pages.

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
