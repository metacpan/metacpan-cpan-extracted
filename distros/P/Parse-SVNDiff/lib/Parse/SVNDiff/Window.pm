
package Parse::SVNDiff::Window;

use base qw(Class::Tangram);

use strict;
use warnings;
use bytes;

use Parse::SVNDiff::Ber qw(parse_ber);
use Parse::SVNDiff::Instruction;

use Data::Lazy 0.06;

our $schema =
    { fields =>
      {
       int => [ qw( source_offset source_length target_length lazy ) ],
       idbif => [ qw(inst_data new_data instructions) ],
      }
    };

use constant DEFAULT_BLOCK_SIZE => 4096;

# size a block of something (data or instructions) has to be before we
# make it lazy
use constant MINIMUM_LAZY_SIZE => 16;

sub parse {
    my $self = shift;
    my $fh = shift;

    $self->set_source_offset(parse_ber($fh));
    $self->set_source_length(parse_ber($fh));
    $self->set_target_length(parse_ber($fh));

    my $inst_length = parse_ber($fh);
    my $data_length = parse_ber($fh);

    my $am_lout = $self->lazy;

    #kill 2, $$;

    if ( $am_lout and $inst_length >= MINIMUM_LAZY_SIZE ) {
	my $offset = tell($fh);

	# sadly, have to break encapsulation here, because I never
	# made Class::Tangram use "Want" et al.  it's self, anyway.
	tie $self->{instructions}, 'Data::Lazy',
	    sub {
		#kill 2, $$;
		my $oldpos = tell($fh);
		seek($fh, $offset, 0);
		$self->parse_instructions($fh, $inst_length);
		seek($fh, $oldpos, 0);
		return $self->{instructions};
	    };
	seek($fh, $inst_length, 1);
    } else {
	$self->parse_instructions($fh, $inst_length);
    }

    if ( $am_lout and $data_length >= MINIMUM_LAZY_SIZE ) {
	my $offset = tell($fh);
	tie $self->{new_data}, 'Data::Lazy',
	    sub {
		#kill 2, $$;
		my $oldpos = tell($fh);
		seek($fh, $offset, 0);
		local($/) = \$data_length;
		$self->set_new_data(<$fh>);
		seek($fh, $oldpos, 0);
		return $self->{new_data};
	    };
	seek($fh, $data_length, 1);
    } else {
	local($/) = \$data_length;
	my $new_data = <$fh>;
	$self->set_new_data($new_data);
    }
}

sub parse_instructions {
    my $self = shift;
    my $fh = shift;
    my $inst_length = shift;

    my $pos = tell $fh;

    local($/) = \1;

    my @inst;
    while ( <$fh> ) {
	my $selector = ord($_) >> 6;
	# following || not followed

	my $length = (ord($_) & 0b00111111) || parse_ber($fh);

	my $offset = (($selector == 0b10)
		      ? 0
		      : parse_ber($fh));

	#kill 2, $$ if
	     #( !defined($selector)
	       #or !defined($length)
	       #or !defined($offset) );
	push @inst, [ $selector, $length, $offset ];

	last if tell($fh) - $pos >= $inst_length;
    }
    #kill 2, $$;
    $self->set_instructions(\@inst);
}

sub open {
    my $self = shift;
    $self->new_data;
}

# if new_data chunks are sufficiently big (say, more than pipe
# buffering size), it might make sense to use this iterator version of
# new_data.  untested.

sub new_data_iter {
    my $self = shift;
    if ( $self->{new_data} ) {
	my $spent;
	return sub {
	    $spent++ ? "" : $self->{new_data};
	}
    } else {
	my ($fh, $offset, $length) = @{$self->{data}};
	my $max_size = (stat $fh)[11] || DEFAULT_BLOCK_SIZE;
	return sub {
	    return "" if $length == 0;
	    (tell($fh) == $offset)
		or (seek($fh, $offset, 0)
		    or die "fh $fh can't seek to $offset; $!");
	    local($/) = \($length > $max_size ? $max_size : $length);
	    my $chunk = <$fh>;
	    $offset += length($chunk);
	    $length -= length($chunk);
	    return $chunk;
	};
    }
}

sub dump {
    my $self = shift;

    my $inst_dump = join("", map {

	my ($selector, $length, $offset) = @$_;
	my $dump = "";
        if ($length >= 0b01000000) {
	    #untested branch
            $dump .= chr($selector << 6) . pack('w', $length);
        }
        else {
            $dump .= chr(($selector << 6) + $length);
	}
	unless ($selector == SELECTOR_NEW) {
	    $dump .= pack('w', $offset);
	}
	#kill 2, $$;
	$dump;
    } @{$self->instructions});

    #kill 2, $$;
    my $new_data = $self->new_data;

    return (pack('w w w w w',
		 (map { $self->$_ }
		  qw( source_offset source_length target_length )),
		 length($inst_dump), length($new_data),
		),
	    $inst_dump,
	    $new_data);
}

# 
sub apply_fh {
    my $self = shift;
    my $source_fh = shift;
    my $target_fh = shift;

    my $chunk_size = #eval{(stat $source_fh)[11]} ||
	DEFAULT_BLOCK_SIZE;

    my $data_offset   = 0;
    #my $target_offset = tell($target_fh);
    my $source_offset = $self->source_offset;

    # bah, would need to seek output stream without this.
    my $target_chunk = "";

    my $new_data = $self->new_data;

    foreach my $inst (@{$self->instructions}) {

	my ($selector, $length, $offset) = @{$inst};

	if ($selector == SELECTOR_SOURCE) {

	    seek($source_fh, $source_offset + $offset, 0);

	    local($/) = \$length;
	    $target_chunk .= <$source_fh>;
	    #_copy($source_fh, $target_fh, $length, $chunk_size);

	}
	elsif ($selector == SELECTOR_TARGET) {

	    my $overflow = -(length($target_chunk) - ($offset + $length));

	    if ($overflow <= 0) {
		# originally untested branch
		$target_chunk .= substr($target_chunk, $offset, $length);
	    }
	    else {
		$target_chunk .=
		    substr( ( substr($target_chunk, $offset)
			      x ( int($overflow / (length($target_chunk)
						   - $offset) ) + 1 )
			    ), 0, $length
			  );
	    }
	}
	else {
	    $target_chunk .= substr( $new_data,
				     0,
				     $length,
				     "" );
	}
    }

    print $target_fh $target_chunk;

}

our $chunk_size = 4096;

sub _copy {
    my ($source_fh, $target_fh, $length, $chunks);
    while ( $length > 0 ) {
	local($/) = \($length > $chunks ? $chunks : $length);
	my $chunk = <$source_fh>;
	$length -= length $chunk;
	print($target_fh, $chunk);
    }
}


1;


