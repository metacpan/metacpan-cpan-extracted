package PDF::Tiny;

use 5.01;

$VERSION = '0.09'; # Update the POD, too!

# Fields
sub vers () { 0 }
sub fh   () { 1 }
sub trai () { 2 } # trailer
sub id   () { 3 } # original doc ID
sub stxr () { 4 } # startxref, used for /Prev when appending
sub file () { 5 } # file name
sub size () { 6 } # object count + 1
sub free () { 7 } # array of free object ids

# Hash fields; must be consecutive
sub xrft () { 8 } # xref table
sub mods () { 9 } # modified objects
sub objs () {10 }

sub impo () {12 } # imported objects

sub DEBUG () { 0 }

sub croak {
 die "$_[0] at " . join(' line ', (caller(DEBUG ? 0 : 1+$_[1]))[1,2])
                 . ".\n";
}

$null = ['null'];

use warnings; no warnings qw 'numeric uninitialized';

# REGEXPS FOR PARSING

$S = '[\0\t\cj\cl\cm ]'; # PDF whitespace chars
$_S = '[\0\t\cl ]'; #PDF whitespace chars except line breaks
$N = '(?:\cm\cj?|\cj)'; # PDF line break chars
$D = '[\(\)<>\[\]\{\}\/]'; # PDF delimiter characters (except %);
$R = '[^\0\t\cj\cl\cm \(\)<>\[\]\{\}\/%]'; # PDF regular characters


# CONSTRUCTOR

sub new {
 my $class = shift;
 my ($file, %opts);
 if (@_ == 1) {
  $file = shift;
 }
 else {
  %opts = @_;
  $file = $opts{filename};
 }
 my $self = [];
 $self->[file] = $file;
 $self->[$_] = {} for xrft..objs; # This is why they must be consecutive.
 $self->[free] = [];
 bless $self, $class;
 if (defined $file) {
  open my $fh, "<", $file or croak "Cannot open $file: $!";
  binmode $self->[fh] = $fh;
  defined read $fh, my $read, 1024 or croak "Cannot read $file: $!";
  if ($read !~ /%PDF-([0-9.]+)/) {
   croak "The file $file is not a PDF";
  }
  $self->[vers] = $1;
  _parse_xref($self);
  $self->[size] = $self->[trai][1]{Size}[1];
  if ($self->[trai][1]{ID}) {
   $self->[id] = $self->[trai][1]{ID}[1][0][1];
  }
 }
 else {
  $self->[vers] = $opts{version} || 1.4;
  $self->[trai] = make_dict(my $trailer_hash = {});
  if (!$opts{empty}) {
   $$trailer_hash{Root} = make_ref("1 0");
   @{$self->[objs]}{"1 0","2 0"} =
    ( make_dict({
              Type => make_name("Catalog"), Pages => make_ref("2 0")
      }),
      make_dict({
       Type => make_name("Pages"),
       Kids => make_array([]),
       Count => make_num(0)
     })
    );
   $self->[size] = 3;
  }
  else { $self->[size] = 1; }
 }
 $self;
}

sub _parse_xref {
	my($self) = shift;
	my $fh = $self->[fh];
	seek $fh, -1024,2 or seek $fh, 0,0;
	read $fh, my $read, 1024
		or croak "Cannot read $self->[file]: $!", 1;
	$read =~ /startxref$N(\d+)$N%%EOF$N?$/o;

	$self->[stxr] = my $startxref = $1;
	my $xref = $self->[xrft];
	
	my $trailer;
	while(defined $startxref){
		# read from the position indicated by $startxref, up to the word
		# "startxref"
		
		seek $fh, $startxref, 0 
			or croak "Cannot seek in $self->[file]: $!",1;
		read $fh, my $read, 1024, length $read
			 or croak "Cannot read $self->[file]: $!", 1;
		if ($read =~ /^$S*[0-9]/o) { # cross-reference stream
			my $obj = _read_obj($self, $startxref);
			my $stream = $self->decode_stream($obj);
			$trailer = $$obj[1];
			my $hash = $$trailer[1];
			my @widths = map $$_[1], @{$$hash{W}[1]};
			my $width = $widths[0] + $widths[1] + $widths[2];
			my $unpack = join '', map "H".$_*2, @widths;
			my @indices = $$hash{Index}
				? map $$_[1], @{$$hash{Index}[1]}
				: (0, $$hash{Size}[1]);
			my ($ix, $last) = splice @indices, 0, 2;
			$last += $ix - 1;
			while (length $stream) {
				my($type,$where,$gen)
					= map hex,
					      unpack $unpack,
					             substr $stream, 0,
					                    $width, '';
				$widths[0] or $type = 1;

				if ($type == 1) {
					my $obj_ref = "$ix $gen";
					!exists $$xref{$obj_ref}
					 and $$xref{$obj_ref} = $where;
				}
				elsif ($type == 2) {
					my $obj_ref = "$ix 0";
					!exists $$xref{$obj_ref}
					 and $$xref{$obj_ref} =
					      ["$where 0", $gen];
				}
				else { # free
					push @{$self->[free]}, "$ix $gen"
					 if $ix && $gen != 65535
				}
				if ($ix++ > $last) {
					($ix, $last) = splice @indices,0,2;
					$last += $ix - 1;
				}
			}
		}
		else {
		    while($read !~ /startxref/){
			read $fh, $read, 1024, length $read
			 or croak "Cannot read $self->[file]: $!", 1;
		    }
		    $read =~ /xref(.*?)trailer(.*)/s;
		    my $xreftext =$1;

		    $trailer = parse_string("$2",qr/^startxref\z/);

		    # remove initial line, and read the numbers,
		    # repeating as necessary

		    while ($xreftext=~ s/^$N?(\d+) (\d+).*?$N//o) {
			for ($1..$1+$2-1) { 	
				#$xreftext =~ s/(.{20})//s; # get 20 bytes
				my $_1 = substr($xreftext,0,20,'');
				my $obj_ref =  "$_ " . substr($_1,11,5)*1;
				if (substr ($_1, 17,1) eq 'n') {
					!exists $$xref{$obj_ref}
					  and $$xref{$obj_ref} =
							  substr($_1,0,10);
					# (See PDF Reference [5th ed.], p. 70.)
				}
				else { # free
					push @{$self->[free]}, $obj_ref
					 unless substr($_1,11,5) == 65535
				}
			}
		    }
		}
		unless ($self->[trai]) {
			$self->[trai] = $trailer;
			exists $$trailer[1]{Encrypt}
				and croak "$self->[file] is encrypted", 1;
		}

		$trailer = $$trailer[1];
		$startxref = defined $$trailer{Prev} ? $$trailer{Prev}[1] : undef;
	}

}

