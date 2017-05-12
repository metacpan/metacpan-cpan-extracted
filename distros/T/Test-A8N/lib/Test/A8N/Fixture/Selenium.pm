package Test::A8N::Fixture::Selenium;
use warnings;
use strict;

use Moose::Role;
use WWW::Selenium;
our @EXCLUDE_METHODS = qw(
    page_mapping
    selenium_class
    selenium
);

before 'DEMOLISH' => sub {
    my $self = shift;
    if (exists $self->ctxt->{selenium}) {
        $self->ctxt->{selenium}->stop();
    }
};

has 'selenium_class' => (
    is => 'rw',
    required => 1,
    isa => 'Str',
    default => sub { "WWW::Selenium"; },
    lazy => 1,
);

sub page_mapping {
    my $self = shift;
    my ($url) = @_;
    my $base = $self->_get_metavar('selenium.browser_url');
    $base =~ s/\/$//;
    return "$base$url";
}

sub selenium {
    my $self = shift;

    return $self->ctxt->{selenium}
        if (exists $self->ctxt->{selenium});

    my %args = (
        host => $self->_get_metavar('selenium.server'),
        port => $self->_get_metavar('selenium.port'),
        browser => $self->_get_metavar('selenium.browser'),
        browser_url => $self->_get_metavar('selenium.browser_url'),
    );

    foreach my $key (keys %args) {
        delete $args{$key} unless ($args{$key});
    }

    $args{browser} = "*$args{browser}" if (exists $args{browser});

    # Create, save and return a selenium object for this appliance
    my $class = $self->selenium_class;
    eval "use $class;";
    die "$@\n" if $@;
    $self->ctxt->{selenium} = $class->new( %args );
    $self->ctxt->{selenium}->start();
    return $self->ctxt->{selenium};
}

=head1 FIXTURE ACTIONS

=cut

=head2 goto page

  goto page: /some/url
  goto page: PageName

Sets the current browser context to a page, either using the absolute path supplied, or
using an abstract page name as defined by the page_mapping hash.  Either set this at run-time,
or override it in a subclass.

=cut

sub goto_page {
    my $self = shift;
    my ($page) = @_;

    $self->selenium->open( $self->page_mapping($page) );
}

1;
__END__

=head1 SEE ALSO

L<Test::A8N::Fixture>

=cut

