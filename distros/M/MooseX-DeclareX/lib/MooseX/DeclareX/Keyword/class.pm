package MooseX::DeclareX::Keyword::class;

BEGIN {
	$MooseX::DeclareX::Keyword::class::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::DeclareX::Keyword::class::VERSION   = '0.009';
}

require MooseX::Declare;

use Moose;
extends 'MooseX::Declare::Syntax::Keyword::Class';
with 'MooseX::DeclareX::Plugin';
with 'MooseX::DeclareX::Registry';

sub preferred_identifier { 'class' }

before add_namespace_customizations => sub {
	my ($self, $ctx, $pkg, $o) = @_;
	$_->setup_for($pkg, provided_by => ref $self)
		foreach @{ $self->default_inner };
};

1;
