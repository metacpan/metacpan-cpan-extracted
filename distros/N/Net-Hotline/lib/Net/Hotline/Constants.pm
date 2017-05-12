package Net::Hotline::Constants;

## Copyright(c) 1998-2002 by John C. Siracusa.  All rights reserved.  This
## program is free software; you can redistribute it and/or modify it under
## the same terms as Perl itself.

use strict;

use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS $VERSION %HTLC_COLORS);

$VERSION = '0.80';

require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw(
HTLC_CHECKBYTES HTLC_COLORS HTLC_DATA_BAN HTLC_DATA_CHAT HTLC_DATA_DESTDIR
HTLC_DATA_DIRECTORY HTLC_DATA_FILE HTLC_DATA_FILE_RENAME HTLC_DATA_HTXF_SIZE
HTLC_DATA_ICON HTLC_DATA_LOGIN HTLC_DATA_MSG HTLC_DATA_NEWS_POST
HTLC_DATA_NICKNAME HTLC_DATA_OPTION HTLC_DATA_PASSWORD HTLC_DATA_PCHAT_REF
HTLC_DATA_PCHAT_SUBJECT HTLC_DATA_RFLT HTLC_DATA_SOCKET HTLC_DEFAULT_ICON
HTLC_DEFAULT_LOGIN HTLC_DEFAULT_NICK HTLC_EWOULDBLOCK HTLC_FOLDER_TYPE
HTLC_HDR_CHAT HTLC_HDR_FILE_DELETE HTLC_HDR_FILE_GET HTLC_HDR_FILE_GETINFO
HTLC_HDR_FILE_LIST HTLC_HDR_FILE_MKDIR HTLC_HDR_FILE_MOVE HTLC_HDR_FILE_PUT
HTLC_HDR_FILE_SETINFO HTLC_HDR_LOGIN HTLC_HDR_MSG HTLC_HDR_NEWS_GETFILE
HTLC_HDR_NEWS_POST HTLC_HDR_PCHAT_ACCEPT HTLC_HDR_PCHAT_CLOSE
HTLC_HDR_PCHAT_CREATE HTLC_HDR_PCHAT_DECLINE HTLC_HDR_PCHAT_INVITE
HTLC_HDR_PCHAT_SUBJECT HTLC_HDR_USER_CHANGE HTLC_HDR_USER_CREATE
HTLC_HDR_USER_GETINFO HTLC_HDR_USER_GETLIST HTLC_HDR_USER_KICK
HTLC_HDR_USER_OPEN HTLC_INFO_FALIAS_TYPE HTLC_INFO_FOLDER_TYPE
HTLC_MACOS_TO_UNIX_TIME HTLC_MAGIC HTLC_MAGIC_LEN HTLC_MAX_PATHLEN
HTLC_NEWLINE HTLC_PATH_SEPARATOR HTLC_TASK_BAN HTLC_TASK_FILE_DELETE
HTLC_TASK_FILE_GET HTLC_TASK_FILE_INFO HTLC_TASK_FILE_LIST
HTLC_TASK_FILE_MKDIR HTLC_TASK_FILE_MOVE HTLC_TASK_FILE_PUT HTLC_TASK_KICK
HTLC_TASK_LOGIN HTLC_TASK_NEWS HTLC_TASK_NEWS_POST HTLC_TASK_PCHAT_ACCEPT
HTLC_TASK_PCHAT_CREATE HTLC_TASK_SEND_MSG HTLC_TASK_SET_INFO
HTLC_TASK_USER_INFO HTLC_TASK_USER_LIST HTLC_UNIX_TO_MACOS_TIME
HTLS_DATA_AGREEMENT HTLS_DATA_CHAT HTLS_DATA_COLOR HTLS_DATA_FILE_COMMENT
HTLS_DATA_FILE_CREATOR HTLS_DATA_FILE_CTIME HTLS_DATA_FILE_ICON
HTLS_DATA_FILE_LIST HTLS_DATA_FILE_MTIME HTLS_DATA_FILE_NAME
HTLS_DATA_FILE_SIZE HTLS_DATA_FILE_TYPE HTLS_DATA_HTXF_REF HTLS_DATA_HTXF_SIZE
HTLS_DATA_ICON HTLS_DATA_MSG HTLS_DATA_NEWS HTLS_DATA_NEWS_POST
HTLS_DATA_NICKNAME HTLS_DATA_PCHAT_REF HTLS_DATA_PCHAT_SUBJECT
HTLS_DATA_SERVER_MSG HTLS_DATA_SOCKET HTLS_DATA_TASK_ERROR HTLS_DATA_USER_INFO
HTLS_DATA_USER_LIST HTLS_HDR_AGREEMENT HTLS_HDR_CHAT HTLS_HDR_MSG
HTLS_HDR_NEWS_POST HTLS_HDR_PCHAT_INVITE HTLS_HDR_PCHAT_SUBJECT
HTLS_HDR_PCHAT_USER_JOIN HTLS_HDR_PCHAT_USER_LEAVE HTLS_HDR_POLITE_QUIT
HTLS_HDR_TASK HTLS_HDR_USER_CHANGE HTLS_HDR_USER_LEAVE HTLS_MAGIC
HTLS_MAGIC_LEN HTLS_TCPPORT HTRK_MAGIC HTRK_MAGIC_LEN HTRK_TCPPORT
HTRK_UDPPORT HTXF_BUFSIZE HTXF_MAGIC HTXF_MAGIC_LEN HTXF_PARTIAL_CREATOR
HTXF_PARTIAL_TYPE HTXF_RESUME_MAGIC HTXF_RFLT_MAGIC HTXF_TCPPORT
PATH_SEPARATOR SIZEOF_HL_DATA_HDR SIZEOF_HL_FILE_FORK_HDR
SIZEOF_HL_FILE_LIST_HDR SIZEOF_HL_FILE_UPLOAD_HDR SIZEOF_HL_FILE_XFER_HDR
SIZEOF_HL_LONG_HDR SIZEOF_HL_PROTO_HDR SIZEOF_HL_SHORT_HDR
SIZEOF_HL_TASK_FILLER SIZEOF_HL_USER_LIST_HDR MACOS_MAX_FILENAME
HTLS_DATA_REPLY HTLS_DATA_IS_REPLY);

