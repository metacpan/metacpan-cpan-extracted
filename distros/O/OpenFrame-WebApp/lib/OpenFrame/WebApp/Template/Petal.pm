=head1 NAME

OpenFrame::WebApp::Template::Petal - a Petal template processing wrapper

=head1 SYNOPSIS

  use OpenFrame::WebApp::Template::Petal;

  my $tmpl = new OpenFrame::WebApp::Template::Petal;
  $tmpl->file( $local_file_path )
       ->template_vars( { fred => fish } )
       ->processor( new Petal( %args ) ); # optional

  try {
      $response = $tmpl->process;
  } catch OpenFrame::WebApp::Template::Error with {
      my $e = shift;
      print $e->flag, $e->message;
  }

=cut

package OpenFrame::WebApp::Template::Petal;

use strict;
use warnings::register;

use Petal;
use Error qw( :try );
use OpenFrame::WebApp::Template::Error;

use base qw( OpenFrame::WebApp::Template );

our $VERSION = (split(/ /, '$Revision: 1.7 $'))[1];


## use new petal instance as default
sub default_processor {
    my $self = shift;
    $Petal::INPUT = 'XHTML';
    return new Petal( $self->file );
}

## always need a new petal processor, if one was not already set:
sub process {
    my $self = shift;

    my $undef_processor = $self->processor ? 0 : 1;

    my $ofResult = $self->SUPER::process(@_);

    $self->processor( undef ) if $undef_processor;

    return $ofResult;
}

## process the template file
sub process_template {
    my $self = shift;

    my $output;
    eval {
	$output = $self->processor->process( $self->template_vars );
    };

    unless ($output) {
	throw OpenFrame::WebApp::Template::Error(
						 flag     => eTemplateError,
						 template => $self->file,
						 message  => $@,
						);
    }

    return $output;
}


1;

__END__

=head1 DESCRIPTION

The C<OpenFrame::WebApp::Template::Petal> class is wrapper around Petal.
It inherits its functionality from L<OpenFrame::WebApp::Template>.

Uses XHTML Petal input by default, set processor() manually to override this.

=head1 TEMPLATE TYPE

petal

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<Petal>,
L<OpenFrame::WebApp::Template>,
L<OpenFrame::WebApp::Template::Factory>

=cut
