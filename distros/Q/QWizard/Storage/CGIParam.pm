package QWizard::Storage::CGIParam;

use strict;
use QWizard::Storage::Base;
our @ISA = qw(QWizard::Storage::Base);

our $VERSION = '3.15';
use CGI;

our %cached_params = ();

sub new {
    my $class = shift;
    bless {}, $class;
}

sub maybe_create_cgi {
    my $self = shift;
    if (!exists($self->{'cgi'})) {
	# we do this here late binding as possible for various reasons
	$self->{'cgi'} = new CGI;
    }
}

sub get {
    my ($self, $it) = @_;
    $self->maybe_create_cgi();
    return $cached_params{$it} if (exists($cached_params{$it}));
    return $self->{'cgi'}->param($it);
}

sub set {
    my ($self, $it, $val) = @_;
    $self->maybe_create_cgi();
    return $self->{'cgi'}->param($it, $val);
}

sub get_all {
    my ($self) = @_;
    my %ret;
    my @names = $self->{'cgi'}->param;
    map { $ret{$_} = $self->{'cgi'}->param($_) } @names;
    return \%ret;
}

sub reset {
    my ($self) = @_;
    $self->maybe_create_cgi();
    $self->{'cgi'}->delete_all();
    %cached_params = (); 
}

1;

=pod

=head1 NAME

QWizard::Storage::CGIParam - Stores data in CGI variables

=head1 SYNOPSIS

  my $st = new QWizard::Storage::CGIParam();
  $st->set('var', 'value');
  $st->get('var');

=head1 DESCRIPTION

Stores data passed to it inside of CGI parameters.

=head1 AUTHOR

Wes Hardaker, hardaker@users.sourceforge.net

=head1 SEE ALSO

perl(1)

Net-Policy: http://net-policy.sourceforge.net/

=cut
