package Silki::Controller::File;
{
  $Silki::Controller::File::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Silki::I18N qw( loc );
use Silki::Schema::File;

use Moose;

BEGIN { extends 'Silki::Controller::Base' }

with 'Silki::Role::Controller::File';

sub _set_file : Chained('/wiki/_set_wiki') : PathPart('file') : CaptureArgs(1) {
    my $self    = shift;
    my $c       = shift;
    my $file_id = shift;

    my $file = Silki::Schema::File->new( file_id => $file_id );

    my $wiki = $c->stash()->{wiki};
    $c->redirect_and_detach( $wiki->uri( with_host => 1 ) )
        unless $file && $file->wiki()->wiki_id() == $wiki->wiki_id();

    $c->stash()->{file} = $file;
}

sub file : Chained('_set_file') : PathPart('') : Args(0) : ActionClass('+Silki::Action::REST') {
}

sub file_GET_html {
    my $self = shift;
    my $c    = shift;

    my $file = $c->stash()->{file};

    if ( $file->is_displayable_in_browser() ) {
        my $name = $file->filename();
        $name = substr( $name, 0, 16 ) . q{ ...} if length $name > 16;

        $c->add_tab(
            {
                uri         => $file->uri(),
                label       => $name,
                tooltip     => loc( 'Contents of %1', $file->filename() ),
                is_selected => 1,
            }
        );

        $c->stash()->{template} = '/file/view-in-frame';
    }
    else {
        $self->_download( $c, $file, 'attachment' );
    }

    return;
}

sub file_DELETE {
    my $self = shift;
    my $c    = shift;

    my $wiki = $c->stash()->{wiki};

    $self->_require_permission_for_wiki( $c, $wiki, 'Delete' );

    my $file = $c->stash()->{file};

    my $msg = loc( 'Deleted the file %1', $file->filename() );

    $file->delete( user => $c->user() );

    $c->session_object()->add_message($msg);

    $c->redirect_and_detach( $wiki->uri( with_host => 1 ) );
}

sub content : Chained('_set_file') : PathPart('content') : Args(0) {
    my $self = shift;
    my $c    = shift;

    my $file = $c->stash()->{file};

    # If the file type is something like text/x-python, the browser might
    # prompt the user to save the file. However, if we force text/plain, the
    # browser displays the file nicely.
    my $ct = $file->mime_type() =~ /^text/ ? 'text/plain' : $file->mime_type();

    $self->_download( $c, $file, 'inline', $ct );

    return;
}

sub download : Chained('_set_file') : PathPart('content_as_attachment') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $self->_download( $c, $c->stash()->{file}, 'attachment' );

    return;
}

sub _download {
    my $self         = shift;
    my $c            = shift;
    my $file         = shift;
    my $disposition  = shift;
    my $content_type = shift || $file->mime_type();

    $c->response()->status(200);

    $content_type = 'text/plain'
        if $disposition eq 'inline' && $content_type =~ /^application/;

    $c->response()->content_type($content_type);

    my $name = $file->filename();
    $name =~ s/\"/\\"/g;

    $c->response()
        ->header( 'Content-Disposition' => qq{$disposition; filename="$name"} );
    $c->response()->content_length( $file->file_size() );
    $c->response()->header( 'X-Sendfile' => $file->file_on_disk() );

    $c->detach();
}

sub small_image : Chained('_set_file') : PathPart('small') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $c->status_not_found()
        unless $c->stash()->{file}->is_browser_displayable_image();

    $self->_serve_image( $c, $c->stash()->{file}, 'small_image_file' );
}

sub thumbnail : Chained('_set_file') : PathPart('thumbnail') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $c->status_not_found()
        unless $c->stash()->{file}->is_browser_displayable_image();

    $self->_serve_image( $c, $c->stash()->{file}, 'thumbnail_file' );
}

sub delete_confirmation : Chained('_set_file') : PathPart('delete_confirmation') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $self->_require_permission_for_wiki( $c, $c->stash()->{wiki}, 'Delete' );

    $c->stash()->{template} = '/file/delete-confirmation';
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Controller class for files

__END__
=pod

=head1 NAME

Silki::Controller::File - Controller class for files

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

