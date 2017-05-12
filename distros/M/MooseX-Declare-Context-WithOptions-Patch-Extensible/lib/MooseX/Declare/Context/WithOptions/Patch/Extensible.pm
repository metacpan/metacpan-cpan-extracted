package MooseX::Declare::Context::WithOptions::Patch::Extensible;

use 5.010;
use strict;
use warnings;
use utf8;

BEGIN {
	$MooseX::Declare::Context::WithOptions::Patch::Extensible::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::Declare::Context::WithOptions::Patch::Extensible::VERSION   = '0.002';
}

# I had hoped to do this with Module::Patch, but it seems that Module::Patch
# doesn't work especially well with Moose roles. Patching a sub in the role
# does not necessarily affect the classes that the role has been composed with.

use Carp;
use MooseX::Declare::Context::WithOptions 0.22;

sub import
{
	carp "MooseX::Declare::Context::WithOptions->VERSION gt '0.35'"
		if MooseX::Declare::Context::WithOptions->VERSION gt '0.35';
}

{
	package  # hide from CPAN indexer
	MooseX::Declare::Context::WithOptions;
	
	use Moose::Role;
	use Carp qw(croak);
	
	no warnings 'redefine';
	
	has allowed_option_names => (
		is       => 'rw',
		isa      => 'ArrayRef',
		lazy     => 1,
		default  => sub { [qw[ extends with is ]] },
	);
	
	sub strip_options {
		my ($self) = @_;
		my %ret;
		
		# Make errors get reported from right place in source file
		local $Carp::Internal{'MooseX::Declare'} = 1;
		local $Carp::Internal{'Devel::Declare'} = 1;
		
		$self->skipspace;
		my $linestr = $self->get_linestr;
		
		while (substr($linestr, $self->offset, 1) !~ /[{;]/) {
			my $key = $self->strip_name;
			if (!defined $key) {
				croak 'expected option name'
					if keys %ret;
				return; # This is the case when { class => 'foo' } happens
			}
			
			croak "unknown option name '$key'"
				unless grep { $key eq $_ } @{ $self->allowed_option_names }; ##DIFF
			
			my $val = $self->strip_name;
			if (!defined $val) {
				if (defined($val = $self->strip_proto)) {
					$val = [split /\s*,\s*/, $val];
				}
				else {
					 croak "expected option value after $key";
				}
			}
			
			$ret{$key} ||= [];
			push @{ $ret{$key} }, ref $val ? @{ $val } : $val;
		 } continue {
			$self->skipspace;
			$linestr = $self->get_linestr();
		 }
		
		my $options = { map {
			my $key = $_;
			$key eq 'is'
				? ($key => { map { ($_ => 1) } @{ $ret{$key} } })
				: ($key => $ret{$key})
		} keys %ret };
		
		$self->options($options);
		
		 return $options;
	}
}

1;

__END__

=head1 NAME

MooseX::Declare::Context::WithOptions::Patch::Extensible - patch MooseX::Declare for extensibility

=head1 SYNOPSIS

 use MooseX::Declare::Context::WithOptions::Patch::Extensible;

=head1 DESCRIPTION

This module extends MooseX::Declare::Context::WithOptions to add a new
attribute C<allowed_option_names> containing an arrayref of option names
that it can parse. The default is the standard MooseX::Declare list of
'extends', 'with' and 'is'.

It also patches the C<strip_options> method so that it pays attention to
that arrayref.

If you don't understand why you'd need to do this, then you probably don't
need to do this.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-Declare-Context-WithOptions-Patch-Extensible>.

=head1 SEE ALSO

C<MooseX::Declare>.

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

