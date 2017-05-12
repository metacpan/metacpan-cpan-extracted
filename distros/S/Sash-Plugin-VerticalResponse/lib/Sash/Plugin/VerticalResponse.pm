package Sash::Plugin::VerticalResponse;

use strict;
use warnings;

our $VERSION = '1.02';

use Carp;

use base qw( Sash::Plugin::Base );
use Sash::Plugin::VerticalResponse::Command;
use Sash::Plugin::VerticalResponse::Cursor;

sub connect {
    my $class = shift;
    my $args = shift; # hashref

    # First make sure we have the appropriate environment variables defined.
    $ENV{HTTPS_PKCS12_FILE} = $args->{terminal}->prompt_for( 'Certificate File' )
        unless defined $ENV{HTTPS_PKCS12_FILE};
        
    $ENV{HTTPS_PKCS12_PASSWORD} = $args->{terminal}->prompt_for( 'Passphrase' )
        unless defined $ENV{HTTPS_PKCS12_PASSWORD};
    
    $ENV{VR_API_SOAP_ENDPOINT} = $args->{endpoint};
    
    # Confusing nomenclature here.  The client specified in the CLI is
    # really the name of the class to use to interact with the API.
    my $client_class = $args->{client} || 'VR::API';

    eval "use $client_class";
    croak $@ if $@;
        
    my $client;

    eval {
        $client = $client_class->new;
        $client->login( $args );
        
        $class->client( $client );
    }; if ( $@ ) {
        croak $class . '->connect Cannot connect to VerticalResponse API using endpoint ' . $args->{endpoint} . "\n$@";
    }
}

=head1 NAME

Sash::Plugin::VerticalResponse

=head1 VERSION

This documentation refers to version 1.01.

=head1 SYNOPSIS

    sash> set output tabular
    
    sash> getUserByEmailAddress wes@verticalresponse.com
    
    sash> set output vertical
    
    sash> getCompany( { company_id = 12344 } )
    
    sash> set output perlval
    
    sash> $user = $client->getUserByEmailAddresss( { email_address => 'wes@verticalresponse.com' } )
    
    sash> x $user

=head1 DESCRIPTION

This is a plugin for the amazing sash tool that provides a command line interface
to the VerticalResponse API L<http://www.verticalresponse.com/api>.  It can be used
to invoke methods available in the API as well as a development tool to write and debug
applications written in perl.

B<NOTE>: VRAPI will be used in this documentation to refer to the VerticalResponse API.

=head1 CONNECTING

There are a few ways to instruct sash to connect to the VRAPI.  The simplest method
is to define the L<ENVIRONMENT VARIABLES> listed in the section below.  Then you
can simply type sash at the command prompt and get started.  The other option is
to use the traditional command line with the available L</FLAGS> illustrated below:.

    wes:~> sash -u wes@verticalresponse.com -e https://api.verticalresponse.com/1.0/VRAPI
    password:
    
    Certificate File: /a/secret/igotacertificatefile.p12
    
    Passphrase:
    Connection to https://api.verticalresponse.com/1.0/VRAPI established!
    
    Welcome to sash.  Commands end with the familiar ; or press 'return'.
    Type 'help' for the complete command reference.
    
    sash>

You will be prompted for the certificate file and its passphrase when you use the
command line flags.

=head2 Environment Variables

=over 4

=item *

B<SASH_USERNAME>

Your VR account username.

=item *

B<SASH_PASSWORD>

Obvious heh?

=item *

B<SASH_ENDPOINT>

Define the endpoint to be https://api.verticalresponse.com/1.0/VRAPI

=item *

B<SASH_CLIENT>

This is defaulted to VR::API but partners should define it to be VR::API::Partner

=item *

B<HTTPS_PKCS12_FILE> 

The location of your certificate file (I<required> by VR::API).

=item *

B<HTTPS_PKCS12_PASSWORD>

The password tied to your certificate file if defined.

=back

=head2 Flags

=over 4

=item *

B<-u, -user>

Your VR account username

=item *

B<-p, -password>

You can define your password on the command line but you probably shouldn't.

=item *

B<-e, -endpoint>

Define the endpoint to be https://api.verticalresponse.com/1.0/VRAPI

=item *

B<-client>

This is defaulted to VR::API but partners should define it to be VR::API::Partner

=item *

B<-f, -filename>

You can give sash a perl script to run on your behalf. Typically this is run in
conjunction with the interactive flag.

