package Seshat::Parallel;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Data::Dumper;

require Exporter;
require AutoLoader;
require Seshat;


@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '1.01';

sub new {
        my ($classname,$files) = @_;
        my $self = {};
	foreach (@$files) {
		$self->{files}->{$_} = Seshat->new($_); 
	}
        $self->{NAME} = "Seshat::Parallel";
        bless ($self,$classname);
        return $self;
}
sub write {
	my ($self, $string, $flag) = @_;
	foreach ( keys %{$self->{files}} ) {
		my $lh = $self->{files}->{$_};
		my $res = $lh->write($string,$flag);
		warn "$@" unless $res;
	}
}
sub register {
	my ($self, $filename) = @_;
	if (! exists $self->{files}->{$filename}) {
		$self->{files}->{$filename} = Seshat->new($filename);
	} else {
		$@ = "The requested file is already in queue";
		return undef;
	}
	return 1;
}
sub unregister {
	my ($self, $filename) = @_;
	if (exists $self->{files}->{$filename}) {
		delete $self->{files}->{$filename};
	} else {
		$@ = "The requested file is not in queue";
		return undef;
	}	
	return 1;
} 

1;
__END__

=head1 NAME

Seshat::Parallel - Perl extension for Seshat  

=head1 SYNOPSIS

  use Seshat::Parallel;
  
  my $plh = Seshat::Parallel->new("filename1"[,"filename2",...]);

  $plh->write($string, $bol_flag);

  my $res = $plh->registar("filename3");

  my $res = $plh->register("filename1");

=head1 DESCRIPTION

This is an extension for Seshat, it introduces multiple , simultaneous, log writing.
The module uses a list of filenames given by the user and, every time its required, the modulo writes the string
to all the filenames specified.

=head1 AUTHOR

Bruno Tavares (bruno.tav@clix.pt)

=head1 SEE ALSO

perl(1).

=cut
