package Mock::Data::GeneratorSub;
use strict;
use warnings;
require Mock::Data::Generator;
our @ISA= qw( Mock::Data::Generator );

# ABSTRACT: Wrap a coderef to become a blessed Generator object
our $VERSION = '0.03'; # VERSION


sub new {
	my ($class, $coderef, @params)= @_;
	if (ref $coderef eq 'HASH') {
		@params= @{ $coderef->{params} || [] };
		$coderef= $coderef->{coderef};
	}
	if (ref $class) {
		$coderef ||= $class->{coderef};
		@params= $class->_merge_params(@params);
		$class= ref $class;
	}
	Scalar::Util::reftype($coderef) eq 'CODE' or Carp::croak("Not a coderef");
	bless {
		coderef => $coderef,
		params => \@params,
	}, $class;
}

sub _merge_params {
	my $self= shift;
	my $p= $self->{params};
	my $named_p= ref $p->[0] eq 'HASH'? $p->[0] : undef;
	# Merge any options-by-name newly supplied with options-by-name from @params
	unshift @_, (ref $_[0] eq 'HASH')? { %$named_p, %{shift @_} } : $named_p
		if $named_p;
	# Append positional params if none provided
	push @_, @{$p}[1..$#$p]
		unless @_ > 1;
	return @_;
}


sub generate {
	my ($self, $mock)= (shift, shift);
	$self->{coderef}->($mock, @_? $self->_merge_params(@_) : @{$self->{params}});
}


sub compile {
	my $self= shift;
	my $params= $self->{params};
	return $self->{coderef} unless @_ || @$params;
	my @new_params= $self->_merge_params(@_);
	my $coderef= $self->{coderef};
	return sub { $coderef->(shift, @new_params) };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mock::Data::GeneratorSub - Wrap a coderef to become a blessed Generator object

=head1 DESCRIPTION

This class wraps a generator coderef to become a L<Generator|Mock::Data::Generator> object,
and supply default parameters for L</generate> which can be overridden or combined with
additional parameters.

=head1 CONSTRUCTOR

=head2 new

  Mock::Data::GeneratorSub->new( $coderef, @default_params );

This object's C<generate> method calls the C<$coderef> after merging the parameters passed
to C<generate> with this list of C<@default_params>.  When merging parameters, named parameters
are replaced by-name, and positional parameters are replacing entirely if new positional
parameters are provided.

=head1 METHODS

=head2 generate

  $generator->generate($mock, @params);

Merge C<@params> with C<< $self->params >>  and then call C<< $self->coderef >>

=head2 compile

  $generator->compile(@params);

Return a function C<< sub($mock){ ... } >> which calls C<< $self->coderef >> with the
C<@params> merged with C<< $self->params >>.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 VERSION

version 0.03

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
