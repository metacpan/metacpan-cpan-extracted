package Module::Depends::Tree;

use warnings;
use strict;

use Module::CoreList;
use Module::Depends;
use Module::Depends::Intrusive;
use LWP::UserAgent;
use Archive::Extract;
use CPANPLUS::Backend;

=head1 NAME

Module::Depends::Tree - A container for functions for the deptree program

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

No user-servicable parts inside.  F<deptree> is the only thing that
should use this module directly.

=cut

# Working accumulators

our $mirror;
our $workdir;

our %used;
our %stats;
our %prereqs;
our %metadeps;
our %packages;

# Modules to not display
our %skippers = ( perl => 1, %{$Module::CoreList::version{5.008004}} );

our $singleton_cpan;

# Returns a singleton CPANPLUS::Backend
sub cpan {
    $singleton_cpan ||= CPANPLUS::Backend->new();

    return $singleton_cpan;
}


sub print_deps {
    my $level = shift;
    my $name = shift;
    my %seen = @_;

    print '    ' x $level if $level;
    print $name, "\n";
    $used{$name}++;

    my $stats = $stats{$name};

    if ( $stats && !$stats->package_is_perl_core ) {
        $seen{$name} = 1;
        for my $name ( sort keys %{$prereqs{$name}} ) {
            print_deps( $level+1, $name, %seen ) unless $seen{$name} || $skippers{$name};
        }
    }
}


sub fetch_meta_deps {
    my $modstats = shift;

    my $package = $modstats->package;

    # These two are too hairy to get into.
    return {} if $package =~ /^mod_perl/ || $package =~ /^FCGI/;

    if ( !exists $metadeps{$package} ) {
        my $path = $modstats->path;
        die '$mirror must be defined' unless $mirror;
        die '$workdir must be defined' unless $workdir;

        my $fullpath = "$mirror/$path/$package";
        my $tarball = "$workdir/$package";

        if ( ! -e $tarball ) {
            my $ua = LWP::UserAgent->new();
            warn "Fetching $fullpath\n";
            my $resp = $ua->get( $fullpath, ':content_file' => $tarball );
            if ( !$resp->is_success ) {
                my $error = $resp->status_line;
                die "Can't read $fullpath into $tarball:\n$error";
            }
        }

        my $unpack_dir = $tarball;
        $unpack_dir =~ s/(\.tar)?(\.(bz2|gz))?$//;
        if ( ! -d $unpack_dir ) { # we have to go extract
            my $ae = Archive::Extract->new( archive => $tarball );
            my $ok = $ae->extract( to => $workdir ) or die $ae->error;
        }
        my $deps = Module::Depends->new->dist_dir( $unpack_dir )->find_modules->requires;
        my $build_deps = Module::Depends->new->dist_dir( $unpack_dir )->find_modules->build_requires;
        unless ( $deps && keys %{$deps} ) {
            local *STDOUT = *STDERR;
            warn "Intrusive on $package\n";
            $deps = Module::Depends::Intrusive->new->dist_dir( $unpack_dir )->find_modules->requires || {};
            $build_deps = Module::Depends::Intrusive->new->dist_dir( $unpack_dir )->find_modules->build_requires || {};
        }
        for my $key ( keys %$build_deps ) {
            $deps->{$key} ||= $build_deps->{$key};
        }
        $metadeps{$package} = $deps;
    }
    return $metadeps{$package};
}


sub process_queue {
    my @queue = @_;

    while ( @queue ) {
        my $name = shift @queue;
        next if $stats{$name}; # Already have it

        my $stats = $stats{$name} = cpan()->module_tree( $name );
        if ( !$stats ) {
            warn "I don't know about $name\n";
            next;
        }
        next if $stats->package_is_perl_core;

        push( @{$packages{ $stats->package }}, $name );
        my $deps = fetch_meta_deps( $stats ) or next;
        my $reqs = $prereqs{$name} = $deps;

        if ( $reqs ) {
            for my $key ( keys %$reqs ) {
                push @queue, $key unless $skippers{$key};
            }
        }
    }
}
=head1 AUTHOR

Andy Lester, C<< <andy at petdance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-module-depends-tree at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Depends-Tree>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Module::Depends::Tree

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Module-Depends-Tree>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Module-Depends-Tree>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Depends-Tree>

=item * Search CPAN

L<http://search.cpan.org/dist/Module-Depends-Tree>

=item * Source code repository

L<http://code.google.com/p/module-depends-tree/source>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Andy Lester & Socialtext, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Module::Depends::Tree
