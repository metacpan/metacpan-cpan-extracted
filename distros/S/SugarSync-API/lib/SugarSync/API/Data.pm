#! perl

=head1 SugarSync API description

=head2 Requirements

A valid SugarSync user name, with password.

A valid SugarSync developer access key id with private access key.

=head2 Authorization

POST the following XML to C<https://api.sugarsync.com/authorization>.

    <?xml version="1.0" encoding="UTF-8"?>
    <authRequest>
	<username>$username</username>
	<password>$password</password>
	<accessKeyId>$akeyid</accessKeyId>
	<privateAccessKey>$pacckey</privateAccessKey>
    </authRequest>

The result is a small XML data package.

    HTTP/1.1 201 Created
    Connection: close
    Date: Wed, 31 Aug 2011 11:15:57 GMT
    Accept-Ranges: bytes
    Location: https://api.sugarsync.com/authorization/Oz3odjluQU6n6RCA
    Server: Noelios-Restlet-Engine/1.1.5
    Content-Type: application/xml; charset=UTF-8
    Client-Date: Wed, 31 Aug 2011 11:15:57 GMT
    Client-Peer: 74.201.86.35:443
    Client-Response-Num: 1
    Client-SSL-Cert-Issuer: /C=US/ST=Arizona/L=Scottsdale/O=GoDaddy.com, Inc./OU=http://certificates.godaddy.com/repository/CN=Go Daddy Secure Certification Authority/serialNumber=07969287
    Client-SSL-Cert-Subject: /O=*.sugarsync.com/OU=Domain Control Validated/CN=*.sugarsync.com
    Client-SSL-Cipher: AES256-SHA
    Client-SSL-Warning: Peer certificate not verified

    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <authorization>
      <expiration>2011-08-31T05:15:57.516-07:00</expiration>
      <user>https://api.sugarsync.com/user/123456</user>
    </authorization>

Most important is the Location: header of the result:

    Location: https://api.sugarsync.com/authorization/Oz3odjluQU6n6RCA

This url (which is much longer than shown here) has to be passed as
Authorization: header to all subsequent calls. 

Note that it is only of limited validity, e.g., 1 hour.

=head2 Requests

When autorization is complete, further requests are common https:
get requests. Almost all of them return XML data. For convenience,
the XML data is shown here as a Perl structure.

WARNING: When transforming the XML to Perl (e.g., with XML::Simple)
be careful about repeating entries. E.g.,

  <foo>
   <bar>111</bar>
   <bar>222</bar>
  <foo>

will return { foo => [ 111, 222 ] }, but

  <foo>
   <bar>111</bar>
  <foo>

will return { foo => 111 }

=head3 User info

Get C<https://api.sugarsync.com/user>.

Returns:

    {
      'quota' => {
	 'usage' => '94055',
	 'limit' => '6039797760'
      },
      'salt' => 'C2c4DA==',
      'webArchive' => 'https://api.sugarsync.com/folder/:sc:123456:1',
      'publicLinks' => 'https://api.sugarsync.com/user/123456/publicLinks/contents',
      'mobilePhotos' => 'https://api.sugarsync.com/folder/:sc:123456:3',
      'nickname' => 'happyreader',
      'deleted' => 'https://api.sugarsync.com/folder/:sc:123456:9',
      'albums' => 'https://api.sugarsync.com/user/123456/albums/contents',
      'username' => 'happyreader@example.com',
      'receivedShares' => 'https://api.sugarsync.com/user/123456/receivedShares/contents',
      'magicBriefcase' => 'https://api.sugarsync.com/folder/:sc:123456:2',
      'workspaces' => 'https://api.sugarsync.com/user/123456/workspaces/contents',
      'syncfolders' => 'https://api.sugarsync.com/user/123456/folders/contents',
      'recentActivities' => 'https://api.sugarsync.com/user/123456/recentActivities/contents'
    };

=head3 receivedShares

Get the receivedShares url from the user info.

Returns:

    {
      'receivedShare' => [
	{
	  'owner' => 'https://api.sugarsync.com/contact/123456/654321',
	  'permissions' => {
	    'readAllowed' => {
	      'enabled' => 'true'
	    },
	    'writeAllowed' => {
	      'enabled' => 'false'
	    }
	  },
	  'timeReceived' => '2011-08-21T06:00:14.000-07:00',
	  'ref' => 'https://api.sugarsync.com/receivedShare/123456/:sc:654321:186_8178842',
	  'sharedFolder' => 'https://api.sugarsync.com/folder/:sc:654321:186_8178842',
	  'displayName' => 'boeken'
	}
      ]
    };

=head3 sharedFolder

Returns slightly more detailed data for the shared folder.

    {
      'sharing' => {
	'shareList' => 'https://api.sugarsync.com/sharelist/:sc:654321:186_8178842',
	'readAllowed' => {
	  'enabled' => 'true'
	},
	'writeAllowed' => {
	  'enabled' => 'false'
	},
	'enabled' => 'true'
      },
      'parent' => 'https://api.sugarsync.com/folder/:sc:654321:2',
      'files' => 'https://api.sugarsync.com/folder/:sc:654321:186_8178842/contents?type=file',
      'collections' => 'https://api.sugarsync.com/folder/:sc:654321:186_8178842/contents?type=folder',
      'contents' => 'https://api.sugarsync.com/folder/:sc:654321:186_8178842/contents',
      'dsid' => '/sc/654321/186_8178842',
      'timeCreated' => '2011-08-20T10:41:52.000-07:00',
      'displayName' => 'boeken'
    };

As all folders, the sharedFolder can contain files and collections
(subfolders). Retrieving the contents link returns both files and
folders:

    {
      'collection' => [
	{
	  'ref' => 'https://api.sugarsync.com/folder/:sc:654321:186_8179242',
	  'contents' => 'https://api.sugarsync.com/folder/:sc:654321:186_8179242/contents',
	  'type' => 'folder',
	  'displayName' => 'AA'
	},
	{
	  'ref' => 'https://api.sugarsync.com/folder/:sc:654321:4497561_97048',
	  'contents' => 'https://api.sugarsync.com/folder/:sc:654321:4497561_97048/contents',
	  'type' => 'folder',
	  'displayName' => 'BB'
	},
      ],
      'file' => {
          'fileData' => 'https://api.sugarsync.com/file/:sc:654321:4497561_327763/data',
          'lastModified' => '2011-08-28T23:03:48.000-07:00',
          'presentOnServer' => 'true',
          'mediaType' => 'application/octet-stream',
          'ref' => 'https://api.sugarsync.com/file/:sc:654321:4497561_327763',
          'size' => '695067',
          'displayName' => 'De woorden van Babel - Andreu Carranza.epub'
      },
      'hasMore' => 'false',
      'end' => '26',
      'start' => '0'
    };

This example shows one file and two collections. Note that files and
collections may be returned as scalars instead of ARRAYs if there's
only one element. See XML::Simple for details.

Also note the hasMore attribute, that (I assume) indicates whether all
data was returned with this call. Likewise, start and end seem to
indicate the first and last entry. I haven't found out what to do in
case hasMore is true.

=head3 Collections

See L<sharedFolder>,

=head3 Files

To retrieve file data, use a normal https get.

For a mirror, you might want to set the file times according to the
lastModified attribute.

=head1 Miscellaneous

When the authorization token expires, you'll get a HTTP 401
Unauthorized result. Renew the token and retry.

Server errors like 503 Server unavailable may occur. 

=cut
