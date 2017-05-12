=head1 NAME

OpenFrame::WebApp::Template::Error - Template errors

=head1 SYNOPSIS

  use OpenFrame::WebApp::Template::Error;
  throw OpenFrame::WebApp::Template::Error( flag     => eTemplateError,
                                            message  => $text,
                                            template => $file );

=cut


package OpenFrame::WebApp::Template::Error;

use utf8;
use strict;
use warnings::register;

our $VERSION = (split(/ /, ' $Revision: 1.3 $ '))[2];
our @EXPORT  = qw( eTemplateError eTemplateNotFound );

use base qw( Exporter OpenFrame::WebApp::Error );

use constant eTemplateError    => 'error.template.process';
use constant eTemplateNotFound => 'error.template.not.found';

sub new {
    my $class = shift;
    local $Error::Depth = $Error::Depth + 1;
    $class->SUPER::new(map { /^((?:message)|(?:template))$/ ? "-$1" : $_; } @_);
}

sub message {
    my $self = shift;
    if (@_) {
	$self->{-message} = shift;
	return $self;
    } else {
	return $self->{-message};
    }
}

sub template {
    my $self = shift;
    if (@_) {
	$self->{-template} = shift;
	return $self;
    } else {
	return $self->{-template};
    }
}


1;


__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Template Error class.  Inherits interface from C<OpenFrame::WebApp::Error>.

=head1 EXPORTED FLAGS

 eTemplateError
 eTemplateNotFound

=head1 METHODS

=over 4

=item message

set/get error message emitted by the template processing engine (if any).

=item template

set/get template file associated with this error (if any).

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<OpenFrame::WebApp::Error>, L<OpenFrame::WebApp::Template>

=cut


