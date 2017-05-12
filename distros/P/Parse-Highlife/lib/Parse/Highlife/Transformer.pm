package Parse::Highlife::Transformer;

use strict;
use Parse::Highlife::Utils qw(params);
use Data::Dump qw(dump);

sub new
{
	my( $class, @args ) = @_;
	my $self = bless {}, $class;
	return $self -> _init( @args );
}

sub _init
{
	my( $self, @args ) = @_;
	$self->{'transformers'} = {};
	$self->{'stringifiers'} = {};
	return $self;
}

sub transformer
{
	my( $self, $name, $coderef )
		= params( \@_, 
				-rule => '',
				-fn => sub {},
			);
	$self->{'transformers'}->{$name} = $coderef;
	return 1;
}

sub stringifier
{
	my( $self, $name, $coderef )
		= params( \@_, 
				-rule => '',
				-fn => sub {},
			);
	$self->{'stringifiers'}->{$name} = $coderef;
	return 1;
}

sub transform
{
	my( $self, $ast, @params ) = @_;
	
	my $transformer_name = $ast->{'rulename'};
	#print "-- TRANSFORM $transformer_name --\n";
	
	if( exists $self->{'transformers'}->{$transformer_name} ) {
		my $new_ast = $self->{'transformers'}->{$transformer_name}->( $self, $ast, @params );
		return ( defined $new_ast && ref $new_ast eq 'Parse::Highlife::AST' ? $new_ast : $ast );
	}
	else {
		return $self->transform_children( $ast, @params );
	}
}

sub transform_children
{
	my( $self, $ast, @params ) = @_;
	if( $ast->{'category'} eq 'group' ) {
		$ast->{'children'} = 
			[
				map { $self->transform( $_, @params ) } @{$ast->{'children'}}
			];
	}
	# leaf's are not transformed by default
	return $ast;
}

sub stringify
{
	my( $self, $ast, @params ) = @_;
	
	my $stringifier_name = $ast->{'rulename'};
	#print "-- STRINGIFY $stringifier_name --\n";
	
	if( exists $self->{'stringifiers'}->{$stringifier_name} ) {
		my $string = $self->{'stringifiers'}->{$stringifier_name}->( $self, $ast, @params );
		return ( defined $string && ! ref $string ? $string : '?' );
	}
	else {
		return $self->stringify_children( $ast, @params );
	}
}

sub stringify_children
{
	my( $self, $ast, @params ) = @_;
	if( $ast->{'category'} eq 'group' ) {
		return join '', map { $self->stringify( $_, @params ) } @{$ast->{'children'}};
	}
	# leaf's are not stringified by default
	return $ast->{'children'};
}

1;

