package Net::PSYC::MMP::Compress;

use strict;

use Compress::Zlib;

my $dict = "_source_targetpsyc://_notice";

sub new {
    my $class = shift;
    my $obj = shift;
    my $self = {
	'connection' => $obj,
    };
    
    bless $self, $class;
    
    return $self;
}

sub init {
    my $self = shift;
    my $hook = shift;

    my $status;
    if ($hook eq 'decrypt') {
#	($self->{'i'}, $status) = inflateInit( Dictionary => $dict );
	($self->{'i'}, $status) = inflateInit( );
if (Net::PSYC::FORK) {
	$self->{'connection'}->hook('receive', $self, 10);
} else {
	$self->receive();
}
	if ($status == Z_OK) {
	    $self->{'connection'}->hook('decrypt', $self, 10);
	    return 1;
	}
    } elsif ($hook eq 'encrypt') {
#	($self->{'d'}, $status) = deflateInit( Dictionary => $dict );
	($self->{'d'}, $status) = deflateInit( );
	if ($status == Z_OK) {
	    $self->{'connection'}->hook('encrypt', $self, -10);
	    return 1;
	}
    }
    return 0;
}

sub receive {
    my $self = shift;
    $self->{'connection'}->rmhook('receive', $self);

    my ($out, $status) = $self->{'i'}->inflate(\$$self{'connection'}->{'I_BUFFER'});
    if ($status == Z_OK) {
	$self->{'connection'}->{'I_BUFFER'} = $out;
	return 1;
    }
    Net::PSYC::W0('Could not decompress the incoming stream from %s: %s',
	$self->{'connection'}->{'psycaddr'}, $self->{'i'}->msg());
    return 0;	
}

sub encrypt {
    my $self = shift;
    my $data = shift;
   
    my ($out, $status) = $self->{'d'}->deflate($data);
    if ($status == Z_OK) {
	$$data = $out;
	($out, $status) = $self->{'d'}->flush(Z_PARTIAL_FLUSH);
	$$data .= $out;
	return 1;
    }
    print STDERR "Zlib encryption for $self->{'connection'}->{'R_IP'}:$self->{'connection'}->{'R_PORT'} failed: $status (".$self->{'d'}->msg().")\n";
    return 0;
}

sub decrypt {
    my $self = shift;
    my $data = shift;
    
    unless ($self->{'i'}) {
	print STDERR "You did not prepare me for zlib-deflation for $self->{'connection'}->{'R_IP'}:$self->{'connection'}->{'R_PORT'}\n";
	return -1;
    }
    
    # TODO find out whether its better to use compress/uncompress. these
    # objects seem to be rather unneeded.
    
    my ($out, $status) = $self->{'i'}->inflate($data);
    if ($status == Z_OK) {
	$$data = $out;
	return 1;
    }
    print STDERR "Zlib decryption for $self->{'connection'}->{'R_IP'}:$self->{'connection'}->{'R_PORT'} failed: $status (".$self->{'i'}->msg().")\n";
    return 0;
}

sub status {
    my $self = shift;
    my $return = "_compress status:\n";
    if ($self->{'d'}) {
	$return .= "OUT: ".$self->out_rate()."\n";
    }
    if ($self->{'i'}) {
	$return .= "IN: ".$self->in_rate()."\n";
    }
}

# compression rates for incoming/outgoing data
sub in_rate {
    my $self = shift;
    unless ($self->{'i'}) {
	return 1;
    }
    return $self->{'i'}->total_out() / $self->{'i'}->total_in();
}

sub out_rate {
    my $self = shift;
    unless ($self->{'d'}) {
	return 1;
    }
    return $self->{'i'}->total_in() / ($self->{'i'}->total_out()||1);
}
1;

__END__

#define Z_OK            0
#define Z_STREAM_END    1
#define Z_NEED_DICT     2
#define Z_ERRNO        (-1)
#define Z_STREAM_ERROR (-2)
#define Z_DATA_ERROR   (-3)
#define Z_MEM_ERROR    (-4)
#define Z_BUF_ERROR    (-5)
#define Z_VERSION_ERROR (-6)

