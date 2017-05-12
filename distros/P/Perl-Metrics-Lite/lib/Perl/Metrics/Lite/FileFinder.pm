package Perl::Metrics::Lite::FileFinder;
use strict;
use warnings;
use Carp qw(cluck confess);
use English qw(-no_match_vars);
use File::Basename qw(fileparse);
use File::Find qw(find);
use IO::File;
use Readonly;

Readonly::Scalar our $PERL_FILE_SUFFIXES => qr{ \. (:? pl | pm | t ) }sxmi;
Readonly::Scalar our $SKIP_LIST_REGEX =>
    qr{ \.svn | \. git | _darcs | CVS }sxmi;
Readonly::Scalar my $PERL_SHEBANG_REGEX => qr/ \A [#] ! .* perl /sxm;
Readonly::Scalar my $DOT_FILE_REGEX     => qr/ \A [.] /sxm;

sub new {
    my ( $class, %args ) = @_;
    my $self = bless( {}, $class );
    return $self;
}

sub find_files {
    my ( $self, @directories_and_files ) = @_;
    foreach my $path (@directories_and_files) {
        if ( !-r $path ) {
            confess "Path '$path' is not readable!";
        }
    }
    my @found = $self->list_perl_files(@directories_and_files);
    return \@found;
}

sub list_perl_files {
    my ( $self, @paths ) = @_;
    my @files;

    my $wanted = sub {
        return if $self->should_be_skipped($File::Find::name);
        if ( $self->is_perl_file($File::Find::name) ) {
            push @files, $File::Find::name; ## no critic (ProhibitPackageVars)
        }
    };

    File::Find::find( { wanted => $wanted, no_chdir => 1 }, @paths );

    my @sorted_list = sort @files;
    return @sorted_list;
}

sub should_be_skipped {
    my ( $self, $fullpath ) = @_;
    my ( $name, $path, $suffix ) = File::Basename::fileparse($fullpath);
    return $path =~ $SKIP_LIST_REGEX;
}

sub is_perl_file {
    my ( $self, $path ) = @_;
    return if ( !-f $path );
    my ( $name, $path_part, $suffix )
        = File::Basename::fileparse( $path, $PERL_FILE_SUFFIXES );
    return if $name =~ $DOT_FILE_REGEX;
    if ( length $suffix ) {
        return 1;
    }
    return _has_perl_shebang($path);
}

sub _has_perl_shebang {
    my $path = shift;

    my $fh = IO::File->new( $path, '<' );
    if ( !-r $fh ) {
        cluck "Could not open '$path' for reading: $OS_ERROR";
        return;
    }
    my $first_line = <$fh>;
    $fh->close();
    return if ( !$first_line );
    return $first_line =~ $PERL_SHEBANG_REGEX;
}

1;

__END__

=encoding utf-8

=head1 NAME

Perl::Metrics::Lite::FileFinder - find perl files in paths

=head2 find_files( @directories_and_files )

Uses I<list_perl_files> to find all the readable Perl files
and returns a reference to a (possibly empty) list of paths.

=head2 list_perl_files

Takes a list of one or more paths and returns an
alphabetically sorted list of only the perl files.
Uses I<is_perl_file> so may throw an exception if a file is unreadable.

=head2 is_perl_file($path)

Takes a path to a file and returns true if the file appears to be a Perl file,
otherwise returns false.

If the file name does not match any of @Perl::Metrics::Lite::PERL_FILE_SUFFIXES
then the file is opened for reading and the first line examined for a a Perl
'shebang' line. An exception is thrown if the file cannot be opened in this case.

=cut
