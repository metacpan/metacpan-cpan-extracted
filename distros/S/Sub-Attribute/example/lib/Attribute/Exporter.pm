package Attribute::Exporter;

use warnings;
use strict;

use Sub::Attribute;
use parent qw(Exporter);

sub _attr_exporter_register{
	my($class, $type, $sym, $tags) = @_;
	unless($sym){
		require Carp;
		Carp::croak('Cannot export anonymous subroutine');
	}

	my $name = *{$sym}{NAME};

	my $export_tags = do{
		no strict 'refs';
		push @{$class . '::' . $type}, $name;

		\%{$class . '::EXPORT_TAGS'};
	};

	push @{$export_tags->{all} ||= []}, $name;

	if($tags){
		foreach my $tag(split q{ }, $tags){
			push @{$export_tags->{$tag}  ||= []}, $name;
		}
	}
	return;
}

sub Export :ATTR_SUB{
	my($class, $sym, undef, undef, $tags) = @_;
	$class->_attr_exporter_register(EXPORT => $sym, $tags);
}

sub Exportable :ATTR_SUB{
	my($class, $sym, undef, undef, $tags) = @_;
	$class->_attr_exporter_register(EXPORT_OK => $sym, $tags);
}

1;
__END__

=head1 NAME

Attribute::Exporter - Provides exporting attributes

=head1 SYNOPSIS

	package Foo;
	use parent qw(Attribute::Exporter);

	sub bar :Export(common){
		# ...
	}

	sub baz :Exportable(util){
		# ...
	}

	# and later
	package main;

	use Foo; # import bar()

	use Foo qw(:util); # import baz()

	use Foo qw(:all);  # import bad() and baz()

=cut