# HIGH-LEVEL METHODS

sub page_count {
 $_[0]->get_obj("/Root", "/Pages", "/Count")->[1]
}

sub _walk_pages {
	my $self = shift;
	my $pages = shift || $self->get_obj("/Root", "/Pages")
	                  || return wantarray ? () : 0;
	my @pages;		# output
	my $kids = $self->get_obj($pages, "/Kids");
	if ($self->get_obj($pages, "/Count")->[1] == @{$$kids[1]}) {
         return @{$$kids[1]}
	}
	my $kid;
	for (0 .. $#{$$kids[1]}){
		$kid = $$kids[1][$_];
		push @pages, ${$self->get_obj($kid, '/Type')}[1] eq 'Pages'
			? _walk_pages($self, $kid)
			: $kid;
	}
	return @pages;
}

sub delete_page {
 my ($self, $num,) = @'_;
 my $root = $self->get_obj("/Root");
 my $pages_id = $$root[1]{Pages}[1];
 my $pages = $self->get_obj($pages_id);
 my $pages_array = $self->get_obj($pages, '/Kids');
 my $count = $self->get_obj($pages, "/Count");
 if (@{$pages_array->[1]} != $count->[1]) {
  # Flatten the pages array.  Other structures just require too much code.
  _flatten_pages($self, $pages_id, $pages, $pages_array);
 }
 splice @{$pages_array->[1]}, $num, 1;
 $count->[1]--;
 _:
}

sub import_page {
 my ($self, $source_pdf, $num, $whither) = @'_;
 my @pages = _walk_pages($source_pdf);
 my $page_to_import =
  $source_pdf->get_obj(($pages[$num] || croak "No such page: $num")->[1]);

 # We cannot simply use import_obj.  import_obj will follow the /Parent
 # link and import the entire page tree from the source PDF.
 # Furthermore, if the values of /Resources, /MediaBox and /CropBox are
 # inherited from the parent node that we are not importing, they need to
 # be transferred to the page object itself.
 my $temp_copy = [@$page_to_import];
 $temp_copy->[1] = {%{ $temp_copy->[1] }};
 my $node = $temp_copy;
 while (!$temp_copy->[1]{Resources} || !$temp_copy->[1]{MediaBox}
     || !$temp_copy->[1]{CropBox} and $node->[1]{Parent}) {
   $node = $source_pdf->get_obj($node, '/Parent');
   $node->[1]{$_} and !$temp_copy->[1]{$_}
                  and  $temp_copy->[1]{$_} = $node->[1]{$_}
     for qw< Resources MediaBox CropBox >;
 }
 delete $temp_copy->[1]{Parent};
 my $page_id =
  $self->add_obj(my $real_copy=$self->import_obj($source_pdf, $temp_copy));
 
 my $root = $self->get_obj("/Root");
 my $pages_id = $$root[1]{Pages}[1];
 $real_copy->[1]{Parent} = ['ref',$pages_id];
 my $pages = $self->get_obj($pages_id);
 my $pages_array = $self->get_obj($pages, '/Kids');
 my $count = $self->get_obj($pages, "/Count");
 if (@{$pages_array->[1]} != $count->[1]) {
  # Flatten the pages array.  Other structures just require too much code.
  _flatten_pages($self, $pages_id, $pages, $pages_array);
 }
 splice @{$pages_array->[1]}, $whither//@{$pages_array->[1]}, 0,
        ['ref',$page_id];
 $count->[1]++;
 _:
}
sub _flatten_pages {
 my ($self, $pages_id, $pages, $pages_array) = @ '_;
 my @pages = _walk_pages($self, $pages);
 for (@pages) {
  my $page = $self->get_obj($_);
  next if $page->[1]{Parent}[1] eq $pages_id;
  my $node = $page;
  while (!$page->[1]{Resources} || !$page->[1]{MediaBox}
      || !$page->[1]{CropBox} and $node->[1]{Parent}[1] ne $pages_id) {
    $node = $self->get_obj($node, '/Parent');
    $node->[1]{$_} and $page->[1]{$_} = $node->[1]{$_}
      for qw< Resources MediaBox CropBox >;
  }
  $page->[1]{Parent}[1] = $pages_id;
 }
 $pages_array->[1] = \@pages;
}

