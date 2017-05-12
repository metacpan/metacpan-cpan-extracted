=head1 NAME

OpenFrame::WebApp::Template::Factory - a factory for various types of template
wrappers.

=head1 SYNOPSIS

  use OpenFrame::WebApp::Template::Factory;

  my $tf = new OpenFrame::WebApp::Template::Factory()
    ->type( 'tt2' )
    ->directory( $local_dir )            # optional
    ->processor( new Template( ... ) );  # optional

  my $tmpl = $tf->new_template( $file, @new_args );

=cut

package OpenFrame::WebApp::Template::Factory;

use strict;
use warnings::register;

use OpenFrame::WebApp::Template;

our $VERSION = (split(/ /, '$Revision: 1.2 $'))[1];

use base qw ( OpenFrame::WebApp::Factory );

sub directory {
    my $self = shift;
    if (@_) {
	$self->{template_dir} = shift;
	return $self;
    } else {
	return $self->{template_dir};
    }
}

sub processor {
    my $self = shift;
    if (@_) {
	$self->{template_processor} = shift;
	return $self;
    } else {
	return $self->{template_processor};
    }
}

sub get_types_class {
    my $self = shift;
    return OpenFrame::WebApp::Template->types->{$self->type};
}

sub new_template {
    my $self = shift;
    my $path = shift;
    $self->new_object( @_ )
         ->file( $self->get_template_file($path) )
         ->processor( $self->processor );
    # $tmpl->process should check for undef processor
}

## get path to the template file
## shamelessly stolen from OpenFrame::AppKit::Segment::TT2
sub get_template_file {
    my $self = shift;
    my $path = shift;

    return $path unless ($self->directory);

    ## split up the path so we know where we are
    my ($volume, $dirs, $file) = File::Spec->splitpath( $path );

    ## make sure we have a file
    if (!$file) {
	$file = "index.html";
    }

    ## get the reconstituted path, with index.html tagged on if
    ## there was no file.
    return File::Spec->catfile( $self->directory, $dirs, $file );
}


1;

__END__

=head1 DESCRIPTION

The C<OpenFrame::WebApp::Template::Factory> class should be used to create
template wrappers as needed.  It lets you specify a template directory where
all the template files must live.

This class inherits its interface from C<OpenFrame::WebApp::Factory>.
It uses C<OpenFrame::WebApp::Template->types()> to resolve class names.

=head1 ADDITIONAL METHODS

=over 4

=item directory()

set/get template root directory.  only 1 entry is supported currently.

=item processor()

set/get optional template processor (for greater control).

=item new_template( $file, ... )

creates a new template wrapper of the appropriate type for the $file given
(if C<template_directory> is set, it is treated as the root directory).
passes all other arguments to the template's constructor.

=back

=head1 TODO

Support for multiple template directories.

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

Based on C<OpenFrame::AppKit::Segment::TT2>, by James A. Duncan.

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<OpenFrame::WebApp::Factory>,
L<OpenFrame::WebApp::Template>

=cut
