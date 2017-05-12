package Net::iContact;
# vim: set expandtab tabstop=4 shiftwidth=4 autoindent smartindent:
use warnings;
use strict;

use Carp qw/carp croak/;
use Digest::MD5 qw/md5_hex/;
use HTTP::Request::Common qw/PUT GET/;
use LWP::UserAgent;
use XML::Bare;
use Data::Dumper;

### Not importing; don't want XML::Generator's AUTOLOAD
require XML::Generator;

use constant API_BASE => 'http://api.icontact.com/icp/core/api/v1.0/';

our $VERSION = '0.02';
our $AUTOLOAD;

our %ok_field;
for (qw|error username password api_key secret token seq debug ua|) { $ok_field{$_}++ };

### catchall accessor
sub AUTOLOAD {
    my $name = $AUTOLOAD;
    $name =~ s/.*://;
    return if $name =~ /^[A-Z]+$/;

    carp "Invalid attribute or method" and return unless $ok_field{$name};
    return $_[0]->{$name};
}
sub new {
    $#_ >= 4 or croak "Invalid number of arguments";

    my ($class_name, $user, $pass, $api_key, $secret) = @_;
    my $debug = $_[5] if ($#_ == 5);

    $pass = md5_hex($pass);
    my ($self) = {  'username' => $user,
                    'password' => $pass,
                    'api_key'  => $api_key,
                    'secret'   => $secret,
                    ## Token and sequence number are given to us by
                    ## the app after login
                    'token'    => '',
                    'seq'      => 0,
                    ## debug mode
                    'debug'    => $debug,
                    ## keep one of these around
                    'ua'       => LWP::UserAgent->new,
    };
    bless($self, $class_name);
    return $self;
}

sub login {
    my $self = shift;
    my $call = 'auth/login/' . $self->username . '/' . $self->password;
    my $root = $self->get($call, {'api_key' => $self->api_key });
    return unless $root;

    $self->{'token'} = $root->{response}->{auth}->{token}->{value};
    $self->{'seq'}   = $root->{response}->{auth}->{seq}->{value};
    return 1;
}

### Most of this code is shared with all of the GET calls.
### _getcall takes a string (the RHS of `my $call =') and a coderef
### (callback for processing the tree XML::Bare returns).
###
### It returns a subroutine that preforms the requested call.
sub _getcall {
    my ($cstr, $munge) = @_;

    my $ret = q|sub {
        my $self = shift;my $call = CALL;my %args = @_;
        my $root = $self->get($call, { $self->_stdargs, %args });
        unless ($root) {
            warn 'Got error: ' . $self->error->{code} . ': ' . $self->error->{message} . "\n";
            return;
        }
        return $munge->($root);
    }|;
    $ret =~ s/CALL/$cstr/;
    return eval $ret;
}

### Build the GET functions with _getcall.
*contacts = _getcall q("contacts"), 
                    sub { _to_arrayref(shift->{response}->{contact}) };
*contact  = _getcall q("contact/" . shift),
                    sub { _to_hashref (shift->{response}->{contact}) };
*subscriptions = _getcall q{"contact/" . shift() . "/subscriptions"},
                    sub { _to_subs(shift->{response}->{contact}->{subscription})};
*campaigns = _getcall q("campaigns"),
                    sub { _to_arrayref(shift->{response}->{campaigns}->{campaign})};
*campaign  = _getcall q("campaign/" . shift),
                    sub { _to_hashref (shift->{response}->{campaign})};
*lists = _getcall q("lists"),
                    sub { _to_arrayref(shift->{response}->{lists}->{list})};
*list  = _getcall q("list/" . shift),
                    sub { _to_hashref (shift->{response}->{list})};
*custom_fields = _getcall q{"contact/" . shift() . "/custom_fields"},
                    sub { _to_cfields (shift->{response}->{contact}->{custom_fields}->{custom_field})};
*stats = _getcall q{"message/" . shift() . "/stats"},
                    sub { _to_stats   (shift->{response}->{message}->{stats})};


sub putmessage {
    my ($self, $subject, $campaign, $text, $html) = @_;
    my $call = 'message';

    my $X = new XML::Generator ':pretty';
    my $xml = $X->xml($X->message(
                  $X->subject($X->xmlcdata($subject)),
                  $X->campaign($campaign),
                  $X->text_body($X->xmlcdata($text)),
                  $X->html_body($X->xmlcdata($html)),
              ))->stringify;

    my $root = $self->put($call, { $self->_stdargs }, $xml);
    return unless $root;

    return $root->{response}->{result}->{message}->{id}->{value};
}

sub putcontact {
    my ($self, $contact, $id) = @_;
    my $call = 'contact' . ($id ? "/$id" : '');

    my $X = new XML::Generator ':pretty';
    my $xml = $X->xml($X->contact(($id ? { 'id' => $id } : { }),
                                   map {$X->$_($contact->{$_})} keys %$contact,
                     ))->stringify;

    my $root = $self->put($call, { $self->_stdargs }, $xml);
    return unless $root;

    return $root->{response}->{result}->{contact}->{id}->{value};
}

sub putsubscription {
    my ($self, $contactid, $listid, $status) = @_;
    my $call = "contact/$contactid/subscription/$listid";

    my $X = new XML::Generator ':pretty';
    my $xml = $X->xml($X->subscription({'id' => $listid},
                                       $X->status($status),
                     ))->stringify;

    my $root = $self->put($call, { $self->_stdargs }, $xml);
    ## False on failure, 1 on success.
    return unless $root;
    return 1;
}

sub gen_sig {
    my ($self,$call,$args) = @_;
    my $sig = $self->secret;
    $sig .= $call;
    for my $key (sort (keys(%$args))) {
        $sig .= $key . $args->{$key};
    }
    return md5_hex($sig);
}

sub gen_url {
    my ($self,$call,$args) = @_;
    my $url = API_BASE . $call;
    my $sig = $self->gen_sig($call, $args);

    $url .= "/?api_sig=$sig";

    while (my ($key,$val) = each(%$args)) {
        $url .= "&$key=$val";
    }
    return $url;
}

sub get {
    my ($self,$call,$args) = @_;

    ## Generate the URL and make the call
    my $url = $self->gen_url($call, $args);
    warn "GET'ing: $url\n\n" if $self->debug;
    my $response = $self->ua->request(GET $url);
    croak "Could not make API call: GET/$call" unless $response->is_success;

    $self->{'seq'}++;
    my $xml = $response->content;
    warn "\n\nGot:\n$xml\n\n" if $self->debug;

    ## Parse it, check for errors
    my $root = _parse($xml);
    unless (_success($root)) {
        $self->{'error'} = _get_error($root);
        return;
    }
    return $root;
}

sub put { 
    my ($self,$call,$args,$xml) = @_;
    $args->{'api_put'} = $xml;

    ## Generate the URL and make the call
    my $url = $self->gen_url($call, $args);
    warn "PUT'ing: $url\ncontent:\n$xml\n\n" if $self->debug;
    my $response = $self->ua->request(PUT $url, Content => $xml);
    croak "Could not make API call: PUT/$call" unless $response->is_success;

    $self->{'seq'}++;
    $xml = $response->content;
    warn "\n\nGot:\n$xml\n" if $self->debug;

    ## Parse it, check for errors
    my $root = _parse($xml);
    unless (_success($root)) {
        $self->{'error'} = _get_error($root);
        return;
    }

    return $root;
}

### The following subs are for internal use only.

# _get_error( ROOT )
#
# Extracts the error code and message from the given XML.
# 
#     ROOT: an XML::Bare root node
#
# Returns a hashref.  (See C<error>).


sub _get_error {
    my $root = shift;
    return  {   'code'    => $root->{response}->{error_code}->{value},
                'message' => $root->{response}->{error_message}->{value}, };
}

# _parse( TEXT )
#
# Parses the XML in the first argument.
#
#     TEXT: scalar string containing XML
#
# Returns an XML::Bare root node.

sub _parse {
    my $xml = new XML::Bare( text => shift );
    return $xml->parse;
}

# _success( ROOT )
#
# Check whether or not a call was successful based on the XML returned.
#
#     ROOT: an XML::Bare root node
#
# Returns true on success and false on failure

sub _success {
    my $root = shift;
    my $status = $root->{response}->{status}->{value};
    return unless $status eq 'success'; # false return on failure,
    return 1;                           # otherwise 1
}

# _to_arrayref( NODE )
#
# Convert an XML::Bare hash tree to an array.
# Returns an arrayref.

sub _to_arrayref {
    my @ret;
    my $ar = shift;
    if (ref($ar) eq 'ARRAY') {
        for my $item (@$ar) {
            push @ret, $item->{id}->{value};
        }
    } else {
        if (defined($ar->{id}->{value})) {
            push @ret, $ar->{id}->{value};
        }
    }
    return \@ret;
}

# _to_hashref( NODE )
#
# Convert an XML::Bare hash tree to a hash.
# Returns a hashref.

sub _to_hashref {
    ## Convert the tree returned by XML::Bare into a "normal" hashref,
    ##  so keys can be accessed without excessive referenceage..
    my %ret;
    my $ar = shift;
    while (my ($key,$val) = each(%$ar)) {
        next if $key =~ /(value|pos)/;
        $ret{$key} = $val->{value};
    }
    return \%ret;
}

# _to_subs( NODE )
#
# Convert an XML::Bare hash tree to a hash.  Special case for
# GET call `subscriptions'

sub _to_subs {
    my $subscription = shift;
    my %ret;

    if (ref($subscription) eq 'ARRAY') {
        for my $item (@$subscription) {
            $ret{$item->{id}->{value}} = $item->{status}->{value};
        }
    } else {
        if (defined($subscription->{id}->{value})) {
            $ret{$subscription->{id}->{value}} = $subscription->{status}->{value};
        }
    }
    return \%ret;
}

# _to_cfields( NODE )
#
# Convert an XML::Bare hash tree to a hash.  Special case for
# GET call `custom_fields'

sub _to_cfields {
    my %ret;
    my $fields = shift;
    if (ref($fields) eq 'ARRAY') {
        for my $item (@$fields) {
            $ret{$item->{name}->{value}} = {
                'formal_name' => $item->{formal_name}->{value},
                'value' => $item->{value}->{value},
                'type' => $item->{type}->{value},
            }
        }
    } else {
        if (defined($fields->{name}->{value})) {
            $ret{$fields->{name}->{value}} = {
                'formal_name' => $fields->{formal_name}->{value},
                'value' => $fields->{value}->{value},
                'type' => $fields->{type}->{value},
            }
        }
    }

    return \%ret;
}

# _to_stats( NODE )
#
# Convert an XML::Bare hash tree to a hash.  Special case for
# GET call `stats'

sub _to_stats {
    my $stats = shift;
    my %ret;
    for (qw/bounces released unsubscribes forwards complaints opens clicks/) {
        $ret{$_} = {
          'count'   => $stats->{$_}->{count}->{value},
          'percent' => $stats->{$_}->{percent}->{value},
        }
    }
    $ret{opens}->{unique} = $stats->{opens}->{unique}->{value};
    $ret{clicks}->{unique} = $stats->{clicks}->{unique}->{value};

    return \%ret;
}



# _stdargs( SELF )
#
# Return a hash containing the standard arguments to api calls.
# Requires access to $self.

sub _stdargs {
    my $self = shift;
    return ( 'api_key' => $self->api_key,
             'api_seq' => $self->seq,
             'api_tok' => $self->token, );
}

=head1 NAME

Net::iContact - iContact API

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Net::iContact;

    my $api = Net::iContact->new('user', 'pass', 'key', 'secret');
    $api->login();
    for my $list (keys %{$api->lists}) {
        print "ID: " . $list->{'id'} . "\n";
        print "Name: " . $list->{'name'} . "\n";
    }
    ...

=head1 ACCESSORS

The following functions take no arguments and return the property
indicated in the name.

=head2 error( )

Returns the last error recieved, if any, as a hashref containing two
keys: code, and message.

Example:
    print "Error code: " . $api->error->{'code'};

=head2 username( )

Returns the username that was supplied to the constructor.

=head2 password( )

Returns an md5 hash of the password that was supplied to the
constructor.

=head2 api_key( )

Returns the api key.

=head2 secret( )

Returns the shared secret.

=head2 token( )

Returns the current token, if authenticated.

=head2 seq( )

Returns the current sequence number, if authenticated.

=head2 new( USERNAME, PASSWORD, APIKEY, SECRET, [DEBUG] )

The constructor takes four scalar arguments and an optional fifth:

    USERNAME: your iContact username
    PASSWORD: your iContact password
    APIKEY: the API key given to your application
    SECRET: the shared secret given to your application
    DEBUG: turns on debugging output.  Optional, default is zero.

When DEBUG is true, Net::iContact will print the URLs it calls and the
XML returned on STDERR.

Example:
    my $api = Net::iContact->new('user', 'pass', 'key', 'secret');

=head2 login( )

Logs into the API.  Takes no arguments, returns true on success and
false on error.

Example:
    my $ret = $api->login;
    unless ($ret) {
        print 'Error ' . $api->error->{'code'} . ': '
                . $api->error->{'message'} . "\n";
    }

=head1 API GET METHODS

For more details on the API calls implemented below, see the API
documentation: L<http://app.icontact.com/icp/pub/api/doc/api.html>

=head2 contacts( [FIELDS] )

Search for contacts.

    FIELDS: optional hash of search criteria

Returns an arrayref of all found contact IDs.  If called with no
arguments, returns all contacts in the account.

Example:
    my $contacts = $api->contacts();    # get all contacts
    ## get all contacts with @example.com email addresses and the first
    ## name 'Steve'
    $contacts = $api->contacts( 'email' => '*@example.com',
                                'fname' => 'Steve');
    for my $id (@$contacts) {
        # ...
    }

=head2 contact( ID )

    ID: numeric contact ID

Returns a hashref representing the contact with the given ID.
See C<contacts>

Example:
    my $contact = $api->contact($id);
    print $contact->{fname} .' '. $contact->{lname} .' <'. $contact->{email} . ">\n";

=head2 subscriptions( ID )

    ID: numeric contact ID

Returns a hashref of the given contact's subscriptions.
See C<contacts>

=head2 custom_fields( ID )

    ID: numeric contact ID

Returns a hashref of the given contact's custom fields.
See C<contacts>

=head2 campaigns( )

Returns an arrayref of all campaign IDs defined in the account, or a
false value on error.

=head2 campaign( ID )

    ID: numeric campaign ID

Returns a hashref representing the campaign with the given ID.
See C<campaigns>.

=head2 lists( )

Returns an arrayref of all list IDs defined in the account, or a false
value on error.

=head2 list( ID )

    ID: numeric list ID

Returns a hashref representing the list with the given ID.
See C<lists>.

=head2 stats( ID )

    ID: numeric message ID

Returns a hashref containing stats for the given message ID.

=head1 API PUT FUNCTIONS

For more details on the API calls implemented below, see the API
documentation: L<http://app.icontact.com/icp/pub/api/doc/api.html>

=head2 putmessage( SUBJECT, CAMPAIGN, TEXT_BODY, HTML_BODY )

Create a message.

    SUBJECT: subject of the message
    CAMPAIGN: campaign to use
    TEXT_BODY: text part of the message
    HTML_BODY: html part of the message

Returns the ID of the created message on success, or a false value on
failure.

=head2 putcontact( CONTACT, [ID] )

Insert or update a contact's info.

    CONTACT: hashref of contact info
    ID: optional contact ID

The CONTACT hashref has the following possible keys:

=over 4

=item * fname

=item * lname

=item * email

=item * prefix

=item * suffix

=item * buisness

=item * address1

=item * address2

=item * city

=item * state

=item * zip

=item * phone

=item * fax

=back

Returns the ID of the contact on success, or a false value on failure.

=head2 putsubscription( CONTACTID, LISTID, STATUS )

Update a contact's subscription.

    CONTACTID: contact ID to update
    LISTID: list ID
    STATUS: CONTACTID's subscription to LISTID (eg 'subscribed',
        'unsubscribed', 'deleted'...)

