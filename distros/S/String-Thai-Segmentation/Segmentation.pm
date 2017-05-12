package String::Thai::Segmentation;

use 5.00503;
use strict;

require Exporter;
require DynaLoader;
use vars qw($VERSION @ISA @EXPORT_OK);
@ISA = qw(Exporter
	DynaLoader);

@EXPORT_OK = qw();

$VERSION = '0.01';

bootstrap String::Thai::Segmentation $VERSION;

sub new {
	my $class=shift;
	my $self={};
	$self->{wc}=String::Thai::Segmentation->get_wc();
	bless $self,$class;
}

sub separate {
	my $self=shift;
	$self->string_separate($self->{wc},$_[0],$_[1]);
}

sub cut_raw {
	my $self=shift;
	my $tmp=$self->wordcut($self->{wc},$_[0]);
	split(/#K_=/,$tmp);
}

sub cut_no_space {
	my $self=shift;
	my $tmp=$self->wordcut($self->{wc},$_[0]);
	split(/#K_=|\s+/,$tmp);
}

sub cut {
	my $self=shift;
	my $tmp=$self->wordcut($self->{wc},$_[0]);
	split(/#K_=|(\s+)/,$tmp);
}

sub DESTROY {
	my $self=shift;
	$self->destroy_wc($self->{wc});
}

1;
__END__

=head1 NAME

String::Thai::Segmentation - an object-oriented interface of Thai word segmentation

=head1 SYNOPSIS

	use String::Thai::Segmentation;

	#create object
	$sg=String::Thai::Segmentation->new();

	# insert separator to $thai_string
	$result=$sg->separate($thai_string,$separator);

	# split $thai_string to array include all spacing
	@result=$sg->cut($thai_string);

	# split $thai_string to array exclude spacing
	@result=$sg->cut_no_space($thai_string);

	# split $thai_string to array as of the original library
	@result=$sg->cut_raw($thai_string);

=head1 DESCRIPTION

Thai language is known to be a "word-sticked language", all words in a sentence are next to each other with out spacing. It is hard for programmers to solve problems on this kind of language, such as translating or searching.

The module is a object-oriented interface of Thai word segmentation library (http://thaiwordseg.sourceforge.net).

=head2 EXPORT

None by default.

=head1 SEE ALSO

http://thaiwordseg.sourceforge.net

=head1 AUTHOR

Komtanoo  Pinpimai(romerun@romerun.com)

=head1 COPYRIGHT AND LICENSE

Perl License.

=cut
