package RecentInfo::Manager 0.03;
use 5.020;
use experimental 'signatures';

use Exporter 'import';
use Module::Load;
our @EXPORT_OK = (qw(add_recent_file remove_recent_file recent_files));

=head1 NAME

RecentInfo::Manager - manage recent documents

=head1 SYNOPSIS

  use RecentInfo::Manager 'add_recent_file';
  add_recent_file('output.pdf');

  # oo interface
  my $mgr = RecentInfo::Manager->new();
  $mgr->load();
  $mgr->add('output.pdf');
  $mgr->save;

=head1 FUNCTIONS

=head2 C<< add_recent_file $filename, $file_options >>

  add_recent_file( 'output.pdf', { mime_type => 'application/pdf' } );

Adds C<output.pdf> as a recently used (or created) file for the current
application. If the MIME filetype is not given, it is inferred from
the filename.

=cut

sub add_recent_file($filename, $file_options={}, $options={}) {
    my $mgr = RecentInfo::Manager->new(%$options);

    if( ! ref $filename ) {
        $filename = [ [$filename => $file_options] ];
    }

    my @files = map {
        ! ref $_ ? [$_ => $file_options] : $_
    } $filename->@*;

    for my $f (@files) {
        $mgr->add( $f->@* );
    };
    $mgr->save();
};

=head2 C<< remove_recent_file $filename >>

  remove_recent_file( 'oops.xls' );

Removes the given file from the list of recently accessed files.

=cut

sub remove_recent_file($filename, $options={}) {
    my $mgr = RecentInfo::Manager->new(%$options);

    if( ! ref $filename ) {
        $filename = [ $filename ];
    }

    my @files = $filename->@*;

    for my $f (@files) {
        $mgr->remove( $f );
    };
    $mgr->save();
};

sub mime_match( $type, $pattern ) {
    $pattern =~ s/\*/.*/g;
    $type =~ /$pattern/
}

=head2 C<< recent_files $options >>

  my @entries = recent_files( { mime_type => 'application/pdf' });

Returns a list of filenames of the recently accessed files.
In the options hash, you can pass in the following keys:

=over 4

=item B<mime_type> - search for the given MIME type. C<*> is a wildcard.

=item B<app> - search for the given application name.

=back

=cut

sub recent_files($recent_options=undef, $options={}) {
    my $mgr = RecentInfo::Manager->new(%$options);
    $recent_options //= {
        app => $mgr->app,
    };

    my $appname = $recent_options->{app};
    my $mimetype = $recent_options->{mime_type};
    my @res = map { $_->to_native } grep {
          defined $appname ? grep { $_->name eq $appname } $_->applications->@*
        : defined $mimetype ? mime_match( $_->mime_type, $mimetype )
        : 1
    } $mgr->entries->@*;

    return @res
};

=head1 METHODS

The module also acts as a factory for OS-specific implementations.

=head2 C<< ->new >>

  my $mgr = RecentInfo::Manager->new();
  $mgr->load();
  $mgr->add('output.pdf');
  $mgr->save;

=cut

our $implementation;
sub new($factoryclass, @args) {
    $implementation //= $factoryclass->_best_implementation();

    # return a new instance
    $implementation->new(@args);
}

sub _best_implementation( $class, @candidates ) {
    my $impl;
    if( $^O =~ /cygwin|MSWin32/ ) {
        $impl = 'RecentInfo::Manager::Windows';
    } else {
        $impl = 'RecentInfo::Manager::XBEL';
    }
    load $impl;
    return $impl;
};

1;

=head1 SEE ALSO

L<Mac::RecentDocuments> - recent documents for old MacOS

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

