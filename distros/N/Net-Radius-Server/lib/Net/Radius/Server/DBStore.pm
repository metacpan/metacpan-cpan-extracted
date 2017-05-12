#! /usr/bin/perl
#
#
# $Id: DBStore.pm 109 2009-10-17 22:00:16Z lem $

package Net::Radius::Server::DBStore;

use 5.010;
use strict;
use warnings;

use Storable qw/freeze/;

use Net::Radius::Server::Base qw/:set/;
use base 'Net::Radius::Server::Base';
__PACKAGE__->mk_accessors(qw/key_attrs param store result sync 
			  pre_store_hook single frozen hashref 
			  internal_tie/);
our $VERSION = do { sprintf "%0.3f", 1+(q$Revision: 109 $ =~ /\d+/g)[0]/1000 };

sub mk
{
    my $class = shift;
    die "->mk() cannot have arguments when in object-method mode\n" 
	if ref($class) and $class->isa('UNIVERSAL') and @_;

    my $self = $class;

    if (@_)
    {
	$self = $class->new(@_);
	die "Failed to create new object\n" unless $self;
    }

    die "->mk() cannot proceed with no valid param defined\n"
	unless ref($self->param) eq 'ARRAY';

    # Enforce default values

    $self->frozen(1)       unless defined $self->frozen();
    $self->single(1)       unless defined $self->single();
    $self->internal_tie(1) unless defined $self->internal_tie();

    $self->key_attrs([ 'NAS-IP-Address', '|', 'Acct-Session-Id' ]) 
	unless $self->key_attrs();

    $self->store([ qw/ packet peer_addr peer_host peer_port port /]) 
	unless $self->store();

    $self->sync(1)
	unless defined $self->sync();
    
    $self->log_level(1)
	unless defined $self->log_level();

    # Create the tied hash that we will be passing into the actual method.

    my ($db, %hash);
    my ($c, @params) = (@{$self->param});

    $self->hashref(\%hash) unless $self->hashref;

    $self->log(2, "Tying to class '" . $c  . "'");
    $self->log(3, "Tie parameters are " . join(', ', @params));
    if ($self->internal_tie)
    {
	eval { $db = tie %{$self->hashref}, $c, @params };

	die "->mk() unable to tie: $!" unless $db;
	die "->mk() problem during tie: $@" if $@;
    }
    else
    {
	$self->log(2, "Not tying because ->internal_tie is true");
    }
    
    return sub { $self->_do_tie( $db, $self->hashref, @_ ) };
}

# Convert a scalar into the corresponding Radius attribute in
# $req. Will return non-matched scalars, to be used as delimiters in
# the resulting key.
sub _k
{
    my ($self, $db, $rhash, $r_data, $req, $attr) = @_;
    my $v = undef;

    if (ref($attr) eq 'ARRAY')
    {
	$v = $req->vsattr(@$attr);
	return $v->[0] if ref($v) eq 'ARRAY';
	return $v if defined $v;
	return '';
    }
    elsif (ref($attr) eq 'CODE')
    {
	return $attr->($self, $db, $rhash, $r_data, $req);
    }
    else
    {
	$v = $req->attr($attr);
	return $v if defined $v;
    }

    return $attr;
}

