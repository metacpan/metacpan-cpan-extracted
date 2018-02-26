package Pod::ProjectDocs::DocManager;

use strict;
use warnings;

our $VERSION = '0.51';    # VERSION

use Moose;
use Carp();
use File::Find;
use IO::File;
use Pod::ProjectDocs::Doc;

has 'config' => ( is => 'ro', );
has 'desc' => (
    is  => 'rw',
    isa => 'Str',
);
has 'suffix' => ( is => 'rw', );
has 'parser' => ( is => 'ro', );
has 'docs'   => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

sub BUILD {
    my $self = shift;
    $self->_find_files();
    return;
}

sub _find_files {
    my $self = shift;
    foreach my $dir ( @{ $self->config->libroot } ) {
        unless ( -e $dir && -d _ ) {
            Carp::croak(qq/$dir isn't detected or it's not a directory./);
        }
    }
    my $suffixs = $self->suffix;
    $suffixs = [$suffixs] if !ref $suffixs;
    foreach my $dir ( @{ $self->config->libroot } ) {
        foreach my $suffix (@$suffixs) {
            my $wanted = sub {
                return unless $File::Find::name =~ /\.$suffix$/;
                ( my $path = $File::Find::name ) =~ s#^\\.##;
                my ( $fname, $fdir ) =
                  File::Basename::fileparse( $path, qr/\.$suffix/ );
                my $reldir = File::Spec->abs2rel( $fdir, $dir );
                $reldir ||= File::Spec->curdir;
                my $relpath = File::Spec->catdir( $reldir, $fname );
                $relpath .= ".";
                $relpath .= $suffix;
                $relpath =~ s:\\:/:g if $^O eq 'MSWin32';
                my $matched = 0;

                foreach my $regex ( @{ $self->config->except } ) {
                    if ( $relpath =~ /$regex/ ) {
                        $matched = 1;
                        last;
                    }
                }

                # check if there is actually any POD inside, skip otherwise
                my $content = join( '',
                    IO::File->new( $File::Find::name, 'r' )->getlines() );
                $matched = 1 if $content !~ m{^=(head1|head2|item|cut)}ismxg;

                unless ($matched) {
                    push @{ $self->docs },
                      Pod::ProjectDocs::Doc->new(
                        config      => $self->config,
                        origin      => $path,
                        origin_root => $dir,
                        suffix      => $suffix,
                      );
                }
            };
            File::Find::find( { no_chdir => 1, wanted => $wanted }, $dir );
        }
    }
    $self->docs( [ sort { $a->name cmp $b->name } @{ $self->docs } ] );
    return;
}

1;
__END__
