############################################################
#
#   $Id: Handle.pm 976 2007-03-04 20:47:36Z nicolaw $
#   Parse::DMIDecode::Handle - SMBIOS Structure Handle Object Class
#
#   Copyright 2006 Nicola Worthington
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
############################################################

package Parse::DMIDecode::Handle;
# vim:ts=4:sw=4:tw=78

use strict;
use Parse::DMIDecode::Constants qw(@TYPES %GROUPS %TYPE2GROUP);
#use Scalar::Util qw(refaddr);
#use Storable qw(dclone);
use Carp qw(croak cluck confess carp);
use vars qw($VERSION $DEBUG);

$VERSION = '0.03' || sprintf('%d', q$Revision: 976 $ =~ /(\d+)/g);
$DEBUG ||= $ENV{DEBUG} ? 1 : 0;

my $objstore = {};


#
# Methods
#

sub new {
	ref(my $class = shift) && croak 'Class name required';
	croak 'Odd number of elements passed when even was expected' if @_ % 2;

	my $stor = {@_};
	my @validkeys = qw(raw nowarnings);
	my $validkeys = join('|',@validkeys);
	my @invalidkeys = grep(!/^$validkeys$/,keys %{$stor});
	delete $stor->{$_} for @invalidkeys;
	cluck('Unrecognised parameters passed: '.join(', ',@invalidkeys))
		if @invalidkeys && $^W;

	return unless defined defined $stor->{raw};
	for (split(/\n/,$stor->{raw})) {
		if (/^Handle ([0-9A-Fx]+)(?:, DMI type (\d+), (\d+) bytes?\.?)?\s*$/) {
			$stor->{handle} = $1;
			$stor->{dmitype} = $2 if defined $2;
			$stor->{bytes} = $3 if defined $3;
		} elsif (defined $stor->{handle} &&
				/^\s*DMI type (\d+), (\d+) bytes?\.?\s*$/) {
			$stor->{dmitype} = $1 if defined $1;
			$stor->{bytes} = $2 if defined $2;
		} else {
			$stor->{raw_entries} = [] unless defined $stor->{raw_entries};
			push @{$stor->{raw_entries}}, $_;
		}
	}

	my ($data,$keywords) = _parse($stor)
		if $stor->{raw_entries};

	my @objects;
	for my $name (keys(%{$data})) {
		my $self = bless \(my $dummy), $class;
		push @objects, $self;

		$objstore->{_refaddr($self)} = _deepcopy($stor);
		my $stor = $objstore->{_refaddr($self)};

		$stor->{description} = substr($name,4);
		$stor->{data} = $data->{$name} || {};
		$stor->{keywords} = $keywords->{$name} || {};

		DUMP('$self',$self);
		DUMP('$stor',$stor);
	}

	DUMP('\@objects',\@objects);
	return @objects;
}


no warnings 'redefine';
sub UNIVERSAL::a_sub_not_likely_to_be_here { ref($_[0]) }
use warnings 'redefine';


sub _blessed ($) {
	local($@, $SIG{__DIE__}, $SIG{__WARN__});
	return length(ref($_[0]))
			? eval { $_[0]->a_sub_not_likely_to_be_here }
			: undef
}


sub _refaddr($) {
	my $pkg = ref($_[0]) or return undef;
	if (_blessed($_[0])) {
		bless $_[0], 'Scalar::Util::Fake';
	} else {
		$pkg = undef;
	}
	"$_[0]" =~ /0x(\w+)/;
	my $i = do { local $^W; hex $1 };
	bless $_[0], $pkg if defined $pkg;
	return $i;
}


sub _deepcopy{
	my $this = shift;
	if (!ref($this)) {
		$this;
	} elsif (ref($this) eq 'ARRAY') {
		[ map _deepcopy($_), @{$this} ];
	} elsif (ref($this) eq 'HASH'){
		scalar { map { $_ => _deepcopy($this->{$_}) } keys %{$this} };
	} else {
		confess "What type is $_?";
	}
}


sub parsed_structures {
	my $self = shift;
	croak 'Not called as a method by parent object'
		unless ref $self && UNIVERSAL::isa($self, __PACKAGE__);
	return _deepcopy($objstore->{_refaddr($self)}->{data});
}


