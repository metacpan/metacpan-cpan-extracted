#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <netinet/sctp.h>

MODULE = Net::SIGTRAN::SCTP PACKAGE = Net::SIGTRAN::SCTP 

int _socket()
CODE:
   RETVAL = socket( AF_INET, SOCK_STREAM, IPPROTO_SCTP );
OUTPUT:
   RETVAL

int _bind(listenSock,portnumber)
int listenSock
int portnumber
CODE:
   struct sockaddr_in servaddr;
   struct sctp_initmsg initmsg;
   bzero( (void *)&servaddr, sizeof(servaddr) );
   servaddr.sin_family = AF_INET;
   servaddr.sin_addr.s_addr = htonl( INADDR_ANY );
   servaddr.sin_port = htons(portnumber);
   bind( listenSock, (struct sockaddr *)&servaddr, sizeof(servaddr) );
   /* Specify that a maximum of 5 streams will be available per socket */
   memset( &initmsg, 0, sizeof(initmsg) );
   initmsg.sinit_num_ostreams = 5;
   initmsg.sinit_max_instreams = 5;
   initmsg.sinit_max_attempts = 4;
   setsockopt( listenSock, IPPROTO_SCTP, SCTP_INITMSG,&initmsg, sizeof(initmsg) );

   /* Place the server socket into the listening state */
   listen( listenSock, 5 );

   RETVAL=listenSock;
OUTPUT:
   RETVAL

int _connect(connSock,hostname,portnumber)
int connSock
char *hostname
int portnumber
CODE:
   int in;
   struct sockaddr_in servaddr;
   struct sctp_status status;
   struct sctp_event_subscribe events;
   struct sctp_initmsg initmsg;

   /* Specify that a maximum of 5 streams will be available per socket */
   memset( &initmsg, 0, sizeof(initmsg) );
   initmsg.sinit_num_ostreams = 5;
   initmsg.sinit_max_instreams = 5;
   initmsg.sinit_max_attempts = 4;
   setsockopt( connSock, IPPROTO_SCTP, SCTP_INITMSG, &initmsg, sizeof(initmsg) );

   /* Specify the peer endpoint to which we'll connect */
   bzero( (void *)&servaddr, sizeof(servaddr) );
   servaddr.sin_family = AF_INET;
   servaddr.sin_port = htons(portnumber);
   servaddr.sin_addr.s_addr = inet_addr(hostname);

   /* Connect to the server */
   connect( connSock, (struct sockaddr *)&servaddr, sizeof(servaddr) );

   /* Enable receipt of SCTP Snd/Rcv Data via sctp_recvmsg */
   memset( (void *)&events, 0, sizeof(events) );
   events.sctp_data_io_event = 1;
   setsockopt( connSock, SOL_SCTP, SCTP_EVENTS, (const void *)&events, sizeof(events) );

   /* Read and emit the status of the Socket (optional step) */
   in = sizeof(status);
   getsockopt( connSock, SOL_SCTP, SCTP_STATUS,
                     (void *)&status, (socklen_t *)&in );

   printf("assoc id  = %d\n", status.sstat_assoc_id );
   printf("state     = %d\n", status.sstat_state );
   printf("instrms   = %d\n", status.sstat_instrms );
   printf("outstrms  = %d\n", status.sstat_outstrms );

   RETVAL=connSock;
OUTPUT:
   RETVAL
 
int _accept(listenSock)
int listenSock
CODE:
   int connSock;
   int in;
   struct sctp_status status;

   //printf("Socket: %d\n",listenSock);
   connSock = accept( listenSock, (struct sockaddr *)NULL, (int *)NULL );

   /* Read and emit the status of the Socket (optional step) */
   in = sizeof(status);
   getsockopt( connSock, SOL_SCTP, SCTP_STATUS,
                     (void *)&status, (socklen_t *)&in );

   printf("assoc id  = %d\n", status.sstat_assoc_id );
   printf("state     = %d\n", status.sstat_state );
   printf("instrms   = %d\n", status.sstat_instrms );
   printf("outstrms  = %d\n", status.sstat_outstrms );

   RETVAL=connSock;
OUTPUT:
   RETVAL

int _recieve(connSock,buffer,buffersize)
int connSock
char *buffer
int buffersize
CODE:
   int oi, i,len,flags;
   char *tempbuffer;
   struct sctp_sndrcvinfo sndrcvinfo;
   tempbuffer = (char*) malloc(buffersize+1);
   len=sctp_recvmsg( connSock, (void *)tempbuffer, buffersize,
      (struct sockaddr *)NULL, 0, &sndrcvinfo, &flags );
   if (len>0) { 
      //printf("buffer leng %d\n",len);
      buffer = (char*) malloc((len*2)+1);
      //printf("After malloc\n");
      //buffer[0]=0;
      for (i=0;i<len;i++) {
         oi=(unsigned int)tempbuffer[i];
         if (oi<0) oi+=256;
         sprintf(buffer+(i*2),"%02x",oi);
         //printf("%d ",oi);
         //sprintf(buffer+(i*2),"%02x",ord(tempbuffer[i]));
         //sprintf(buffer+(i*2),"%02x",(unsigned int)tempbuffer[i]);
    //     sprintf(buffer,"%x",tempbuffer[i]);
    //     buffer+=2;
      }
      //printf("\n");
      buffer[len*2]=0;
      //printf("Buffer=%s\n",buffer);
   } else {
      buffer = (char*) malloc(1);
      buffer[0]=0;
   }
   free(tempbuffer);
   RETVAL=len;
OUTPUT:
   buffer
   RETVAL

int _send(connSock,ppid,flags,stream_no,timetolive,context,buffersize,buffer)
int connSock
unsigned long ppid
unsigned long flags
unsigned int stream_no
unsigned long timetolive
unsigned long context
unsigned long buffersize
char *buffer
CODE:
   //printf("Sending ppid=%lu, flags=%lu, stream_no=%lu, timetolive=%lu, context=%lu, buffersize=%lu\n",ppid,flags,stream_no,timetolive,context,buffersize);
   RETVAL= sctp_sendmsg( connSock, (void *)buffer, buffersize,
                         NULL, 0, ppid, flags, stream_no, timetolive, context );
   //printf("SCTP PDU Sent\n");
OUTPUT:
   RETVAL

void _close(connSock)
int connSock
CODE:
   close(connSock);

