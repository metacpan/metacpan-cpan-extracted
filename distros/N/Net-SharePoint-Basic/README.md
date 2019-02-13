

# perl-net-sharepoint-basic

## Overview
Net::SharePoint::Basic - Basic interface to Microsoft SharePoint REST API.

This module provides a basic interface for managing the Shared Folders catalog in the Microsoft SharePoint site via its REST API. In the current version only the following actions are supported:

 * generating a connection token
 * upload file or string
 * download file content and save it
 * list contents of folder
 * create new folder
 * delete file or folder
 * copy an object to a different location
 * move an object to a different location
 
More actions are expected to be added in the future as well as we plan to increase the versatility of the arguments accepted by this module and the sample implementation of a client, 'sp-client', that comes with it.

The interface is object oriented. A few constants are exported.

The full testing (and naturally the full usage) of the module requires a working SharePoint site configuration. The structure of the configuration file will be described in this manual as well. The sample configuration file provided in this distribution will not work against SharePoint and plays the role of a placeholder only.

## Try it out

### API interface

    use Net::SharePoint::Basic;

    my $sp = Net::SharePoint::Basic->new({config_file => 'sharepoint.conf'});
    # creates Shared Documents/test
    my $response = $sp->makedir({retries => 1}, '/test');
    # uploads a string as Shared Documents/test/teststring
    $sp->upload({}, '/test/teststring', 'abcd');
    # uploads a file 'testfile' into Shared Documents/test/
    $sp->upload({type => 'file'}, '/test/', 'testfile');
    # downloads contents of a file
    $sp->download({}, '/test/teststring');
    # downloads contents and saves it to a file
    $sp->download({save_file => 'testfile'}, '/test/teststring');
    # lists contents of a folder
    $sp->list({}, '/test');
    # deletes the folder
    $sp->delete({}, '/test');

### Provided basic CLI tool sp-client

```
Usage: scripts/sp-client -h|--help | -V|--version | [-v|--verbose | -d|--debug] [ -f|--config-file CONFIG_FILE ] [ -t|---token-file FILE ] [ -l|--log-file FILE ] [ --retries RETRIES ] [ --max-log-size SIZE] [ --chunk-size SIZE ] CMD SHAREPOINTPATH {LOCALPATH|SHAREPOINT-TARGET}
Options:
 	-h|--help                 print this message and exit
	-V|--version              print version of the package and exit
	-v|--verbose              produce verbose output to STDERR
	-d|--debug                produce debug output to STDERR
	-f|--config-file CONFIG   use CONFIG file instead of
	                          /etc/sharepoint.conf
	-t|--token-file  FILE     use token file FILE instead of
	                          /var/run/sharepoint.token
	   --retries     RETRIES  set the number of retries to RETRIES
	                          instead of 3
	   --max-log-size SIZE    set the max log history size to SIZE
	                          instead of 500000
	   --chunk-size   SIZE    set the upload chunk size to SIZE
	                          instead of 200000000
Arguments:
	CMD                       command, one of
	                          copy, delete, download, list, makedir, move, upload
	SHAREPOINTPATH            remote path to operate upon
	LOCALPATH                 {for upload or download}
	                          files to upload into sharepoint or
	                           path to store the download
	                          OR
	SHAREPOINT-TARGET         {for copy and move}
                                  destination for moved or copied object
Note: use delete for both files and folders
```
### Prerequisites

* Perl v5.10.1 or above
* Perl Modules:
  - experimental
  - JSON::XS
  - LWP::UserAgent
  - IO::Scalar
  - File::Path
  - URI::Escape
  
For the full list consult the 'requires' section of Build.PL - some of these modules come with Perl itself.

### Build & Run

To install this module, run the following commands:

1. perl Build.PL
2. ./Build
3. ./Build test
4. ./Build install

For later, releases of an RPM and a DEB package are planned.

## Documentation

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Net::SharePoint::Basic

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-SharePoint-Basic

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Net-SharePoint-Basic

    CPAN Ratings
        http://cpanratings.perl.org/d/Net-SharePoint-Basic

    Search CPAN
        http://search.cpan.org/dist/Net-SharePoint-Basic/
	
    GitHub Repository
        https://github.com/vmware/perl-net-sharepoint-basic

## Releases & Major Branches

The package is primarily released on CPAN, but may be released as an RPM or DEB as well. It may also be built as RPM or DEB by Linux distributions maintainers independently from us.

## Contributing

The team welcomes contributions from the community. If you wish to contribute code and you have not signed our contributor license agreement (CLA), our bot will update the issue when you open a Pull Request. For any
questions about the CLA process, please refer to our [FAQ](https://cla.vmware.com/faq). For more detailed information,
refer to [CONTRIBUTING.md](CONTRIBUTING.md).

## License
Copyright (C) 2018-2019 VMware Inc. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [LICENSE.txt](LICENSE.txt) for more information.