%EXPORT_TAGS = ('all' => \@EXPORT_OK);

use constant PATH_SEPARATOR => ($^O eq 'MacOS') ? ':' : '/';

%HTLC_COLORS = (0 => 'gray',
                1 => 'black',
                2 => 'red',
                3 => 'pink');

# Hotline gives times relative to Mac OS epoch.  Add this constant to the
# times returned by Hotline to get the time since the unix epoch.
use constant HTLC_MACOS_TO_UNIX_TIME => -2082830400;

# Add this constant to Unix times to get Hotline (Mac OS) times
use constant HTLC_UNIX_TO_MACOS_TIME =>  2082830400;

use constant HTLC_PATH_SEPARATOR   => ':';

use constant HTLC_FOLDER_TYPE      => 'fldr';
use constant HTXF_PARTIAL_TYPE     => 'HTft';
use constant HTXF_PARTIAL_CREATOR  => 'HTLC';

use constant HTLC_INFO_FOLDER_TYPE => 'Folder';
use constant HTLC_INFO_FALIAS_TYPE => 'Folder Alias';

use constant HTLC_DEFAULT_NICK     => 'guest';
use constant HTLC_DEFAULT_LOGIN    => 'guest';
use constant HTLC_DEFAULT_ICON     => 410;

use constant HTLC_EWOULDBLOCK      => 2; # Can be anything > 1, really

use constant HTLC_MAX_PATHLEN      => 255;
use constant MACOS_MAX_FILENAME    => 31;

# Arbitrary unique task type constants
use constant HTLC_TASK_FILE_DELETE  => 1;
use constant HTLC_TASK_FILE_GET     => 2;
use constant HTLC_TASK_FILE_INFO    => 3;
use constant HTLC_TASK_FILE_LIST    => 4;
use constant HTLC_TASK_FILE_MKDIR   => 5;
use constant HTLC_TASK_FILE_MOVE    => 6;
use constant HTLC_TASK_FILE_PUT     => 7;
use constant HTLC_TASK_KICK         => 8;
use constant HTLC_TASK_LOGIN        => 9;
use constant HTLC_TASK_NEWS         => 10;
use constant HTLC_TASK_NEWS_POST    => 11;
use constant HTLC_TASK_SEND_MSG     => 12;
use constant HTLC_TASK_SET_INFO     => 13;
use constant HTLC_TASK_USER_INFO    => 14;
use constant HTLC_TASK_USER_LIST    => 15;
use constant HTLC_TASK_PCHAT_CREATE => 16;
use constant HTLC_TASK_PCHAT_ACCEPT => 17;
use constant HTLC_TASK_BAN          => 18;

