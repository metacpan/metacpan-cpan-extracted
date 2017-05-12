package Number::Phone::RO;

use 5.014000;
use strict;
use warnings;
use parent qw/Number::Phone/;
use utf8;
use re '/s';

sub AREA_NAMES ();

our $VERSION = '1.000';

our %cache;

sub _normalized {
	my ($nr) = @_;
	$nr =~ y/0-9+//cd;
	$nr =~ s/^[+]40//;
	$nr =~ s/^0//;
	$nr
}

sub _analyze_number {
	my ($nr) = @_;
	my %info;

	return { valid => 0 } unless length $nr == 9;
	$info{valid} = 1;

	$info{geographic} = $nr =~ /^[23][3-6]/ ? 1 : 0;
	@info{qw/fixed_line mobile/} = (1, 0) if $nr =~ /^[23]/;
	@info{qw/fixed_line mobile/} = (0, 1) if $nr =~ /^7/;
	$info{tollfree} = $nr =~ /^800/ ? 1 : 0;
	$info{specialrate} = $nr =~ /^90/ ? 1 : 0;
	$info{adult} = 1 if $nr =~ /^906/;

	my $arealen = $nr =~ /^[23]1/ ? 2 : 3;
	$info{areacode} = substr $nr, 0, $arealen;
	$info{subscriber} = substr $nr, $arealen;

	\%info
}

sub _info { $cache{${$_[0]}} }

sub new {
	my ($class, $nr) = @_;
	$nr = _normalized $nr;
	$cache{$nr} = _analyze_number $nr;
	my $self = bless \$nr, $class;
	$self->is_valid ? $self : undef
}

sub is_valid       { shift->_info->{valid} }
sub is_geographic  { shift->_info->{geographic} }
sub is_fixed_line  { shift->_info->{fixed_line} }
sub is_mobile      { shift->_info->{mobile} }
sub is_tollfree    { shift->_info->{tollfree} }
sub is_specialrate { shift->_info->{specialrate} }
sub is_adult       { shift->_info->{adult} }

sub country_code { 40 }
sub regulator { 'ANCOM, http://ancom.org.ro'}

sub areacode   { shift->_info->{areacode} }
sub areaname   { $_[0]->is_geographic ? AREA_NAMES->{substr $_[0]->areacode, 1} : undef }
sub subscriber { shift->_info->{subscriber} }

sub format { ## no critic (ProhibitBuiltinHomonyms)
	my ($self) = @_;
	join ' ',
	  '+40',
	  $self->areacode,
	  (substr $self->subscriber, 0, 3),
	  (substr $self->subscriber, 3);
}

sub intra_country_dial_to { "0${$_[0]}" }

use HTTP::Tiny;

my $ht = HTTP::Tiny->new(agent => "Number-Phone-RO/$VERSION ");

sub query_portabilitate {
	my ($self) = @_;
	$self->_info->{portabilitate_queried} = 1;
	my $req = $ht->get("http://portabilitate.ro/ro-no-0$$self");
	return unless $req->{success};
	my ($initial_operator) = $req->{content} =~ /lnkOperatorInitial">([^<]*)</x;
	my ($current_operator) = $req->{content} =~ /lnkOperator">([^<]*)</x;
	$initial_operator //= $current_operator;
	$self->_info->{initial_operator} = $initial_operator;
	$self->_info->{current_operator} = $current_operator;
}

sub operator {
	my ($self) = @_;
	$self->query_portabilitate unless $self->_info->{portabilitate_queried};
	$self->_info->{initial_operator}
}

sub operator_ported {
	my ($self) = @_;
	$self->query_portabilitate unless $self->_info->{portabilitate_queried};
	$self->_info->{current_operator}
}

use constant AREA_NAMES => {
	1  => 'București',
	30 => 'Suceava',
	31 => 'Botoșani',
	32 => 'Iași',
	33 => 'Neamț',
	34 => 'Bacău',
	35 => 'Vaslui',
	36 => 'Galați',
	37 => 'Vrancea',
	38 => 'Buzău',
	39 => 'Brăila',
	40 => 'Tulcea',
	41 => 'Constanța',
	42 => 'Călărași',
	43 => 'Ialomița',
	44 => 'Prahova',
	45 => 'Dâmbovița',
	46 => 'Giurgiu',
	47 => 'Teleorman',
	48 => 'Argeș',
	49 => 'Olt',
	50 => 'Vâlcea',
	51 => 'Dolj',
	52 => 'Mehedinți',
	53 => 'Gorj',
	54 => 'Hunedoara',
	55 => 'Caraș-Severin',
	56 => 'Timiș',
	57 => 'Arad',
	58 => 'Alba',
	59 => 'Bihor',
	60 => 'Sălaj',
	61 => 'Satu Mare',
	62 => 'Maramureș',
	63 => 'Bistrița-Năsăud',
	64 => 'Cluj',
	65 => 'Mureș',
	66 => 'Harghita',
	67 => 'Covasna',
	68 => 'Brașov',
	69 => 'Sibiu',
};

1;
__END__

=encoding utf-8

=head1 NAME

Number::Phone::RO - Phone number information for Romania (+40)

=head1 SYNOPSIS

  use Number::Phone::RO;
  my $nr = Number::Phone::RO->new('+40250123456');
  say $nr->is_geographic;   # 1
  say $nr->is_fixed_line;   # 1
  say $nr->is_mobile;       # 0
  say $nr->is_tollfree;     # 0
  say $nr->is_specialrate;  # 0
  say $nr->areacode;        # 250
  say $nr->areaname;        # Vâlcea
  say $nr->subscriber;      # 123456
  say $nr->operator;        # (the name of this number's original operator)
  say $nr->operator_ported; # (the name of this number's current operator)
  say $nr->format;          # +40 250 123 456

=head1 DESCRIPTION

See the L<Number::Phone> documentation for usage information. The
following methods from L<Number::Phone> are overridden:

=over

=item B<is_geographic>

=item B<is_fixed_line>

=item B<is_mobile>

=item B<is_tollfree>

=item B<is_specialrate>

=item B<is_adult>

=item B<country_code>

Always returns 40.

=item B<regulator>

Returns the name and URL of the regulator, ANCOM.

=item B<areacode>

=item B<areaname>

=item B<operator>

=item B<operator_ported>

=item B<subscriber>

=item B<format>

=back

Other methods:

=over 4

=item B<query_portabilitate>

Queries L<http://portabilitate.ro> to get the information for the
B<operator> and B<operator_ported> methods. The result is cached.
Note that failures (such as number invalid, no internet connection)
are also cached. Also note that the service rate limits
requests. Going over the (unspecified) rate limit causes the service
to ask for a captcha (which is interpreted as a failure by this
function).

This method is automatically called by B<operator> and
B<operator_ported> the first time they are called. A possible reason
for calling it explicitly is refreshing the cache.

=back

=head1 TODO

Only long (10 digits) numbers are supported.

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2016 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
