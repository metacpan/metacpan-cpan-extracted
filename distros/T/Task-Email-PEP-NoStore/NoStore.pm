package Task::Email::PEP::NoStore;
use strict;
use warnings;

=head1 NAME

Task::Email::PEP::NoStore - every Perl Email Project distribution... except Email::Store

=head1 SYNOPSIS

  $ cpanp install Task::Email::PEP::NoStore

=head1 DESCRIPTION

This is a L<Task>-style bundle of the latest version of every PEP-maintaned
module, as of the time of bundle-construction.  It does not include
Email::Store or its plugins, as those drastically increase the prerequisite
chain.

=head1 VERSION

version 8100.021

=cut

our $VERSION = '8100.021';

=head2 CONTENTS

Data::Message                      1.011 - Parse and Reconstruct RFC2822 Compliant Messages             

Email::ARF::Report                 0.003 - interpret Abuse Reporting Format (ARF) messages              

Email::Abstract                    2.134 - unified interface to mail representations                    

Email::Address                     1.882 - RFC 2822 Address Parsing and Creation                        

Email::Address                     1.889 - RFC 2822 Address Parsing and Creation                        

Email::Date                        1.103 - Find and Format Date Headers                                 

Email::Date::Format                1.002 - produce RFC 2822 date strings                                

Email::Delete                      1.022 - Delete Messages from Folders                                 

Email::Filter                      1.031 - Library for creating easy email filters                      

Email::Folder                      0.854 - read all the messages from a folder as Email::Simple objects.

Email::Folder::IMAP                1.102 - Email::Folder Access to IMAP Folders                         

Email::Folder::IMAPS               1.102 - Email::Folder Access to IMAP over SSL Folders                

Email::Folder::POP3                1.013 - Email::Folder Access to POP3 Folders                         

Email::FolderType                  0.813 - determine the type of a mail folder                          

Email::FolderType::Net             1.041 - Recognize folder types for network based message protocols.  

Email::LocalDelivery               0.217 - Deliver a piece of email - simply                            

Email::MIME                        1.861 - Easy MIME message parsing.                                   

Email::MIME::Attachment::Stripper  1.314 - Strip the attachments from a mail                            

Email::MIME::ContentType           1.014 - Parse a MIME Content-Type Header                             

Email::MIME::Creator               1.454 - Email::MIME constructor for starting anew.                   

Email::MIME::Encodings             1.311 - A unified interface to MIME encoding and decoding            

Email::MIME::Modifier              1.442 - Modify Email::MIME Objects Easily                            

Email::MIME::XPath                 0.004 - access MIME documents via XPath queries                      

Email::MessageID                   1.351 - Generate world unique message-ids.                           

Email::Reply                       1.202 - Reply to a Message                                           

Email::Send                        2.192 - Simply Sending Email                                         

Email::Send::IO                    2.200 - Send messages using IO operations                            

Email::Send::IO                    2.200 - Send messages using IO operations                            

Email::Sender                      0.001 - it sends mail                                                

Email::Simple                      2.003 - simple parsing of RFC2822 message format and headers         

Email::Simple::Creator             1.424 - build an Email::Simple object from scratch                   

Email::Simple::FromHandle          0.050 - an Email::Simple but from a handle                           

Email::Simple::Headers             1.030 - (DEPRECATED) get all headers of an Email::Simple             

Email::Stuff                       2.04  - A more casual approach to creating and sending Email:: emails

Email::Thread                      0.711 - Use JWZ's mail threading algorithm with Email::Simple objects

Email::Valid                       0.179 - Check validity of Internet email addresses                   

MIME::Lite                         3.021 - low-calorie MIME generator                                   

Mail::Audit                        2.222 - Library for creating easy mail filters                       

Mail::Audit::DKIM                  0.002 - Mail::Audit plugin for domain key verification               

Mail::Audit::List                  1.852 - Mail::Audit plugin for automatic list delivery               

Mail::Audit::PGP                   1.701 - Mail::Audit plugin for PGP header fixing                     

Mail::DeliveryStatus::BounceParser 1.518 - Perl extension to analyze bounce messages                    

Mail::LocalDelivery                0.304 - Deliver mail to a local mailbox                              

Mail::LocalDelivery                0.304 - Deliver mail to a local mailbox                              

Mail::SpamAssassin::SimpleClient   0.005 - easy client to SpamAssassin's spamd                          

Net::Server::Mail                  0.16  - Class to easily create a mail server                         


=head2 PERL EMAIL PROJECT

This bundle is maintained by the Perl Email Project.

  http://emailproject.perl.org/wiki/Task::Email::PEP::NoStore

=head2 SEE ALSO

http://emailproject.perl.org/

=head2 COPYRIGHT

This code is copyright (C) 2006, Ricardo SIGNES.  It is released under the same
terms as perl itself.  No claims are made, here, as to the copyrights of the
software pointed to by this bundle.

=cut

1;
