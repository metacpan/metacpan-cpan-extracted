package MooX::HasEnv;
BEGIN {
  $MooX::HasEnv::AUTHORITY = 'cpan:GETTY';
}
{
  $MooX::HasEnv::VERSION = '0.004';
}
# ABSTRACT: Making attributes based on ENV variables

use strict;
use warnings;
use Package::Stash;

sub import {
	my ( $class ) = @_;
	my $caller = caller;

	eval qq{
		package $caller;
		use Moo;
	};

 	my $stash = Package::Stash->new($caller);

	$stash->add_symbol('&has_env', sub {
		my ( $name, $env_var, $default ) = @_;
		my $builder = '_build_'.$name;
		$stash->add_symbol('&'.$builder, sub {
			my ( $self ) = @_;
			my $env_value = defined $env_var && defined $ENV{$env_var} ? $ENV{$env_var} : undef;
			return defined $env_value ?
				$env_value :
				defined $default ?
					ref $default eq 'CODE' ?
						$default->($self) :
					$default :
				undef;
		});
		$caller->can("has")->($name,
			is => 'ro',
			lazy => 1,
			builder => $builder,
		);
	});
}

1;


__END__
=pod

=head1 NAME

MooX::HasEnv - Making attributes based on ENV variables

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  package MyApp::Config;

  use MooX::HasEnv; # also adds use Moo;

  has_env var => MYAPP_VARIABLE => '0';
  has_env var_name => 'MYAPP_VARIABLE_NAME'; # no default
  has_env foo => undef, '2';

  use Path::Class;

  has_env root => MYAPP_ROOT => file(__FILE__)->parent->parent->parent->absolute."";

=head1 DESCRIPTION

=encoding utf8

=head1 SUPPORT

IRC

  Join #web-simple on irc.perl.org. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-moox-hasenv
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-moox-hasenv/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

