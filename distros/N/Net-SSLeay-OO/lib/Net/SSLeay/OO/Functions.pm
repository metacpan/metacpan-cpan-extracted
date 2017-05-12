
package Net::SSLeay::OO::Functions;

use Net::SSLeay;

my %prefixes = (
	""       => "Net::SSLeay::OO::SSL",
	BIO      => "Net::SSLeay::OO::BIO",
	CIPHER   => "Net::SSLeay::OO::Cipher",
	COMP     => "Net::SSLeay::OO::Compression",
	CTX      => "Net::SSLeay::OO::Context",
	DH       => "Net::SSLeay::OO::KeyType::DH",
	ENGINE   => "Net::SSLeay::OO::Engine",
	ERR      => "Net::SSLeay::OO::Error",
	EVP_PKEY => "Net::SSLeay::OO::PrivateKey",

	#MD2 => undef,
	#MD4 => undef,
	#MD5 => undef,
	PEM => "Net::SSLeay::OO::PEM",

	#P_ASN1_UTCTIME => undef,
	RAND    => "Net::SSLeay::OO::PRNG",
	RSA     => "Net::SSLeay::OO::KeyType::RSA",
	SESSION => "Net::SSLeay::OO::Session",

	#X509V3_EXT => undef,
	X509_NAME      => "Net::SSLeay::OO::X509::Name",
	X509_STORE     => "Net::SSLeay::OO::X509::Store",
	X509_STORE_CTX => "Net::SSLeay::OO::X509::Context",
	X509           => "Net::SSLeay::OO::X509",
);

my %ready;

while ( my ( $sym, $glob ) = each %Net::SSLeay:: ) {
	my $display = $sym =~ /ERRZX/;
	print STDERR "Considering $sym: " if $display;
	my ( $sub_pkg, $method ) =
		$sym =~ m{^(?:([A-Z][A-Z0-9]*(?:_[A-Z][A-Z0-9]*)*)_)?
			  ([a-z]\w+)$}x;
	if ( !$method ) {
		print STDERR "didn't match pattern, next\n" if $display;
		next;
	}
	use Data::Dumper;
	if ( !*{"Net::SSLeay::$sym"}{CODE} ) {
		print STDERR "not a func, next\n" if $display;
		next;
	}
	if ( $method eq "new" ) {
		print STDERR "it's 'new', next\n" if $display;
		next;
	}
	my $pkg = $prefixes{ $sub_pkg || "" };
	if ( !$pkg ) {
		print STDERR "destination package undefined; next\n"
			if $display;
		next;
	}
	print STDERR " => belongs in $pkg as $method\n" if $display;
	if ( *{$glob}{CODE} ) {
		$ready{$pkg}{$method} = \&{*$glob};
	}
	else {
		$ready{$pkg}{$method} = sub {
			goto \&{"Net::SSLeay::$sym"};
		};
	}
}

sub import {
	my $pkg     = shift;
	my $caller  = caller;
	my $install = shift || sub {shift};
	my %opts = @_;
	my %exclude;
	if ( my $aref = $opts{-exclude} ) {
		die "usage: -exclude => [qw( func1 func2 )]"
			unless ref $aref eq "ARRAY";
		%exclude = map { $_ => 1 } @$aref;
	}
	my %include;
	if ( my $href = $opts{-include} ) {
		die "usage: -include => { foo_func => 'methname' }"
			unless ref $href eq "HASH";
		%include = %$href;
	}
	if ( !ref $install ) {
		my $att = $install;
		$install = sub {
			my $code   = shift;
			my $method = shift;
			sub {
				my $self = shift;
				my @rv;
				my $pointer = $self->$att
					or die "no pointer in $self; this"
					. " object may be being used outside of its valid lifetime";
				if (wantarray) {
					@rv = $code->( $pointer, @_ );
				}
				else {
					$rv[0] = $code->( $pointer, @_ );
				}
				&Net::SSLeay::OO::Error::die_if_ssl_error(
					$method);
				wantarray ? @rv : $rv[0];
			};
		};
	}
	if ( my $table = delete $ready{$caller} ) {
		while ( my ( $method, $code ) = each %$table ) {
			next if $exclude{$method};
			my $fullname = $caller . "::" . $method;
			next if defined &{$fullname};
			*{$fullname} = $install->( $code, $method );
		}
		while ( my ( $source, $dest ) = each %include ) {
			my $fullname = $caller . "::" . $dest;
			my $code = Net::SSLeay->can($source);
			next unless $code;
			*{$fullname} = $install->( $code, $dest );
		}
	}
}

1;

__END__

=head1 NAME

Net::SSLeay::OO::Functions - convert Net::SSLeay functions to methods

=head1 SYNOPSIS

 use Net::SSLeay::OO::Functions 'foo';

 # means, roughly:
 use Net::SSLeay::OO::Functions sub {
         my $code = shift;
         sub {
             my $self = shift;
             $code->($self->foo, @_);
         }
     };

=head1 DESCRIPTION

This internal utility module distributes Net::SSLeay functions into
the calling package.  Its import method takes a callback which should
return a callback to be assigned into the symbol table; not providing
that will mean that the Net::SSLeay function is directly assigned into
the symbol table of the calling namespace.

If a function is passed instead of a closure, it is taken to be the
name of an attribute which refers to where the Net::SSLeay magic
pointer is kept.

The difference between the version of the installed handler function
and the actual installed function is that the real one checks for
OpenSSL errors which were raised while the function was called.

After the first argument, options may be passed:

=over

=item B<-exclude => [qw(func1 func2)]>

Specify NOT to include some functions that otherwise would be; perhaps
they won't work, perhaps they are badly named for their argument types.

=item B<-include => { func_name => 'method_name'}>

Import the L<Net::SSLeay> function called C<func_name>, as the local
method C<method_name>.  This is mostly useful for functions which were
missing their prefix indicating the argument types.

=back

=head1 AUTHOR

Sam Vilain, L<samv@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2009  NZ Registry Services

This program is free software: you can redistribute it and/or modify
it under the terms of the Artistic License 2.0 or later.  You should
have received a copy of the Artistic License the file COPYING.txt.  If
not, see <http://www.perlfoundation.org/artistic_license_2_0>

=head1 SEE ALSO

L<Net::SSLeay::OO>

=cut

# Local Variables:
# mode:cperl
# indent-tabs-mode: t
# cperl-continued-statement-offset: 8
# cperl-brace-offset: 0
# cperl-close-paren-offset: 0
# cperl-continued-brace-offset: 0
# cperl-continued-statement-offset: 8
# cperl-extra-newline-before-brace: nil
# cperl-indent-level: 8
# cperl-indent-parens-as-block: t
# cperl-indent-wrt-brace: nil
# cperl-label-offset: -8
# cperl-merge-trailing-else: t
# End:
# vim: filetype=perl:noexpandtab:ts=3:sw=3
