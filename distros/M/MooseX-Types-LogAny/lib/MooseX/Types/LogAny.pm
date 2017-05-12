package MooseX::Types::LogAny;
use 5.008;
use strict;
use warnings;

our $VERSION = '0.001003'; # VERSION

BEGIN {
	warnings::warnif('deprecated',
		'see Log::Any documentation for how to use with Moose');
}

use MooseX::Types -declare => [qw(
	LogAny
	LogAnyBase
	LogAnyNull
	LogAnyProxy
)];

class_type LogAnyBase,  { class => 'Log::Any::Adapter::Base' };
class_type LogAnyNull,  { class => 'Log::Any::Adapter::Null' };
class_type LogAnyProxy, { class => 'Log::Any::Proxy' };
subtype    LogAny, as LogAnyBase|LogAnyNull|LogAnyProxy;

1;

# ABSTRACT: DEPRECATED MooseX::Types for Log::Any

__END__

=pod

=head1 NAME

MooseX::Types::LogAny - DEPRECATED MooseX::Types for Log::Any

=head1 VERSION

version 0.001003

=head1 SYNOPSIS

	use Moose;
	use Class::Load 0.20 'load_class';
	use MooseX::Types::LogAny qw( LogAny );

	has log => (
		isa     => LogAny,
		is      => 'ro',
		lazy    => 1,
		default => sub { load_class('Log::Any')->get_logger },
	);

=head1 DESCRIPTION

This module is no longer recommended, the reason for its existence has been
resolved in recent versions of L<Log::Any> see it's documentation for how to
use L<Log::Any> with L<Moose>.

The motivation behind this modules is that L<Log::Any::Adapter::Null> does not
inherit from L<Log::Any::Adapter::Base> which all of the other adapters do.
Moose will not allow a type union of undefined types unless they are Moose
classes. This module allows you to simply use the L<LogAny> type which has
done the union for you.

=head1 SUBROUTINES

=head2 LogAny

Type union of L<LogAnyNull> and L<LogAnyBase>

=head2 LogAnyNull

Class L<Log::Any::Adapter::Null>

=head2 LogAnyBase

Class L<Log::Any::Adapter::Base>

=head2 LogAnyProxy

Class L<Log::Any::Proxy>

=head1 SEE ALSO

=over

=item L<MooseX::Types>

=item L<Log::Any>

=item L<Log::Any::Adapter>

=back

=head1 ACKNOWLEDGMENTS

Development sponsored by L<HostGator.com|http://hostgator.com>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/xenoterracide/moosex-types-logany/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
