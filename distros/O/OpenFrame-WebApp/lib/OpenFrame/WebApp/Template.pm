=head1 NAME

OpenFrame::WebApp::Template - abstract class for template processing wrappers

=head1 SYNOPSIS

  # abstract class - does nothing on its own
  use OpenFrame::WebApp::Template::SomeClass;

  my $tmpl = new OpenFrame::WebApp::Template::SomeClass()
    ->file( $local_path )
    ->template_vars( { some => vars } );

  try {
      $ofResponse = $tmpl->process;
  } catch OpenFrame::WebApp::Template::Error with {
      my $e = shift;
      print $e->flag, $e->message;
  }

=cut

package OpenFrame::WebApp::Template;

use strict;
use warnings::register;

use Error qw( :try );
use OpenFrame::Response;
use OpenFrame::WebApp::Error::Abstract;
use OpenFrame::WebApp::Template::Error;

use base qw ( OpenFrame::Object );

our $VERSION = (split(/ /, '$Revision: 1.13 $'))[1];

our $TYPES = {
	      tt2   => 'OpenFrame::WebApp::Template::TT2',
	      petal => 'OpenFrame::WebApp::Template::Petal',
	     };

## get hash of known template types
sub types {
    my $self = shift;
    if (@_) {
	$TYPES = shift;
	return $self;
    } else {
	return $TYPES;
    }
}

## object init
sub init {
    my $self = shift;
    $self->template_vars( {} );
}

## template processor
sub processor {
    my $self = shift;
    if (@_) {
	$self->{template_processor} = shift;
	return $self;
    } else {
	return $self->{template_processor};
    }
}

## override this method
sub default_processor {
    my $self = shift;
    throw OpenFrame::WebApp::Error::Abstract( class => ref($self) );
}

## local path to the template file
sub file {
    my $self = shift;
    if (@_) {
	$self->{template_file} = shift;
	return $self;
    } else {
	return $self->{template_file};
    }
}

## hash of template processing vars
sub template_vars {
    my $self = shift;
    if (@_) {
	$self->{template_vars} = shift;
	return $self;
    } else {
	return $self->{template_vars};
    }
}

## process the template file
sub process {
    my $self = shift;
    my $file = $self->file;

    return ($self->file_not_found) unless (-e $file);

    $self->processor( $self->default_processor ) unless $self->processor;

    my $output = $self->process_template;

    my $response = new OpenFrame::Response;
    $response->code( ofOK );
    $response->message( $output );

    return $response;
}

## override this method
sub process_template {
    my $self = shift;
    throw OpenFrame::WebApp::Error::Abstract( class => ref($self) );
}

## what to do when template file is not found
sub file_not_found {
    my $self = shift;
    throw OpenFrame::WebApp::Template::Error(
					     flag     => eTemplateNotFound,
					     template => $self->file,
					    );
}


1;

__END__

=head1 DESCRIPTION

The C<OpenFrame::WebApp::Template> class is an abstract wrapper around a
template system like C<Template::Toolkit>, C<HTML::Template>, C<Petal>, etc.

This class was meant to be used with C<OpenFrame::WebApp::Template::Factory>.

=head1 METHODS

=over 4

=item types

set/get the hash of $template_types => $class_names known to this class.

=item processor()

set/get the template processor (ie: tt2 instance).

=item file()

set/get local path to template file.

=item template_vars()

set/get hash of template processing variables.

=item process()

process the template file with the template processing variables, and produce
an OpenFrame::Response with the result.  throws an
C<OpenFrame::WebApp::Template::Error> if there was a problem.

=back

=head1 SUB-CLASSING

Read through the source of this package and the known sub-classes first.
The minumum you need to do is this:

  use base qw( OpenFrame::WebApp::Template );

  OpenFrame::WebApp::Template->types->{my_type} = __PACKAGE__;

  sub default_processor {
      return new Some::Template::Processor();
  }

  sub process_template {
      ...
      throw OpenFrame::WebApp::Template::Error( ... ) if ($error);
      return $output;
  }

You must register your template type if you want to use the Template::Factory.

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

Inspired by C<OpenFrame::AppKit::Segment::TT2> by James A. Duncan.

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<OpenFrame::WebApp::Template::Factory>,
L<OpenFrame::WebApp::Template::Error>,
L<OpenFrame::WebApp::Template::TT2>,
L<OpenFrame::WebApp::Template::Petal>,

=cut
