package Object::Stash::Util;

use 5.010;
use strict;
use utf8;

our @EXPORT_OK;
BEGIN {
	$Object::Stash::AUTHORITY = 'cpan:TOBYINK';
	$Object::Stash::VERSION   = '0.006';
	
	@EXPORT_OK = qw/
		has_stash make_method make_stash
		/;
	
	require Object::Role;
	require Object::Stash;
}

use Carp qw/croak/;

use base qw/Exporter Object::Role/;

our $caller_level = 0;

sub make_method
{
	my $stash   = shift;
	my $method  = shift;
	my $options = { @_ };
	my $package;

	if ($stash =~ m{^(.+)::([^:]+)$})
	{
		$package = $1;
		$stash   = $2;
	}
	else
	{
		$package = caller($caller_level);
	}
	
	my $stash_coderef = do {
		no strict 'refs';
		\&{ "$package\::$stash" };
		};

	my $slot    = $options->{'slot'} // $method;
	my $default = sub { undef };
	if (exists $options->{'default'})
	{
		$default = (ref $options->{'default'} eq 'CODE') ?
			$options->{'default'} :
			sub { $options->{'default'} } ;
	}
	
	my $coderef =
		($options->{'is'} eq 'ro') ?
		sub
		{
			my $self = shift;
			my $hash = $self->$stash_coderef;
			$hash->{$slot} = $default->($self) unless exists $hash->{$slot};
			$hash->{$slot};
		} :
		sub :lvalue
		{
			my $self = shift;
			my $hash = $self->$stash_coderef;
			$hash->{$slot} = shift if @_;
			$hash->{$slot} = $default->($self) unless exists $hash->{$slot};
			$hash->{$slot};
		} ;
	
	__PACKAGE__ -> install_method(
		$method => $coderef,
		do { my $caller = caller($caller_level) },
		);
}

sub make_stash
{
	my ($stash, @args) = @_;
	my $package;

	if ($stash =~ m{^(.+)::([^:]+)$})
	{
		$package = $1;
		$stash   = $2;
	}
	else
	{
		$package = caller($caller_level);
	}
	
	no strict 'refs';
	Object::Stash->import(-method => [$stash], -package => $package, @args)
		unless Object::Stash::is_stash(\&{"$package\::$stash"});
}

sub has_stash
{
	my ($stash_name, %args) = @_;
	my $old_caller_level;
	local $caller_level = $old_caller_level + 1;
	
	make_stash($stash_name, -type => ($args{isa} // 'object'));
	
	if (ref $args{handles} eq 'ARRAY')
	{
		my @handles = @{ $args{handles} };
		while (@handles)
		{
			my $method = shift @handles;
			my $opts   = (ref $handles[0] eq 'HASH') ?  shift(@handles) : {};
			make_method($stash_name, $method, %$opts);
		}
	}
	elsif (ref $args{handles} eq 'HASH')
	{
		my %handles = %{ $args{handles} };
		while (my ($method, $opts) = each %handles)
		{
			make_method($stash_name, $method, %$opts);
		}
	}
	elsif (!ref $args{handles})
	{
		make_method($stash_name, $args{handles});
	}
	
	return;
}

__PACKAGE__
__END__

=head1 NAME

Object::Stash - provides a Catalyst-like "stash" method for your class

=head1 SYNOPSIS

 {
   package MyPerson;
   use Object::New;
   use Object::Stash::Util 'has_stash';
   
   has_stash personal_data => (
     isa     => 'Object',
     handles => {
       name    => { is => 'ro' },
       age     => { is => 'rw' },
       mbox    => { is => 'rw', default => sub { ... } },
       },
     );
 }
 
 my $bob = MyPerson->new;
 $bob->personal_data(name => 'Bob', age => 21, likes => 'fish');
 $bob->age++;
 printf("%s is aged %d", $bob->name, $bob->age);

=head1 DESCRIPTION

=head2 C<< has_stash >>

This module exists to provide a function C<has_stash> which is similar
in spirit to the C<has> function provided by L<Moose> (and Moose-like
modules), however the attribute it creates:

=over

=item * is always read-only

=item * is always a hashref (or a special blessed hashref)

=item * is not initialised by the constructor

=back

Like Moose's C<has> it takes a list of options, but only two options are
currently supported:

=over

=item * B<isa> - "HashRef" or "Object"

=item * B<handles> - can be a hashref like:

 handles => {
   'foo'  => {},
   'bar'  => { is => 'ro' },
   'baz'  => {},
   }

or an arrayref like:

 handles => [
   'foo',
   'bar'  => { is => 'ro' },
   'baz',
   ]

or if you only want to handle one method, can just be a string:

 handles => 'foo'

=back

The "handles" stuff allows you to delegate certain methods from your
class to the stash. Thus, given the package in the SYNOPSIS section above,
the C<MyPerson> class has methods C<name>, C<age> and C<mbox> defined,
which store their data inside the C<personal_data> stash.

Each delegated method has its own set of method options (like the
C<< is => 'ro' >> stuff above). The following method options are currently
supported:

=over

=item * B<is> - "ro" (read only) or "rw" (read-write)

Note that the method being read-only doen't prevent the data being
modified in other ways (not using the installed method).

=item * B<default> - value to use as the default value for the
method (if the setter has not yet been called). If you provide
a coderef here, then it will be executed and expected to return
the default value. The default is set lazily.

=item * B<slot> - hash key to use when storing data in the stash.
Defaults to the method name.

=back

Future versions may add other Moose-inspired options here, such as C<isa>.

=head2 Lower-Level functions

=over

=item C<< make_stash($stash_name, %opts) >>

=item C<< make_method($stash_name, $method_name, %opts) >>

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Object-Stash>.

=head1 SEE ALSO

L<Object::Stash>.

L<Mo>, L<Moo>, L<Mouse>, L<Moose>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

