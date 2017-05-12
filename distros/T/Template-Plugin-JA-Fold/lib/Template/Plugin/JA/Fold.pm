package Template::Plugin::JA::Fold;
use strict;
use warnings;
use utf8;
use 5.008001;
use base qw(Template::Plugin);
use Lingua::JA::Fold qw(fold);

our $VERSION = '0.03';

sub new {
	my ( $class, $context, @params ) = @_;
	$context->define_filter( 'fold' => $class->_filter_factory() );
	my $self = bless { _CONTEXT => $context, }, $class;
	return $self;
}

sub _filter_factory {
	my $class = shift;
	my $code  = sub {
		my ( $context, @args ) = @_;
		return sub {
			my $text = shift;
			fold( text => $text, length => $args[0], mode => $args[1] );
		};
	};
	return [ $code => 1 ];
}

1;
__END__

=head1 NAME

Template::Plugin::JA::Fold - Template plugin that interface to Lingua::JA::Fold

=head1 SYNOPSIS

  [% USE JA::Fold %]
  [% foo | fold(10,'full-width') | html | html_line_break %]

=head1 DESCRIPTION

Template::Plugin::JA::Fold is plugin that interface to Lingua::JA::Fold 
for Template-Toolkit

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 SEE ALSO

L<Template>
L<Template::Plugin>
L<Lingua::JA::Fold>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
