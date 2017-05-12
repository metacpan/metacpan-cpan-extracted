package Parse::Token::Lite::Builder;

use Parse::Token::Lite;
use Carp;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(ruleset on name with match start end);

our $VERSION = '0.200'; # VERSION
# ABSTRACT: DSL for Parse::Token::Lite

*_on = sub{ croak 'on'; };
*_name = sub{ croak 'name'; };
*_with = sub{ croak 'with'; };
*_match = sub{ croak 'match'; };
*_start = sub{ croak 'start'; };
*_end = sub{ croak 'end'; };

sub on($&){ goto &_on };
sub name($){ goto &_name };
sub with(&){ goto &_with };
sub match($&){ goto &_match };
sub start($){ goto &_start };
sub end($){ goto &_end };

sub ruleset(&){
	my $rules = {};
	my $code = shift;

	local *_match = sub($&){
		my ($pat, $code) = @_;
		my $_rule = {re=>$pat, state=>[] };
		
		local *_name = sub($){ $_rule->{name} = $_[0]; };
		local *_with = sub(&){ $_rule->{func} = $_[0]; };
		local *_start = sub($){ push(@{$_rule->{state}}, '+'.$_[0]); }; 
		local *_end  = sub($){ push(@{$_rule->{state}}, '-'.$_[0]); }; 

		$code->();
		push(@{$rules->{MAIN}},$_rule);
	};

	local *_on = sub($&){
		my ($state, $code) = @_;

		local *_match = sub($&){
			my ($pat, $code) = @_;
			my $_rule = {re=>$pat, state=>[] };
			
			local *_name = sub($){ $_rule->{name} = $_[0]; };
			local *_with = sub(&){ $_rule->{func} = $_[0]; };
			local *_start = sub($){ push(@{$_rule->{state}}, '+'.$_[0]); }; 
			local *_end  = sub($){ push(@{$_rule->{state}}, '-'.$_[0]); }; 

			$code->();
			push(@{$rules->{$state}},$_rule);
		};

		$code->();
	};

	$code->();

	return $rules;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::Token::Lite::Builder - DSL for Parse::Token::Lite

=head1 VERSION

version 0.200

=head1 SYNOPSIS

	use Parse::Token::Lite;
	use Parse::Token::Lite::Builder;
	use Data::Printer;
	use Data::Dumper;

	my $ruleset = ruleset{
		match qr/123/ => sub{
			name 'BEGIN';
			start 'TEST';
		};

		on 'TEST' => sub{
			match qr/567/ => sub{
				name 'END';
				end 'TEST';
			};

			match qr/./ => sub{
				name 'NUM';
			};
		};
	};

=head1 AUTHOR

khs <sng2nara@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by khs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
