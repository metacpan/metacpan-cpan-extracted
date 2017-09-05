
=head1 Name
 
QBit::Application::Model::DB::Filter
 
=head1 Description
 
Base class for DB filters.

=cut

package QBit::Application::Model::DB::Filter;
$QBit::Application::Model::DB::Filter::VERSION = '0.019';
use qbit;

use base qw(QBit::Application::Model::DB::Class);

=head1 Package methods

=head2 new
 
=cut

sub new {
    my ($class, $filter, %opts) = @_;

    return $filter if blessed($filter) && $filter->isa(__PACKAGE__);

    my $self = $class->SUPER::new(%opts);

    $self->_add($filter) if defined($filter);

    return $self;
}

=head2 and
 
=cut

sub and {
    $_[0]->_add($_[1], type => 'AND');
}

=head2 or
 
=cut

sub or {
    $_[0]->_add($_[1], type => 'OR');
}

=head2 and_not
 
=cut

sub and_not {
    $_[0]->_add($_[1], type => 'AND NOT');
}

=head2 or_not
 
=cut

sub or_not {
    $_[0]->_add($_[1], type => 'OR NOT');
}

=head2 expression
 
=cut

sub expression {
    my ($self) = @_;

    return exists($self->{'__FILTER__'}) ? $self->{'__FILTER__'} : ();
}

sub _add {
    my ($self, $filter, %opts) = @_;

    if (ref($filter) eq 'HASH') {
        $filter = clone($filter);
        my @cmprs = ();
        push(@cmprs, [$_ => '=' => \$filter->{$_}]) foreach sort keys(%$filter);
        $filter = [AND => \@cmprs];
    }

    if (ref($filter) eq 'ARRAY' && @$filter == 3) {
        $filter = [AND => [$filter]];
    }

    if (blessed($filter)) {
        throw gettext('Bad filter object: %s is not %s descendant', ref($filter), __PACKAGE__)
          unless $filter->isa(__PACKAGE__);
        $filter = $filter->{'__FILTER__'};
    }

    return $self unless defined($filter);

    my ($type, $not) = split(/\s+/, $opts{'type'} || 'AND');

    if (exists($self->{'__FILTER__'})) {
        if ($self->{'__FILTER__'}[0] eq $type) {
            push(
                @{$self->{'__FILTER__'}[1]},
                $not ? {NOT => [$filter]} : ($filter->[0] eq $type ? @{$filter->[1]} : $filter)
            );
        } else {
            $self->{'__FILTER__'} = [$type => [$self->{'__FILTER__'}, $not ? {NOT => [$filter]} : $filter]];
        }
    } else {
        $self->{'__FILTER__'} = $filter;
    }

    return $self;
}

TRUE;

=pod

For more information see code and test.

=cut
