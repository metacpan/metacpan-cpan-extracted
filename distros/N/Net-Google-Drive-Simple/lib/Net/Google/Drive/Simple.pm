###########################################
package Net::Google::Drive::Simple;
###########################################

use strict;
use warnings;

use constant {
    'DEFAULT_VERSION'     => 2,
    'RECOMMENDED_VERSION' => 3,
};

use Net::Google::Drive::Simple::V2;
use Net::Google::Drive::Simple::V3;

our $VERSION = '3.02';

###########################################
sub new {
###########################################
    my ( $class, %options ) = @_;

    my $version = $options{'version'} || DEFAULT_VERSION();
    if ( $version != DEFAULT_VERSION() && $version != RECOMMENDED_VERSION() ) {
        die "Incorrect version number ($version) - must be '2' or '3'";
    }

    my $impl =
      $version == DEFAULT_VERSION()
      ? Net::Google::Drive::Simple::V2->new(%options)
      : Net::Google::Drive::Simple::V3->new(%options);

    return $impl;
}

1;

__END__

=head1 NAME

Net::Google::Drive::Simple - Simple modification of Google Drive data

=head1 SYNOPSIS

    use feature 'say';
    use Net::Google::Drive::Simple;

    # requires a ~/.google-drive.yml file with an access token,
    # see description below.
    my $gd = Net::Google::Drive::Simple->new( 'version' => 3 ); # v3 interface (RECOMMENDED!)
    my $gd = Net::Google::Drive::Simple->new();                 # v2 interface (OUTDATE!)

    my $children = $gd->children( "/" ); # or any other folder /path/location

    foreach my $item ( @$children ) {

        # item is a Net::Google::Drive::Simple::Item object

        if ( $item->is_folder ) {
            say "** ", $item->title, " is a folder";
        } else {
            say $item->title, " is a file ", $item->mimeType;
            eval { # originalFilename not necessary available for all files
              say $item->originalFilename(), " can be downloaded at ", $item->downloadUrl();
            };
        }
    }

=head1 DESCRIPTION

Net::Google::Drive::Simple authenticates with a user's Google Drive and
offers several convenience methods to list, retrieve, and modify the data
stored in the 'cloud'. See C<eg/google-drive-upsync> as an example on how
to keep a local directory in sync with a remote directory on Google Drive.

All methods are documented based on the version you use:

=over 4

=item * V3 (recommended)

    # Create default V3 API:
    my $gd = Net::Google:Drive::Simple->new( 'version' => 3 );

The methods available are documented in
L<Net::Google::Drive::Simple::V3>.

=item * V2 (default, outdated)

    # Create default V2 API:
    my $gd = Net::Google:Drive::Simple->new();

    # or:
    my $gd = Net::Google:Drive::Simple->new( 'version' => 2 );

The methods available are documented in
L<Net::Google::Drive::Simple::V2>.

=back

=head2 GETTING STARTED

To get the access token required to access your Google Drive data via
this module, you need to run the script C<eg/google-drive-init> in this
distribution.

Before you run it, you need to register your 'app' with Google Drive
and obtain a client_id and a client_secret from Google:

    https://developers.google.com/drive/web/enable-sdk

Click on "Enable the Drive API and SDK", and find "Create an API project in
the Google APIs Console". On the API console, create a new project, click
"Services", and enable "Drive API" (leave "drive SDK" off). Then, under
"API Access" in the navigation bar, create a client ID, and make sure to
register a an "installed application" (not a "web application"). "Redirect
URIs" should contain "http://localhost". This will get you a "Client ID"
and a "Client Secret".

Then, replace the following lines in C<eg/google-drive-init> with the
values received:

      # You need to obtain a client_id and a client_secret from
      # https://developers.google.com/drive to use this.
    my $client_id     = "XXX";
    my $client_secret = "YYY";

Then run the script. It'll start a web server on port 8082 on your local
machine.  When you point your browser at http://localhost:8082, you'll see a
link that will lead you to Google Drive's login page, where you authenticate
and then allow the app (specified by client_id and client_secret above) access
to your Google Drive data. The script will then receive an access token from
Google Drive and store it in ~/.google-drive.yml from where other scripts can
pick it up and work on the data stored on the user's Google Drive account. Make
sure to limit access to ~/.google-drive.yml, because it contains the access
token that allows everyone to manipulate your Google Drive data. It also
contains a refresh token that this library uses to get a new access token
transparently when the old one is about to expire.

=head1 METHODS

=over 4

=item C<new()>

Constructor, creates a helper object to retrieve Google Drive data
later.

While v2 (the outdated version) is still supported by Google, we
recommend you use v3:

    # Returns object of Net::Google::Drive::Simple::V3
    my $gd = Net::Google::Drive::Simple->new( 'version' => 3 );

    # Returns object of Net::Google::Drive::Simple::V2
    my $gd = Net::Google::Drive::Simple->new( 'version' => 2 );
    # or:
    my $gd = Net::Google::Drive::Simple->new();

Read up on the methods in each class: L<Net::Google::Drive::Simple::V3>
and L<Net::Google::Drive::Simple::V2>.

=back

=head1 Error handling

In case of an error while retrieving information from the Google Drive
API, the methods above will return C<undef> and a more detailed error
message can be obtained by calling the C<error()> method:

    print "An error occurred: ", $gd->error();

=head1 LOGGING/DEBUGGING

Net::Google::Drive::Simple is Log4perl-enabled.
To find out what's going on under the hood, turn on Log4perl:

    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($DEBUG);

=head1 LEGALESE

Copyright 2012-2019 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2019, Nicolas R. <cpan@atoomic.org>
2012-2019, Mike Schilli <cpan@perlmeister.com>