sub keyword {
	my $self = shift;
	croak 'Not called as a method by parent object'
		unless ref $self && UNIVERSAL::isa($self, __PACKAGE__);
	croak sprintf('%s elements passed when one was expected',
		(@_ > 1 ? 'Multiple' : 'No')) if @_ != 1;
	return $objstore->{_refaddr($self)}->{keywords}->{$_[0]};
}


sub keywords {
	my $self = shift;
	croak 'Not called as a method by parent object'
		unless ref $self && UNIVERSAL::isa($self, __PACKAGE__);
	return sort(keys(%{$objstore->{_refaddr($self)}->{keywords}}));
}


sub raw {
	my $self = shift;
	croak 'Not called as a method by parent object'
		unless ref $self && UNIVERSAL::isa($self, __PACKAGE__);
	return $objstore->{_refaddr($self)}->{raw};
}


sub description {
	my $self = shift;
	croak 'Not called as a method by parent object'
		unless ref $self && UNIVERSAL::isa($self, __PACKAGE__);
	return $objstore->{_refaddr($self)}->{description};
}


sub bytes {
	my $self = shift;
	croak 'Not called as a method by parent object'
		unless ref $self && UNIVERSAL::isa($self, __PACKAGE__);
	return $objstore->{_refaddr($self)}->{bytes};
}


sub type { &dmitype; }
sub dmitype {
	my $self = shift;
	croak 'Not called as a method by parent object'
		unless ref $self && UNIVERSAL::isa($self, __PACKAGE__);
	return $objstore->{_refaddr($self)}->{dmitype};
}


sub address { &handle; }
sub handle {
	my $self = shift;
	croak 'Not called as a method by parent object'
		unless ref $self && UNIVERSAL::isa($self, __PACKAGE__);
	return $objstore->{_refaddr($self)}->{handle};
}


sub _parse {
	my $stor = shift;
	return unless defined $stor->{raw_entries};

	my $name_indent = 0;
	my $key_indent  = 0;
	my $name = '';
	my $name_cnt = 0;
	my $key = '';
	my $legacy_dmidecode_binary_data = 0;

	my @errors;
	my %data;
	my %keywords;

#	DUMP('$stor->{raw_entries}',$stor->{raw_entries});

	for (my $l = 0; $l < @{$stor->{raw_entries}}; $l++) {
		local $_ = $stor->{raw_entries}->[$l];
		my ($indent) = $_ =~ /^(\s+)/;
		$indent = '' unless defined $indent;
		$indent = length($indent);

		# Old version of dmidecode - we don't support this very well
#Handle 0xD402
#|   DMI type 212, 47 bytes.
#70 00 71 00 03 40 59 6d d8 00 55 7f 80 d9 00 55 |   p.q..@Ym..U....U
#7f 00 00 c0 5c 00 0a 03 c0 67 00 05 83 00 76 00 |   ....\....g....v.
#00 84 00 77 00 00 ff ff 00 00 00                |   ...w.......
		if ((!$name || $legacy_dmidecode_binary_data) && /^(([a-f0-9]{2} )+)\s*\t[[:print:]]{1,16}\s*$/) {
			my $data = $1;
			chop $data;
			$name ||= sprintf('%03d|%s',++$name_cnt,'OEM-specific Type');
			$key = 'Header and Data';
			$legacy_dmidecode_binary_data = 1;
			$data{$name}->{$key}->[1] = [] unless defined $data{$name}->{$key}->[1];
			push @{$data{$name}->{$key}->[1]}, $data;
			next;
		}

		$name_indent = $indent if $l == 0;
		if ($l == 1) {
			if ($indent > $name_indent) { $key_indent = $indent; }
			else { push @errors, "Parser warning: key_indent ($indent) <= name_indent ($name_indent): $_"; }
		}

		# data
		if (/^\s{$name_indent}(\S+.*?)\s*$/) {
			$name = sprintf('%03d|%s',++$name_cnt,$1);
			$data{$name} = {};
			$key = '';

		} elsif ($name && /^\s{$key_indent}(\S.*?)(?::|:\s+(\S+.*?))?\s*$/) {
			$key = $1;
			$data{$name}->{$key}->[0] = $2;
			$data{$name}->{$key}->[1] = [] unless defined $data{$name}->{$key}->[1];
			$keywords{$name}->{_keyword($stor,$key)} = $data{$name}->{$key}->[0]
				if defined $TYPE2GROUP{$stor->{dmitype}}

		} elsif ($name && $key && $indent > $key_indent && /^\s*(\S+.*?)\s*$/) {
			push @{$data{$name}->{$key}->[1]}, $1;
			$keywords{$name}->{_keyword($stor,$key)} = $data{$name}->{$key}->[1]
				if defined $TYPE2GROUP{$stor->{dmitype}};# && !defined $data{$name}->{$key}->[0];

		# unknown
		} else {
			push @errors, "Parser warning: $_";
		}
	}

	sub _keyword {
		my ($stor,$key) = @_;
		(my $keyword = $key) =~ s/[^a-z0-9]/-/gi;
		$keyword = lc("$TYPE2GROUP{$stor->{dmitype}}-$keyword");
		return $keyword;
	}

	#if ($^W && @errors) {
	if (@errors && !$stor->{nowarnings}) {
		carp $_ for @errors;
	}

	return (\%data,\%keywords);
}


