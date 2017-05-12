package Net::SugarCRM::Entry;

use warnings;
use strict;
use JSON;

our $VERSION = sprintf "3.%05d", q$Revision: 20471 $ =~ /(\d+)/xg;

=head1 Net::SugarCRM::Entry

Represens an entry from Sugar

=head2 new

Creates a new entry

=cut


sub new {
    my $class = shift;
    my $self = shift;
    $self = {} if (!$self);
    return bless $self, $class;
}

=head2 module_name

Returns the module name

=cut
sub module_name { return shift->{module_name} }

=head2 id

Returns the id of the module

=cut
sub id { return shift->{id} }

sub DESTROY { }

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    my $field = $AUTOLOAD;
    $field =~ s/.*:://;

    if (exists $self->{name_value_list}{$field}) {
        my $ret = $self->{name_value_list}{$field}{value};
        $self->{name_value_list}{$field}{value} = $_[0] if ($#_ > -1);
	if (ref $ret eq 'JSON::XS::Boolean') {
	    $ret = '';
	}
        return $ret;
    } else {
        confess("$field: No such attribute");
    }
}

=head2 has

Returns true for a given attribute if it exists in this entry.

=cut
sub has {
    my ($self, $field) = @_;
    return exists($self->{name_value_list}{$field});
}

1;