=head1 MISC FUNCTIONS

The following functions are intended for internal use, but may be useful
for debugging purposes.

=head2 gen_sig( METHOD, ARGS )

Generates an api signature.

    METHOD: scalar name of the method to be called
    ARGS: a hashref of arguments to above method

Returns the generated signature string.

=head2 gen_url( METHOD, ARGS )

Generates the URL to call, including the api_sig.

    METHOD: scalar name of the method to be called
    ARGS: a hashref of arguments to above method

Returns the URL generated.

Example:
    my $url = $api->gen_url('auth/login/' . $api->username . '/'
            . $api->password, { 'api_key' => $api->api_key });

=head2 get( METHOD, ARGS )

Makes an API GET call.

    METHOD: scalar name of the method to be called
    ARGS: a hashref of arguments to above method

Returns the raw XML recieved from the API.

=head2 put( METHOD, ARGS, XML )

Makes an API PUT call.

    METHOD: scalar name of the method to be called
    ARGS: hashref of arguments to above method
    XML: XML to PUT

Returns the raw XML recieved from the API.

=head1 AUTHOR

Ian Kilgore, C<< <ian at icontact.com> >>

=head1 BUGS

Need better documentation of return values (possibly documentation with
Dumper output of the return values).

Net::iContact does not yet support authenticating to accounts with
multiple client folders.

This module makes no attempt to deal with being rate-limited by the API.

=head1 TODO

PUT methods that are not provided at this time:

=over 4

=item * message/[message_id]/sending_info

=back

GET methods that are not provided at this time:

=over 4

=item * message/[id]/stats/opens

=item * message/[id]/stats/clicks

=item * message/[id]/stats/bounces

=item * message/[id]/stats/unsubscribes

=item * message/[id]/stats/forwards

=back

Please report any bugs or feature requests to
C<bug-icontact-api at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-iContact>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::iContact

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-iContact>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-iContact>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-iContact>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-iContact>

=back

=head1 ACKNOWLEDGEMENTS

=head1 SEE ALSO

L<http://app.icontact.com/icp/pub/api/doc/api.html>

=head1 COPYRIGHT & LICENSE

Copyright 2007 iContact, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Net::iContact
