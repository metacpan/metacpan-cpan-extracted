package OurCal::View;

use strict;
use UNIVERSAL::require;
use Module::Pluggable sub_name    => '_views',
                      search_path => 'OurCal::View';


=head2 NAME

OurCal::View - base class for all OourCal views

=head1 METHODS

=cut

=head2 new <param[s]>

=cut

sub new {
    my $class = shift;
    my %what  = @_;
    return bless \%what, $class;
}


=head2 views

Returns a has with key-value pairs representing the shortname and 
equivalent class for all views installed.

=cut

sub views {
    my $self  = shift;
    my $class = (ref $self)? ref($self) : $self;

    my %views;
    foreach my $view ($self->_views) {
        my $name = $view;
        $name =~ s!^${class}::!!;
        $views{lc($name)} = $view;
    }
    return %views;
}

=head2 load_view <name>

Returns an object representing a view of the same name of a type, 
defined in the config and found in C<views>. Authomatically passes in 
the correct config.

=cut

sub load_view {
    my $self  = shift;
    my $name  = shift;
    my %opts  = @_;
    my %views = $self->views;
    my $class = $views{lc($name)}    || die "Couldn't get a class for view of type $name\n";
    $class->require || die "Couldn't require class $class: $@\n";
    return $class->new(%opts);
}

1;

