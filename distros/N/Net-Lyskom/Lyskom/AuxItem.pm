package Net::Lyskom::AuxItem;
use base qw{Net::Lyskom::Object};

use strict;
use warnings;
use Carp;
use Net::Lyskom::Util qw{:all};

=head1 NAME

Net::Lyskom::AuxItem - Object representing a Protocol A AuxItem.

=head1 SYNOPSIS

  $ai = Net::Lyskom::AuxItem->new(
				  tag => "content_type",
				  data => "text/html"
				 );

=head1 DESCRIPTION

A helper module for Net::Lyskom

=head2 Methods

=over

=cut

our %type = (
	    content_type => 1,
	    fast_reply => 2,
	    cross_reference => 3,
	    no_comments => 4,
	    personal_comment => 5,
	    request_confirmation => 6,
	    read_confirm => 7,
	    redirect => 8,
	    x_face => 9,
	    alternate_name => 10,
	    pgp_signature => 11,
	    pgp_public_key => 12,
	    e_mail_address => 13,
	    faq_text => 14,
	    creating_software => 15,
	    mx_author => 16,
	    mx_from => 17,
	    mx_reply_to => 18,
	    mx_to => 19,
	    mx_cc => 20,
	    mx_date => 21,
	    mx_message_id => 22,
	    mx_in_reply_to => 23,
	    mx_misc => 24,
	    mx_allow_filter => 25,
	    mx_reject_forward => 26,
	    notify_comments => 27,
	    faq_for_conf => 28,
	    recommended_conf => 29,
	    allowed_content_type => 30,
	    canonical_name => 31,
	    mx_list_name => 32,
	    send_comment_to => 33,
	    mx_mime_belongs_to => 10100,
	    mx_mime_part_in => 10101,
	    mx_mime_misc => 10102,
	    mx_envelope_sender => 10103,
	    mx_mime_file_name => 10104
	   );

our %epyt = reverse %type;

=item new(tag => content_type, [...])

Create a new AuxItem object. All possible attributes can be set at 
creation time, by use of fairly standard arguments. What the attributes
are and what they mean can be found in the Protocol A documentation. All
names are kept the same, except that hyphens have been changed to underscores.

=cut

sub new {
    my $self = {};
    my $class = shift;
    my %a = @_;

    $class = ref($class) if ref($class);

    bless $self,$class;

    $self->tag($a{tag});

    if ($a{inherit_limit}) {
	$self->inherit_limit($a{inherit_limit})
    } else {
	$self->inherit_limit(0)
    }

    if ($a{deleted}) {
	$self->deleted($a{deleted})
    } else {
	$self->deleted(0)
    }

    if ($a{inherit}) {
	$self->inherit($a{inherit})
    } else {
	$self->inherit(0)
    }

    if ($a{secret}) {
	$self->secret($a{secret})
    } else {
	$self->secret(0)
    }

    if ($a{hide_creator}) {
	$self->hide_creator($a{hide_creator})
    } else {
	$self->hide_creator(0)
    }

    if ($a{dont_garb}) {
	$self->dont_garb($a{dont_garb})
    } else {
	$self->dont_garb(0)
    }

    $self->data($a{data});

    $self->{aux_no} = $a{aux_no} if $a{aux_no};
    $self->{creator} = $a{creator} if $a{creator};
    $self->{created_at} = $a{created_at} if $a{created_at};

    return $self;
}

sub new_from_stream {
    my $s = {};
    my $class = shift;
    my $arg = $_[0];

    $class = ref($class) if ref($class);
    bless $s,$class;

    $s->{aux_no}        = shift @{$arg};
    $s->{tag}           = shift @{$arg};
    $s->{creator}       = shift @{$arg};
    $s->{created_at}    = Net::Lyskom::Time->new_from_stream($arg);
    my $flags           = shift @{$arg}; 
    $s->{inherit_limit} = shift @{$arg};
    $s->{data}          = shift @{$arg};

    my($deleted, $inherit, $secret, $hide_creator, $dont_garb)
      = $flags =~ m/./g;
    $s->dont_garb($dont_garb);
    $s->hide_creator($hide_creator);
    $s->secret($secret);
    $s->inherit($inherit);
    $s->deleted($deleted);

    return $s;
}

