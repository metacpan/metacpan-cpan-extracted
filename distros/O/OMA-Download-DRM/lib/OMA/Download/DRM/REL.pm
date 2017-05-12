package OMA::Download::DRM::REL;
use strict;
=head1 NAME

OMA::Download::DRM::REL - Perl extension for packing REL objects according to the OMA DRM 1.0 specification.

=head1 DESCRIPTION

Open Mobile Alliance Digital Rights Management Rights Expression Language implementation

This is a partial implementation - Needs to be completed

=cut

BEGIN {
    use 5.8.7;
}
=head1 CONSTRUCTOR

=head2 new

  # $class can be OMA::Download::DRM::REL::XML or OMA::Download::DRM::REL::WBXML

  my $rel=$class->new(
      
        ### Mandatory
        'uid'                 => 'cid:image239872@example.com',
        'permission'          => 'display',   					# Can be either 'display', 'play', 'execute' or 'print'
        
        ### Optional
        'key'                 => 'im9aazbjfgsorehf',
        'count'               => 3
  );

=cut
### Class constructor ----------------------------------------------------------
sub new {
    my ($class, %arg)=@_;
    die "Need Permission argument" unless $arg{'permission'};
    my $self={
        'uid'            => $arg{'uid'},
        'permission'     => $arg{'permission'},
        'count'          => $arg{'count'},
        'key'            => $arg{'key'} || undef,
    };
    $self=bless $self, $class;
	$self->_init;
    $self;
}
### Properties -----------------------------------------------------------------
=head1 PROPERTIES

=head2 uid

Returns the unique identifier

  print $rel->uid;

=cut
sub uid {
    my ($self, $val)=@_;
    $self->{uid} = $val if $val;
    $self->{uid}
}

=head2 permission

Get or set permission type. Can be either 'display', 'play', 'execute' or 'print'
 
 print $rel->permission;

 $rel->permission('display');

=cut
sub permission {
    my ($self, $val)=@_;
    $self->{permission} = $val if $val;
    $self->{permission}
}

=head2 key

Get or set the encryption key

  print $rel->key;
  
  $rel->key('0123456789ABCDEF');

=cut
sub key {
    my ($self, $val)=@_;
    $self->{uid} = $val if defined $val;
    $self->{uid}
}

=head2 count

Get or set accesses count limit

  print $rel->count;

  $rel->count(3);

=cut
sub count {
    my ($self, $val)=@_;
    $self->{count} = $val if defined $val;
    $self->{count}
}
### Private methods --------------------------------------------------------------------
sub _packin {
    my $self=$_[0];
    
    # version
    my $context=$self->_in_element('context', $self->_in_element('version', $self->_in_string('1.0')));
    
    # agreement
    ## asset
    my $assetcontext=$self->_in_element('context', $self->_in_element('uid', $self->_in_string($self->{uid})));
    my $assetkeyinfo = $self->{key} ? $self->_in_element('KeyInfo', $self->_in_element('KeyValue', $self->_in_opaque($self->{key}))) : '';
    my $asset=$self->_in_element('asset', $assetcontext.$assetkeyinfo); 
    
    ## permission
    my $count=$self->_in_element('count', $self->_in_string($self->{count}));
    my $constraint = $self->_in_element('constraint', $count) if $self->{count};
    my $permission=$self->_in_element('permission', $self->_in_element($self->{'permission'}, $constraint)); 

    
    my $agreement=$self->_in_element('agreement', $asset.$permission); 

    return $context.$agreement;
}

1;
__END__
=head1 TODO

Use more than one permission, and other constraints than count

=head1 SEE ALSO

* OMA-Download-REL-V1_0-20040615-A

* OMA::Download::DRM::REL::XML

* OMA::Download::DRM::REL::WBXML

=head1 AUTHOR

Bernard Nauwelaerts, E<lt>bpn@localhostE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Bernard Nauwelaerts.

Released under the GPL.

=cut
