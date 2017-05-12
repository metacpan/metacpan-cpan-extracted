package Python::Serialise::Marshal;

use strict;
use IO::File;
use File::Binary;
use Math::Complex;
use vars qw($VERSION);

$VERSION   = '0.02';


my %_set_handlers = (
	
	'NONE'    => \&_set_none,
        'INTEGER' => \&_set_int,
        'FLOAT'   => \&_set_float,
	'LONG'    => \&_set_long,
        'STRING'  => \&_set_string,
        'HASH'    => \&_set_dict,
        'ARRAY'   => \&_set_mylist,
	'COMPLEX' => \&_set_complex,
);


my %_get_handlers = ( 
		'N' => \&_get_none,
                'i' => \&_get_int,
#               'l' => \&_get_long, # long support is broken
                'f' => \&_get_float,
		's' => \&_get_string,
		'(' => \&_get_list,
		'[' => \&_get_list,
		'{' => \&_get_dict,
		'x' => \&_get_complex,
);


=head1 NAME

Python::Serialise::Marshal - a module for reading and writing marshalled Python files

=head1 SYNOPSIS


    use Python::Serialise::Marshal;

    my $pr = Python::Serialise::Marshal->new("file/for/reading");
    while (my $data = $pr->load()) {
          print Dumper $data;
    }

    my $pw = Python::Serialise::Marshal->new(">file/for/writing");
    
    $pw->dump(['a' 'list']);
    $pw->dump("a string");
    $pw->dump(42);
    $pw->dump({'a'=>'hash'});

    $pw->close();  

=head1 DESCRIPTION

Marshalling is a method of serialising files in Python (another method, 
Pickling, is also available). It is the method that Mailman uses to store 
its config files.

This module is an attempt to write a pure Perl implementation of the algorithm.

=head1 METHODS

=head2 new <filename>

Open a file for reading or writing. Can take any arguments that C<IO::File> can.

=cut 


sub new {
        my $class = shift;
        my $file  = shift || die "You must pass a file\n";

        ## FIXME error here
        my $fh    = File::Binary->new($file) || die "Couldn't open file\n";
        my $self = { _fh => $fh };

	$self->{_fh}->set_endian($File::Binary::BIG_ENDIAN);

        return bless $self, $class;
        
}




=head2 load

Returns the next data structure from the marshalled file or undef.

=cut

sub load {
        my $self = shift;
        $self->{_cur_id} = 0;


        my $id = $self->_get_char();
        return undef if (!defined $id or $id eq "");

        my $sub = $_get_handlers{$id}    || die "We have no handler to deal with '$id'\n";
        return $self->$sub();

}

=head2 dump <data structure>

Takes a ref to an array or a hash or a number or string and pickles it. 

Structures may be nested.

=cut



sub dump {
        my $self = shift;
        my $val  = shift;

	my $type = $self->_type($val);
        my $sub  = $_set_handlers{$type} || die "We have no handler for value '$val' of type $type";
        
        return $self->$sub($val);
        
        #$self->_write($line);
        #return $line;

}

sub _write {
	my $self = shift;
	my $line = shift;

	$self->{_fh}->put_bytes($line);
}


sub _get_char
{
        my $self = shift;
	return $self->{_fh}->get_bytes(1);

}

sub _put_char
{
	my $self = shift;
	my $char = shift;
	$self->{_fh}->put_bytes($char);
}


sub _get_int {
	my $self = shift;

	return $self->{_fh}->get_si32();


}

sub _set_int {
	my $self = shift;
	my $val  = shift;

	$self->_put_char('i');
	$self->{_fh}->put_si32($val);
}

sub _get_long {
	my $self = shift;

	return 0;


}

sub _get_float {
	my $self = shift;
	my $size = $self->{_fh}->get_ui8();
	return $self->{_fh}->get_bytes($size);	

}

sub _set_float {
	my $self = shift;
	my $val  = shift;

	$self->_put_char('f');
	$self->{_fh}->put_ui8(length($val));
	$self->{_fh}->put_bytes($val);	

}

sub _get_string {
	my $self = shift;
	my $size = $self->{_fh}->get_ui32();
	
	if ($size>0) {
		return $self->{_fh}->get_bytes($size);
	} else {
		return "";
	}
}

sub _set_string {
	my $self = shift;
	my $val  = shift;
	$self->_put_char('s');
	$self->{_fh}->put_ui32(length $val);
	$self->{_fh}->put_bytes($val);
}

sub _get_list {
	my $self = shift;
	my $n    = $self->{_fh}->get_ui32();
	my @return;
	foreach (1..$n) {
		push @return, $self->load();
	}

	return \@return;
}

