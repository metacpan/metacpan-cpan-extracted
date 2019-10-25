# QMail::QueueHandler

Perl library for dealing with QMail queues

## Introduction

QMail::QueueHandler is a Perl library for handling QMail mail queues.

It is based on [qmHandle](http://qmhandle.sourceforge.net/), a command line program written
by Michele Beltrame, but rewritten to take advantage of modern Perl techniques.

The QMail::QueueHandler distribution contains a new version of qmHandle which has much
the same functionality as the original version.

## Installation

You need a working installation of Qmail for this to work properly. It
looks for QMail queues in all the standard places.

## qmHandle

qmHandle accepts a number of command-line options.

* a: (Attempt to) send all queued messages
* l: List message queues
* L: List local message queue
* R: List remote message queue
* N: List message numbers only
* c: Coloured output
* s: Show statistics of queues
* m <id>: Display message with given number
* f <id>: Delete messages from given sender
* F <id>: Delete messages from given sender (regex match)
* d <id>: Delete message with given number
* S <subj>: Delete messages with matching subject
* h <header>: Delete messages with matching header (case insensitive)
* b <body>: Delete messages with matching body (case insensitive)
* H <body>: Delete messages with matching header (case sensitive)
* B <body>: Delete messages with matching body (case sensitive)
* t <email_addr>: Flag messages with matching recipients
* D: Delete all messages in queues
* V: Display program version
* ?: Display help

## Author

QMail::QueueHandler is written by Dave Cross - dave(at)perlhacks.com, based on
original work by Michele Beltrame.