sub append {
 my $self = shift;
 if (!defined $self->[file]) {
  croak "No file to write to!"
 }
 if (!%{$self->[mods]}) {
  return;
 }
 if ($self->[trai][1]{Type}) {
  croak "Cannot append to files with cross-reference streams";
 }
 open my $fh, ">>", $self->[file]
   or croak "Cannot open $self->[file] for writing: $!";
 binmode $fh;
 local ($\,$,);
 print $fh "\n";  # The existing %%EOF might not have \n after it

 # Update the doc ID now.  If it already exists, it might be an indirect
 # object, in which case changes to it must included in the objects that we
 # append to the file before we reach the trailer.
 my $id_array = $self->vivify_obj('array',"/ID");
 if (@{$$id_array[1]} == 2
      and $self->vivify_obj('str', $id_array, 0)->[1] ne $self->[id]
       || $self->vivify_obj('str', $id_array, 1)->[1] ne $self->[id]) {
  # User has assigned his own id.  Leave it alone.
 }
 else {
  $self->vivify_obj('str', $id_array, 0)->[1]
    ||= time."" ^ "".rand ^ "".(0+$self);
  $self->vivify_obj('str', $id_array, 1)->[1]
     ^= time."" ^ "".rand ^ "".(0+$self);
  @{$$id_array[1]} = @{$$id_array[1]}[0,1];
 }

 my %offsets;
 my @ids = grep $self->[objs]{$_}, sort {$a<=>$b} keys %{$self->[mods]};
 for (@ids) {
  my $obj = $self->[objs]{$_};
  $offsets{$_} = tell $fh;
  
  if ($$obj[0] eq 'stream') {
   print $fh join_tokens(
              $_,'obj',
              _serialize($obj)
             ), $$obj[2], "\nendstream endobj\n"
  }
  else {
   print $fh join_tokens(
              $_,'obj',
              _serialize($obj),
              "endobj"
             ), "\n";
  }
 }
 my $startxref = tell $fh;
 print $fh "xref\n";
 # Divide the ids into chunks of consecutive numbers
 my @chunks = ['0 65535'];
 $offsets{'0 65535'} = $self->[free][0];
 for (@ids) {
  if ($chunks[-1][-1] + 1 != $_) {
   push @chunks, [];
  }
  push @{$chunks[-1]}, $_
 }
 for (@chunks) {
  printf $fh "%d %s\n", $$_[0], scalar @$_;
  printf $fh "%010d %05d %s \n",
              $offsets{$_}, /\ (\d+)/, $_ == 0 ? "f" : "n"
   for @$_;
 }
 my $trailerhash = $self->[trai]->[1];
 $trailerhash->{Prev} = ['num', $self->[stxr]];
 $trailerhash->{Size} = ['num', $self->[size]];
 print $fh join_tokens(trailer=>serialize($self->[trai])),
          "\nstartxref\n$startxref\n%%EOF\n";
 close $fh or croak "Cannot close $self->[file]: $!";
}

