package Plucene::Index::FieldInfos;

=head1 NAME 

Plucene::Index::FieldInfos - a collection of FieldInfo objects

=head1 SYNOPSIS

	my $fis = Plucene::Index::FieldInfos->new($dir_name);
	my $fis = Plucene::Index::FieldInfos->new($dir_name, $file);

	$fis->add(Plucene::Document $doc, $indexed);
	$fis->add(Plucene::Index::FieldInfos $other_fis, $indexed);
	$fis->add($name, $indexed);

	$fis->write($path);

	my @fields = $fis->fields;

	my $field_number = $fis->field_number($name);
	my   $field_info = $fis->field_info($name);
	my   $field_name = $fis->field_name($number);
	my   $num_fields = $fis->size;
	

=head1 DESCRIPTION

This is a collection of field info objects, which happen to live in 
the field infos file. 

=head1 METHODS

=cut

use strict;
use warnings;

use Carp qw(confess);
use File::Slurp;
use Class::Struct 'Plucene::Index::FieldInfo' =>
	[ name => '$', is_indexed => '$', number => '$' ];

=head2 new

	my $fis = Plucene::Index::FieldInfos->new($dir_name);
	my $fis = Plucene::Index::FieldInfos->new($dir_name, $file);

This will create a new Plucene::Index::FieldInfos object with the passed
directory and optional filename.
	
=cut

sub new {
	my ($class, $dir, $file) = @_;
	my $self = bless {}, $class;
	$file
		? $self->_read("$dir/$file")
		: $self->_add_internal("", 0);
	return $self;
}

=head2 add

	$fis->add(Plucene::Document $doc, $indexed);
	$fis->add(Plucene::Index::FieldInfos $other_fis, $indexed);
	$fis->add($name, $indexed);

This will add the fields from a Plucene::Document or a 
Plucene::Index::FieldsInfos to the field infos file.

It is also possible to pass the name of a field and have it added
to the file.
	
=cut

sub add {
	my ($self, $obj, $indexed) = @_;
	if ( UNIVERSAL::isa($obj, "Plucene::Document")
		or UNIVERSAL::isa($obj, "Plucene::Index::FieldInfos")) {
		$self->add($_->name, $_->is_indexed) for $obj->fields;
		return;
	}
	confess "Don't yet know how to handle a $obj" if ref $obj;
	my $name = $obj;                       # For clarity. :)
	my $fi   = $self->field_info($name);
	$fi
		? $fi->is_indexed($indexed)
		: $self->_add_internal($name, $indexed);
}

sub _add_internal {
	my ($self, $name, $indexed) = @_;
	my $fi = Plucene::Index::FieldInfo->new(
		name       => $name,
		is_indexed => $indexed,
		number     => $#{ $self->{bynumber} } + 1,
	);
	push @{ $self->{bynumber} }, $fi;
	$self->{byname}{$name} = $fi;
}

=head2 field_number

	my $field_number = $fis->field_number($name);

This will return the field number of the field with $name. If there is 
no match, then -1 is returned.
	
=cut

sub field_number {
	my ($self, $name) = @_;
	return -1 unless defined $name;
	my $field = $self->{byname}{$name} or return -1;
	return $field->number;
}

=head2 fields

	my @fields = $fis->fields;

This will return all the fields.

=cut

sub fields { return @{ $_[0]->{bynumber} } }

=head2 field_info

	my $field_info = $fis->field_info($name);

This will return the field info for the field called $name.

=cut

# Please ensure nothing in the code tries passing this a number. :(
sub field_info { $_[0]->{byname}{ $_[1] } }

=head2 field_name

	my $field_name = $fis->field_name($number);

This will return the field name for the field whose number is $number.

=cut

sub field_name { $_[0]->{bynumber}[ $_[1] ]->name }

=head2 size 

	my $num_fields = $fis->size;

This returns the number of field info objects.

=cut

sub size { scalar $_[0]->fields }

=head2 write

	$fis->write($path);

This will write the field info objects to $path.

=cut

# Called by DocumentWriter->add_document and
# SegmentMerger->merge_fields

sub write {
	my ($self, $file) = @_;
	my @fi       = @{ $self->{bynumber} };
	my $template = "w" . ("w/a*C" x @fi);
	my $packed   = pack $template, scalar(@fi),
		map { $_->name => ($_->is_indexed ? 1 : 0) } @fi;
	write_file($file => $packed);
}

sub _read {
	my ($self, $filename) = @_;
	my @fields = unpack "w/(w/aC)", read_file($filename);
	while (my ($field, $indexed) = splice @fields, 0, 2) {
		$self->_add_internal($field => $indexed);
	}
}

1;
