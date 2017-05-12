use strict;
use warnings;
use v5.8.0;

package Nexus::Uploader;
$Nexus::Uploader::VERSION = '1.0.0';

# ABSTRACT: Upload files to a Sonatype Nexus instance. Modelled on L<CPAN::Uploader>.

use utf8;
use Moose;

use Carp;
use JSON;
use MIME::Base64;
use REST::Client;
use Log::Any qw($log);

use namespace::autoclean;


has username => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => 'anonymous',
);


has password => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => '',
);


has nexus_URL => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => 'http://localhost:8081/repository/maven-releases',
);


has group =>
    ( is => 'ro', isa => 'Str', required => 1, default => 'AUTHORID', );


has artefact => ( is => 'ro', isa => 'Str', required => 1, );


has version => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


around [qw(group artefact)] => sub {
    my $orig  = shift;
    my $self  = shift;
    my $value = $self->$orig;
    $value =~ s/::/-/g;
    $value =~ s#/#.#g;
    return $value;
};


sub upload_file {
    my $self    = shift;
    my $archive = shift;
    if ( !-f $archive ) {
        croak "Unable to find file '$archive'\n";
    }
    my $arguments = shift;
    if ($arguments) {
        my $uploader = __PACKAGE__->new(%$arguments);
        return $uploader->upload_file($archive);
    }

    use Data::Dumper;
    $log->debug( Dumper($self) );

    my $headers = {
        Accept        => 'application/json',
        Authorization => 'Basic '
            . encode_base64( $self->username . ':' . $self->password )
    };

    my $Nexus = REST::Client->new();
    $Nexus->setFollow(1);
    my $artefact_URL =

        join( '/',
        $self->nexus_URL, $self->group, $self->artefact, $self->version,
        $self->artefact . '-' . $self->version . '.tar.gz' );
    $log->debug($artefact_URL);
    $Nexus->PUT( $artefact_URL, $archive, $headers );
    $log->debug( $Nexus->responseCode() );
    my $rc = $Nexus->responseCode();

    if ( 400 <= $rc && $rc <= 599 ) {
        croak( "HTTP error $rc: " . $Nexus->responseContent() );
    }
}


sub log {
    my $self = shift;
    $log->info(@_);
}


sub log_debug {
    my $self = shift;
    $log->debug(@_);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Nexus::Uploader - Upload files to a Sonatype Nexus instance. Modelled on L<CPAN::Uploader>.

=head1 VERSION

version 1.0.0

=head1 ATTRIBUTES

=head2 username

This is the Nexus user to log in with. It defaults to C<anonymous>.

=head2 password

The Nexus password. It is *strongly* advised that you take advantage of the Nexus user tokens feature!

Default is the empty string.

=head2 nexus_URL

The Nexus URL (base URL) to use. Defaults to L<http://localhost:8081/repository/maven-releases>.

=head2 group

The group to use when uploading. The C<group> is a Maven concept, and the best approximation to CPAN is probably the CPAN author ID.

Defaults to C<AUTHORID> if not provided.

=head2 artefact

The artefact name to use when uploading - there is no default. A good value for CPAN modules would be the distribution name.

=head2 version

The version of the artefact being uploaded. There is no default.

=head2 group and artefact processing

C<group> and C<artefact> atrributes have colons and full stops modified as follows:

  :: goes to -
  . goes to /

This is in order to maintain compatibility with Maven's conventions.

=head1 METHODS

=head2 upload_file

The method that does the grunt work of uploading (via a PUT request) to a standard Nexus repository, i.e. not the Staging suite.

  Nexus::Uploader->upload_file($file, \%arguments);

  $uploader->upload_file($file);

Valid C<%arguments> are the attributes specified above.

=head2 log

Included for compatibility with L<CPAN::Uploader> - passes straight through to the C<info> logging level.

=head2 log_debug

Included for compatibility with L<CPAN::Uploader> - passes straight through to the C<debug> logging level.

=head1 SEE ALSO

- L<CPAN::Uploader>

=head1 AUTHOR

Brad Macpherson <brad@teched-creations.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Brad Macpherson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