sub print {
 my $self = shift;
 my %args = @_;
 $args{fh} // $args{filename} // croak "No file to write to!";
 my $fh;
 if ($args{filename}) {
  open $fh, ">", $args{filename}
    or croak "Cannot open $args{filename} for writing: $!";
 }
 else { $fh = $args{fh} }
 binmode $fh;
 local ($\,$,);
 my $pos = length(my $buf = "%PDF-$self->[vers]\n%\xff\xff\xff\xff\n");
 print $fh $buf;

 # Generate the doc ID now.  If it already exists, it might be an indirect
 # object, in which case changes to it must included in the objects that we
 # append to the file before we reach the trailer.
 my $id_array = $self->vivify_obj('array',"/ID");
 if (@{$$id_array[1]} == 2
      and $self->vivify_obj('str', $id_array, 0)->[1] ne $self->[id]) {
  # User has assigned his own id.  Leave it alone.
 }
 else {
  @{$$id_array[1]} = (['str', time."" ^ "".rand ^ "".(0+$self)])x2;
 }

 # We assume that if this points to a cross-reference stream’s dictionary
 # then we will not be emitting that cross-reference stream.
 delete @{ $self->[trai][1] }{qw< XRefStm Length Filter DecodeParms F
                                  FFilter FDecodeParms DL Type Size Index
                                  Prev W >};

 my @trailer = _serialize($self->[trai]);
 my %seen;
 my @ids;
 for (2..$#trailer) {
  next unless $trailer[$_] eq 'R';
  my $id = sprintf '%d %d',@trailer[$_-2,$_-1];
  next if $seen{$id}++;
  push @ids, $id;
 }
 my %offsets;
 while (@ids) {
  my $id = shift @ids;
  my $del = !$self->[objs]{$id};
  my $obj = $self->get_obj($id) or next;
  my @tokens = (my $flat = $obj->[0] eq 'flat')
                ? tokenize($obj->[1],qr/^(?:endobj|stream)\z/)
                : $obj->[0] eq 'tokens' ? @{$obj->[1]} : _serialize($obj);
  for (2..$#tokens) {
   next unless $tokens[$_] eq 'R';
   my $id = sprintf '%d %d',@tokens[$_-2,$_-1];
   next if $seen{$id}++;
   push @ids, $id;
  }
  $offsets{$id} = $pos;
  if ($$obj[0] eq 'stream') {
   $pos += length($buf = join_tokens(
              $id,'obj',
              @tokens
             ) . $$obj[2] . "\nendstream endobj\n"
           );
   print $fh $buf;
  }
  else {
   $pos += length ($buf = join_tokens(
              $id,'obj',
              @tokens,
              "endobj"
             ) . "\n"
           );
   print $fh $buf;
  }
  delete $self->[objs]{$id} if $del; # Avoid reading the whole file into
 }                                   # memory at once.
 for (sort {$a<=>$b} keys %offsets) {
  $ids[$_] = $_;
 }
 my @free = $ids[0] = '0 65535';
 for (1..$#ids-1) {
  next if $ids[$_];
  push @free, $ids[$_] = "$_ 0";
 }
 my %next_free;
 for (0..$#free) {
  $next_free{$free[$_]} = 0+$free[$_+1];
 }
 my $startxref = $pos;
 printf $fh "xref\n0 %d\n", scalar @ids;
 for (@ids) {
  printf $fh "%010d %05d %s \n",
              exists $next_free{$_}
               ? ($next_free{$_}, /\ (\d+)/, "f")
               : ($offsets  {$_}, /\ (\d+)/, "n")
 }
 my $trailerhash = $self->[trai]->[1];
 delete $trailerhash->{Prev};
 $trailerhash->{Size} = ['flat', 1+$ids[-1]];
 print $fh join_tokens(trailer=>serialize($self->[trai])),
          "\nstartxref\n$startxref\n%%EOF\n";
 if ($args{filename}) {
  close $fh or croak "Cannot close $args{filename}: $!";
 }
}

# LOW-LEVEL METHODS

sub version :lvalue { $_[0][vers] }
#sub xref { $_[0][xrft] }

sub modified {
 my $self = shift;
 @_ or return $self->[mods];
 if (@_ == 1 && $_[0] !~ m.^/.) {
  croak "$_[0] is not an object id"
   unless $_[0] =~ /^[0-9]+ [0-9]+\z/ || $_[0] eq 'trailer';
  $self->[mods]{$_[0]}++;
  return
 }
 my (undef, $last_ref) = _get_obj($self, 0, @_);
 $last_ref and $self->[mods]{$last_ref}++;
 $self->[mods];
}

sub objects { $_[0][objs] }
sub trailer { $_[0][trai] }

sub read_obj {
 my $self = shift;
 my $id = shift;
 { return $self->[objs]{$id} || next }
 croak "$id is not a valid id" unless $id =~ /^[0-9]+ [0-9]+\z/;
 if (!$self->[fh]) {
  croak "No file open";
 }
 my $loc = $self->[xrft]{$id} || return $null;
 if (ref $loc) { # handle object streams here
  my ($strmid, $ix) = @$loc;
  # Since we have to decompress the stream and calculate the offsets, let’s
  # go ahead and extract all the objects into the objects hash,  in flat
  # format.  We may have reached this code because somebody  manually
  # deleted an objects entry in order to re-read it, so only extract
  # objects that are not already in the hash.
  my $obj = $self->get_obj($strmid);
  my $stream = \$self->decode_stream($obj);
  my $count = $self->get_obj($$obj[1], "/N")->[1];
  my $first = $self->get_obj($$obj[1], "/First")->[1];
  my @numbers =
   split /(?:$S++|%[^\cm\cj]*[\cm\cj])+/, substr $$stream, 0, $first, '';
  while (@numbers) {
   my ($id, $off) = splice @numbers, 0, 2;
   $id .= " 0";
   $self->[objs]{$id} ||=
    ['flat',
      substr $$stream, $off, @numbers ? $numbers[1]-$off : length $$stream]
  }
  return $self->[objs]{$id}
 }
 # otherwise use the seek-and-read approach
 _read_obj($self, $loc, $id);
}
sub _read_obj {
 my ($self, $loc, $id) = @_;
 seek $self->[fh], $loc, 0;
 read $self->[fh], my $buf, 1024 or croak "Cannot read $self->[file]: $!";

 my @tokens = tokenize($buf, qr/^(?:endobj|stream)\z/,
                       sub {
                        defined read $self->[fh], $buf, 1024, length $buf
                         or croak "Cannot read $self->[file]: $!"
                       });
 my $read_id = 0+shift(@tokens) . ' ' . (0+shift@tokens);
 if ($id and $read_id ne $id) {
  croak "$self->[file]: Found $read_id at offset $loc instead of $id";
 }
 shift @tokens; # remove “obj”
 my $obj;
 if ($tokens[-1] eq 'stream') {
  my $pos = tell $self->[fh];
  $obj = _interpret_token(\@tokens);
  $buf =~ s/^\cm?\cj//;
  # Create the new obj now, to avoid having to copy a huge buffer on pre-
  # COW perls.
  my $new_obj = ['stream', $obj, $buf];
    # Have to use get_obj here, not $obj[1]{Length}[1], as /Length could be
    # an indirect reference.
  my $stream_length = $self->get_obj($obj, '/Length')->[1];
  if (length $buf < $stream_length) {
   seek $self->[fh], $pos, 0;
   read $self->[fh], $new_obj->[2], $stream_length-length $buf, length $buf
     or croak "Cannot read $self->[file]: $!";
  }
  else {
   substr $new_obj->[2], $stream_length, = '';
  }
  $obj = $new_obj;
 }
 else {
  pop @tokens; # remove ‘endobj’
  $obj = ['tokens', \@tokens];
 }
 $self->[objs]{$read_id} = $obj
}

