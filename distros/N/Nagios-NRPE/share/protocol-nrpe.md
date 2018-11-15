NRPE PROTOCOL
=============

This document shall describe the NRPE Protocol so people more
fortunate than the author can easily port NRPE into their own
application.

# Basic Communication

The communication between check_nrpe and nrped is as follows:

```
 .------------.                      .-------.
 |            |---Query-Packet------>|       |
 | check_nrpe |                      | nrped |
 |____________|<--Response-Packet----|_______|
 
```

## Structure of a packet sent to nrped

it uses the "packet" struct defined in "include/common.h"

### NRPE v. 2
```
typedef struct packet_struct{
	int16_t   packet_version;
	int16_t   packet_type;
	u_int32_t crc32_value;
	int16_t   result_code;
	char      buffer[MAX_PACKETBUFFER_LENGTH];
        }packet;

```
Values in the struct can be explained as following for a sent query:

```
| size(in byte) | type       | name           | description                                     | Value         |
|---------------+------------+----------------+-------------------------------------------------+---------------|
| 2             | int16_t    | packet_version | uint16_t of host byte network order (hostshort) | 1/2/3         |
| 2             | int16_t    | packet_type    | uint16_t query to the server                    | 1             |
| 4             | u_int32_t  | crc32_value    | checksum of the packet(htonl)                   | <checksum>    |
| 2             | int16_t    | result_code    | left empty on query                             | null          |
| 1024          | char[1024] | buffer         | Query with packet buffer length padded with     | "check_users" |
|               |            |                | randomized data and terminated with \x0         |               |
```

TCP Data looks like this:

```
|-------------+---------+------+-------+------------+----------|
| BYTE        | 0     1 | 2  3 | 4   7 | 8        9 | 10  1035 |
|-------------+---------+------+-------+------------+----------|
| DESCRIPTION | VERSION | TYPE | CRC32 | RESULTCODE | BUFFER   |
|-------------+---------+------+-------+------------+----------|
```

### NRPE v. 3

NRPE v. 3 works mostly like NRPE v. 2 but the length of the buffer is now of variable length. This means that the
length of the packet buffer must now be sent as a field in the packet. An alignment field is also added and the 
buffer is padded if it is shorter than 1024, so a v. 3 packet can be larger than a v. 2 packet, but not smaller.

```
typedef struct packet_struct{
	int16_t   packet_version;
	int16_t   packet_type;
	u_int32_t crc32_value;
	int16_t   result_code;
	int16_t   alignment;
	int32_t   buffer_length;
	char      buffer[];
        }packet;

```
Values in the struct can be explained as following for a sent query:

```
| size(in byte) | type       | name           | description                                     | Value         |
|---------------+------------+----------------+-------------------------------------------------+---------------|
| 2             | int16_t    | packet_version | uint16_t of host byte network order (hostshort) | 1/2/3         |
| 2             | int16_t    | packet_type    | uint16_t query to the server                    | 1             |
| 4             | u_int32_t  | crc32_value    | checksum of the packet(htonl)                   | <checksum>    |
| 2             | int16_t    | result_code    | left empty on query                             | null          |
| 2             | int16_t    | alignment      | alignment of the packet                         | 0             |
| 4             | int32_t    | buffer_length  | length of the buffer                            | <length>      |
| >= 1024       | char[]     | buffer         | packet buffer terminated  with \x0              | "check_users" |
```

TCP Data looks like this:

```
|-------------+---------+------+-------+------------+-----------+--------------+----------|
| BYTE        | 0     1 | 2  3 | 4   7 | 8        9 | 10     11 | 12        15 | 16     ? |
|-------------+---------+------+-------+------------+-----------+--------------+----------|
| DESCRIPTION | VERSION | TYPE | CRC32 | RESULTCODE | ALIGNMENT | BUFFERLENGTH | BUFFER   |
|-------------+---------+------+-------+------------+-----------+--------------+----------|
```

# Client Side

A short description of the workflow internal to check_nrpe:

 - calculate `crc32` for 0xEDB88320L
 
_IF IT WAS COMPILED WITH SSL_

 - (SSLeay) Start SSLv2/SSLv3 in clien mode context
 
_ENDIF_

 - Start TCP Connection: host,port,SOCKET

_IF IT WAS COMPILED WITH SSL_

 - Start Connection in SSL Context

_ENDIF_
 
 - build Packet

 - send packet
 
 - validate packet (crc32)
 
 - read response packet
 








