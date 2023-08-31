package Random::AcademicTitle::CZ;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Readonly;

Readonly::Array our @TITLES_AFTER => (
	'Ph.D.',
	'Th.D.',
	'DiS.',
	'DSc.',
);
Readonly::Array our @TITLES_AFTER_OLD => (
	'CSc.',
	'DrSc.',
	'Dr.',
	'Th.D.',
);
Readonly::Array our @TITLES_BEFORE => (
	'prof.',
	'doc.',
	'MUDr.',
	'MVDr.',
	'MDDr.',
	'PharmDr.',
	'JUDr.',
	'PhDr.',
	'RNDr.',
	'ThDr.',
	'Ing.',
	'Ing. arch.',
	'Mgr.',
	'MgA.',
	'Bc.',
	'BcA.',
	'ThLic.',
);
Readonly::Array our @TITLES_BEFORE_OLD => (
	'akad. arch.',
	'akad. mal.',
	'ak. soch.',
	'MSDr.',
	'PaedDr.',
	'PhMr.',
	'RSDr.',
	'RTDr.',
	'RCDr.',
	'ThMgr.',
);

our $VERSION = 0.02;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Set up old titles.
	$self->{'old'} = 0;

	# Process parameters.
	set_params($self, @params);

	return $self;
}

sub random_title_after {
	my $self = shift;

	my @titles = @TITLES_AFTER;
	if ($self->{'old'}) {
		push @titles, @TITLES_AFTER_OLD;
	}
	my $title = $titles[int(rand(@titles))];

	return $title;
}

sub random_title_before {
	my $self = shift;

	my @titles = @TITLES_BEFORE;
	if ($self->{'old'}) {
		push @titles, @TITLES_BEFORE_OLD;
	}
	my $title = $titles[int(rand(@titles))];

	return $title;
}


1;

__END__

=pod

=encoding utf8

=head1 NAME

Random::AcademicTitle::CZ - Class for random Czech academic title.

=head1 SYNOPSIS

 use Random::AcademicTitle::CZ;

 my $obj = Random::AcademicTitle::CZ->new(%params);
 my $title_after = $obj->random_title_after;
 my $title_before = $obj->random_title_before;

=head1 DESCRIPTION

This module could generate actual Czech academic title or academic titles from
all history in the Czech lands.

The information about Czech academic titles you can see at
L<https://cs.wikipedia.org/wiki/Akademick%C3%BD_titul>.

=head1 METHODS

=head2 C<new>

 my $obj = Random::AcademicTitle::CZ->new(%params);

Constructor.

=over 8

=item * C<old>

Flag for set old titles.

Default value is 0.

=back

=head2 C<random_title_after>

 my $dt = $obj->random_title_after;

Get random academic title after name.

Returns string.

=head2 C<random_title_before>

 my $dt = $obj->random_title_before;

Get random academic title before name.

Returns string.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE

=for comment filename=get_academic_titles.pl

 use strict;
 use warnings;

 use Random::AcademicTitle::CZ;

 # Object.
 my $obj = Random::AcademicTitle::CZ->new;

 # Get titles.
 my $title_after = $obj->random_title_after;
 my $title_before = $obj->random_title_before;

 # Print out.
 print "Title before: $title_before\n";
 print "Title after: $title_after\n";

 # Output like:
 # Title before: JUDr.
 # Title after: Th.D.

=head1 DEPENDENCIES

L<Class::Utils>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Mock::Person::CZ>

Generate random sets of Czech names.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Random-AcademicTitle-CZ>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