use constant HTRK_TCPPORT   => 5498;
use constant HTRK_UDPPORT   => 5499;
use constant HTLS_TCPPORT   => 5500;
use constant HTXF_TCPPORT   => 5501;

use constant HTXF_BUFSIZE   => 4096;

use constant HTLC_NEWLINE   => "\015";

use constant HTLC_MAGIC        => pack("C12", 84, 82, 84, 80, 72, 79, 84, 76, 0, 1, 0, 2);
use constant HTLC_MAGIC_LEN    => 12;
use constant HTLS_MAGIC        => pack("C8", 84, 82, 84, 80, 0, 0, 0, 0);
use constant HTLS_MAGIC_LEN    => 8;
use constant HTRK_MAGIC	       => pack("C6", 72, 84, 82, 75, 0, 1);
use constant HTRK_MAGIC_LEN    => 6;
use constant HTXF_MAGIC	       => pack("C4", 72, 84, 88, 70);
use constant HTXF_MAGIC_LEN    => 4;
use constant HTXF_RFLT_MAGIC   => pack("C4", 82, 70, 76, 84);
use constant HTXF_RESUME_MAGIC => pack("n3", 0x00CC, 0x0002, 0x0001);

use constant HTLC_HDR_CHAT              => 0x00000069;
use constant HTLC_HDR_FILE_DELETE       => 0x000000CC;
use constant HTLC_HDR_FILE_GET          => 0x000000CA;
use constant HTLC_HDR_FILE_GETINFO      => 0x000000CE;
use constant HTLC_HDR_FILE_LIST         => 0x000000C8;
use constant HTLC_HDR_FILE_MKDIR        => 0x000000CD;
use constant HTLC_HDR_FILE_MOVE         => 0x000000D0;
use constant HTLC_HDR_FILE_PUT          => 0x000000CB;
use constant HTLC_HDR_FILE_SETINFO      => 0x000000CF;
use constant HTLC_HDR_LOGIN             => 0x0000006B;
use constant HTLC_HDR_MSG               => 0x0000006C;
use constant HTLC_HDR_NEWS_GETFILE      => 0x00000065;
use constant HTLC_HDR_NEWS_POST         => 0x00000067;
use constant HTLC_HDR_PCHAT_ACCEPT      => 0x00000073;
use constant HTLC_HDR_PCHAT_CLOSE       => 0x00000074;
use constant HTLC_HDR_PCHAT_CREATE      => 0x00000070;
use constant HTLC_HDR_PCHAT_DECLINE     => 0x00000072;
use constant HTLC_HDR_PCHAT_INVITE      => 0x00000071;
use constant HTLC_HDR_PCHAT_SUBJECT     => 0x00000078;
use constant HTLC_HDR_USER_CHANGE       => 0x00000130;
use constant HTLC_HDR_USER_CREATE       => 0x0000015E;
use constant HTLC_HDR_USER_GETINFO      => 0x0000012F;
use constant HTLC_HDR_USER_GETLIST      => 0x0000012C;
use constant HTLC_HDR_USER_KICK         => 0x0000006E;
use constant HTLC_HDR_USER_OPEN         => 0x00000160;

use constant HTLC_DATA_BAN              => 0x0071;
use constant HTLC_DATA_CHAT             => 0x0065;
use constant HTLC_DATA_DESTDIR          => 0x00D4;
use constant HTLC_DATA_DIRECTORY        => 0x00CA;
use constant HTLC_DATA_FILE             => 0x00C9;
use constant HTLC_DATA_FILE_RENAME      => 0x00D3;
use constant HTLC_DATA_HTXF_SIZE        => 0x006C;
use constant HTLC_DATA_ICON             => 0x0068;
use constant HTLC_DATA_LOGIN            => 0x0069;
use constant HTLC_DATA_MSG              => 0x0065;
use constant HTLC_DATA_NEWS_POST        => 0x0065;
use constant HTLC_DATA_NICKNAME         => 0x0066;
use constant HTLC_DATA_OPTION           => 0x006D;
use constant HTLC_DATA_PASSWORD         => 0x006A;
use constant HTLC_DATA_PCHAT_REF        => 0x0072;
use constant HTLC_DATA_PCHAT_SUBJECT    => 0x0073;
use constant HTLC_DATA_RFLT             => 0x00CB;
use constant HTLC_DATA_SOCKET           => 0x0067;