=item data([$data])

Get or set the data attribute of the AuxItem.

=cut

sub data {
    my $self = shift;

    $self->{data} = $_[0] if defined $_[0];
    return $self->{data};
}

=item inherit_limit([$limit])

Get or set the inherit_limit attribute of the AuxItem.

=cut

sub inherit_limit {
    my $self = shift;

    $self->{inherit_limit} = $_[0] if defined $_[0];
    return $self->{inherit_limit};
}

=item tag([$tag])

Get or set the tag attribute of the AuxItem. It is a fatal error to use
a tag type that is not defined in the protocol specification.

=cut

sub tag {
    my $self = shift;

    return $self->{tag} unless defined $_[0];
    croak "Unknown AuxItem tag: $_[0]" unless $type{$_[0]};
    $self->{tag} = $type{$_[0]};
    return $self->{tag};
}

=item deleted([$boolean])

Get or set the deleted flag of the AuxItem.

=cut

sub deleted {
    my $self = shift;

    $self->{deleted} = ($_[0])?1:0 if defined $_[0];
    return $self->{deleted}
}

=item inherit([$boolean])

Get or set the inherit flag of the AuxItem.

=cut

sub inherit {
    my $self = shift;

    $self->{inherit} = ($_[0])?1:0 if defined $_[0];
    return $self->{inherit}
}

=item secret([$boolean])

Get or set the secret flag of the AuxItem.

=cut

sub secret {
    my $self = shift;

    $self->{secret} = ($_[0])?1:0 if defined $_[0];
    return $self->{secret}
}

=item hide_creator([$boolean])

Get or set the hide_creator of the AuxItem.

=cut

sub hide_creator {
    my $self = shift;

    $self->{hide_creator} = ($_[0])?1:0 if defined $_[0];
    return $self->{hide_creator}
}

=item dont_garb([$boolean])

Get or set the dont_garb attribute of the AuxItem.

=cut

sub dont_garb {
    my $self = shift;

    $self->{dont_garb} = ($_[0])?1:0 if defined $_[0];
    return $self->{dont_garb}
}

=item aux_no()

Get the aux_no attribute of the AuxItem.

=cut

sub aux_no {
    my $self = shift;

    warn "Attempt to set AuxItem aux_no after creation!" if $_[0];
    return $self->{aux_no};
}

=item creator()

Get the creator attribute of the AuxItem.

=cut

sub creator {
    my $self = shift;

    warn "Attempt to AuxItem set creator after creation!" if $_[0];
    return $self->{creator};
}

=item created_at()

Get the created_at attribute of the AuxItem. Returns a
C<Net::Lyskom::Time> object.

=cut

sub created_at {
    my $self = shift;

    warn "Attempt to set AuxItem created_at after creation!" if $_[0];
    return $self->{created_at}
}

=item as_string()

Return the object contents as a string.

=cut

sub as_string {
    my $s = shift;
    my $res = "AuxItem -> { ";

    foreach (keys %{$s}) {
	$res .= sprintf "%s => ",$_;
	if (ref $s->{$_}) {
	    $res .= $s->{$_}->as_string;
	    $res .= ", ";
	} else {
	    $res .= sprintf "%s, ",$s->{$_};
	}
    }
    $res .= " }";
    return $res;
}

=item to_server()

Return a reference to a four-element array representing this AuxItem, 
suitable for using as the third argument in a call to 
Net::Lyskom->create_text()

=cut

sub to_server {
    my $self = shift;
    my @res;

    $res[0] = $self->tag;
    $res[1] = sprintf("%s%s%s%s%s000",
		      $self->deleted?"1":"0",
		      $self->inherit?"1":"0",
		      $self->secret?"1":"0",
		      $self->hide_creator?"1":"0",
		      $self->dont_garb?"1":"0",
		     );
    $res[2] = $self->inherit_limit;
    $res[3] = holl($self->data);

    return @res;
}

=back

=cut

return 1;

=head1 AUTHOR

Calle Dybedahl <calle@lysator.liu.se>

=cut