sub get_obj {
 splice @_, 1, 0, 0;
 (&_get_obj)[0]
}
sub _get_obj {
 my $self = shift;
 my $vivify = shift;
 my $obj = shift;
 # $obj may be any of:
 #  • "4 0"
 #  • "/Root"
 #  • ['dict', { ... }]
 #  • ['array', { ... }]
 #  • ['ref', "4 0 R"]
 #  • ['anything else', ...] 
 my $lastref;
 {
  if (ref $obj) {
   if ($$obj[0] eq 'ref') {
    $obj = $$obj[1]; redo
   }
  }
  elsif ($obj =~ m.^/.) {
   my $subobj = $self->[trai][1]{substr $obj, 1};
   if (!$subobj) {
    if ($vivify) {
     $obj = $self->[trai][1]{substr $obj, 1} =_viv($vivify, @_ ? $_[0]: ())
    }
    else {
     return
    }
   }
   else { $obj = $subobj }
   redo; # $obj may be ['ref', '1894 0']
  }
  else {
   $lastref = $obj;
   $obj = $self->[objs]{$obj} || $self->read_obj($obj);
  }
 }
 $obj or return;
 while (@_) {
  if ($$obj[0] eq 'stream') { $obj = $$obj[1] } # for get_obj($stream,$key)
  _unflatten($obj);
  my $key = shift;
  my $subobj = $key =~ m.^/. ? $$obj[1]{substr $key, 1} : $$obj[1][$key];
  if (!$subobj) {
   if ($vivify) {
    $obj = $key =~ m.^/. ? $$obj[1]{substr $key, 1} : $$obj[1][$key] =
     _viv($vivify, @_ ? $_[0]: ())
   }
   else {
    return
   }
  }
  else { $obj = $subobj }
  if ($obj && $$obj[0] eq 'ref') {
   $lastref = $$obj[1];
   $obj = $self->[objs]{$$obj[1]} || $self->read_obj($$obj[1]);
  }
 }
 _unflatten($obj);
 $obj->[0] eq 'null' and return;
 $obj, $lastref;
}
sub _unflatten {
  my $obj = shift;
  if ($$obj[0] eq 'flat') {
   @$obj = @{ _interpret_token([tokenize($$obj[1])]) };
  }
  elsif($$obj[0] eq 'tokens') {
   @$obj = @{ _interpret_token($$obj[1]) };
  }
}
sub _viv {
 my ($type, $key) = @_;
 [defined $key
       ? $key =~ m.^/. ? ('dict',{}) : ('array',[])
       : ($type, $type eq 'dict'                ? {}
               : $type =~ /^(?:array|tokens)\z/ ? []
               : $type eq 'num'                 ? 0
               : $type eq 'null'                ? ()
               : $type eq 'stream'              ? (['dict',{}], '') : '')
     ];
}

sub vivify_obj {
 my $self = $_[0];
 if ($_[1] !~ /^[a-z]+\z/) {
  croak "First arg to vivify_obj must be a type";
 }
 my($obj, $lastref) = &_get_obj;
 $lastref and $$self[mods]{$lastref}++;
 $obj;
}

sub get_page {
 my $self = shift;
 my @pages = _walk_pages($self);
 $self->get_obj($pages[$_[0]])
}

