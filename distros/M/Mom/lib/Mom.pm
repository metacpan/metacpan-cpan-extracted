use 5.008008;
use strict;
use warnings;

package Mom;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.006';

use parent qw( MooX::Press );
use Carp qw();
use Import::Into;
use Regexp::Common;

my $token_re = qr{(?:
	(?: [^0-9\W]\w* )
	| \: (?: isa|enum|does|type|handles|with|extends|default|requires|builder|trigger|clearer ) $RE{balanced}
	| \: (?: role|ro|rwp|rw|bare|private|lazy|required|clearer|builder|trigger|std|common|path|req )
	| \!
)}x;

sub import {
	my $me     = shift;
	my $caller = caller;
	my $import = join q( ), @_;
	
	my $attr;
	my %opts = ( factory => undef );
	my $kind = 'class';
	my %import_types;
	
	$import =~ s/\s+//;
	while ( $import =~ /^($token_re)/ ) {
		
		my $token = $1;
		$import = substr($import, length($token));
		$import =~ s/\s+//;
		
		if ( $token =~ /^:(role)$/ ) {
			$kind = 'role';
		}
		if ( $token =~ /^:(common|std|path)$/ ) {
			$import_types{$1} = 1;
		}
		elsif ( $token =~ /^:(extends|with).(.+).$/ ) {
			$opts{$1} = [ split /\s*,\s*/, $2 ];
		}
		elsif ( $token =~ /^:(rw|ro|rwp|bare|private)$/ ) {
			$opts{has}{$attr}{is} = $1;
		}
		elsif ( $token =~ /^:(lazy)$/ ) {
			$opts{has}{$attr}{$1} = 1;
		}
		elsif ( $token =~ /^:(required|req|clearer|trigger|builder)$/ ) {
			my $o = $1;
			$o = 'required' if $o eq 'req';
			$opts{has}{$attr}{$1} = 1;
		}
		elsif ( $token =~ /^:(enum|handles).(.+).$/ ) {
			my ( $o, $v ) = ( $1, $2 );
			push @{ $opts{has}{$attr}{$o} ||= [] }, split /\s*,\s*/, $v;
			if ( $o eq 'handles' and $v =~ /^[12]$/ ) {
				$opts{has}{$attr}{$o} = $v;
			}
		}
		elsif ( $token =~ /^:(isa|does|type|default|builder|trigger|clearer).(.+).$/ ) {
			$opts{has}{$attr}{$1} = $2;
		}
		elsif ( $token =~ /^:(requires).(.+).$/ ) {
			push @{ $opts{requires} ||= [] }, split /\s*,\s*/, $2;
		}
		elsif ( $token eq '!' ) {
			$opts{has}{$attr}{required} = 1;
		}
		else {
			$opts{has}{$attr = $token} = {};
		}
	}
	
	if ( $import ) {
		Carp::croak("Unrecognized syntax: $import");
	}
	
	my @super_args = (
		factory_package => $me,
		type_library    => "$me\::Types",
		prefix          => undef,
		$kind           => [ $caller => \%opts ],
	);
	$me->SUPER::import( @super_args );
	
	($kind eq 'role' ? 'Moo::Role' : 'Moo')->_install_subs($caller);
	'Scalar::Util'->import::into($caller, qw(blessed));
	'Carp'->import::into($caller, qw(croak confess carp));
	
	if ($import_types{std}) {
		require Types::Standard;
		'Types::Standard'->import::into($caller, qw(-types -is -assert));
	}
	
	if ($import_types{common}) {
		require Types::Common::Numeric;
		'Types::Common::Numeric'->import::into($caller, qw(-types -is -assert));
		require Types::Common::String;
		'Types::Common::String'->import::into($caller, qw(-types -is -assert));
	}
	
	if ($import_types{path}) {
		require Types::Path::Tiny;
		'Types::Path::Tiny'->import::into($caller, qw(-types -is -assert));
		require Path::Tiny;
		'Path::Tiny'->import::into($caller);
	}
	
	'namespace::autoclean'->import::into($caller);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Mom - Moo objects minimally

=head1 SYNOPSIS

This:

  use Mom;

Is (roughly) a shortcut for:

  use Moo;
  use Scalar::Util qw( blessed );
  use Carp qw( carp croak confess );
  use namespace::autoclean;

But Mom takes care of a lot more. This:

  use Mom q{ foo bar:rw:type(Int) baz! };

Is (roughly) a shortcut for:

  use Moo;
  use Scalar::Util qw( blessed );
  use Carp qw( carp croak confess );
  use Types::Standard qw();
  use namespace::autoclean;
  
  has foo => ( is => "ro" );
  has bar => ( is => "rw", isa => Types::Standard::Int );
  has baz => ( is => "ro", required => 1 );

Tokens which don't start with a colon are created as attributes in
your package. Tokens starting with a colon are flags that affect either
the preceeding attribute or the package as a whole.

=head1 DESCRIPTION

This documentation assumes familiarity with L<Moo>.

=head2 Motivation

The documentation for L<MooX::ShortHas> says instead of this:

  use Moo;
  
  has hro => is => ro => required => 1;
  has hlazy => is => lazy => builder => sub { 2 };
  has hrwp => is => rwp => required => 1;
  has hrw => is => rw => required => 1;

You can now write this:

  use Moo;
  use MooX::ShortHas;
  
  ro "hro";
  lazy hlazy => sub { 2 };
  rwp "hrwp";
  rw "hrw";

I thought I could go even shorter.

  use Mom q{ hro! hlazy:lazy:default(2) hrwp!:rwp hrw!:rw };

=head1 IMPORT

All of Mom's magic happens in the import statement.

=head2 Flags Affecting Attributes

=over

=item C<< :rw >>

Like C<< is => "rw" >> in Moo.

=item C<< :ro >>

Like C<< is => "ro" >> in Moo, though this is already the default.

=item C<< :rwp >>

Like C<< is => "rwp" >> in Moo

=item C<< :bare >>

Like C<< is => "bare" >> in Moo

=item C<< :lazy >>

Like C<< lazy => 1 >> in Moo.

=item C<< :required >> or C<< :req >> or C<< ! >>

Like C<< required => 1 >> in Moo.

=item C<< :clearer >>

Like C<< clearer => 1 >> in Moo.

=item C<< :clearer(methodname) >>

Like C<< clearer => "methodname" >> in Moo.

=item C<< :builder >>

Like C<< builder => 1 >> in Moo.

=item C<< :builder(methodname) >>

Like C<< builder => "methodname" >> in Moo.

=item C<< :trigger >>

Like C<< trigger => 1 >> in Moo.

=item C<< :trigger(methodname) >>

Like C<< trigger => "methodname" >> in Moo.

=item C<< :isa(Class::Name) >>

Like C<< isa => InstanceOf[Class::Name] >> in Moo/Types::Standard.

=item C<< :does(Role::Name) >>

Like C<< isa => ConsumerOf[Role::Name] >> in Moo/Types::Standard.

=item C<< :type(TypeName) >>

Like C<< isa => TypeName >> in Moo/Types::Standard.

=item C<< :enum(list,of,strings) >>

Like C<< isa => Enum["list","of","strings"] >> in Moo/Types::Standard.

=item C<< :default(value) >>

Like C<< default => "value" >> in Moo.

For simple (string/numeric) defaults. Doesn't accept coderefs.

=item C<< :handles(list,of,methods) >>

Like C<< handles => ["list","of","methods"] >> in Moo.

Currently no support for a hashref of delegations.

=item C<< :handles(1) >> or C<< :handles(2) >>

Like L<MooX::Enumeration>.

=back

=head2 Flags Affecting Package

=over

=item C<< :role >>

Creates a Moo::Role instead of a Moo class.

=item C<< :extends(Class::Name) >>

Like C<< extends "Class::Name" >> in Moo.

=item C<< :with(Role::Name) >>

Like C<< with "Role::Name" >> in Moo.

=item C<< :requires(list,of,methods) >>

Like C<< requires ("list", "of", "methods"); >> in Moo::Role.

=item C<< :std >>

Like C<< use Types::Standard qw( -types -is -assert ) >>

=item C<< :common >>

Like:

  use Types::Common::Numeric qw( -types -is -assert );
  use Types::Common::String qw( -types -is -assert );

=item C<< :path >>

Like:

  use Types::Path::Tiny qw( -types -is -assert );
  use Path::Tiny qw( path );

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Mom>.

=head1 SEE ALSO

L<Moo>, L<Types::Standard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020, 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

