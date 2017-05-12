
package AddressBook;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw( getaddresses );

$VERSION = sprintf "%d.%02d", q$Revision: 1.0 $ =~ m#(\d+)\.(\d+)#;

use Carp;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};

	$self->{SETUP} = {};

	$self->{BOOKNAME} = shift; # Which address book
	$self->{FIELDS} = {}; # Field names and array positions
	$self->{BOOK} = []; # The addressbook contents

    bless $self, $class;

	open (FMT,"<$self->{BOOKNAME}.dat.fmt") || die "Can't open format file,$!\n";
	while (<FMT>) {
		chomp;
		if (/^\d+/) {
			my ($num, $name) = (split(/\s+/,$_));
			$self->{FIELDS}{$name} = $num;
		}
		elsif (/^label\d+/) {
			s/^label//;
			my $num = (split(/\s+/,$_))[0];
			my $label = $_;
			$label =~ s/\d+\s+//;
			$label =~ s/"//g;
			$self->{FIELDS}{"$label"} = $self->{FIELDS}{"other".$num};
			$self->{FIELDS}{"other".$num} = undef;
		}
	}
	close FMT;

	open (DAT,"<$self->{BOOKNAME}.dat") || die "Can't open data file,$!\n";
	while (<DAT>) {
		chomp;
		push @{$self->{BOOK}},$_;
	}

     return $self;
}

# ****************************************************************
#	return a subset of the addressbook
sub getaddresses {
    my $self = shift;
	my $field = shift;
	my $tag = shift;

	my $selected;

	foreach (@{$self->{BOOK}}) {
		my @record = (split(';',$_));
		my $index = $self->{FIELDS}{$field};
		if (defined $record[$index] && $tag =~ /$record[$index]/) {
			push @{$selected},\@record;
		}
	}

    return $selected;
}


1;
__END__

=head1 NAME

AddressBook.pm - Read and select from an ASCII address book as defined
				 by http://home.pages.de/~clemens and his Tcl/Tk
				 addressbook software.
				 Moved to http://addressbook.home.pages.de or
				 http://www.red.roses.de/~clemens/addressbook/
                         

=head1 SYNOPSIS

  use AddressBook;

  my $book = "$ENV{HOME}/addresses_private";

  	#	set the addressbook and open it

	my $addr = AddressBook->new($book);

	#	Get all addresses in which the 'remark' field equals 'EFM'

	my $data = $addr->getaddresses('remark','EFM');

	#	Print out a list of addresses

	foreach (sort {$a->[1] cmp $b->[1]} @{$data}) {
		print "$_->[0] $_->[1]\n",
			  "$_->[3] \n",
			  "$_->[5], $_->[6]  $_->[7]\n",
			  "$_->[10]\n",
			  "$_->[13]\n\n";
	}


=head1 DESCRIPTION

	Open an address database and select entries. Need to add stuff like
	"list the available fieldnames", "generate statistics on fields &
	values", and similar databasey type stuff.

	Primarily built to build data for my PostScript::MailLabels modules
	so I can print my Christmas Card mailing labels. 8-)

=head1 AUTHOR

    Alan Jackson
    November 1999
    alan@ajackson.org


=head1 SEE ALSO

=cut
