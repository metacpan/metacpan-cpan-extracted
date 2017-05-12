package OAuthomatic::Config;
# ABSTRACT: Aggregated bag for various OAuthomatic parameters, separated from main class to make passing them around easier.

use Moose;
use MooseX::AttributeShortcuts;
use MooseX::Types::Path::Tiny qw/AbsDir AbsPath/;
use Carp;
use Path::Tiny;
use Try::Tiny;
use OAuthomatic::Types;
use namespace::sweep;

# FIXME: validation of params syntax (especially URLs and html_dir)



has 'app_name' => (
    is => 'ro', isa => 'Str', required => 1);

has 'password_group' => (
    is => 'ro', isa => 'Str', default => 'OAuthomatic tokens');

has 'browser' => (
    is => 'ro', isa => 'Str', default => sub {
        # FIXME: consider trying more than one command (Browser::Open supports it)
        my $self = shift;
        require Browser::Open;
        # Note: on Debian/Ubuntu it uses sensible-browser which checks BROWSER, then
        # tries gnome-www-browser and few others. Reasonable way to reconfigure:
        #   sudo update-alternatives --config gnome-www-browser
        my $command = Browser::Open::open_browser_cmd();
        print "[OAuthomatic] Will use browser $command\n" if $self->debug;
        return $command;
    });

has 'html_dir' => (
    is => 'lazy', isa => AbsDir, coerce=>1,
    default => sub {
        my $self = shift;
        require File::ShareDir;
        my $share_dir;
        try {
            $share_dir = path(File::ShareDir::dist_dir("OAuthomatic"));
        } catch {
            if(/Failed to find share dir/) {
                # Look for local development run
                $share_dir = path(__FILE__)->absolute->parent->parent->parent->child("share");
                print "[OAuthomatic] Can't find instaled html_dir, trying $share_dir\n" if $self->debug;
            }
            OAuthomatic::Error::Generic->throw(
                ident => "Can not find html_dir",
                extra => $_)
                unless ($share_dir && $share_dir->exists);
        };
        my $hd = $share_dir->child("oauthomatic_html");
        OAuthomatic::Error::Generic->throw(
            ident => "Invalid html_dir",
            extra => "Directory $hd not found")
            unless $hd->is_dir;
        print "[OAuthomatic] Using own HTML templates from: $hd\n" if $self->debug;
        return $hd;
    });

has 'debug' => (is => 'ro', isa => 'Bool');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuthomatic::Config - Aggregated bag for various OAuthomatic parameters, separated from main class to make passing them around easier.

=head1 VERSION

version 0.0201

=head1 SYNOPSIS

    my $config = OAuthomatic::Config->new(
         app_name => "News trend parser",
         password_group => "OAuth tokens (personal)",
         html_dir => "/usr/local/share/custom/oauthomatic-green",
         browser => "opera",
         debug => 1,
    );

=head1 DESCRIPTION

See L<OAuthomatic> for description of all parameters.

This object is used as simple bag to pass a few common params
between various L<OAuthomatic> modules.

=head1 AUTHOR

Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Marcin Kasperski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
