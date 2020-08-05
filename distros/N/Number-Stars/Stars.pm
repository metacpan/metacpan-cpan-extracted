package Number::Stars;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Number of stars.
	$self->{'number_of_stars'} = 10;

	# Process parameters.
	set_params($self, @params);

	if ($self->{'number_of_stars'} !~ m/^\d+$/) {
		err "Parameter 'number_of_stars' must be a number.";
	}

	return $self;
}

# Convert percent number to stars definition.
sub percent_stars {
	my ($self, $percent) = @_;

	my $stars_hr = {};
	my $star_percent = 100 / $self->{'number_of_stars'};
	foreach my $star_id (1 .. $self->{'number_of_stars'}) {
		if ($percent >= $star_id * $star_percent) {
			$stars_hr->{$star_id} = 'full';
		} elsif ($percent >= ($star_id * $star_percent) - ($star_percent / 2)) {
			$stars_hr->{$star_id} = 'half',
		} else {
			$stars_hr->{$star_id} = 'nothing',
		}
	}

	return $stars_hr;
}

__END__

=pod

=encoding utf8

=head1 NAME

Number::Stars - Class for conversion between percent number to star visualization.

=head1 SYNOPSIS

 use Number::Stars;

 my $obj = Number::Stars->new(%params);
 my $stars_hr = $obj->percent_stars($percent);

=head1 METHODS

=head2 C<new>

 my $obj = Number::Stars->new(%params);

Constructor.

Returns instance of Number::Stars.

=over 8

=item * C<number_of_stars>

Number of stars.

Default value is 10.

=back

=head2 C<percent_stars>

 my $stars_hr = $obj->percent_stars($percent);

Get stars structure for setting of star visualisation.
(e.g.: 50% → ★★★★★☆☆☆☆☆)
Output structure is defined by number of star and its value.
Possible values are: 'nothing', 'half' and 'full', which define type of star.

Returns reference to hash.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Number::Stars;
 use Data::Printer;

 if (@ARGV < 1) {
        print STDERR "Usage: $0 percent\n";
        exit 1;
 }
 my $percent = $ARGV[0];

 # Object.
 my $obj = Number::Stars->new;

 # Get structure.
 my $stars_hr = $obj->percent_stars($percent);

 # Print out.
 print "Percent: $percent\n";
 print "Output structure:\n";
 p $stars_hr;

 # Output for run without arguments:
 # Usage: __SCRIPT__ percent

 # Output for value '55':
 # Percent: 55
 # Output structure:
 # \ {
 #     1    "full",
 #     2    "full",
 #     3    "full",
 #     4    "full",
 #     5    "full",
 #     6    "half",
 #     7    "nothing",
 #     8    "nothing",
 #     9    "nothing",
 #     10   "nothing"
 # }

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Number::Stars;
 use Readonly;
 use Unicode::UTF8 qw(decode_utf8 encode_utf8);

 Readonly::Scalar our $FULL_STAR => decode_utf8('★');
 Readonly::Scalar our $HALF_STAR => decode_utf8('⭒');
 Readonly::Scalar our $NOTHING_STAR => decode_utf8('☆');

 if (@ARGV < 1) {
        print STDERR "Usage: $0 percent\n";
        exit 1;
 }
 my $percent = $ARGV[0];

 # Object.
 my $obj = Number::Stars->new;

 # Get structure.
 my $stars_hr = $obj->percent_stars($percent);

 my $output;
 foreach my $star_num (sort { $a <=> $b } keys %{$stars_hr}) {
       if ($stars_hr->{$star_num} eq 'full') {
               $output .= $FULL_STAR;
       } elsif ($stars_hr->{$star_num} eq 'half') {
               $output .= $HALF_STAR;
       } elsif ($stars_hr->{$star_num} eq 'nothing') {
               $output .= $NOTHING_STAR;
       }
 }

 # Print out.
 print "Percent: $percent\n";
 print 'Output: '.encode_utf8($output)."\n";

 # Output for run without arguments:
 # Usage: __SCRIPT__ percent

 # Output for value '55':
 # Percent: 55
 # Output: ★★★★★⭒☆☆☆☆

=head1 EXAMPLE3

 use strict;
 use warnings;

 use Number::Stars;
 use Readonly;
 use Unicode::UTF8 qw(decode_utf8 encode_utf8);

 Readonly::Scalar our $FULL_STAR => decode_utf8('★');
 Readonly::Scalar our $HALF_STAR => decode_utf8('⭒');
 Readonly::Scalar our $NOTHING_STAR => decode_utf8('☆');

 if (@ARGV < 2) {
        print STDERR "Usage: $0 number_of_stars percent\n";
        exit 1;
 }
 my $number_of_stars = $ARGV[0];
 my $percent = $ARGV[1];

 # Object.
 my $obj = Number::Stars->new(
         'number_of_stars' => $number_of_stars,
 );

 # Get structure.
 my $stars_hr = $obj->percent_stars($percent);

 my $output;
 foreach my $star_num (sort { $a <=> $b } keys %{$stars_hr}) {
       if ($stars_hr->{$star_num} eq 'full') {
               $output .= $FULL_STAR;
       } elsif ($stars_hr->{$star_num} eq 'half') {
               $output .= $HALF_STAR;
       } elsif ($stars_hr->{$star_num} eq 'nothing') {
               $output .= $NOTHING_STAR;
       }
 }

 # Print out.
 print "Percent: $percent\n";
 print 'Output: '.encode_utf8($output)."\n";

 # Output for run without arguments:
 # Usage: __SCRIPT__ number_of_stars percent

 # Output for values 10, 55:
 # Percent: 55
 # Output: ★★★★★⭒☆☆☆☆

 # Output for values 3, 55:
 # Percent: 55
 # Output: ★⭒☆

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>.

=head1 SEE ALSO

=over

=item L<Tags::HTML::Stars>

Tags helper for stars evaluation

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Number-Stars>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020

BSD 2-Clause License

=head1 VERSION

0.01

=cut
