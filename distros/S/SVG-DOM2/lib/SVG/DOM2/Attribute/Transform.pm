package SVG::DOM2::Attribute::Transform;

use base "XML::DOM2::Attribute";

use strict;
use warnings;
use Carp;

sub new
{
	my ($proto, %opts) = @_;
	return $proto->SUPER::new(%opts);
}

sub serialise
{
	my ($self) = @_;
	my $result = '';
	foreach my $transform ($self->transforms) {
		$result .= ';' if $result;
		$result .= $transform->{'type'}.'('.join(',',@{$transform->{'ops'}}).')';
	}
	return $result;
}

sub deserialise
{
	my ($self, $attr) = @_;
	my @result;
#	warn "Deserialising an elements transforms\n";
	foreach my $transform (split(/;/, $attr)) {
		if($transform =~ /(\w+)\((.+)\)/) {
			my $type = $1;
			my @ops = split(/\s*,\s*/, $2);
			push @result, { type => $type, ops => \@ops };
#			warn "found $type\n";
		}
	}
	$self->{'transforms'} = \@result;
	return $self;
}

=head1 METHODS

transforms - return a list of transforms

=cut
sub transforms
{
	my ($self) = @_;
	return @{$self->{'transforms'}};
}

return 1;
