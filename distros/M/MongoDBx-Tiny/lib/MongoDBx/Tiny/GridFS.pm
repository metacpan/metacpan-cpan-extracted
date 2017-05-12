package MongoDBx::Tiny::GridFS;
use strict;
use warnings; 

=head1 NAME

MongoDBx::Tiny::GridFS - wrapper class of MongoDB::GridFS

=cut

use Carp qw(confess);
use MongoDB::GridFS;
use Params::Validate;

=head1 SUBROUTINES/METHODS

=head2 new

  $gridfs = MongoDBx::Tiny::GridFS->new(
  	$database->get_gridfs,$fields_name
  );

=cut

sub new {
    my $class  = shift;
    my $gridfs = shift or confess q/no gridfs/;
    my $field  = shift or confess q/no field/;

    return bless {  _gridfs => $gridfs, _field => $field  }, $class;
}

=head2 gridfs, fields

  # get Mongodb::GridFS
  $gridfs_raw = $gridfs->gridfs;

  # get fields name
  $gridfs_field_name = $gridfs->field;

=cut

sub gridfs { shift->{_gridfs} }

sub field  { shift->{_field}  }

=head2 put

  $gridfs->put('/tmp/foo.txt', {"filename" => 'foo.txt' });
  $gridfs->put('/tmp/bar.txt','bar.txt');
  
  $fh = IO::File->new('/tmp/baz.txt','r');
  $gridfs->put($fh,'baz.txt');

=cut

sub put {
    my $self  = shift;
    my $proto = shift or confess q/no filepath or filehandle/;
    my $opt   = shift or confess q/no gridfs filepath or opt/;
    my $fh;

    if (ref $proto)  {
	$fh = $proto;
    } else {
	require IO::File;
	$fh = IO::File->new($proto,'r');
    }

    if (ref $opt ne 'HASH') {
	# just a gridfs path
	$opt = { $self->field => $opt };
    }

    my $no_exists_check = delete $opt->{no_exists_check};

    my %meta = Params::Validate::validate_with(
	params => $opt,
	spec   => {
	    $self->field => 1,
	}
    );

    unless ($no_exists_check) {
	# xxx
	return if $self->exists_file( $meta{$self->field} );
    }

    my $oid = $self->gridfs->insert($fh, \%meta, { safe => 1 });
    $self->get($oid);
}

=head2 get

  # MongoDBx::Tiny::GridFS::File
  $gridfs_file = $gridfs->get({ filename => 'foo.txt' });
  $foo_txt = $gridfs_file->slurp;

  $bar_txt = $gridfs->get('bar.txt')->slurp;

=cut

sub get {
    my $self = shift;
    my $proto  = shift or confess /no id or query/; # $oid,$query

    my $query = ref $proto eq 'HASH'         ? $proto
	      : ref $proto eq 'MongoDB::OID' ? { _id => $proto }
	      : { $self->field => $proto };
    my $gridfs_object = $self->gridfs->find_one($query);
    return unless $gridfs_object;
    return MongoDBx::Tiny::GridFS::File->new( $gridfs_object, $self->field );
}

=head2 remove

  $gridfs->remove({ filename => 'foo.txt' });
  $gridfs->remove('bar.txt');

=cut

sub remove {
    my $self = shift;
    my $proto  = shift or confess /no id or query/; # $oid,$query

    my $query = ref $proto eq 'HASH'         ? $proto 
              : ref $proto eq 'MongoDB::OID' ? { _id => $proto }
	      : { $self->field => $proto };

    $self->gridfs->remove( $query, {safe => 1, just_one => 1} );
}

=head2 exists_file

  $gridfs->exists_file({ filename => 'foo.txt' });
  $gridfs->exists_file('bar.txt');

=cut

sub exists_file {
    my $self     = shift;
    my $field    = $self->field;

    my $val      = shift or confess qq/no $field value/;
    return $self->gridfs->find_one({ $field  => $val },{ _id => 1 });
}


=head1  MongoDBx::Tiny::GridFS::File

  wrapper class of MongoDB::GridFS::File

=cut

package MongoDBx::Tiny::GridFS::File;
use strict;
use Carp qw(confess);

=head2 new

    $gf = MongoDBx::Tiny::GridFS::File->new( $gridfs->find_one($query), $self->field );

=cut

sub new {
    my $class  = shift;
    my $g_file = shift or confess q/no GridFS::File object/;
    my $field  = shift or confess q/no MongoDBx::Tiny::GridFS::field/;
    # g_file
    # bless { _info => {}, _grid => MongoDB::GridFS } MongoDB::GridFS::File
    unless ($class->can($field)) {
	{
	    no strict 'refs';
	    *{"${class}::" . $field} = sub { shift->gf->{info}->{$field} };
	}
    }

    return bless { _gridfs_file => $g_file, _field => $field }, $class;
}


=head2 gridfs_file, gf

    # MongoDB::GridFS::File
    $gf_raw = $gf->gridfs_file;

=cut

sub gridfs_file { shift->{_gridfs_file} }

sub gf          { shift->gridfs_file    }

=head2 print

  # MongoDB::GridFS::File::print
  $gf->print($fh,$length,$offset);

=cut

sub print       { shift->gf->print(@_)  }

=head2 slurp

  # MongoDB::GridFS::File::slurp
  $all = $gf->slurp();
  $buf = $gf->slurp($length,$offset);

=cut

sub slurp       { shift->gf->slurp(@_)  }

=head2 field

  field name. default is  "filename"

=cut

=head2 _id,chunk_size,upload_date,md5

  MongoDB::GridFS::File attributes

=cut

sub field       { shift->{_field}       }

sub id          { shift->gf->{info}->{_id} }

sub chunk_size  { shift->gf->{info}->{chunkSize} }

sub upload_date { shift->gf->{info}->{uploadDate} }

sub md5         { shift->gf->{info}->{md5} }

1;
__END__

=head1 AUTHOR

Naoto ISHIKAWA, C<< <toona at seesaa.co.jp> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Naoto ISHIKAWA.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

