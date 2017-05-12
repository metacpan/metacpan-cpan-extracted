package Solstice::CGI;

=head1 NAME

Solstice::CGI - For getting the CGI form parameters.

=head1 SYNOPSIS

  use Solstice::CGI;

  my $q = param('q');  # param is exported automagically

=head1 DESCRIPTION

This gets module exports the &param() function by default so you can
get form parameters from the Apache request object.

=cut

use 5.006_000;
use strict;
use warnings;

our ($VERSION) = ('$Revision$' =~ /^\$Revision:\s*([\d.]*)/);

use Solstice::Server;
use CGI;

use base qw(Solstice::Service Exporter);
our @EXPORT = qw(param upload getURLParams getURLParam);
our @EXPORT_OK = qw(header);

=head2 Export

=over 4

=cut


=item param($string)

Gets a CGI parameter.

=cut

sub param {
    _fixArgs(\@_);

    my $server = Solstice::Server->new();
    return $server->param(@_);
}

=item header(%options)

Gets the http header that you would print.

=cut

sub header {
    _fixArgs(\@_);
    return CGI->new()->header(@_);
}


sub _setNamedURLParams {
    my $self = shift;
    my $args = shift;

    $self->set('named_url_arg_list', $args);
}



=item _setURLArgs

=cut

sub _setURLParams {
    my $self = shift;
    my $args = shift;

    $self->set('url_arg_list', $args);
}


sub getURLParam {
    my $name = shift;
    return Solstice::CGI->get('named_url_arg_list') ? Solstice::CGI->get('named_url_arg_list')->{$name} : undef;
}

=item getURLParams

=cut

sub getURLParams {
    my $args = Solstice::CGI->get('url_arg_list') || [];
    return @{$args};
}

=back

=head2 Methods 

=over 4

=cut

=item new()

You may optionally create a Solstice::CGI object and call methods on it 
instead of using the default exported subroutines.

=cut

sub new {
    return bless {}, shift;
}

=item upload($param)

Returns an Apache::Upload object, or undef if there was an error.

=cut

sub upload {
    _fixArgs(\@_);

    my $server = Solstice::Server->new();

    if ($server->getUploadSuccessful()) {
        return $server->getUpload(shift);
    }
}

=back

=head2 Private Functions

=over 4

=cut

=item _fixArgs(\@_)

Modifies the argument list in place to get rid of $self if present.

=cut

sub _fixArgs {
    my $args = shift;
    if (defined $args->[0] && ref($args->[0]) eq 'Solstice::CGI') {
        shift(@$args);
    }
}


1;

__END__

=back

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision$



=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
