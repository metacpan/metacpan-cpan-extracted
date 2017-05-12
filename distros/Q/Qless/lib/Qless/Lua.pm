package Qless::Lua;
=head1 NAME

Qless::Lua

=cut

use strict; use warnings;
use File::ShareDir qw();
use overload '&{}' => sub { my $self = shift; sub { $self->call(@_) }; }, fallback => 1;

sub new {
	my $class = shift;
	my ($name, $r) = @_;

	$class = ref $class if ref $class;
	my $self = bless {}, $class;

	$self->{'name'}  = $name;
	$self->{'redis'} = $r;
	$self->{'sha'}   = undef;

	$self;
}

sub reload {
	my ($self) = @_;

	my $filename = File::ShareDir::dist_file('Qless', $self->{'name'}.'.lua');
	open my $fh, '<', $filename or die $!;
	my $content = do { local $/;  <$fh> };
	close $fh;

	return $self->{'sha'} = $self->{'redis'}->script('load', $content);
}

sub call {
	my ($self, $keys, @args) = @_;
	
	$self->reload if !$self->{'sha'};

	$keys ||= [];
	my $keys_count = scalar @{ $keys };

	my $rv = eval {
		$self->{'redis'}->evalsha($self->{'sha'}, $keys_count, $keys_count ? @{ $keys } : (), @args);
	};

	if ($@) {
		$self->reload;
		$rv = $self->{'redis'}->evalsha($self->{'sha'}, $keys_count, $keys_count ? @{ $keys } : (), @args);
	}

	return $rv;
}

1;