# The import cache looks like this:
#                   # src       dest   src      dest
# { $other_pdf   => { '2 0' => '1 0', '12 0' => '13 0', ... },
#   $another_pdf => { '1 0' => '3 0', '12 0' => '13 0', ... },
#   ...
# }
# where src is the PDF imported from and dest is the PDF that owns the
# cache.
sub import_obj {
 my ($self, $spdf, $obj) = @'_;
 my $cach =
  ($self->[impo] ||=
    do { require Hash'Util'FieldHash; &Hash'Util'FieldHash'fieldhash({}) })
   ->{$spdf} ||= {};
 my $ret;
 if (!ref $obj) {
   croak "$obj is not an object id" unless $obj =~ /^[0-9]+ [0-9]+\z/;
   if ($cach->{$obj}) {
     return $cach->{$obj}
   }
   # Assign a new number now.  In the loop below, we assume that all
   # objects have had new numbers assigned already, and that the objects
   # just need cloning.
   # Temporarily assign an empty array.
   $ret = $cach->{$obj} = $self->add_obj([]);
 }
 my $return_id = !ref $obj;
 my @objs = $obj;
 while (@objs) {
  my $obj = shift @objs;
  my $id;
  if (!ref $obj) {
   $id = $obj;
   $obj = $spdf->read_obj($obj);
  }
  my @tokens = ($obj->[0] eq 'flat')
                 ? tokenize($obj->[1],qr/^stream\z/)
                 : $obj->[0] eq 'tokens' ? @{$obj->[1]} : _serialize($obj);
  for (2..$#tokens) {
    next unless $tokens[$_] eq 'R';
    my $id = sprintf '%d %d',@tokens[$_-2,$_-1];
    if (!$cach->{$id}) {
     # Temporarily assign an empty array.
     $cach->{$id} = $self->add_obj([]);
     # Add to the list of ids to process.
     push @objs, $id;
    }
    @tokens[$_-2,$_-1] = split / /, $cach->{$id};
  }
  # Clone the object.
  # If an object id is in @objs at this point, it can only be because it
  # has had a new id assigned already.
  my $clone =
    $id && ($cach->{$id} || die "Internal error: $obj got uncached")
      ? $self->[objs]{$cach->{$id}}  # cached empty array
      : [];   # cloning the top-level object with no cache
  $ret ||= $clone;

  ## We are not supporting flat streams yet (if ever).
  #if ($$obj[0] eq 'flat' && $tokens[-1] eq "stream\n") {
  # pop @tokens;
  # @$clone = ('stream', ['tokens', \@tokens,  ...???
  #}

  if ($$obj[0] eq 'stream') {
    # tokenize() above will have ended up putting a "stream\n" token on the
    # end, which we do not want in the dictionary.
    pop @tokens;
    @$clone = ('stream', ['tokens', \@tokens], $$obj[2]);
  }
  else {
    @$clone = ('tokens', \@tokens);
  }
 }
 _unflatten($ret) if ref $ret;
 $ret;
}

sub add_obj {
 my $self = shift;
 my $id = shift @{$self->[free]} || $self->[size]++ . ' 0';
 $self->[objs]{$id} = shift;
 $self->[mods]{$id}++;
 $id;
}

sub decode_stream :lvalue{
 my $self = shift;
 my $stream = $self->get_obj(@_);
 my @filters = $self->get_obj($stream, "/Filter");
 if (@filters) {
   if ($filters[0][0] eq 'array') {
    @filters = map $self->get_obj($filters[0],$_)->[1],0..$#{$filters[0][1]};
   }
   else { @filters = $filters[0][1] }
 }
 my @params = $self->get_obj($stream, "/DecodeParms")
           || $self->get_obj($stream, "/DP"); # unofficial but Acrobat sup-
 if (@params) {                               # ports it
  if ($params[0][0] eq 'array') {
   @params = map scalar $self->get_obj($params[0], $_),
                 0..$#{$params[0][1]};
  }
 }
 $stream = \$stream->[2];
 for (@filters) {
  $stream = _unfilter($self, $stream, $_, shift @params);
 }
 $$stream
}

sub _unfilter {
 my ($self, $stream, $filter, $params) = @_;
 $filter eq 'FlateDecode'
   or croak "The $filter filter is not supported", 1;
 my ($predictor, $bpc, $cols, $colours) = (1, 8, 1, 1);
 if ($params) {
  $params->[1]{Predictor}
   and $predictor = $self->get_obj($params, "/Predictor")->[1];
  $predictor == 1 || $predictor >= 10
   || croak "Predictor functions other than PNG are not supported", 1;
  $params->[1]{BitsPerComponent}
   and $bpc = $self->get_obj($params, "/BitsPerComponent")->[1];
  $$params[1]{Columns} and $cols=$self->get_obj($params, "/Columns")->[1];
  $$params[1]{Colours} and $colours=$self->get_obj($params,"/Colors")->[1];
  $bpc % 8 and croak "BitsPerComponent values that are not multiples of"
                   . " 8 are not supported", 1;
  $bpc >>= 3; # bytes per component
  $bpc *= $colours;
 }
 require Compress::Zlib;
 my $x = Compress'Zlib'inflateInit()
  or croak "Could not create an inflation stream (whatever that is)", 1;
 my ($flate_output, $flate_stat) = inflate $x my $copy = $$stream;
 croak "Inflation failed for some reason", 1
  unless $flate_stat == &Compress'Zlib'Z_STREAM_END;
 if ($predictor >= 10) { # rats
  my $output = '';
  my $rowsize = 1 + $bpc * $cols;
  my $prev = "\0"x($rowsize-1);
  for my $row (1..length($flate_output) / $rowsize) {
   my $filter = vec $flate_output, ($row-1) * $rowsize, 8;
   my $samples = substr $flate_output, ($row-1) * $rowsize + 1, $rowsize-1;
   if ($filter == 2) { # Up (first ’cos it’s the most common)
    for (0..$rowsize-2) {
     vec ($samples, $_, 8) += vec $prev, $_, 8;
    }
   }
   elsif (!$filter) { # Nothing
   }
   elsif ($filter == 1) { # Sub (left)
    for (0..$rowsize-2) {
     vec ($samples, $_, 8) += vec $samples, $_ - $bpc, 8;
    }
   }
   elsif ($filter == 3) { # Avg
    for (0..$rowsize-2) {
     vec ($samples, $_, 8) +=
      (vec($prev, $_, 8) + vec $samples, $_ - $bpc, 8) / 2;
    }
   }
   elsif ($filter == 4) { # Paeth
    for (0..$rowsize-2) {
     my ($a,$b,$c) = (vec($samples, $_ - $bpc, 8),
                      vec($prev   , $_       , 8),
                      vec $prev   , $_ - $bpc, 8 );
     my $p = $a + $b - $c;
     my ($pa, $pb, $pc) = (abs($p - $a), abs($p - $b), abs($p - $c));
     vec $samples, $_, 8 =>=
       $pa <= $pb && $pa <= $pc ? $a : $pb <= $pc ? $b : $c
    }
   }
   else { croak "Invalid PNG filter value: $filter", 1 }
   $output .= $prev = $samples;
  }
  \$output;
 }
 else {
  \$flate_output;
 }
}


# FUNCTIONS

*tokenise = *tokenize;
sub tokenize { # This function tokenizes.
	# accepts three arguments: the text to parse, the token to stop
	# on (such as 'endobj') and a function to supply more text
	# the 2nd and 3rd args are optional

    for (shift) {
	my $endtoken=shift;
	my $more   = shift;
	my @tokens;
	my $prev_length;
	TOKEN: while (1) {
		if ($more and length() < 500) {
			&$more();
		}
		elsif(!length or length == $prev_length) {
			last TOKEN;
		}
		$prev_length = length;
		s/^(?:$S++|%[^\cm\cj]*$N)+//o;
		if (s _^(($R+)|<<|>>|[\[\]\{\}]|/$R*)__o) 	{
			push @tokens, $1;
			last TOKEN if defined $endtoken && length $2
			           && $1 =~ $endtoken;
			next TOKEN
		}
		if (s.^\(..) {  # remove paren.
			&$more()
				until s/(
				 (?:\\.|[^()\\])++# escaped char or non-\()
				  |
				 \((?1)\) # parenthesized stuff
				)*\) # final closing paren
				//xs;
			push @tokens, "($1)";
			next
		}
		s.^(<[^>]*>)..	and push @tokens, $1;
		&$more() while /^<[^>]*\z/;
	}
	return @tokens;
    }
}

sub join_tokens {
 # PDF lines are not supposed to be longer than 255 (outside of content
 # streams).  I don’t know whether that includes the line ending.  I assume
 # it does.
 my $ret = '';
 my $line = '';
 for (@_) {
  # We assume that only strings can get too long to fit on a line.  After
  # all, they are the only token that can be split between lines.
  if (length() + length $line > 254 && /^$S*([(<])/o) {
   my $hex = $1 eq '<';
   # Put a line break before the string.
   $ret .= "$line\n";
   $line = '';
   # To keep this code simple, just ignore the fact that strings can have
   # embedded line breaks.  Just split it up into pieces that are small
   # enough to fit on a line.
   while (length > 254) {
     # Don’t split it between an escaper and an escapee.
     my $piecepiece = substr $_, 0, 253;
     chop $piecepiece unless $piecepiece =~ /^[^\\]*(?:\\.[^\\]*)*\z/s;
     $ret .= $hex ? "$piecepiece\n" : "$piecepiece\\\n";
     substr $_, 0, length $piecepiece, = '';
   }
   $ret .= "$_\n";
  }
  else {
   # Wherever whitespace is mandatory, use a line break, to avoid that more
   # complicated string-splitting logic above. (Speeeeeeeed!) (I hope.)
   # PDF::Extract won’t be able to read it.  That’s the least of
   # its problems.
   for (ref eq 'SCALAR' ? $$_ : $_) {
    if (length($line) and $line !~ /$D\z/o && !/^$D/o
                        ||length($line) + length > 254) {
     $ret .= "$line\n";
     $line = '';
    }
    $line .= $_;
   }
  }
 }
 "$ret$line";
}

sub parse_string {
 parse_tokens( tokenize @_[0,1] )
}

sub parse_tokens {
	my @newtokens;
	wantarray or return _interpret_token(\@_);
	while (scalar ( @_)){
		push @newtokens, _interpret_token(\@_);
	}
	return @newtokens;
}

sub _interpret_token { # pass an array ref
	# interpret_token removes the first token or set of tokens from an
	# array and returns the token in 'parsed object' format.

    my $tokens = shift;
    for (shift @$tokens) {

	# references:

	if ($_ =~ /^\d+$/ and
	    @$tokens >= 2 && $$tokens[0] =~ /^\d+$/
	    && $$tokens[1] eq 'R') {
		my $to_return =  ['ref',
			"$_ " . (shift @$tokens)];
		shift @$tokens; # shift off the 'R'
		return $to_return;
	}

	# names

	elsif (s.^/..) { # if it begins with "/"
		# replace #XX sequences with real chars:
		s/#([a-f\d]{2})/chr hex $1/gie;
		return ['name', $_];
	}

	# dictionaries:

	elsif ($_ eq '<<') {
		my %tmp_hash;
		while(scalar @$tokens){
			my $name = shift @$tokens;
			if ($name eq '>>') {
				return ['dict', \%tmp_hash];
			}else {
				$name =~ s.^/..;
				# replace #XX sequences with real chars:
				$name =~ s/#([a-f\d]{2})/chr hex $1/gie;
				$tmp_hash{$name} = 
					_interpret_token($tokens);
				delete $tmp_hash{$name}
					if $tmp_hash{$name}[0] eq 'null'
			}
		}
	}

	# arrays:

	elsif ($_ eq '[') {
		my @tmp_array;
		while(scalar @$tokens){
			if ($$tokens[0] eq ']') {
				shift @$tokens; #shift off the "]"
				return ['array', \@tmp_array];
			}else {
				push @tmp_array, _interpret_token($tokens);
			}
		}
	}

	# strings

	elsif (s/^\(//){ #if it begins with a '('
				#i.e., if it's a string
		s/\)$//; # remove final ")"
		# and remove wack escapes:
		s,($N)|\\($N|\d{1\,3}|.),  my $match = $2;
					my $unescaped = $1;
			$unescaped    ? "\cj"  :	# EOL
			$match =~ /$N/o ? '' :		# \EOL
			$match=~/\d/?chr oct$match :	# octal
			$match eq 'n' ? "\cj" :		# CR
			$match eq 'r' ? "\cm" :		# LF
			$match eq 't' ? "\t" :		# tab
			$match eq 'b' ? "\010" :	# backspace
			$match eq 'f' ? "\x0c" :	# form feed
			$match eq '(' ? "(" :		# (
			$match eq ')' ? ')' :		# )
			$match eq '\\' ? '\\' :		# |
			length $match ? $match :  # ignore backslash as per Adobe's instructions
			$fullmatch			# anything else
		,goes;
		return ['str', $_];
	}

	# numbers:

	elsif (/^[+\-]?\d+$/ or
	       /^[+\-]?[\d\.]+$/ && y/.// == 1) {
			return ['num',$_];
	}

	# hex strings

	elsif (s/^<//){ #if it begins with a '<'
		s/>$//; # remove final ">"
		s/$S//g; #remove whitespace
		return ['str', pack "H*", $_];
	}

	# booleans:

	elsif ($_ eq 'true') {
		return ['bool', 1];
	}
	elsif($_ eq 'false'){
		return ['bool',''];
	}

	# null:

	elsif ($_ eq 'null') {
		return ['null', ];
	}


	# in case something went wrong:

	else { return ['?',$_]; }
    }
}

*serialise = *serialize;
sub serialize {
 join_tokens(&_serialize)
}
sub _serialize;
sub _serialize {
    for (shift) {
	# numbers
	if($$_[0]eq'num'){ for ($$_[1]) {
		!$_||$_==-0 and return 0;
		/^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]*)\z/ and return $_;
		my $ret = 0+$_;
		return $ret unless $ret =~ /e([+-][0-9]+)/;
		$ret = sprintf"%.$1f",$ret;
		$ret =~ s/\.?0+\z//;
		return $ret;
	}}
	
	# names
	if($$_[0]eq'name'){
	    for (my $copy = $$_[1]) {
		s/($D|$S|#)/sprintf'#%02x',ord$1/ego;
		return "/$_";
	    }
	}
	
	# dictionaries
	if ($$_[0] eq 'dict') {
		my (@ret,$key,$key_copy);
		for $key (sort keys %{$$_[1]}) {
			($key_copy=$key)
				=~s/($D|$S|#)/sprintf'#%02x',ord$1/ego;
			push @ret,"/$key_copy", _serialize $$_[1]{$key};
		}
		return"<<",@ret,">>";
	}
	
	# indirect references
	$$_[0] eq 'ref' and return split(/ /,$$_[1]), "R";

	# arrays
	if ($$_[0]eq'array'){
		my (@ret);
		for(@{$$_[1]}){
			push @ret, _serialize$_;
		}
		return "[",@ret,"]";
	}
	
	# screams
	if ($$_[0]eq'stream'){
		return _serialize($$_[1]), "stream\n"
	}
	
	# strings
	if($$_[0]eq 'str'){
		 # copy it so we don't modify the object being flattened
		for (my $ret = $$_[1]) {
			s/([\\()\r])/$1 eq "\r" ? '\r' : "\\$1"/ge;
			return"($_)";
		}
	}
	
	$$_[0]eq'tokens'&&return@{$$_[1]};
	
	# booleans
	$$_[0]eq'bool'&&return+(false=>'true')[$$_[1]];
	
	$$_[0]eq'flat'&&return\$$_[1];
	
	$$_[0]eq'null'&&return'null';
	
	# If we get this far, then there's probably an empty array element or hash value which is not supposed to be there, so we shouldn't return anything.
    }
}

for (qw< bool num str name array dict ref>) {
 eval "sub make_$_ { ['$_', \$_[0] ] }"
}




                              !()__END__()!

