package Pod::ProjectDocs::DocManager;

use strict;
use warnings;

our $VERSION = '0.48'; # VERSION

use base qw/Class::Accessor::Fast/;
use File::Find;
use IO::File;
use Pod::ProjectDocs::Doc;

__PACKAGE__->mk_accessors(qw/
    config
    desc
    suffix
    parser
    docs
/);

sub new {
    my ($class, @args) = @_;
    my $self = bless {}, $class;
    $self->_init(@args);
    return $self;
}

sub _init {
    my ( $self, %args ) = @_;
    $args{suffix} = [ $args{suffix} ] unless ref $args{suffix};
    $self->config( $args{config} );
    $self->desc( $args{desc} );
    $self->suffix( $args{suffix} );
    $self->parser( $args{parser} );
    $self->docs( [] );
    $self->_find_files;
    return;
}

sub _find_files {
    my $self = shift;
    foreach my $dir ( @{ $self->config->libroot } ) {
        unless ( -e $dir && -d _ ) {
            $self->_croak(qq/$dir isn't detected or it's not a directory./);
        }
    }
    my $suffixs = $self->suffix;
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
                my $content = join('', IO::File->new( $File::Find::name, 'r' )->getlines());
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

sub get_docs {
    my $self = shift;
    return @{ $self->docs };
}

sub _croak {
    my ( $self, $msg ) = @_;
    require Carp;
    Carp::croak($msg);
}

1;
__END__
