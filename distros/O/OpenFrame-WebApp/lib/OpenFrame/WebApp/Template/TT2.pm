=head1 NAME

OpenFrame::WebApp::Template::TT2 - a TT2 template processing wrapper

=head1 SYNOPSIS

  use OpenFrame::WebApp::Template::TT2;

  my $tmpl = new OpenFrame::WebApp::Template::TT2;
  $tmpl->file( $local_file_path )
       ->template_vars( { fred => fish } );

  $response = $tmpl->process;

=cut

package OpenFrame::WebApp::Template::TT2;

use strict;
use warnings::register;

use Error qw( :try );
use Template;
use OpenFrame::WebApp::Template::Error;

use base qw( OpenFrame::WebApp::Template );

our $VERSION = (split(/ /, '$Revision: 1.10 $'))[1];

our $TT2 = new Template;

## set/get the TT2 processor
sub tt2 {
    my $self = shift;
    if (@_) {
	$TT2 = shift;
	return $self;
    } else {
	return $TT2;
    }
}

## use tt2 as default
sub default_processor {
    my $self = shift;
    return $self->tt2;
}

## process the template file
sub process_template {
    my $self = shift;

    my $output;
    $self->processor->process( $self->file, $self->template_vars, \$output );

    unless ($output) {
	throw OpenFrame::WebApp::Template::Error(
						 flag     => eTemplateError,
						 template => $self->file,
						 message  => $self->processor->error->as_string,
						);
    }

    return $output;
}


1;

__END__

=head1 DESCRIPTION

The C<OpenFrame::WebApp::Template::TT2> class is wrapper around the
C<Template::Toolkit>.  It inherits its functionality from
L<OpenFrame::WebApp::Template>

=head1 TEMPLATE TYPE

tt2

=head1 METHODS

=over 4

=item tt2( [ $template ] )

set/get the TT2 singleton of this class.  a default is created when the class
is loaded.

=back

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

Based on C<OpenFrame::AppKit::Segment::TT2>, by James A. Duncan.

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<Template>,
L<OpenFrame::WebApp::Template>,
L<OpenFrame::WebApp::Template::Factory>

=cut