sub _do_tie
{
    my $self   = shift;
    my $db     = shift;
    my $rhash  = shift;
    my $r_data = shift;

    my $req    = $r_data->{request};

    $self->log(2, 'Storing data');
    $self->log(4, "self=$self rhash=$rhash r_data=$r_data");

    # Find the key to store
    my $key = join('', (map { $self->_k($db, $rhash, $r_data, $req, $_) } 
			@{$self->key_attrs}));
    $self->log(4, 'Storing data using key "' . $key . '"');

    # Invoke hook, if available
    my $f = undef;
    if ($f = $self->pre_store_hook()
	and ref($f) eq 'CODE')
    {
	$self->log(3, 'Invoking pre_store_hook');
	# Note that the pre_store_hook could change object's config...
	$f->($self, $db, $rhash, $r_data, $req, $key);
    }
    else
    {
	$self->log(4, 'no pre_store_hook');
    }

    # Find what to store
    my @store = @{$self->store};
    $self->log(4, 'Storing the following items: ' . join(', ', @store));
    my %data = map { $_ => $r_data->{$_} } @store;

    if ($self->single)
    {
	$self->log(4, "Single Store $key: ", \%data);
	$rhash->{$key} = ($self->frozen ? freeze \%data : \%data);
    }
    else
    {
	while (my ($k, $v) = each %data)
	{
	    $self->log(4, "Non-Single Store $key->$k: $v");
	    $rhash->{$key}->{$k} = ($self->frozen ? freeze $v : $v)
	}
    }
    $self->log(4, "tuple contains: " . $rhash->{$key} // 'undef');

    # Force sync writes
    $db->db_sync if $db and $self->sync and $db->can('db_sync');

    if ($self->can('result') and exists $self->{result})
    {
	my $r = $self->result;
	$self->log(3, "Returning $r");
	return $r;
    }

    $self->log(3, "Returning CONTINUE by default");
    return NRS_SET_CONTINUE;
}

42;

__END__

=head1 NAME

Net::Radius::Server::DBStore - Store Radius packets into a Tied Hash

=head1 SYNOPSIS

  use MLDBM::Sync;
  use MLDBM qw(DB_File Storable);
  use Net::Radius::Server::DBStore;
  use Net::Radius::Server::Base qw/:set/;

  my $obj = Net::Radius::Server::DBStore->new
    ({
      log_level      => 4,
      param          => [ 'MLDBM::Sync', 
                          @Tie_Opts ],
      store          => [qw/packet peer_addr port/],
      pre_store_hook => sub { ... },
      sync           => 1,
      single         => 1,
      internal_tie   => 1,
      frozen         => 0,
      key_attrs      => [ 'Acct-Session-Id', [ Vendor => 'PrivateSession' ] ],
      hashref        => \%external_hash,
      result         => NRS_SET_CONTINUE,
    });

  my $sub = $obj->mk();

  # or

  my $sub = Net::Radius::Server::DBStore->mk
    ({
    # ... same parameters as above ...
    });

=head1 DESCRIPTION

C<Net::Radius::Server::DBStore> is a match or set method factory than
can be used within C<Net::Radius::Server::Rule> objects.

Note that this factory can produce either match or set methods. The
only practical difference is the actual result to be returned, that
defaults to C<NRS_SET_CONTINUE>. This is so, as it is anticipated that
the most common use for this class would be producing set methods, so
that accounting packets can be stored after classification that can be
made using corresponding match methods.

You can trivially replace the result to be returning by using the
C<result> key, as shown in the SYNOPSIS.

=over

=item C<-E<gt>new($hashref)>

Creates a new Net::Radius::Server::DBStore(3) object that acts as aod
factory. C<$hashref> referenes a hash with the attributes that will
apply to this object, so that multiple methods (that will share the
same underlying object) can be created and given to different rules.

=item C<-E<gt>mk($hashref)>

Invokes C<-E<gt>new()> passing the given C<$hashref> if needed.

At this stage, an object-private hash is tied to the specified class
(MLDBM::Sync(3) as in the SYNOPSIS), using the given flags. This
hash is stored in the object and will be shared by any methods
constructed from it.

This makes more efficient the case where you want to store information
coming from various different rules, such as when matching for
different types of service, more efficient.

C<-E<gt>mk()> then returns a method that is suitable to be employed as
either a match or set method within a C<Net::Radius::Server::Rule>
object.

=item C<$self-E<gt>mk()> or C<__PACKAGE__-E<gt>mk($hashref)> 

This method returns a sub suitable for calling as either a match or
set method for a C<Net::Radius::Server::Rule> object. The resulting
sub will return C<NRS_SET_CONTINUE> by default, unless overriden by
the given configuration.

The sub contains a closure where the object attributes -- Actually,
the object itself -- are kept.

When invoked as an object method (ie, C<$self-E<gt>mk()>), no
arguments can be given. The object is preserved as is within the
closure.

When invoked as a class method (ie, C<__PACKAGE__-E<gt>mk($hashref)>),
a new object is created with the given arguments and then, this object
is preserved within the closure. This form is useful for compact
filter definitions that require little or no surrounding code or
holding variables.

=item C<-E<gt>_do_tie()>

You're not supposed to call this method directly. It is called by the
sub produced with C<-E<gt>mk()>. Within this method, the following
takes place:

=over

=item *

The record key is calculated by using the corresponding configuration
entry.

=item *

The requested information is stored in the tied hash, thus inserted in
the underlying storage method.

=item *

The required return value is passed back to the caller.

=back

=back

=head2 Configuration Keys

The following configuration keys are understood by this class, in
addition to the ones handled by Net::Radius::Server::Base(3). Note
that those are available in the factory object (the one retured by the
call to C<-E<gt>new()>) as same-name accessors.

=over

=item B<param     =E<gt> [ @args ]>

The actual parameters to the C<tie>. This parameter is mandatory. The
first item in the C<@args> list has to be the name of the class to
tie. Tipically you will want to use MLDBM(3), MLDBM::Sync(3),
BerkeleyDB::Hash(3) or Tie::DBI(3).

    param => [ 'MLDBM::Sync', '/my/db/file.db' ],

Note that concurrency will be an issue. You need to insure that you
use modules and settings that consider the fact that multiple
instances will be writing at the same time.

=item B<key_attrs =E<gt> [ @keys ]>

Specify the Radius attributes to use as the record key for accessing
the database. Each element of the list can be one of the following types:

=over

=item B<Scalar>

This is either an attribute name or a delimiter. Actually, any string
is used to look up the corresponding attribute in the request
packet. If this fails, the actual string is inserted as the value of
the key. Upon success, the value of the corresponding attribute is
inserted in the key.

=item B<sub or CODE ref>

This sub will be called with the following arguments: The
Net::Radius::Server::DBStore(3) object, the C<tied()> object as
returned by C<tie>, a reference to the tied hash, a reference to the
hash with data passed to the method and a Net::Radius::Packet(3)
object with the decoded request this rule is responding to.

The return value of the sub will be inserted in the key.

This is useful to create hash keys that depend on information not
within the actual Radius request.

=item B<ArrayRef>

This is interpreted as a VSA. The first element of the given list
encodes the vendor name. The second attribute encodes the vendor
attribute name.

If the attribute is found within the request packet, its value is
substituted at the current location of the key. Otherwise, an empty
string will be substituted in its place.

=back

The following example:

      key_attrs => [ 'Acct-Session-Id', '|', [ Cisco => 'Foo' ] ]

Would produce a key like this:

      DEADBEEF872374628742|

Or if the ficticious VSA was defined, something like

      DEADBEEF872374628742|The_Value

The default attribute list is C<[ 'NAS-IP-Address', '|',
'Acct-Session-Id' ]> which is likely to be suitable for Radius
accounting packets. Note that RFC-2866 states that the
C<Acct-Session-Id> attribute is unique, but this is generally so
within a single device. When multiple devices are served, there may be
a chance of collision. Including the IP Address of the NAS helps solve
the problem. You must review your own environment and insure that the
given key will produce unique values for each session.

=item B<store =E<gt> [ @items ]>

Tells the method which pieces of information to store within the tied
hash. This corresponds to the attributes that are passed to the actual
method. You might want to take a look at Net::Radius::Server::NS(3)
and Net::Radius::Server::Rule(3) for more information.

You should be conservative with this config entry, to store only as
much information as needed. Note that you might be storing potentially
sensitive information, such as user passwords, so appropiate care
should be taken.

The dafault value for C<@items> is C<packet, peer_addr, peer_host,
peer_port, port>. This default should avoid storing huge objects
alongside the useful data.

Be aware that storing decoded packets (ie, including either C<request>
or C<response> on the list of C<@items>) will lead to storing the NAS
shared secret and the dictionaries using to encode and decode the
packets. This will be large.

=item B<pre_store_hook =E<gt> $sub>

This C<$sub> will be called before actually calculating and storing in
the BerkeleyDB(3) database. The following arguments are passed, in
this order: The Net::Radius::Server::DBStore(3) object, the
C<tied()> object as returned, a reference to the tied
hash, a reference to the hash with data passed to the method, a
Net::Radius::Packet(3) object with the decoded request this rule is
responding to and the calculated key for this entry.

The return value of the sub is currently ignored.

=item B<sync =E<gt> $value>

Causes a call to C<-E<gt>db_sync()> after each insertion when
C<$value> evaluates to true, which is the default. When set to a false
value, no calls will be made.

The call to C<-E<gt>db_sync()> probably causes a performance hit.

=item B<single =E<gt> $value>

When set to true (the default), stores all the required elements as a
single hash. When set to false, each tuple is stored individually
within a hashref associated to the key.

=item B<frozen =E<gt> $value>

When set to true (the default), uses C<freeze()> from Storable(3) to
serialize the values prior to storing.

=item B<internal_tie =E<gt> $value>

When true, the default, C<tie()> will be performed on the hash. In
certain cases, you might want to "share" a hash. In these cases, the
actual tying can be done elsewhere.

=item B<hashref =E<gt> $hashref>

Tells the factory to work with an external hash. This is useful to
have external code modifying the underlying hash outside of a RADIUS
transaction.

If not provided, each call to C<-E<gt>mk()> ties a private hash. Note
that you can use C<hashref> in a call to C<-E<gt>new()>, and then all
the functions generated with C<-E<gt>mk()> will share the same hash.

=back

=head2 EXPORT

None by default.

=head1 BUGS

This code uses C<die()> currently, however it is likely that
C<croak()> would be better. The problem with this, is that using
C<croak()> as intended, results in Perl returning errors like this
one...

    Bizarre copy of HASH in sassign 
        at /usr/share/perl/5.10/Carp/Heavy.pm line 96.

while running C<make test> in my test machine. Since I don't want to
run any risks, I'll stick to the C<die()> calls which do not
manipulate the stack so much.

=head1 SEE ALSO

Perl(1), BerkeleyDB(3), Class::Accessor(3), MLDBM(3), MLDBM::Sync(3),
Net::Radius::Packet(3), Net::Radius::Server(3),
Net::Radius::Server::Base(3), Net::Radius::Server::NS(3),
Net::Radius::Server::Rule(3), Storable(3), Tie::DBI(3).

=head1 AUTHOR

Luis E. Muñoz, E<lt>luismunoz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2009 by Luis E. Muñoz

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL version 2.

=cut


