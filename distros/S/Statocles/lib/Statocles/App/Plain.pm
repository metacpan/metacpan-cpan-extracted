package Statocles::App::Plain;
our $VERSION = '0.085';
# ABSTRACT: (DEPRECATED) Plain documents made into pages with no extras

use Statocles::Base 'Class';
extends 'Statocles::App::Basic';
use Statocles::Util qw( derp );

#pod =attr store
#pod
#pod The L<store|Statocles::Store> containing this app's documents. Required.
#pod
#pod =cut

before pages => sub {
    derp qq{Statocles::App::Plain has been renamed to Statocles::App::Basic and will be removed in 2.0. Change the app class to "Statocles::App::Basic" to silence this message.};
};

#pod =method command
#pod
#pod     my $exitval = $app->command( $app_name, @args );
#pod
#pod Run a command on this app. Commands allow creating, editing, listing, and
#pod viewing pages.
#pod
#pod =cut

before command => sub {
    derp qq{Statocles::App::Plain has been renamed to Statocles::App::Basic and will be removed in 2.0. Change the app class to "Statocles::App::Basic" to silence this message.};
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::App::Plain - (DEPRECATED) Plain documents made into pages with no extras

=head1 VERSION

version 0.085

=head1 SYNOPSIS

    my $app = Statocles::App::Plain->new(
        url_root => '/',
        store => 'share/root',
    );
    my @pages = $app->pages;

=head1 DESCRIPTION

B<NOTE:> This application has been renamed L<Statocles::App::Basic>. This
class will be removed with v2.0. See L<Statocles::Help::Upgrading>.

This application builds simple pages based on L<documents|Statocles::Document>. Use this
to have basic informational pages like "About Us" and "Contact Us".

=head1 ATTRIBUTES

=head2 store

The L<store|Statocles::Store> containing this app's documents. Required.

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
