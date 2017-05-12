use strict;
use warnings;

package Parse::PAUSE;
our $VERSION = '1.001';


use Scalar::Util qw(blessed);
use Module::Pluggable require => 1;

sub parse {
    my ($class, $content) = @_;

    for my $plugin ($class->plugins()) {
        my $parsed_content_obj = $plugin->_process($content);

        if (
            defined $parsed_content_obj and
            ref $parsed_content_obj and
            blessed $parsed_content_obj and
            $parsed_content_obj->does('Parse::PAUSE::Plugin')
        ) {
            return $parsed_content_obj;
        }
    }

    return;
}

1;

__END__

=head1 NAME

Parse::PAUSE - Parses CPAN upload emails sent by PAUSE

=head1 VERSION

version 1.001

=head1 SYNOPSIS

  use Parse::PAUSE;

  my $content = 'The uploaded file...'; # body of CPAN upload email from PAUSE
  my $upload  = Parse::PAUSE->parse($content);

  print $upload->pathname(), "\n"; # $CPAN/authors/id/S/SU/SUKRIA/Coat-Persistent-0.104.tar.gz
  print $upload->entered_by(), "\n"; # SUKRIA (Alexis Sukrieh)

=head1 DESCRIPTION

Given the content of a CPAN upload email sent by PAUSE, this module will
parse the content, and return an object which can be queried for the
discrete bits of information about the upload.

=head1 SUBROUTINES/METHODS

The public API of this class exposes the following:

=head2 CLASS METHODS

=over 4

=item * B<parse>

Parses given content of a CPAN upload email sent by PAUSE. Returns an object
that can be queried on success and undef on failure. Newlines will be
automatically normalized.

=back

=head2 OBJECT METHODS

=over 4

=item * B<upload>

Returns the uploaded filename or URL. For example: "Coat-Persistent-0.104.tar.gz".

=item * B<pathname>

Returns the CPAN path of the upload. For example: "$CPAN/authors/id/S/SU/SUKRIA/Coat-Persistent-0.104.tar.gz".

=item * B<size>

Returns the size of the upload. For example: "24105".

=item * B<md5>

Returns the MD5 checksum of the upload. For example: "5f84687ad671b675c6e2936c7b2b3fd7".

=item * B<entered_by>

Returns the Perl author of the upload. For example: "SUKRIA (Alexis Sukrieh)".

=item * B<entered_on>

Returns the datetime of upload. For example: "Fri, 05 Jun 2009 17:10:00 GMT".

=item * B<completed>

Returns the datetime that paused completed servicing the upload. For example: "Fri, 05 Jun 2009 17:11:11 GMT".

=item * B<paused_version>

Returns the version of paused that processed the upload. For example: "1047".

=back

=head1 DIAGNOSTICS

This module throws no exceptions. If the content is unparseable, the
constructor, parse, will return undef.

=head1 CONFIGURATION AND ENVIRONMENT

This module does not employ any configuration nor environment variables.

=head1 DEPENDENCIES

=over 4

=item * B<Moose>

=item * B<Encode>

=item * B<Encode::Newlines>

=item * B<Module::Pluggable>

=item * B<Scalar::Util>

=back

=head1 INCOMPATIBILITIES

No known incompatibilities.

=head1 BUGS AND LIMITATIONS

Please report any issues to: http://github.com/afoxson/parse-pause/issues

=head1 AUTHOR

Adam J. Foxson <afoxson@pobox.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009 Adam J. Foxson. All rights reserved.

=head1 LICENSE

This program is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut