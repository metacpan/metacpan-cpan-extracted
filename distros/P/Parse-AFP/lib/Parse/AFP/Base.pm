package Parse::AFP::Base;

use strict;
use Parse::Binary;
use base 'Parse::Binary';
use constant BASE_CLASS => 'Parse::AFP';
use constant DEFAULT_ARGS => ( Length => 0 );

sub padding {
    my ($self, $field) = @_;
    my $padding = $self->PADDING;
    return $padding if defined($padding);
    return "\xFF" x $self->member_length_bytes;
}

sub member_length_bytes {
    my ($self) = @_;
    my ($field) = $self->member_fields or return 0;
    $self->field_format($field) =~ m{(\S+)/} or return 0;
    return length(pack($1, 0));
}

sub refresh_length {
    my ($self) = @_;
    if ($self->has_field('Length')) {
	my $length = length($self->dump);
	foreach my $field ($self->fields) {
	    last if $field eq 'Length';
	    $length -= $self->field_length($field);
	}
	$self->SetLength($length);
    }
}

sub refresh_parent {
    my ($self) = @_;
    $self->refresh_length;
    $self->SUPER::refresh_parent;
}

sub load_size {
    my ($self, $data) = @_;
    $self->SUPER::load_size($data);
    if ($self->has_field('Length')) {
	$self->SetLength( $self->Length + $self->field_length('Length') );
    }
}

sub dump {
    my ($self) = @_;

    local $SIG{__WARN__} = sub {};
    return $self->SUPER::dump unless $self->has_members;

    my $out = '';
    foreach my $field ($self->fields) {
	my $packer = $self->field_packer($field) or die "No packer for $field\n";

	if ($self->member_class($field)) {
	    my $format = $packer->{Format}[0];
	    my $prefix = ($format =~ m{\((.*?)/}) ? $1 : '';
	    my $length = $self->member_length_bytes;

	    foreach my $member (@{$self->field($field)}) {
		my $rv = $packer->format({ $field => $member });
		if ($prefix) {
		    my @leading = unpack($prefix, $rv);
		    $leading[-1] += $length;
		    my $leading = pack($prefix, @leading);
		    substr($rv, 0, length($leading), $leading);
		}
		$out .= $rv;
	    }
	}
	else {
	    $out .= $packer->format($self->struct);
	}
    }

    $self->set_size(length($out));
    return $out;
}

sub set_field_arrayref {
    my ($self, $field, $data) = @_;
    @{$self->struct->{$field}||=[]} = @{$data||[]};
}

sub validate_memberdata {
    my ($self, $field) = @_;
    $field = $self->field($field) or return;
    @$field = grep {
	ref($_) eq 'CODE' or $self->valid_memberdata($field, $_)
    } @$field;
}

sub spawn_obj {
    my $self = shift;
    my $obj = $self->spawn(CC => '5a', @_);
    @{$obj}{qw( lazy output )} = @{$self}{qw( lazy output )};
    $obj->refresh;
    return $obj;
}

1;
