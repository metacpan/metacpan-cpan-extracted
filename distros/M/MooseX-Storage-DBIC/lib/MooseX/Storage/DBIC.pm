package MooseX::Storage::DBIC;

use Moose::Role;
use namespace::autoclean;
use MooseX::Storage::DBIC::Basic;

=head1 NAME

MooseX::Storage::DBIC - Additional MooseX::Storage functionality for DBIx::Class rows and data structures.

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

 package My::Schema::Result::Chair;

 # moose attribute we would like to serialize
 has 'legs' => ( is => 'rw', isa => 'Int', default => 4 );

 # column to serialize
 __PACKAGE__->add_columns(
   "id" => { data_type => "integer" },
 );

 # relationship to serialize
 __PACKAGE__->belongs_to("table" => "My::Schema::Result::Table", { chair_id => "id" });

 # field+method to serialize
 sub is_broken { return $self->{is_broken} }

 # declare fields to serialize
 with 'MooseX::Storage::DBIC';
 sub schema { return $myschema }
 __PACKAGE__->serializable(qw/ id legs table is_broken /);

 # convert an instance into a hashref
 my $row = $myschema->resultset('Chair')->first;
 my $serialized = $row->pack;

 # convert hashref back into instance
 my $orig_row = My::Schema::Result::Chair->unpack($serialized);

=head1 WARNINGS

WARNING: This software is highly experimental and untested. Do not
rely on it for anything important. Bug reports and pull requests
welcome.

Please also note that you cannot serialize cyclic references or cyclic
relationships.

=cut

# wish this worked haha
#sub BUILDARGS { $_[2] || {} }

# make some fields serializable
sub serializable {
    my ($class, @fields) = @_;

    # need to define serializable fields as attributes for the storage
    # engine to know about them
     foreach my $f (@fields) {
         next if $class->meta->has_attribute($f);
         $class->meta->add_attribute($f => ( is => 'bare' ));
     }

    # init our version of MooseX::Storage
    my @storage_roles = qw/MooseX::Storage::DBIC::Basic/;
    $_->meta->apply($class->meta) for @storage_roles;
}

1;
