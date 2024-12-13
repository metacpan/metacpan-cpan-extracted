package Quaint;

use 5.006;
use strict;
use warnings;
use meta;
use Module::Runtime qw/use_module/;
use Types::Standard qw/Any Bool Str Int Num HashRef ArrayRef Object/;

our $VERSION = '0.03';

sub import {
	my ($caller) = caller();

	my $metapkg;
	{
		no warnings;
		$metapkg = meta::get_package( $caller );
	}
	$metapkg->add_symbol( '%META', \my %META );

	my $INDEX = 1;

	$metapkg->add_named_sub('ro', sub {
		my @ro;
		for (@_) {
			if (ref $_) {
				$_->{is} = 'ro';
				push @ro, $_;
			} else {
				$META{attribute}{$_} = {
					is => 'ro',
					index => $INDEX++,
					name => $_
				};
				push @ro, $META{attribute}{$_};
			}
		}
		return @ro;
	})->set_prototype('@');

	$metapkg->add_named_sub('req', sub {
		my @req;
		for (@_) {
			if (ref $_) {
				$_->{required} = 1;
				push @req, $_;
			} else {
				$META{attribute}{$_} = {
					required => 1,
					index => $INDEX++,
					name => $_
				};
				push @req, $META{attribute}{$_};
			}
		}
		return @req;
	})->set_prototype('@');

	$metapkg->add_named_sub('default', sub {
		my $default = shift;
		my @def;
		for (@_) {
			if (ref $_) {
				$_->{default} = $default;
				push @def, $_;
			} else {
				$META{attribute}{$_} = {
					default => $default,
					index => $INDEX++,
					name => $_
				};
				push @def, $META{attribute}{$_};
			}
		}
		return @def;
	})->set_prototype('&@');

	$metapkg->add_named_sub('trigger', sub {
		my $trigger = shift;
		my @tri;
		for (@_) {
			if (ref $_) {
				$_->{trigger} = $trigger;
				push @tri, $_;
			} else {
				$META{attribute}{$_} = {
					trigger => $trigger,
					index => $INDEX++,
					name => $_
				};
				push @tri, $META{attribute}{$_};
			}
		}
		return @tri;
	})->set_prototype('&@');

	$metapkg->add_named_sub('before', sub {
		my $function = shift;
		my @before;
		for (@_) {
			if (ref $_) {
				push @{ $_->{before} }, $function;
				push @before, $_;
			} else {
				my $item = $META{attribute}{$_} || $META{function}{$_} || { name => $_, before => [] };
				push @{$item->{before}}, $function;
				push @before, $item;
			}
		}
		return @before;
	})->set_prototype('&@');

	$metapkg->add_named_sub('around', sub {
		my $function = shift;
		my @around;
		for (@_) {
			if (ref $_) {
				push @{ $_->{around} }, $function;
				push @around, $_;
			} else {
				my $item = $META{attribute}{$_} || $META{function}{$_} || { name => $_, around => [] };
				push @{$item->{around}}, $function;
				push @around, $item;
			}
		}
		return @around;
	})->set_prototype('&@');

	$metapkg->add_named_sub('after', sub {
		my $function = shift;
		my @after;
		for (@_) {
			if (ref $_) {
				push @{ $_->{after} }, $function;
				push @after, $_;
			} else {
				my $item = $META{attribute}{$_} || $META{function}{$_} || { name => $_, after => [] };
				push @{$item->{after}}, $function;
				push @after, $item;
			}
		}
		return @after;
	})->set_prototype('&@');


	my $make_attribute = sub {
		my $type = shift;
		for (@_) {
			if (ref $_) {
				$_->{type} = $type;
				$metapkg->add_named_sub($_->{name}, attribute($_));
			} else {
				$META{attribute}{$_} = { name => $_, type => $type, index => $INDEX++ };
				$metapkg->add_named_sub($_, attribute($META{attribute}{$_})); 
			}
		}
	};

	$metapkg->add_named_sub('any', sub {
		$make_attribute->(Any, @_);
	})->set_prototype('@');

	$metapkg->add_named_sub('bool', sub {
		$make_attribute->(Bool, @_);
	})->set_prototype('@');

	$metapkg->add_named_sub('str', sub {
		$make_attribute->(Str, @_);
	})->set_prototype('@');

	$metapkg->add_named_sub('num', sub {
		$make_attribute->(Num, @_);
	})->set_prototype('@');

	$metapkg->add_named_sub('array', sub {
		$make_attribute->(ArrayRef, @_);
	})->set_prototype('@');

	$metapkg->add_named_sub('hash', sub {
		$make_attribute->(HashRef, @_);
	})->set_prototype('@');

	$metapkg->add_named_sub('obj', sub {
		$make_attribute->(Object, @_);
	})->set_prototype('@');

	$metapkg->add_named_sub('function', sub {
		my $function = shift;
		for (@_) {
			if (ref $_) {
				$_->{function} = $function;
				$metapkg->add_named_sub($_->{name}, function($_));
			} else {
				$META{function}{$_} = { name => $_, function => $function };
				$metapkg->add_named_sub($_, function($META{function}{$_}));
			}
		}
	})->set_prototype('&@');


	$metapkg->add_named_sub('extends', sub {
		for (@_) {
			eval { use_module($_); };
			my $extend;
			{
				no warnings;
				$extend = meta::get_package( $_ );
			}
			my %local = $extend->get_symbol('%META')->value;
			my $isa = '@' . $caller . '::ISA';
        		eval "push $isa, '$_'";
			for (sort { $local{attribute}{$a}{index} <=> $local{attribute}{$b}{index} }  keys %{$local{attribute}}) {
				if (!$META{attribute}{$_}) {
					$META{attribute}{$_} = {%{$local{attribute}{$_}}};
					$META{attribute}{$_}{index} = $INDEX++;
				}
			}
			for ( keys %{ $local{function} } ) {
				if (!$META{function}{$_}) {
					$META{function}{$_} = {%{$local{function}{$_}}};
				}
			}
		}
	})->set_prototype('@');

	$metapkg->add_named_sub('new', sub {
		my $self = bless {}, shift;
		my %params = scalar @_ == 1 ? %{$_[0]} : @_;
		my @sorted_keys = sort { $META{attribute}{$a}{index} <=> $META{attribute}{$b}{index} } keys %{$META{attribute}};
		$self->$_($META{attribute}{$_}{default}->($self)) for grep { $META{attribute}{$_}{default} } @sorted_keys;
		$self->$_($params{$_}) for keys %params;
		$self->$_ for grep { $META{attribute}{$_}{required} } @sorted_keys;
		return $self;
	});
}

