package Mojolicious::Plugin::Prove::Controller;

use Mojo::Base 'Mojolicious::Controller';

use App::Prove;
use Capture::Tiny qw(capture);
use File::Basename;
use File::Find::Rule;

sub list {
    my $self = shift;
    
    my $conf = $self->stash->{conf};
    
    my $name = $self->param( 'name' );
    if ( $name && !exists $conf->{$name} ) {
        $self->render( 'prove_exception' );
        return;
    }
    
    if ( $name ) {
        my @files = File::Find::Rule->file->name( '*.t' )->maxdepth( 1 )->in( $conf->{$name} );
        $self->stash( files => [ map{ basename $_ }@files ] );
        $self->stash( names => '' );
    }
    else {
        $self->stash( name  => '' );
        $self->stash( names => [ keys %{$conf} ] );
        $self->stash( files => '' );
    }
    
    $self->render( 'prove_file_list' );
}

sub file {
    my $self = shift;
    
    my $format = defined $self->stash( 'format' ) ? '.' . $self->stash( 'format' ) : '';
    my $file   = $self->param( 'file' ) . $format;
    my $name   = $self->param( 'name' );
    
    $self->stash( format => 'html' );
    
    my $conf = $self->stash->{conf};
    
    if ( !exists $conf->{$name} ) {
        $self->render( 'prove_exception' );
        return;
    }
    
    my @files = File::Find::Rule->file->name( '*.t' )->maxdepth( 1 )->in( $conf->{$name} );
    
    my $found;
    if ( $file ) {
        ($found) = grep{ $file eq basename $_ }@files;
        
        if ( !$found ) {
            $self->render( 'prove_exception' );
            return;
        }
    }
    
    my $content = do{ local ( @ARGV,$/ ) = $found; <> };
    $self->stash( code => $content );
    $self->stash( file => $file );
    
    $self->render( 'prove_file' );
}

sub run {
    my $self = shift;
    
    my $file = $self->param( 'file' );
    my $name = $self->param( 'name' );
    
    my $conf = $self->stash->{conf};
    
    if ( !exists $conf->{$name} ) {
        $self->render( 'prove_exception' );
        return;
    }
    
    my @files = File::Find::Rule->file->name( '*.t' )->maxdepth( 1 )->in( $conf->{$name} );
    
    my $found;
    if ( $file ) {
        ($found) = grep{ $file eq basename $_ }@files;
        
        if ( !$found ) {
            $self->render( 'prove_exception' );
            return;
        }
    }
    
    my @args = $found ? $found : @files;
    @args    = sort @args;

    local $ENV{HARNESS_TIMER};

    my $prove = App::Prove->new;
    $prove->process_args( '--norc', @args );
    my ($stdout, $stderr, @result) = capture {
        $prove->run;
    };
    
    $self->render( text => $stdout );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Prove::Controller

=head1 VERSION

version 0.08

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