sub _set_mylist {
	my $self = shift;
	my $arr  = shift;
	
	$self->_put_char('[');
	$self->{_fh}->put_ui32(scalar @$arr);
	foreach my $val (@$arr) {
		 my $type = $self->_type($val);
             	 my $sub  = $_set_handlers{$type} || die "We have no handler for value '$val' of type '$type'\n";
        	 $self->$sub($val);
	}
	return 1;
}


sub _get_dict {
	my $self = shift;

	my %hash;
	while (1) {
      		my $id = $self->_get_char();
        	return undef if (!defined $id or $id eq "");
		last if $id eq '0';

  	      	my $sub = $_get_handlers{$id}    || die "We have no handler to deal wwith '$id'\n";
        	my $key = $self->$sub();
		
		$id  = $self->_get_char();
  	      	$sub = $_get_handlers{$id}    || die "We have no handler to deal wwith '$id'\n";
        	my $value = $self->$sub();
		
		$hash{$key} = $value;

	}

	return \%hash;
}


sub _set_dict {
	my $self = shift;
	my $hash = shift;

	$self->_put_char('{');
	foreach my $key (keys %$hash) {
                 my $ktype = $self->_type($key);
                 my $ksub  = $_set_handlers{$ktype} || die "We have no handler for key '$key' of type '$ktype'\n";
                 $self->$ksub($key);

		 my $val = $hash->{$key};
                 my $vtype = $self->_type($val);
                 my $vsub  = $_set_handlers{$vtype} || die "We have no handler for value '$val' of type '$vtype'\n";
                 $self->$vsub($val);

	}
	$self->_put_char('0');

}

sub _get_none {
	return Python::Serialise::None->new();
}

sub _set_none {
	my $self = shift;
	$self->_put_char('N');
}

sub _get_complex {
	my $self = shift;

	my $rsize = $self->{_fh}->get_ui8();
	my $real  = $self->{_fh}->get_bytes($rsize);

	my $isize = $self->{_fh}->get_ui8();
	my $imag  = $self->{_fh}->get_bytes($isize);

	my $comp = Math::Complex->new($real, $imag);
	$comp->display_format('cartesian');

	return $comp;
}

sub _set_complex {
	my $self = shift;
	my $comp = shift;
	
	my $real = Re($comp);
	my $imag = Im($comp);

	$self->_put_char('x');
	$self->{_fh}->put_ui8(length $real);
	$self->{_fh}->put_bytes($real);

	$self->{_fh}->put_ui8(length $imag);
	$self->{_fh}->put_bytes($imag);

}

=head2 close

Closes the current file.

=cut 

sub close {
        my $self = shift;
        $self->{_fh}->close();
}


sub _type {
        my $self = shift;
        my $val = shift;

	return "NONE" unless defined $val;

        my $ref = ref $val;	
	return "NONE" if defined $ref and UNIVERSAL::isa($val,'Python::Serialise::None');
	return "COMPLEX" if defined $ref and UNIVERSAL::isa($val,'Math::Complex');

        return $ref if defined $ref && $ref ne "";

	return "INTEGER" if ($val =~ /^[+-]?\d+$/);
        return "FLOAT"   if ($val =~ /^-?(?:\d+(?:\.\d*)?|\.\d+)$/);
        return "STRING";

}

=head1 NOTES

=head2 Complex numbers

Python has inbuilt support form complex numbers whilst Perl 
provides it through the core module C<Math::Complex>. Unserialising 
a Python complex number will return a C<Math::Complex> object 
and, as you'd expect, serialising something that ISA C<Math::Complex>
will result in a serialised Python complex number.

=head2 None

Python has C<None> objects, similar to Perl's C<undef>. 

Because I<load> indictaes "no more objects" by returning C<undef>
we have to return C<Python::Serialise::None> objects. However dump can 
take C<undef> and serialise it as a C<None> object.

=cut

=head1 BUGS

Much less than my C<Pickle> module because this is a 
I<much> saner file format.

=over 4

=item Tests for None

I can't think of a nice elegant way of doing tests at the moment.

I'm sure I will soon.

=item Longs

There's no support for longs. I've figured out how to write them in 
Python but I just can't seem to extract them properly.

=item Unicode

Not an itch that needs scratching at the moment so there's no support.

=item Code

Ditto

=back

=head1 ALTERNATIVES

You could always dump the data structure out as YAML in Python
and then read it back in with YAML in Perl.

I also may look into wrapping the Python source code file in XS.

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

(c) 2003 Simon Wistow

Distributed under the same terms as Perl itself.

This software is under no warranty and will probably ruin your life,
kill your friends, burn your house and bring about the apocalypse.

=head1 SEE ALSO

http://www.python.org, L<YAML>, L<File::Binary>, L<Math::Complex> 
and the RESOURCES file in this distribution.

=cut



package Python::Serialise::None;

sub new {
	my $class = shift;
	return bless {}, $class;	
}

1;
