package PEF::Front::Headers;
use strict;
use warnings;
use PEF::Front::Config;
use Time::Duration::Parse;
use Scalar::Util qw(blessed);
use Encode;
use utf8;

sub new {
	my $self = bless {}, $_[0];
	for (my $i = 1; $i < @_; $i += 2) {
		if (blessed($_[$i]) && $_[$i]->isa("PEF::Front::Headers")) {
			for my $fk (keys %{$_[$i]}) {
				if ('ARRAY' eq ref $_[$i]->{$fk}) {
					@{$self->{$fk}} = @{$_[$i]->{$fk}};
				} else {
					$self->{$fk} = $_[$i]->{$fk};
				}
			}
			--$i;
			next;
		}
		$self->add_header($_[$i], $_[$i + 1]);
	}
	$self;
}

sub is_empty {
	not %{$_[0]};
}

sub add_header {
	my ($self, $key, $value) = @_;
	if (exists $self->{$key}) {
		if ('ARRAY' eq ref $self->{$key}) {
			push @{$self->{$key}}, $value;
		} else {
			$self->{$key} = [$self->{$key}, $value];
		}
	} else {
		$self->{$key} = $value;
	}
}

sub set_header {
	my ($self, $key, $value) = @_;
	$self->{$key} = $value;
}

sub remove_header {
	my ($self, $key) = @_;
	delete $self->{$key};
}

sub get_header {
	my ($self, $key) = @_;
	return if not exists $self->{$key};
	$self->{$key};
}

sub get_all_headers {
	my $self = $_[0];
	my $ret  = [
		map {
			my $key = $_;
			!ref($self->{$key}) || 'ARRAY' ne ref($self->{$key})
				? ($key => $self->{$key})
				: (map {$key => $_} @{$self->{$key}})
		} keys %$self
	];
	$ret;
}

package PEF::Front::HTTPHeaders;
our @ISA = qw(PEF::Front::Headers);

sub new {
	"$_[0]"->SUPER::new(@_[1 .. $#_]);
}

sub _canonical {
	(my $h = lc $_[0]) =~ tr/_/-/;
	$h =~ s/\b(\w)/\u$1/g;
	$h;
}

sub add_header {
	my ($self, $key, $value) = @_;
	$self->SUPER::add_header(_canonical($key), $value);
}

sub set_header {
	my ($self, $key, $value) = @_;
	$self->SUPER::set_header(_canonical($key), $value);
}

sub remove_header {
	my ($self, $key) = @_;
	$self->SUPER::remove_header(_canonical($key));
}

sub get_header {
	my ($self, $key) = @_;
	$self->SUPER::get_header(_canonical($key));
}

1;

__END__

=head1 NAME
 
PEF::Front::Headers - Base headers class

PEF::Front::HTTPHeaders - Class encapsulating HTTP Message headers
 
=head1 SYNOPSIS

  my $basic = $context->{headers}->get_header('basic');

=head1 DESCRIPTION

Usually you can get instance of these classes from C<context>: 
C<$headers> has type C<PEF::Front::HTTPHeaders>. These are also
used in L<PEF::Front::Response> for cookies and headers.

The only difference between C<PEF::Front::Headers> and
C<PEF::Front::HTTPHeaders> is that HTTPHeaders can convert
"CONTENT-TYPE" or "content_type" type of header names to canonical
"Content-Type".

=head1 FUNCTIONS

=head2 new

Constructor. Can set headers and copy from existing L<PEF::Front::Headers>
or derived instances.

  my $h = PEF::Front::Headers->new($header => $value);
  my $h2 = PEF::Front::Headers->new($header1 => $value1, $header2 => $value2, ...);
  my $h3 = PEF::Front::Headers->new($h, $h2);

=head2 add_header($key, $value)

Adds header. This method allows to have multiple headers with the same name.

=head2 set_header($key, $value)
  
Sets header. This method ensures that there's only one header with given name 
in response.

=head2 remove_header($key)

Removes header.

=head2 get_header($key)

Returns header. In case of multiple headers with the same name it returns 
array of them.

=head1 AUTHOR
 
This module was written and is maintained by Anton Petrusevich.

=head1 Copyright and License
 
Copyright (c) 2016 Anton Petrusevich. Some Rights Reserved.
 
This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
