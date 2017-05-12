package PersistentFile;

# c2ph gives us incorrect sizeof's for the total size of the structs

require 'perperl.ph';

my $FILEREV = 6;

sub new { my($class, $fname) = @_;
    bless {fname=>$fname}, $class;
}

sub fname { my $self = shift;
    $self->{fname} ||=
	sprintf("%s.${FILEREV}.%x.F", ($ENV{PERPERL_TMPBASE} || '/tmp/perperl'), $>);
}

sub data { my $self = shift;
    if (!$self->{data}) {
	open(F, $self->fname) || die $self->fname . ": $!\n";
	my $sz = (stat(F))[7];
	my $data;
	read(F, $data, $sz);
	$self->{data} = $data;
	close(F);
    }
    return $self->{data};
}

sub get_struct { my($self, $type, $offset) = @_;
    if ($type !~ /^_/) {
	$type = '_' . $type;
    }
    PersistentStruct->new(substr($self->data, $offset, ${"${type}'sizeof"}), $type);
}

sub file_head {
    shift->get_struct('_file_head', 0);
}

my $slot_size = &_dummy_slot'sizeof(_dummy_slot'slot);
my $slots_offset = $_file'offsetof[&_file'slots];

sub slot { my($self, $slotnum, $type) = @_;
    PersistentSlot->new($slotnum, $self, $type, $slots_offset + ($slotnum-1) * $slot_size);
}


package PersistentStruct;

my %pack_template = (
    1=>'C',
    2=>'S',
    4=>'I',
    8=>'Q',
);

sub new { my($class, $data, $type) = @_;
    bless {data=>$data, type=>$type}, $class;
}

sub fieldnames { my $self = shift;
    $self->{fieldnames} ||= [grep {/./ && !/slot_u/} @{$self->{type}. "'fieldnames"}];
}

sub value { my $self = shift;
    if (!$self->{value}) {
	my $type = $self->{type};
	my %value;
	foreach my $field (@{$self->fieldnames}) {
	    my $idx = &{"${type}'$field"};
	    my $size = ${"${type}'sizeof"}[$idx];
	    my $offset = ${"${type}'offsetof"}[$idx];
	    my $value;
	    if ($size == 8) {
		$value = sprintf('0x%x%08x',
		    unpack('I', substr($self->{data}, $offset)),
		    unpack('I', substr($self->{data}, $offset+4))
		);
	    }
	    elsif (my $t = $pack_template{$size}) {
		$value = unpack($t, substr($self->{data}, $offset));
	    }
	    else {
		$value = substr($self->{data}, $offset, $size);
	    }
	    $value{$field} = $value;
	}
	$self->{value} = \%value;
    }
    return $self->{value};
}

sub fmt_key_val { shift;
    sprintf('%-15s = %s', @_);
}

sub dump { my $self = shift;
    my @lines;
    my $value = $self->value;
    foreach my $fld (@{$self->fieldnames}) {
	push(@lines, $self->fmt_key_val($fld, $value->{$fld}));
    }
    return \@lines;
}


package PersistentSlot;

sub fmt_key_val {
    sprintf('%-15s = %s', @_);
}

sub new { my($class, $slotnum, $file, $type, $offset) = @_;
    my $self = {slotnum=>$slotnum, type=>$type};
    $self->{structs} = [
	$file->get_struct($type, $offset),
	$file->get_struct('slot', $offset),
    ];
    bless $self, $class;
}

sub fieldnames { my $self = shift;
    [map {$_->fieldnames} @{$self->{structs}}];
}

sub slotnum {shift->{slotnum}}

sub dump { my $self = shift;
    return [
	&fmt_key_val('slotnum', $self->{slotnum}),
	(map {@{$_->dump}} @{$self->{structs}}),
        &fmt_key_val('type', $self->{type}),
    ];
}

sub value { my $self = shift;
    return {map {%{$_->value}} @{$self->{structs}}};
}

1;
