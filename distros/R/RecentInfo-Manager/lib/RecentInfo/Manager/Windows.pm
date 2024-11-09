package RecentInfo::Manager::Windows 0.04;
use 5.020;
use Moo 2;
use experimental 'signatures', 'postderef';
use Carp 'croak';

=head1 NAME

RecentInfo::Manager::Windows - manage recent documents under Windows

=cut

use Date::Format::ISO8601 'gmtime_to_iso8601_datetime';
use List::Util 'first';
use File::Spec;
use File::Basename;

use RecentInfo::Entry;
use RecentInfo::Application;
use RecentInfo::GroupEntry;

use Win32;
use Win32::Shortcut;
use Win32API::RecentFiles 'SHAddToRecentDocsA', 'SHAddToRecentDocsW';
use Win32::TieRegistry;

=head1 SYNOPSIS

  use RecentInfo::Manager::Windows;
  my $mgr = RecentInfo::Manager::Windows->new();
  $mgr->load();
  $mgr->add('output.pdf');
  $mgr->save();

=cut

has 'recent_path' => (
    is => 'lazy',
    default => sub { Win32::GetFolderPath(Win32::CSIDL_RECENT()) },
);

# On Windows, app has no meaning
has 'app' => (
    is => 'lazy',
    default => sub { undef },
);

# This should use ShellExecuteEx instead, but our API is string-based instead
# of directly executing things ...
has 'exec' => (
    is => 'lazy',
    default => sub { sprintf "'%s %%u'", $_[0]->app },
);

has 'entries' => (
    is => 'lazy',
    default => \&load,
    clearer => 'clear_entries',
);

sub load( $self, $recent=$self->recent_path ) {
    if( defined $recent && -e $recent ) {
        opendir my( $dh), $recent or croak "Can't read '$recent': $!";
        my @entries = map { "$recent\\$_" }
                      grep { !/\A\.\.?\z/ }
                      readdir( $dh );
        return $self->_parse( \@entries );
    } else {
        warn "Empty? $recent";
        return [];
    }
}

sub _mime_type_from_name( $fn ) {
    state $filetypes = $Registry->{"HKEY_CLASSES_ROOT"};
    state $ft_cache = {};
    my $mime_type;
    if( $fn =~ /(\.[^.]+)\z/) {
        $ft_cache->{ $1 } //= $filetypes->{ $1 };
        my $ft = $ft_cache->{ $1 };
        if( $ft and my $ct = $ft->{"Content Type"}) {
            $mime_type = $ct;
        };
    };
    return $mime_type;
}

# Assumes that the filename is in the current codepage?!
sub _entry_from_Windows_shortcut( $self, $fn ) {
    my $link = Win32::Shortcut->new($fn);
    my @linkstat = stat $fn;
    my $target = $link->Path;
    return unless $target; # we only list entries with a filename/directory name
    return if -d $target; # we only list files, not directories
    my $mime_type = _mime_type_from_name( $target ) // 'application/octet-stream';

    my $res = RecentInfo::Entry->new(
        href => $target,
        added => $linkstat[9],
        #visited => $linkstat[9],
        #modified => $stat[9],
        mime_type => $mime_type,
        # app ?
    );
    $link->Close;
    return $res
}

sub _parse( $self, $entries ) {
    my @bookmarks = sort {
        $a->added <=> $b->added
    } map {
        $self->_entry_from_Windows_shortcut( $_ )
    } $entries->@*;

    return \@bookmarks;
}

sub find( $self, $href ) {
    first { fc($_->href) eq fc($href) } $self->entries->@*;
}

sub add( $self, $filename, $info = {} ) {

    if( ! exists $info->{mime_type}) {
        $info->{mime_type} = _mime_type_from_name($filename) // 'application/octet-stream';
    };

    $filename = File::Spec->rel2abs($filename);

    if( utf8::is_utf8($filename) ) {
        # Assume the filename is UTF-8
        SHAddToRecentDocsU($filename);
    } else {
        # Assume the filename is as returned from some Windows API or file
        # in the current codepage. This might or might not be Latin-1.
        SHAddToRecentDocsA($filename);
    };

    # re-read ->entries
    $self->clear_entries;
}

=head2 C<< ->remove $filename >>

  $mgr->remove('output.pdf');

Removes the filename from the list of recently used files.

=cut

sub remove( $self, $filename ) {
    $filename = basename( $filename );
    my $recent = $self->recent_path;

    unlink Win32::GetANSIPathName("$recent/$filename.lnk");

    # re-read ->entries on next call
    $self->clear_entries;
}

sub save( $self, $filename=$self->recent_path ) {
    # We don't save, as we do direct modification
    1;
}

1;
=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/RecentInfo-Manager>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via Github
at L<https://github.com/Corion/RecentInfo-Manager/issues>

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2024-2024 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut

