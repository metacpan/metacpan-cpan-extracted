package Net::ISC::DHCPd::OMAPI::Actions;

=head1 NAME

Net::ISC::DHCPd::OMAPI::Actions - Common actions on OMAPI objects

=head1 DESCRIPTION

This module contains methods which can be called on each of the
L<Net::ISC::DHCPd::OMAPI> subclasses.

Changing object attributes will not alter the attributes on server. To do
so use L</write> to update the server.

=cut

use Moose::Role;

my $ATTR_ROLE = "Net::ISC::DHCPd::OMAPI::Meta::Attribute";

=head1 ATTRIBUTES

=head2 parent

 $omapi_obj = $self->parent;

Returns the parent L<Net::ISC::DHCPd::OMAPI> object.

=cut

has parent => (
    is => 'ro',
    isa => 'Net::ISC::DHCPd::OMAPI',
    required => 1,
);

=head2 errstr

 $str = $self->errstr;

Holds the latest error. Check this if a method returns empty list.

=cut

has errstr => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

=head2 extra_attributes

 $hash_ref = $self->extra_attributes;

Contains all attributes, which is not predefined by the OMAPI object.

Note: If you ever need to use this - send me a bug report, since it
means something is missing.

=cut

has extra_attributes => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} },
);

=head1 METHODS

=head2 read 

 $int = $self->read;

Open an object. Returns the number of attributes read. 0 = not in server.

It looks up an object on server, by all the attributes that has action
C<lookup>. Will update all attributes in the local object, and setting
all unknown objects in L</extra_attributes>.


This is subject for change, but:

C<read()> will also do a post check which checks if the retrieved values
actually match the one used to lookup. If they do not match all retrieved
data will be stored in L</extra_attributes> and this method will return
zero (0).

=cut

sub read {
    my $self = shift;
    my $post_check_failed = 0;
    my $n = 0;
    my(@out, %out);

    @out = $self->_open;

    %{ $self->extra_attributes } = (); # clear all extra attributes

    while($out[-1] =~ /(\S+)\s=\s(\S+)/g) {
        my($name, $value) = ($1, $2);
        $name =~ s/-/_/g;
        $value =~ s/^"(.*)"$/$1/;
        $n++;

        if(my $attr = $self->meta->get_attribute($name)) {

            if( #_ugly___________________________
                    $attr->does($ATTR_ROLE)
                and $self->${ \"has_$name" }
                and $attr->has_action('lookup')
            ) { #--------------------------------

                if($attr->should_coerce) {
                    $value = $attr->type_constraint->coerce($value);
                }

                if($self->$name ne $value) {
                    $post_check_failed = 1;
                }
            }

            $out{$name} = $value;
        }
        else {
            $self->extra_attributes->{$name} = $value;
        }
    }

    for my $name (keys %out) {
        if($post_check_failed) {
            $self->extra_attributes->{$name} = $out{$name};
        }
        else {
            $self->$name($out{$name});
        }
    }

    return $post_check_failed ? 0 : $n;
}

around read => \&_around;

=head2 write

 $bool = $self->write;
 $bool = $self->write(@attributes);

Will set attributes on server object.

C<@attributes> is by default every attribute on create, or every
attribute with action "modify" on update.

=cut

sub write {
    my $self = shift;
    my @attr = @_;
    my $new = 0;
    my(@cmd, @out);

    # check for existence
    @out = $self->_open;

    if(grep { /not found/i } @out) {
        $new = 1;
    }

    if(@attr == 0) {
        for my $attr ($self->meta->get_all_attributes) {
            my $name = $attr->name;

            next if(!$attr->does($ATTR_ROLE));
            next if(!$self->${ \"has_$name" });
            next if(!$attr->has_action('modify'));

            push @attr, $attr;
        }
    }

    @cmd = map { $self->_set_cmd($_) } @attr or return;

    # set attributes
    @out = $self->_cmd(@cmd);

    # update or create
    @out = $self->_cmd( $new ? "create" : "update" ) or return;

    if(grep { /not found/ } @out) {
        $self->errstr("not found");
        return;
    }

    return $new ? +1 : -1;
}

around write => \&_around;

=head2 unset

 $bool = $self->unset(@attributes);

Will unset values for an object in DHCP server.

=cut

sub unset {
    my $self = shift;
    my @attr = @_;
    my(@out, $success);
    
    @out = $self->_cmd(map { local $_ = $_; s/_/-/g; "unset $_" } @attr);

    # read @out:
    # ip-address = <null>
    # key = value
    # ...

    if($success) {
        $self->${ \"clear_$_" } for(@attr);
    }

    return 1;
}

around unset => \&_around;

=head2 remove

 $bool = $self->remove;

This method will remove the object from the server.

=cut

sub remove {
    my $self = shift;
    my @out;

    @out = $self->_open;
    @out = $self->_cmd('remove');

    if(grep { /not implemented/i } @out) {
        $self->errstr('not implemented');
        return;
    }
    if(grep { /not found/i } @out) {
        $self->errstr('not found');
        return;
    }

    for my $attr ($self->meta->get_all_attributes) {
        next unless($attr->does($ATTR_ROLE));
        my $clearer = 'clear_' .$attr->name;
        $self->$clearer;
    }

    return 1;
}

around remove => \&_around;

# @out = $self->_open;
sub _open {
    my $self = shift;
    my @cmd;

    for my $name ($self->meta->get_attribute_list) {
        my $attr = $self->meta->get_attribute($name);

        next unless($attr->does("Net::ISC::DHCPd::OMAPI::Meta::Attribute"));
        next unless($attr->has_action("lookup"));
        next unless($self->${ \"has_$name" });

        push @cmd, $self->_set_cmd($attr);
    }

    return $self->_cmd(@cmd, "open");
}

sub _set_cmd {
    my $self = shift;
    my $attr = shift;
    my $name = $attr->name;
    my $key = $name;
    my $format;

    $key =~ s/_/-/g;
    $format = $attr->type_constraint->equals('Str') ? 'set %s = "%s"'
            :                                         'set %s = %s';

    return sprintf $format, $key, $self->${ \"raw_$name" };
}

sub _around {
    my $next = shift;
    my $self = shift;
    my $type = lc +(ref($self) =~ /::(\w+)$/)[0];
    my(@out, @ret);

    $self->errstr("");

    @out = $self->_cmd("new $type") or return 0;
    @ret = $self->$next(@_);
    @out = $self->_cmd('close')     or return 0;

    return @ret == 1 ? $ret[0] : @ret;
};

# @buffer = $self->_cmd(@cmd)
# @buffer contains one-to-one output data from @cmd
# $self->errstr is reset each time empty errstr == success
sub _cmd {
    my $self = shift;
    my @cmd  = @_;
    my(@buffer, $head);

    for my $cmd (@cmd) {
        my $tmp = $self->parent->_cmd($cmd);
        last unless(defined $tmp);
        push @buffer, $tmp;
    }

    if($self->parent->errstr) {
        $self->errstr($self->parent->errstr);
        return;
    }

    return @buffer;
}

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut

1;