sub TRACE {
	return unless $DEBUG;
	carp(shift());
}


sub DUMP {
	return unless $DEBUG;
	eval {
		require Data::Dumper;
		local $Data::Dumper::Indent = 2;
		local $Data::Dumper::Terse = 1;
		carp(shift().': '.Data::Dumper::Dumper(shift()));
	}
}

1;



=pod

=head1 NAME

Parse::DMIDecode::Handle - SMBIOS Structure Handle Object Class

=head1 SYNOPSIS

 use Parse::DMIDecode qw();
 my $decoder = new Parse::DMIDecode;
 $decoder->probe;
 
 for my $handle ($decoder->get_handles) {
     printf("Handle %s of type %s is %s bytes long (minus strings).\n".
            "  > Contians the following keyword data entries:\n",
             $handle->handle,
             $handle->dmitype,
             $handle->bytes
         );
 
     for my $keyword ($handle->keywords) {
         my $value = $handle->keyword($keyword);
         printf("Keyword \"%s\" => \"%s\"\n",
                 $keyword,
                 (ref($value) eq 'ARRAY' ?
                     join(', ',@{$value}) : ($value||''))
             );
     }
 }

=head1 DESCRIPTION

=head1 METHODS

=head2 new

Create a new struture handle object. This is called by L<Parse::DMIDecode>'s
I<parse()> (and indirectly by I<probe()>) methods.

=head2 raw

 my $raw_data = $handle->raw;

Returns the raw data as generated by I<dmidecode> that was
parsed to create this handle object.

=head2 bytes

 my $bytes = $handle->bytes;

=head2 address

 my $address = $handle->address;

Returns the address handle of the structure.

=head2 handle

Alias for address.

=head2 dmitype

 my $dmitype = $handle->dmitype;

=head2 type

Alias for dmitype.

=head2 description

 my $description = $handle->description;

=head2 keywords

 my @keywords = $handle->keywords;

Returns a list of keyword data pairs available for retreival from
this handle object.

=head2 keyword

 for my $keyword ($handle->keywords) {
     printf("Keyword \"%s\" => \"%s\"\n",
             $keyword,
             $handle->keyword($keyword)
         );
 }

=head2 parsed_structures

 use Data::Dumper;
 my $ref = $handle->parsed_structures;
 print Dumper($ref);

Returns a copy of the parsed structures. This should be used with care
as this is a cloned copy of the parsed data structures that the
I<Parse::DMIDecode::Handle> object uses internally, and as such may
change format in later releases without notice.

=head1 SEE ALSO

L<Parse::DMIDecode>

=head1 VERSION

$Id: Handle.pm 976 2007-03-04 20:47:36Z nicolaw $

=head1 AUTHOR

Nicola Worthington <nicolaw@cpan.org>

L<http://perlgirl.org.uk>

If you like this software, why not show your appreciation by sending the
author something nice from her
L<Amazon wishlist|http://www.amazon.co.uk/gp/registry/1VZXC59ESWYK0?sort=priority>? 
( http://www.amazon.co.uk/gp/registry/1VZXC59ESWYK0?sort=priority )

=head1 COPYRIGHT

Copyright 2006 Nicola Worthington.

This software is licensed under The Apache Software License, Version 2.0.

L<http://www.apache.org/licenses/LICENSE-2.0>

=cut


__END__




