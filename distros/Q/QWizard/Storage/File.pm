package QWizard::Storage::File;

use QWizard::Storage::Memory;
use strict;

our @ISA = qw(QWizard::Storage::Memory);

our $VERSION = '3.15';

sub new {
    my $class = shift;
    my %args = @_;
    bless \%args, $class;
}

sub set {
    my ($self, $it, $val) = @_;
    $self->SUPER::set($it, $val);
    $self->save_parms();
}

sub set_all {
    my ($self, $vals) = @_;
    $self->SUPER::set_all($vals);
    $self->save_parms();
}

sub save_parms {
    my $self = shift;
    return if (!$self);
    return if ($self->{'dontsave'});
    my $vars = $self->get_all();
    if ($self->{'file'}) {
	open(OPFILE, ">$self->{'file'}");
	foreach my $var (keys(%$vars)) {
	    print OPFILE xlat_data_fw($var),"\n";
	    print OPFILE xlat_data_fw($vars->{$var}),"\n";
	}
	close(OPFILE);
    }
}

sub load_data {
    my $self = shift;
    return if (!$self);
    $self->reset();
    $self->{'dontsave'} = 1;
    if ($self->{'file'} && -f $self->{'file'}) {
	open(IPFILE, "$self->{'file'}");
	while (<IPFILE>) {
	    chomp();
	    my $key = xlat_data_rv($_);
	    $_ = <IPFILE>;
	    chomp();
	    my $val = xlat_data_rv($_);
	    $self->set($key, $val);
	}
    }
    $self->{'dontsave'} = 0;
}

sub xlat_data_fw {
    my $data = shift;
    $data =~ s/([^a-zA-Z0-9])/'%' . ord($1) . ";"/eg;
    return $data;
}

sub xlat_data_rv {
    my $data = shift;
    $data =~ s/\%([0-9]+);/chr($1)/eg;
    return $data;
}

1;

=pod

=head1 NAME

QWizard::Storage::File - Stores data in a file

=head1 SYNOPSIS

  my $st = new QWizard::Storage::File(file => '/path/to/some/file');
  $st->set('var', 'value');
  $st->get('var');

  # optionally bootstrap from an existing file:
  $st->load_data();

=head1 DESCRIPTION

Stores data passed to it in a file (and in memory for faster lookups).

Generally speaking this should *not* be used except when being copied
to from another faster storage mechanism (like a
QWizard::Storage::Memory object).

This module is actually a child class of QWizard::Storage::Memory.

=head1 AUTHOR

Wes Hardaker, hardaker@users.sourceforge.net

=head1 SEE ALSO

perl(1)

Net-Policy: http://net-policy.sourceforge.net/

=cut