sub attribute {
	my ($attr) = @_;
	return sub {
		$attr = scoped($_[0], 'attribute', $attr);
		if (scalar @_ > 1) {
			before($attr, @_) if ($attr->{before});
			if ( $attr->{is} && $attr->{is} eq 'ro' && scalar caller() ne 'Quaint' ) {
				die "attribute $attr->{name} is readonly";
			}
			my $val = $attr->{trigger} ? $attr->{trigger}->($_[0], $_[1]) : $_[1];
			($val) = around($attr, $_[0], $val) if ($attr->{around});
			$_[0]->{$attr->{name}} = $attr->{type} ? $attr->{type}->($val) : $val;
			after($attr, $_[0], $_[0]->{$attr->{name}}) if ($attr->{after});
		}
		if ($attr->{required} && ! defined $_[0]->{$attr->{name}}) {
			die "attribute $attr->{name} is required";
		}
		return $_[0]->{$attr->{name}}
	}
}

sub function {
	my ($attr) = @_;
	return sub {
		my ($self, @params) = @_;
		$attr = scoped($self, 'function', $attr);
		before($attr, $self, @params) if ($attr->{before});
		@params = around($attr, $self, @params) if ($attr->{around});
		@params = $attr->{function}->($self, @params);
		after($attr, $self, @params) if ($attr->{after});
		return wantarray ? @params : $params[0];
	};
}

sub scoped {
	my ($self, $type, $attr) = @_;
	my $extend;
	{
		no warnings;
		$extend = meta::get_package( ref $self );
	}
	my %local = $extend->get_symbol('%META')->value;
	return $local{$type}{$attr->{name}};
}

sub before {
	my ($attr, @params) = @_;
	for (@{$attr->{before}}) {
		$_->(@params);
	}
}

sub around {
	my ($attr, $self, @val) = @_;
	for (@{$attr->{around}}) {
		@val = $_->($self, @val);
	}
	return @val;
}

sub after {
	my ($attr, @params) = @_;
	for (@{$attr->{after}}) {
		$_->(@params);
	}
}


1;

__END__

=head1 NAME

Quaint - Unusual Object Orientation 

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

	package Point;

	use Quaint;

	num req default {
		0
	} qw/x y/;

	function {
		$_[0]->x($_[1]);
		$_[0]->y($_[2]);
	} "move";

	1;
	
	...

	package Point::Extend;

	use Quaint;

	extends 'Point';

	function {
		return sprintf "A point at (%s, %s)\n", $_[0]->x, $_[0]->y;
	} qw/describe stringify/;

	before {
		warn 'Before';
	} around {
		warn 'Around';
		return ($_[1], $_[2]);
	} after {
		warn 'After';
	} qw/move/;

	1;


=head1 Attributes
	
	str ro req default {
		"STRING"
	} trigger {
		$_[1] . '_' . time;
	} "uid";

=cut

=head2 Types

	any qw/one two three/;

=cut

=head3 any

=cut

=head3 bool

=cut

=head3 str

=cut

=head3 num

=cut

=head3 array

=cut

=head3 hash

=cut

=head3 obj

=cut

=head2 Read Only

Make the attribute read only.

	any ro qw/one two three/;

=cut

=head2 Required

Make the attribute required.

	any req qw/one two three/;

=cut

=head2 Default

Set a default for the attribute.

	hash default {
		{
			one => 1,
			two => 2,
			three => 3
		}
	} "four"

=cut

=head2 Trigger

Set a trigger for the attribute.

	array trigger {
		push @{$_[1]}, 'extending passed array';
		return $_[1];
	} 'five';

=head1 Functions

	function {
		"";
	} 'six';

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-quaint at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Quaint>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Quaint

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Quaint>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Quaint>

=item * Search CPAN

L<https://metacpan.org/release/Quaint>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Quaint
