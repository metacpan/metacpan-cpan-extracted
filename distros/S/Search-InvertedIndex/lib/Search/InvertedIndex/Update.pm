package Search::InvertedIndex::Update;

use strict;
use warnings;

use Class::NamedParms;
use vars qw (@ISA $VERSION);

@ISA     = qw (Class::NamedParms);
$VERSION = '1.17';

=head1 NAME

Search::InvertedIndex::Update - A container for a mass data update for a -group/-index.

=head1 SYNOPSIS

=head1 DESCRIPTION

Provides a container for the information to perform an update for a -group/-index
tuple.

=head2 Public API

Inherits 'get','set','clear' and 'exists' methods from Class::NamedParms

=cut

####################################################################

=head2 Initialization

=over 4

=item C<new({ -group =E<gt> $group, -index =E<gt> $index, -keys =E<gt> { ... ) [ -data => E<gt> $data ] });>

Returns and optionally initializes a new Search::InvertedIndex::Update
object.

Examples:

  my $update = Search::InvertedIndex::Update->new;

  my $update = Search::InvertedIndex::Update->new({ -group => $group,
                                                    -index => $index,
                                                     -data => $index_data,
                                                     -keys => {
												               $key0 => 10,
															   $key1 => 20,
															   $key2 => 15,
													         },
												 });

Inherits 'get/set' methods from Class::NamedParms

The -keys parameter is a reference to a hash containing all the keys for
this index and their assigned rankings. Rankings are allowed to be integer values
between -32768 and +32767 inclusive.

The -group and -index are required, the -keys are optional. The Update object is
used for update by replacement of all -keys for the specified -group and -index.
All existing keys are deleted and the passed -keys is used to insert
a completely new set of keys for the specified index/group.

The -data parameter is optional, but if passed will replace the existing -data
record for the -index.

=back

=cut

sub new {
	my $proto = shift;
    my $class = ref ($proto) || $proto;
	my $self  = Class::NamedParms->new(qw(-group -index -keys -data));
	bless $self,$class;

    # Read any passed parms
    my $parm_ref = {};
    if ($#_ == 0) {
        $parm_ref  = shift;
    } elsif ($#_ > 0) {
        %$parm_ref = @_;
    }
    if (not exists $parm_ref->{-data}) {
        $parm_ref->{-data} = undef;
    }
    if (not exists $parm_ref->{-keys}) {
        $parm_ref->{-keys} = undef;
    }
    $self->set($parm_ref);
	return $self;
}

####################################################################

=head1 COPYRIGHT

Copyright 1999-2020, Jerilyn Franz and FreeRun Technologies, Inc. (<URL:http://www.freeruntech.com/>).
All Rights Reserved.

=head1 AUTHOR

Jerilyn Franz

=head1 TODO

Everything.

=cut

1;