=item *

B<-i, -interactive>

If you have run the plugin with the B<-f> flag then when you specify this flag
you are given a I<sash> command prompt with the last result of the executed
script available to you.  See the L<Predefined Variables> section in L</PROGRAMMING>
for more information on taking advantage of this built in feature.

=back

=head1 COMMANDS

Typically the API consists of methods that can be invoked by an external application.
In the case of sash it acts in that role but gives an easier to use interface to
provide access to those methods.  Think of it like the mysql command line tool to the
VRAPI.  You enter a I<command> and it displays a result set.

=head2 show

This command behaves like a standard I<sash> command.

=head3 methods
    
At the present time the only available argument is I<methods>.  This will display
a listing of the methods available in the VRAPI as illustrated below:

    sash> show methods
    +--------------------------------------------+
    | Methods                                    |
    +--------------------------------------------+
    | addListMember                              |
    | ...                                        |
    | validateStreetAddress                      |
    +--------------------------------------------+

    43 rows in set (0.00 sec)

Not very exciting but useful when you want to recall the exact spelling of method.
Sometime in a future release I would like to add support for getting the signature
of the method but we will have to wait for that.

=head2 set

The intention of this command is to allow you to configure aspects of the plugin.

=head3 output [tabular|vertical|perlval]

There is more detail in the L<OUTPUT FORMATS> section of this document but you can
configure the way results of command are displayed.

=head2 VRAPI Methods

All of the VRAPI methods are available as commands in this plugin.  To use them
you have to know the signature of the method you want to use and be able to construct
the appropriate argument.  If you are familiar with Perl then you won't have any
trouble understanding the example below:

    sash> getUserByEmailAddress { email_address => 'wesley_bailey@yahoo.com' }
    +--------------------+------------------------------+
    | Attribute          | Value                        |
    +--------------------+------------------------------+
    | row                |                            1 |
    +--------------------+------------------------------+
    
    ...

The argument to the command is in the form of a Perl anonymous hash.  Hashes in
their simples format are a series of I<key/value> pairs.  Use the I<fat comma> =>
to indicate the I<value> identified by I<key>.  You use a standard comma to seperate
multiple pairs.  The key does not have to be enclosed in quotes if its a single
word but the I<value> must be if you are enclosing a I<string>.  Single or double
quotes are valid.  The example below a call to create a list using I<sash>:

    sash> createList { name => 'sash tester 123' , type => 'email' }
    +-----------+----------+
    | Attribute | Value    |
    +-----------+----------+
    | row       |        1 |
    +-----------+----------+
    | List ID   | 89000184 |
    +-----------+----------+

