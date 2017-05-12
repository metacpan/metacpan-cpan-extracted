# Copyright (c) 2003-2004 Timothy Appnel (cpan@timaoutloud.org)
# http://www.timaoutloud.org/
# This code is released under the Artistic License.
package Net::Trackback::Ping;
use strict;
use base qw( Class::ErrorHandler );

my %fields;
map { $fields{$_}=1 } 
    qw( title excerpt url blog_name timestamp ping_url id);

sub new { 
    my $self = bless {}, $_[0];
    # Should we filter out unknown fields?
    $self->{__stash} = $_[1] if $_[1];
    $self;
}

sub parse {   
    my $class = shift;
    my $q = shift;
    my $tb_id = $q->param('tb_id');
    unless ($tb_id) {
        if ( my $pi = $q->path_info() ) {
            ( $tb_id = $pi ) =~ s!^/!!;
        }
    }
    return $class->error('No Trackback ID (tb_id)') unless $tb_id;
    $tb_id =~ tr/a-zA-Z0-9/_/cs;
    return $class->error('No URL (url)') unless $q->param('url');
    my $self = $class->new();
    $self->{__stash} =
        { map { $_ => scalar $q->param($_) } 
            keys %fields };
    $self->{__stash}->{id} = $tb_id;
    $self->{__stash}->{title} ||= $self->{__stash}->{url};
    $self->{__stash}->{timestamp} = time;
    $self;
}

sub to_hash { %{ $_[0]->{__stash} } }

sub to_urlencoded { 
    my $self = shift;
    my $stash = $self->{__stash};
    my $str;
    foreach (grep { $stash->{$_} } keys %fields) {
        next if ($_ eq 'ping_url' || $_ eq 'timestamp');  
        $str .= '&' if $str;
        (my $val = $stash->{$_})
            =~s!([^a-zA-Z0-9_.-])!uc sprintf "%%%02x",ord($1)!eg;
        $str .= "$_=$val";
    }
    $str;
}

DESTROY { }

use vars qw( $AUTOLOAD );
sub AUTOLOAD {
    (my $var = $AUTOLOAD) =~ s!.+::!!;
    no strict 'refs';
    die "$var is not a recognized method."
        unless ( $fields{$var} );
    *$AUTOLOAD = sub {
        $_[0]->{__stash}->{$var} = $_[1] if $_[1];
        $_[0]->{__stash}->{$var};
    };
    goto &$AUTOLOAD;
}

1;

__END__

=begin

=head1 NAME

Net::Trackback::Ping - an object representing a Trackback ping.

=head1 SYNOPSIS

 use Net::Trackback::Client;
 use Net::Trackback::Ping;
 my $ping = Net::Trackback::Ping->new();
 $ping->title('Net::Trackback Test');
 $ping->url('http://search.cpan.org/search?query=Trackback');
 $ping->ping_url('http://www.movabletype.org/mt/trackback/62');
 my $client = Net::Trackback::Client->new();
 my $msg = $client->send_ping($ping);
 print $msg->to_xml;

=head1 METHODS

=item Net::Trackback::Ping->new([$hashref])

Constuctor method. It will initialize the object if passed a 
hash reference. Recognized keys are url, ping_url, id, title,
excerpt, and blogname. These keys correspond to the methods 
like named methods.

=item Net::Trackback::Ping->parse($CGI)

A method that extracts ping data from an HTTP request and returns a
ping object. In the event a bad ping has been passed in the method
will return C<undef>. USe the C<errstr> method to retrieve the
error message. One required parameter, a reference to a L<CGI>
object or some other that has a C<param> method that works just
like it. See the list of recognized keys in the L<new> method.

=item $ping->url([$url])

Accessor to a resource URL. Passing in an optional string parameter 
sets the value. This value is required to make a ping.

=item $ping->ping_url([$url]) 

Accessor to the URL to ping with the resource's Trackback 
information. Passing in an optional string parameter sets the 
value. This value is required to make a ping.

=item $ping->id([$id])

Accessor to the remote resource ID that is to be pinged. Passing in
an optional string parameter sets the value.

=item $ping->title([$title])

Accessor to the title of resource that is to be pinged. Passing in an
optional string parameter sets the value.

=item $ping->excerpt([$excerpt]);

A brief plain text description of the resource at the other end of
the L<url>. Passing in an optional string parameter sets the value.

B<NOTE:> While the Trackback specification doesn't specify a limit
to the size of an excerpt, some implementations do. For instance as
of Movable Type 3.14, Trackback excerpts cannot exceed 255 
characters.

=item $ping->blog_name([$source]);

Accessor to the source of the ping. Passing in an optional string
parameter sets the value.

=item $ping->to_hash

Returns a hash of the object's current state.

=item $ping->to_urlencoded

Returns a URL encoded string of the object's current state.

=head2 Errors

This module is a subclass of L<Class::ErrorHandler> and inherits
two methods for passing error message back to a caller.

=item Class->error($message) 

=item $object->error($message)

Sets the error message for either the class Class or the object
$object to the message $message. Returns undef.

=item Class->errstr 

=item $object->errstr

Accesses the last error message set in the class Class or the
object $object, respectively, and returns that error message.

=head1 AUTHOR & COPYRIGHT

Please see the Net::Trackback manpage for author, copyright, and 
license information.

=cut

=end