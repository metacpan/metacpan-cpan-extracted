use strict;

package Tamino;

use vars (qw/$VERSION/);

$VERSION = 0.03;

use Class::Accessor;
use Class::Data::Inheritable;

use base qw/Class::Accessor Class::Data::Inheritable/;

use LWP::UserAgent;
use Tamino::Tran;

=head1 NAME

Tamino - Pure Perl Tamino XML DB driver

=head1 SYNOPSIS

    use Tamino;
    
    my $tamino_client = Tamino->new(
        server      => '127.0.0.1/tamino'
        db          => 'mydb'
    );
    
    my $t = $tamino_client->begin_tran
        or die $tamino_client->error;
        
    $c = $t->xquery_cursor(q{
        for $x in collection('mycollection')/doctype/xxx[@yyy=%s][zzz='%s']
        return $x
    }, "('y1','y2')", "z1") or die $t->error;

    while($xml_bare_simple_tree = $c->fetch) {
        print XML::Simple::XMLout($xml_bare_simple_tree, KeyAttr => []);
    }

=head1 DESCRIPTION

This is just an API wrapper.
This driver is based on L<LWP::UserAgent>, L<XML::Bare>, and inherits from L<Class::Accessor> and L<Class::Data::Inheritable>.

=cut

__PACKAGE__->mk_classdata($_) for qw/tran_class lwp_ua_class/;

__PACKAGE__->mk_accessors(qw/server db collection user password tran_class error encoding queries queries_time _debug/);
__PACKAGE__->mk_accessors(qw/_ua/);

__PACKAGE__->tran_class('Tamino::Tran');
__PACKAGE__->lwp_ua_class('LWP::UserAgent');

=head1 CONSTRUCTOR

=over 4

=item new

    my $tamino_client = Tamino->new(
        server  => $server,
        db      => $db,
        %options
    );

B<server> => Tamino server name, without C<http://>, like C<'hostname/tamino'>

B<db> => database name

Options:

B<collection> => collection name (optional)

B<user> => user name (optional)

B<password> => user's password (optional)

B<encoding> => encoding, 'UTF-8' by default

B<timeout> => timeout for LWP::UserAgent

B<keep_alive> => keep_alive for LWP::UserAgent

=back

=cut

sub new ($) {
    my $class = shift;
    my %args = @_;
    
    $args{server} =~ s!^http://!!i;
    
    $class = ref $class || $class;
    my $self = $class->SUPER::new({
        tran_class  => $args{tran_class} || $class->tran_class,
        queries     => 0,
        queries_time=> 0,
        map { $_ => $args{$_} } qw/server db collection user password encoding/,
    });
    
    $self->_ua($class->lwp_ua_class->new(
        timeout => $args{timeout} || 5,
        keep_alive => defined$args{keep_alive}?$args{keep_alive}:10,
    ));
    
    return $self;
}

sub _url ($) {
    my ($self) = @_;
    my $url = 'http://';
    if($self->user) {
        $url .= $self->user;
        $url .= ':'.$self->password if($self->password);
        $url .= '@';
    }
    $url .= $self->server;
    $url .= "/".$self->db;
    $url .= "/".$self->collection if($self->collection);
    return $url;
}

=head1 METHODS

=over 4

=item begin

    my $t = $tamino_client->begin() or die $tamino_client->error;
    $t->xquery(...);

Returns a new L<Tamino::Tran> object. The transaction session is not established.
All operations are made in non-transactional context.

=back

=cut
 
sub begin ($;@) {
    my ($self,%opts) = @_;
    my $class = $self->tran_class;
    my $tran = $class->new(
        %opts,
        ua => $self->_ua,
        url => $self->_url,
        tamino => $self,
        _debug => $self->_debug,
        _no_connect => 1,
    ) or $self->error($class->error);
    
    return $tran;
}

=pod

=over 4

=item begin_tran

    my $t = $tamino_client->begin_tran(%opts) or die $tamino_client->error;
    $t->xquery(...);

Returns a new L<Tamino::Tran> object. The transaction session is established.
All operations are made in the transaction context.

All objects created with I<begin()> and I<begin_tran()> methods do their networking
with the same L<LWP::UserAgent> object, which is initialized in I<< Tamino->new >>

%opts may include:

C<< isolation_level => $level >>, which can be one of:
uncommittedDocument
committedCommand
stableCursor
stableDocument
stableDocument

C<< lock_mode => $mode >>, which can be one of:
unprotected
shared
protected

C<< lock_wait => $wait >>, which can be one of:
yes
no

For What-This-All-Means read Tamino Transaction Guide.

C<< encoding => $enc >> to tell tamino server that you want $enc encoding.

=back

=cut

sub begin_tran ($;@) {
    my ($self,%opts) = @_;
    my $class = $self->tran_class;
    my $tran = $class->new(
        %opts,
        ua => $self->_ua,
        url => $self->_url,
        tamino => $self,
        _debug => $self->_debug,
    ) or $self->error($class->error);
    return $tran;
}

=head1 MISC METHODS

    $tamino_client->server('other_server/tamino');
    $tamino_client->db('other_db');
    $tamino_client->collection('other_collection');
    $tamino_client->user('other_user');
    $tamino_client->password('his_password');
    $tamino_client->encoding('other_encoding');

All of the above change setting for only NEWLY created L<Tamino::Tran> objects.

Note that I<encoding> option only passed to the Tamino DB, this driver does B<nothing> to take care of encoding.   

    print $tamino_client->error;

=head1 SUBCLASSING

You can subclass I<Tamino> class.
You can tell I<Tamino> to use subclassed L<Tamino::Tran> and L<LWP::UserAgent> by saying:

    Tamino->tran_class('My::Tamino::Tran');
    $tamino_client->tran_class('My::Tamino::Tran');
    
    Tamino->lwp_ua_class('My::LWP::UserAgent');

=head1 SEE ALSO

L<Tamino::Tran>
L<XML::Twig>
L<XML::Bare>
L<LWP::UserAgent>
L<Class::Accessor>
L<Class::Data::Inheritable>

=cut

1;

