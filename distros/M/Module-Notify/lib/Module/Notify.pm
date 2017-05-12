package Module::Notify;

use 5.008;
use strict;
use warnings;
no warnings qw( void once uninitialized numeric );

BEGIN {
	$Module::Notify::AUTHORITY = 'cpan:TOBYINK';
	$Module::Notify::VERSION   = '0.002';
}

use Carp qw(croak);
sub _refaddr { 0+$_[0] };

sub _module_notional_filename
{
	my $module = $_[0];
	$module =~ s{::}{/}g;
	return "$module\.pm";
}

sub _unmodule_notional_filename
{
	my $module = $_[0];
	$module =~ s{\.pmc?$}{};
	$module =~ s{/}{::}g;
	return $module;
}

sub _clean_err
{
	chomp(my $err = shift);
	$err =~ s/ at \(eval [0-9]+\) line [0-9]+\.?$//g;
	return "$err";
}

our %NOTIFICATIONS;

sub new
{
	my $class = shift;
	my ($module, $callback) = @_;
	
	# Make sure hook is installed
	my $H = $class->_inc_hook;
	@INC = ($H, grep $_ != $H, @INC) unless $INC[0]==$H;
	
	push @{$NOTIFICATIONS{$module} ||= []}, $callback;
	
	return $class->_run_notifications(module => $module)
		if $INC{_module_notional_filename($module)};
	
	bless [ $module, _refaddr($callback) ], $class;
}

sub cancel
{
	my $self = shift;
	my ($module, $refaddr) = @$self;
	$NOTIFICATIONS{$module} = [
		grep _refaddr($_)!=$refaddr, @{$NOTIFICATIONS{$module} || []}
	];
	return;
}

sub _run_notifications
{
	my $class = shift;
	my ($type, $module) = @_;
	$module = _unmodule_notional_filename($module) if $type eq "filename";
	
	while (my $code = shift @{$NOTIFICATIONS{$module} || []})
	{
		$code->($module);
	}
	
	return;
}

sub _has_notifications
{
	my $class = shift;
	my ($type, $module) = @_;
	$module = _unmodule_notional_filename($module) if $type eq "filename";
	
	!!@{$NOTIFICATIONS{$module} || []};
}

{
	my $hook;
	sub _inc_hook
	{
		my $class = shift;
		$hook ||= sub {
			my $self = shift;
			return unless $class->_has_notifications(filename => $_[0]);
			@INC = grep $_ != $self, @INC;
			my $r = eval "require '$_[0]'";
			unshift @INC, $self;
			$r ? $class->_run_notifications(filename => $_[0]) : croak(_clean_err $@);
			my @lines = ($r, undef);
			return sub { $_ = shift @lines; !!@lines };
		};
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Module::Notify - trigger a callback when a module is loaded

=head1 SYNOPSIS

   use Module::Notify;
   
   Module::Notify->new(Foo => sub { print "2\n" });
   
   # Count to three...
   print "1\n";
   require Foo;
   print "3\n";

=head1 DESCRIPTION

Module::Notify runs callback code when it detects that a particular module
has been loaded.

=head2 Constructor

=over

=item C<< new($module_name, $callback) >>

Runs the callback when the module is loaded.

Unlike most OO modules, you can freely use this in void context, and it
will work fine. However, if you keep the returned reference, you can call
methods on it:

   my $handle = Module::Notify->new($module, $callback);

If the module is I<already> loaded, runs the callback immediately, and
returns undef instead of an object.

=back

=head2 Object Methods

=over

=item C<< cancel >>

Cancels the callback.

=back

=head1 CAVEATS

Module::Notify works through an C<< @INC >> hook. It ought to be the first
item in C<< @INC >> and does its best to insert itself as C<< $INC[0] >>
at every opportunity it gets.

If any other path or hook does end up before Module::Notify's C<< @INC >>
hook, then any modules loaded via that path or hook will escape
Module::Notify's notice.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Module-Notify>.

=head1 SEE ALSO

L<Module::Runtime>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
