package Python::Serialise::Pickle;

use strict;
use Data::Dumper;
use IO::File;
use vars qw($VERSION);

$VERSION   = '0.01';



my %_set_handlers = (
	'NUMBER' => \&_set_num,
	'STRING' => \&_set_string,
	'HASH'   => \&_set_dict,
	'ARRAY'  => \&_set_list,
);


my %_get_handlers = ( 
		'I' => \&_get_num,
		'L' => \&_get_num,
		'F' => \&_get_num,
		'S' => \&_get_string,
		'N' => \&_get_none,
		'l' => \&_get_list,
		'd' => \&_get_dict,
		'c' => \&_get_raw,
		'p' => \&_get_id,
		'i' => \&_get_raw,
		'(' => \&_get_compound,
);


=head1 NAME

Python::Serialise::Pickle - a file for reading and writing pickled Python files

=head1 SYNOPSIS


    use Python::Serialise::Pickle;

    my $pr = Python::Serialise::Pickle->new("file/for/reading");
    while (my $data = $pr->load()) {
          print Dumper $data;
    }

    my $pw = Python::Serialise::Pickle->new(">file/for/writing");
    
    $pw->dump(['a' 'list']);
    $pw->dump("a string");
    $pw->dump(42);
    $pw->dump({'a'=>'hash'});

    $pw->close();  

=head1 DESCRIPTION

Pickling is a method of serialising files in Python (another method, 
Marshalling, is also available).

This module is an attempt to write a pure Perl implementation of the algorithm.


=head1 METHODS

=head2 new <filename>

Open a file for reading or writing. Can take any arguments that C<IO::File> can.

=cut 

sub new {
	my $class = shift;
	my $file  = shift || die "You must pass a file\n";

	## FIXME error here
	my $fh    = IO::File->new($file) || die "Couldn't open file\n";
	my $self = { _fh => $fh };

	return bless $self, $class;
	
}

=head2 load

Returns the next data structure from the pickle file or undef.

=cut

sub load {
	my $self = shift;
	$self->{_cur_id} = 0;

	print "LOAD\n";

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



	my $sub = $_set_handlers{$self->_type($val)};
	
	my $line = $self->$sub($val);
	$line .= ".";
	
	$self->_write($line);
	return $line;

}


sub _backup {
	my $self = shift;
	print "BACKUP\n";
	$self->{_fh}->seek(-1,1);
}


sub _get_char
{
	my $self = shift;
	$self->{_fh}->read(my $data, 1);
	print "C=$data\n";

	return $data;
}

sub _get_line {
	my $self = shift;
	my $line = "";

	while (1) {
		my $char = $self->_get_char();
		last unless defined $char;
		last if $char eq "\n";
		$line .= $char;
	}

	return $line;
}

sub _write {
	my $self = shift;
	my $val  = shift;

	$self->{_fh}->write($val);
}


sub _get_num 
{
	my $self = shift;
	my %opts = @_;

	my $num  = $self->_get_line();

	unless (defined $opts{'ignore_end_marker'} && $opts{'ignore_end_marker'} == 1) {
		$self->_get_char();
	}


	return $num;	
}

sub _set_num 
{
	my $self = shift;
	my $num  = shift;
	my %opts = @_;


	my $return;
	if (int $num != $num) {
		$return =  "F$num\n";
	} else {
		$return = "I$num\n";
	}

	 $return .= $opts{'terminator'} if ($opts{'terminator'});

	return $return;
}