use constant HTLS_HDR_AGREEMENT         => 0x0000006D;
use constant HTLS_HDR_CHAT              => 0x0000006A;
use constant HTLS_HDR_MSG               => 0x00000068;
use constant HTLS_HDR_NEWS_POST         => 0x00000066;
use constant HTLS_HDR_PCHAT_INVITE      => 0x00000071;
use constant HTLS_HDR_PCHAT_SUBJECT     => 0x00000077;
use constant HTLS_HDR_PCHAT_USER_JOIN   => 0x00000075;
use constant HTLS_HDR_PCHAT_USER_LEAVE  => 0x00000076;
use constant HTLS_HDR_POLITE_QUIT       => 0x0000006F;
use constant HTLS_HDR_TASK              => 0x00010000;
use constant HTLS_HDR_USER_CHANGE       => 0x0000012D;
use constant HTLS_HDR_USER_LEAVE        => 0x0000012E;

use constant HTLS_DATA_AGREEMENT        => 0x0065;
use constant HTLS_DATA_CHAT             => 0x0065;
use constant HTLS_DATA_COLOR            => 0x0070;
use constant HTLS_DATA_REPLY            => 0x00D6;
use constant HTLS_DATA_IS_REPLY         => 0x0071;
use constant HTLS_DATA_ICON             => 0x0068;
use constant HTLS_DATA_NEWS             => 0x0065;
use constant HTLS_DATA_NICKNAME         => 0x0066;
use constant HTLS_DATA_SERVER_MSG       => 0x006D;
use constant HTLS_DATA_SOCKET           => 0x0067;
use constant HTLS_DATA_TASK_ERROR       => 0x0064;
use constant HTLS_DATA_USER_INFO        => 0x0065;
use constant HTLS_DATA_USER_LIST        => 0x012C;

use constant HTLS_DATA_FILE_COMMENT     => 0x00D2;
use constant HTLS_DATA_FILE_CREATOR     => 0x00CE;
use constant HTLS_DATA_FILE_CTIME       => 0x00D0;
use constant HTLS_DATA_FILE_ICON        => 0x00D5;
use constant HTLS_DATA_FILE_LIST        => 0x00C8;
use constant HTLS_DATA_FILE_MTIME       => 0x00D1;
use constant HTLS_DATA_FILE_NAME        => 0x00C9;
use constant HTLS_DATA_FILE_SIZE        => 0x00CF;
use constant HTLS_DATA_FILE_TYPE        => 0x00CD;
use constant HTLS_DATA_HTXF_REF         => 0x006B;
use constant HTLS_DATA_HTXF_SIZE        => 0x006C;
use constant HTLS_DATA_MSG              => 0x0065;
use constant HTLS_DATA_NEWS_POST        => 0x0065;
use constant HTLS_DATA_PCHAT_REF        => 0x0072;
use constant HTLS_DATA_PCHAT_SUBJECT    => 0x0073;

use constant SIZEOF_HL_PROTO_HDR        => 20;
use constant SIZEOF_HL_DATA_HDR         => 4;
use constant SIZEOF_HL_SHORT_HDR        => 6;
use constant SIZEOF_HL_LONG_HDR         => 8;
use constant SIZEOF_HL_FILE_LIST_HDR    => 24;
use constant SIZEOF_HL_USER_LIST_HDR    => 12;
use constant SIZEOF_HL_TASK_FILLER      => 2;
use constant SIZEOF_HL_FILE_XFER_HDR    => 40;
use constant SIZEOF_HL_FILE_UPLOAD_HDR  => 111;
use constant SIZEOF_HL_FILE_FORK_HDR    => 16;

1;