You can also use data structures as a valid I<value> in your hash.  The following
example shows how to use anonymous arrays as well and how to code the
I<NVDictionary> (L<http://api.verticalresponse.com/wsdl/1.0/documentation.html>)
datatype:

    sash> addListMember { list_member => { \
    
    > list_id => 89000184, member_data => [ \
    
    > { name => 'first_name' , value => 'Wes' }, \
    
    > { name => 'last_name', value => 'Bailey' }, \
    
    > { name => 'email_address', value => 'wesley_bailey@nowhere.com' } \
    
    > ] } }
    +---------------------------+---------------------------+
    | Attribute                 | Value                     |
    +---------------------------+---------------------------+
    | row                       |                         1 |
    +---------------------------+---------------------------+
    | address_1                 |                           |
    | address_2                 |                           |
    | address_hash              |                           |
    | city                      |                           |
    | country                   |                           |
    | create_date               | 2007-02-24 01:27:35       |
    | email_address             | wesley_bailey@nowhere.com |
    | fax                       |                           |
    | first_name                | Wes                       |
    | gender                    |                           |
    | hash                      | 5cb92e2116                |
    | home_phone                |                           |
    | id                        |                         1 |
    | ip_address                |                           |
    | last_name                 | Bailey                    |
    | last_updated              | 2007-02-24 01:27:35       |
    | list_id                   |                  89000184 |
    | list_name                 | sash\ tester\ 123         |
    | list_type                 | email                     |
    | marital_status            |                           |
    | mobile_phone              |                           |
    | optin_status              |                           |
    | optin_status_last_updated | 2007-02-24 01:27:35       |
    | postalcode                |                           |
    | state                     |                           |
    | work_phone                |                           |
    +---------------------------+---------------------------+
    
    1 rows in set (0.29 sec)

The above also illustrates how you can spread your command over multiple lines
when the argument is quite involved.

It is worth noting that to facilitate programming in the tool you can use
parenthesis to make it more like a traditional method invocation as illustrated
below:

    sash> deleteList( { list_id => 89000184 } )
    +--------------+
    | Deleted List |
    +--------------+
    |     89000184 |
    +--------------+
    
    1 rows in set (0.21 sec)

See more in the L</PROGRAMMING> setion of this document for more information regarding
these features

=head2 Simple Syntax

If you are intimidated by all of the syntax it is good to know that some commands
support a much simpler syntax such that just the values can be passed as arguments
without the need for parenthesis or the anonymous hashes and arrays.  For example
the I<deleteList> command can be written as:
    
    sash> deleteList 89000184
    

The following is a summary of the commands that support the simple syntax and what
the arguments are ( brackets indicate optional arguments ie [, field1, ...]:

=over 4

=item * calculateCampaignAudience campaign_id

=item * createList name, type [, custom_field1, custom_field2, ...]

=item * deleteList list_id

=item * enumerateLists list_id

=item * getCompany company_id [, include_users]

=item * getListMembers list_id

=item * getUser user_id

=item * getUserByEmailAddress email_address

=back

=head1 OUTPUT FORMATS

There are three different output formats that are available to configure the way
the result of a command is interpreted.

=head2 tabular

This is the default setting and is like the standard display by most command line
based database tools like mysql.  It displays a list of columns accross the page
with the labels accross the top.  An example is illustrated below:

    sash> getUserByEmailAddress wesley_bailey@yahoo.com
    +-----------+-----------+----------------+-----------+--------------+------+------------------+
    | address_1 | address_2 | auth_acct_mngr | auth_type | browser_type | city | company_function |
    +-----------+-----------+----------------+-----------+--------------+------+------------------+
    |           |           |                |           | M$ sucks 6   |      |                  |
    +-----------+-----------+----------------+-----------+--------------+------+------------------+
    
    1 rows in set (0.20 sec)
    
Of course for the interest of having readable documentation the above is not all
of the columns that get displayed, but you get the point of the display style.

=head2 vertical

Find the result above unreadable on your small display?  So do I so use vertical
instead and get:

    sash> set output vertical
    
    sash> getUserByEmailAddress joe@nowhere.com
    +--------------------+------------------------------+
    | Attribute          | Value                        |
    +--------------------+------------------------------+
    | row                |                            1 |
    +--------------------+------------------------------+
    | address_1          |                              |
    | address_2          |                              |
    | auth_acct_mngr     |                              |
    | auth_type          |                              |
    | browser_type       | M$ sucks 6                   |
    | ...                |                              |
    | use_logger         |                              |
    +--------------------+------------------------------+
    
    1 rows in set (0.21 sec)

=head2 perlval

This is an interesting option in that instead of trying to format the data for
output it instead just returns the perl code result.  I<Sash> is written in Perl
so you can script this plugin to prototype your application or test a piece of
code that is not working.  See the L</PROGRAMMING> section of this document for more
information on how to use this option to its fullest extent.

=head1 PROGRAMMING

The fun part of this VRAPI plugin for I<sash> is the builtin Perl support.  This means
that almost anything you can do in your Perl application you can try out at the command
prompt and it will work as you expect it to.  The following demonstrates a simple 
example:

    sash> set output perlval

    sash> $name = "Another Sash Example List";

    sash> $type = "email";

    sash> $list = createList( { name => $name, type => $type } );

    sash> open $fh, "</tmp/list.csv";

    sash> while ( <$fh> ) { $client->addListMember( \

        > { list_member => { list_id => $list->{id}, member_data => [ \

        > { name => 'email_address', value => $_ } \

        > ] } } ) }

    sash> close $fh;

In this simple example the file /tmp/list.csv is simply an email address on each line of
the file as illustrated below:

    wes@nowhere.com
    nick@nowhere.com
    lance@nowhere.com

It doesn't get much more simple but come to think of it is pretty damn powerful to be able
to have this kind of functionality in a command line tool isn't it?

To prove to yourself the above worked as expected you can view the results of your efforts
by running the following commands:

    sash> set output vertical

    sash> enumerateLists 89000199
    +-----------------------+-----------------------+
    | Attribute             | Value                 |
    +-----------------------+-----------------------+
    | row                   |                     1 |
    +-----------------------+-----------------------+
    | creation_date         | 2007-02-26T06:34:55Z  |
    | displayed_fields      |                       |
    | fields                |                       |
    | form_id               |                       |
    | id                    |              89000199 |
    | indexed_fields        |                       |
    | last_mailed           |                       |
    | mailable              |                     3 |
    | mailable_last_updated | 2007-02-26T06:36:18Z  |
    | name                  | another wes sash test |
    | size                  |                     3 |
    | status                | active                |
    | type                  | email                 |
    +-----------------------+-----------------------+

    1 rows in set (0.23 sec)

    sash> getListMembers 89000199
    +---------------------------+---------------------------+
    | Attribute                 | Value                     |
    +---------------------------+---------------------------+
    | row                       |                         1 |
    +---------------------------+---------------------------+
    | address_1                 |                           |
    | address_2                 |                           |
    | address_hash              |                           |
    | city                      |                           |
    | country                   |                           |
    | create_date               | 2007-02-26 06:36:18       |
    | email_address             | lance@nowhere.com |
    | fax                       |                           |
    ...

    3 rows in set (0.47 sec)
    
    sash> 

The inquisitive might note that I didn't define the variable C<$client> anywhere in my 
example.  Read the next section to understand how it was defined and how you can use it
as well without worry.

=head2 Predefined Variables

There are some predefined variables that this plugin makes available to facilitate
Perl programming from the command line that can then be transfered into your application
code.  The following is a summary:

=head3 C<$client>

In your application code you are most likely going to invoke the constructor of the
appropriate VR::API class that you are using in the following manner:

    $client = VR::API->new; 

Because this is a pretty standard way of writing you can also use the C<$client> syntax
when you invoke a command regardless of the output format you presently have set:

    sash> $client->getUserByEmailAddress( { email_address => 'wesley_bailey@nowhere.com' } );

This is really helpful when you have the output format set to I<perlval> so that your
command invocation looks and behaves just like it would in Perl:

    sash> set output perlval

    sash> $user = $client->getUserByEmailAddress( { email_address => 'wesley_bailey@yahoo.com' } )

To convince yourself that the variable C<$user> actually has the correct values see the
L</DEBUGGING> section below.

=head3 C<$result>

Any command that you execute that produces a result will have the Perl equivalent stored
in a variable named C<$result>.  This is useful if in the next command you want to refer
to any of the properties of result to be its arguments as demonstrated below:

    sash> getCompany( { id => $result->{company_id} } )

This is useful, but beware trying to result this code in your application unless you have
defined the VRAPI query to be a variable of the same name.

=head1 DEBUGGING

If you are familiar with the Perl debugger then you are used to examining the values
associated with variables at specific points in your program.  You can do the same
thing in sash by using the I<x> command as illustrated below:

    sash> x $user
    $user = bless( {
      "offer_optin" => undef,
      "auth_acct_mngr" => undef,
      "address_2" => undef,
      "state" => undef,
      "password_question" => "America/Los_Angeles",
      "os" => "Windows NT 5.1",
      "url" => undef,
      "postalcode" => undef,
      "id" => 79734,
    ...
      "first_name" => "wesley"
    }, 'User' );

Not quite the same format as in the Perl debugger but readable and it provides useful
information.  If you know perl you will recognize this is a format produced by L<Data::Dumper>.

=head1 EXPIRED SESSION

There are times when you have periods of inactivity and your session with the 
VRAPI expires.  You will suddenly get a fault that at first makes you think you
did something wrong illustrated below:

=over 4

Error while communicating with 
https://api.verticalresponse.com/1.0/VRAPI - SOAP Fault Code: 
SOAP-ENV:VRAPI.ExpiredSession: SOAP Fault String: The specified session_id has
expired -  at ...

=back

When this happens you can use the I<reconnect> or I<refresh> commands to
re-establish your connection to the VRAPI and use I<sash> normally.

=head1 AUTHOR

Wes Bailey, <wes@verticalresponse.com>

=head1 BUGS

When you find a bug in this plugin please contact the author.  There are some bugs
related to sash so please read the information regarding them.

=head1 SEE ALSO

L<sash>

L<VR::API>

L<VR::API::Partner>

=head1 COPYRIGHT

Copyright (C) 2007, Wes Bailey, VerticalResponse Inc.

This sash plugin is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This sash plugin is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

=cut

1;