sub _get_string 
{
	my $self = shift;
	my %opts = @_;


	my $string = $self->_get_line();
	$string =~ s!^(['"])(.*)['"]$!$2!;	
	$string =~ s!"!\\"!g;
	eval "\$string = \"$string\";";

	my $id     = $self->_get_id();
	die "No id!\n" unless defined $id;

	unless (defined $opts{'ignore_end_marker'} && $opts{'ignore_end_marker'} == 1) {
		$self->_get_char();
	}


	return $string;
	

}

sub _set_string
{
	my $self = shift;
	my $string = shift;
	my %opts = @_;

	# escape some control chars
	$string =~ s{
                (.)
            }{
                (ord($1)<33 || ord($1)>126)?sprintf '\\%.3o',ord($1):$1
            }sxeg;
	
	my $return = "S";
	if ($string =~ /^'.+'$/) {
		$return .= "\"$string\"\n";
	} else {
		$return .= "'$string'\n";
	}
	


	$return .= $self->_set_id();
	$return .= $opts{'terminator'} if ($opts{'terminator'});


	return $return;

}


sub _get_id {
	my $self = shift;
	my %opts = @_;

	my $char = $self->_get_char();
	die "Got $char - was expecting 'p' for id"  unless $char eq 'p';
	return $self->_get_line();
}

sub _set_id {
	my $self = shift;
	
	my $id = $self->{_cur_id}++;
	return "p$id\n";
}

sub _get_list {
	my $self = shift;
	my %opts = @_;

	print "GET LIST\n";

	my $oid   = $self->_get_id();
	my @vals;

	while (1) {	
		my $id = $self->_get_char();
		if ($id eq '.' || $id eq 's' || $id eq 'a') {
			last;
		}
		if ($id eq 'g') {
			my $tmp = $self->_get_line();
			last;
		}	

		if ($id eq 't') {
			$self->_backup;
			last;
		}

		
		my $sub = $_get_handlers{$id};
		print "ID=$id\n";
		$opts{'ignore_end_marker'}=0;
		die "No handler for '$id' in get_list ",(join ",",@vals),""  unless defined $sub;
		push @vals, $self->$sub(%opts);
		

	}	
	print "END LIST\n";
	return \@vals;
}

sub _set_list {
	my $self = shift;
	my $list = shift;
	my %opts = @_;
	
	my $terminator = $opts{'terminator'} || "";

	my $return = "";
	$return   .= "(" unless ($opts{ignore_compound});
	$return   .= "l";
	$return   .= $self->_set_id();	

	$opts{'terminator'} = 'a';

	foreach my $val (@$list) {
		my $sub = $_set_handlers{$self->_type($val)};
                die "No handler to set '$val'" unless defined $sub;
                $return .= $self->$sub($val, %opts);

	}

	$return .= $terminator;
	return $return;

}



sub _get_compound {
        my $self = shift;
	my %opts = @_;


	my $id = $self->_get_char();
	
	if ($id eq 'l') { 
		$self->_get_list(%opts);
	} elsif ($id eq 'd') { 
		$self->_get_dict(%opts);
	} else {
		$self->_backup();
		$self->_get_tuple(%opts);
	}
}


sub _get_tuple {
	my $self = shift;
	my %opts = @_;
	my $last_id = $opts{'last_tuple_marker'} || ".";

	my @vals;

	print "GET TUPLE\n";	

        while (1) {
                my $id = $self->_get_char();
	   	if ($id eq '.' || $id eq 'a' || $id eq 's') {
                        last;
                }

		if ($id eq 'g') {
			$self->_get_line();
			next;
		}
		
		if ($id eq 't') {
			$self->_get_id();
			print "Getting ID\n";
			if ($opts{'ignore_end_marker'}) {	
				last;
			} else {
				next;
			}
		}
	        
                my $sub = $_get_handlers{$id};
                die "No handler for type '$id'" unless defined $sub;
                push @vals, $self->$sub(ignore_end_marker=>1);
                
        }
	print "END TUPLE\n";
        return \@vals;
}


sub _get_dict
{
	my $self = shift;
	my %opts = @_;
	my %dict;

	print "GET DICT\n";
	print "IGNORE END MARKER = ",$opts{'ignore_end_marker'},"\n";
	#$opts{'ignore_end_marker'}=1;

		
	my $id = $self->_get_id();



	while (1) {
                my $key_id = $self->_get_char();
		
		


		if ($key_id eq '.')  {
			$self->_backup() if $opts{'ignore_end_marker'};
			last;
		}
		last if ($key_id eq 's' || $key_id eq 'a');
			
		if ($key_id eq 'g') {
			my $tmp = $self->_get_line();
                        next;
		}


                my $key_sub = $_get_handlers{$key_id};
                die "No handler for key '$key_id'" unless defined $key_sub;
		
		my $key = $self->$key_sub( ignore_end_marker => 1);
		
		print "GOT KEY\n";		
			
                my $val_id = $self->_get_char();
                my $val_sub = $_get_handlers{$val_id};
                die "No handler for value '$val_id'" unless defined $val_sub;
		my $val =  $self->$val_sub(%opts);

		$dict{$key} = $val;		



	}
	print "END DICT\n";
	

	return \%dict;

}

sub _set_dict 
{
	my $self = shift;
	my $hash  = shift;
        my %opts = @_;

	my $return = "";
        $return   .= "(";
        $return   .= "d";
        $return   .= $self->_set_id();
	

	$opts{'ignore_compound'}   = 0;
	$opts{'ignore_end_marker'} = 1;
	$opts{'terminator'}        = "";

	foreach my $key (keys %{$hash}) {
		my $val = $hash->{$key};
		
		my $keysub = $_set_handlers{$self->_type($key)};
                die "No handler for setting key '$key'" unless defined $keysub;
                $return .= $self->$keysub($key, %opts);

		my $valsub = $_set_handlers{$self->_type($val)};
                die "No handler for setting val '$val'" unless defined $valsub;
                $return .= $self->$valsub($val, %opts);
				

		$return .= "s";
	}	

	return $return;

}





sub _get_none {
	my $self = shift;
	return $self->_get_raw;

}

sub _get_raw {
	my $self = shift;
	$self->_backup;


	my $val = "";
	while (1) {
		my $char = $self->_get_char();	
		last if ($char eq ".");
		$val .= $char;
		$val .= $self->_get_line();
	}
	return $val;
		
}

sub _type {
	my $self = shift;
	my $val = shift;

	my $ref = ref $val;

	return $ref if defined $ref && $ref ne "";

	return "NUMBER" if ($val =~ /^-?(?:\d+(?:\.\d*)?|\.\d+)$/);
	return "STRING";

}


=head2 close

Closes the current file.

=cut 

sub close {
	my $self = shift;
	$self->{_fh}->close();
}

sub DESTROY {
	my $self = shift;
	$self->close();
}


=head1 BUGS

Almost certainly lots and lots.

=over 4

=item Serialised objects

At the moment we don't deal with serialised objects very well. 
Should probably just take or return a Python::Serialise::Pickle::Object 
object. 

=item The 'None' object

Similar to Perl's undef but an object. At the moment we deal with it badly 
because if we returned undef then that would signify the end of the Pickle file.

Should probably be returned as a special object or something.

=item Longs

There's no testing for longs

=item Unicode

Ditto

=item Some nested dictionaries

Dictionaries are the Python equivalent of hashes. This module can deal with most nested 
dictionaries but, for some reason, this one :

	a={'a':['two',{'goof':'foo', 'a':[1,2,3]}]}

causes it to fail.

Chnaging it slightly starts it working again.

=item Bad reading of specs

This is entirely my fault

=back

=head1 ALTERNATIVES

You could always dump the data structure out as YAML in Python
and then read it back in with YAML in Perl.

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

(c) 2003 Simon Wistow

Distributed under the same terms as Perl itself.

This software is under no warranty and will probably ruin your life,
kill your friends, burn your house and bring about the apocalypse.

=head1 SEE ALSO

http://www.python.org, L<YAML>, L<IO::File> and the RESOURCES file in 
this distribution.

=cut

1;
