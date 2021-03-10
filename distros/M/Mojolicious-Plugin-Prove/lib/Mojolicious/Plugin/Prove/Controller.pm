package Mojolicious::Plugin::Prove::Controller;
$Mojolicious::Plugin::Prove::Controller::VERSION = '0.11';
# ABSTRACT: Controller for Mojolicious::Plugin::Prove

use Mojo::Base 'Mojolicious::Controller';

use App::Prove;
use Mojo::File qw(path);
use Capture::Tiny qw(capture);

sub list {
    my $self = shift;
    
    my $conf = $self->stash->{conf};
    
    my $name = $self->param( 'name' );
    if ( $name && !exists $conf->{$name} ) {
        $self->render( 'prove_exception' );
        return;
    }
    
    if ( $name ) {
        my $files = path( $conf->{$name} )
            ->list
            ->grep( sub { $_->extname eq 't' } )
            ->map( sub { $_->basename } )
            ->to_array;
        $self->stash( files => $files );
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
    
    my $file   = $self->param( 'file' );
    my $name   = $self->param( 'name' );

    $self->stash( format => 'html' );
    
    my $conf = $self->stash->{conf};
    
    if ( !exists $conf->{$name} ) {
        $self->render( 'prove_exception' );
        return;
    }
    
    my $found = path( $conf->{$name} )
        ->list
        ->grep( sub { $_->extname eq 't' and $file eq $_->basename } )
        ->first;
        
    if ( !$found ) {
        $self->render( 'prove_exception' );
        return;
    }
    
    my $content = $found->slurp;

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
    
    my $files = path( $conf->{$name} )
        ->list
        ->grep( sub { $_->extname eq 't' } )
        ->map( sub { [ $_->basename, $_->to_string ] } )
        ->to_array;

    my $found;
    if ( $file ) {
        ($found) = grep{ $file eq $_->[0] } @{$files || []};
        
        if ( !$found ) {
            $self->render( 'prove_exception' );
            return;
        }
    }

    my @args = $found ? $found : @{ $files || [] };
    @args    = sort map{ $_->[1] } @args;

    local $ENV{HARNESS_TIMER};

    my $accepts = $self->app->renderer->accepts( $self )->[0] // 'html';
    my $format  = $accepts =~ m{\Ahtml?} ? 'html' : $accepts;

    my $prove = App::Prove->new;

    $prove->process_args( '--norc', @args );
    $prove->formatter('TAP::Formatter::HTML') if $format eq 'html';

    my ($stdout, $stderr, @result) = capture {
        $prove->run;
    };
    
    if ( $format eq 'html' ) {
        $stdout =~ s{\A.*?^(<!DOCTYPE)}{$1}xms;
        $self->render( text => $stdout );
    }
    else {
        $self->tx->res->headers->content_type('text/plain');
        $self->render( text => $stdout );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Prove::Controller - Controller for Mojolicious::Plugin::Prove

=head1 VERSION

version 0.11

=head1 METHODS

=head2 file

=head2 list

=head2 run

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
