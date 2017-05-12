package QWizard::Storage::Base;

use strict;

our $VERSION = '3.15';

sub new {
    my $class = shift;
    bless {}, $class;
}

# access is called where the first argument could actually be a
# QWizard object, so we drop it.
sub access {
    my $self = shift;
    my ($it);
    if (ref($self) =~ /QWizard/) {
	$it = shift;
    } else {
	$it = $self;
    }
    if ($#_ > -1) {
	$self->set($it, $_[0]);
    }
    return $self->get($it);
}

sub get_all {
    my $self = shift;
    return $self->{'vars'};
}

sub set_all {
    my $self = shift;
    my $vars = shift;
    $self->reset();
    foreach my $key (%$vars) {
	$self->set($key, $vars->{$key});
    }
}

sub copy_from {
    my ($self, $from) = @_;
    $self->set_all($from->get_all);
}

#
# converts all known variables into a future parsable string.
#    warning: not the most efficient encoding.  But it should be safe
#    for use by every transport, assuming '_' and '-' is legal.
#
sub to_string {
    my $self = shift;
    my $vars = $self->get_all();
    my $out;
    foreach my $var (keys(%$vars)) {
	my $varstr = $var;
	$varstr =~ s/([^a-zA-Z0-9])/'_' . (ord($1)) . '_'/eg;
	my $valstr = $vars->{$var};
	$valstr =~ s/([^a-zA-Z0-9])/'_' . (ord($1)) . '_'/eg;
	$out .= '_-' . $varstr . '_-' . $valstr;
    }
    $out =~ s/^_-//;
    return $out;
}

#
# converts an encoded string (see to_string()) into the storage
# container (wiping out previous contents)
#
sub from_string {
    my $self = shift;
    my $str = shift;
    my %vars;

    # delete existing data
    $self->reset();

    # split incoming string into var pieces
    my @vars = split(/_-/,$str);

    # parse each string
    for (my $i = 0; $i <= $#vars; $i += 2) {
	my @parts = ($vars[$i], $vars[$i+1]);
	map { s/_(\d+)_/chr($1)/eg; } @parts;
	$self->set(@parts);
    }
    return $self;
}

1;

=pod

=head1 NAME

QWizard::Storage::Memory - Stores data in CGI variables

=head1 SYNOPSIS

  my $st = new QWizard::Storage::Memory();
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
