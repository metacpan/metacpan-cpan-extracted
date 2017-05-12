package PerlIO::via::dynamic;
use strict;
our $VERSION = '0.14';

=head1 NAME

PerlIO::via::dynamic - dynamic PerlIO layers

=head1 SYNOPSIS

 open $fh, $fname;
 $p = PerlIO::via::dynamic->new
  (translate =>
    sub { $_[1] =~ s/\$Filename[:\w\s\-\.\/\\]*\$/\$Filename: $fname\$/e},
   untranslate =>
    sub { $_[1] =~ s/\$Filename[:\w\s\-\.\/\\]*\$/\$Filename\$/});
 $p->via ($fh);
 binmode $fh, $p->via; # deprecated

=head1 DESCRIPTION

C<PerlIO::via::dynamic> is used for creating dynamic L<PerlIO>
layers. It is useful when the behavior or the layer depends on
variables. You should not use this module as via layer directly (ie
:via(dynamic)).

Use the constructor to create new layers, with two arguments:
translate and untranslate. Then use C<$p->via ($fh)> to wrap the
handle.  Once <$fh> is destroyed, the temporary namespace for the IO
layer will be removed.

Note that PerlIO::via::dynamic uses the scalar fields to reference to
the object representing the dynamic namespace.

=head1 OPTIONS

=over

=item translate

A function that translate buffer upon I<write>.

=item untranslate

A function that translate buffer upon I<read>.

=item use_read

Use C<READ> instead of C<FILL> for the layer.  Useful when caller
expect exact amount of data from read, and the C<untranslate> function
might return different length.

By default C<PerlIO::via::dynamic> creates line-based layer to make
C<translate> implementation easier.

=back

=cut

use Symbol qw(delete_package gensym);
use Scalar::Util qw(weaken);
use IO::Handle;

sub PUSHED {
    die "this should not be via directly"
	if $_[0] eq __PACKAGE__;
    my $p = bless gensym(), $_[0];

    if ($] == 5.010000 && ref($_[-1]) eq 'GLOB') {
        # This is to workaround a core bug in perl 5.10.0, see
        # http://rt.perl.org/rt3/Public/Bug/Display.html?id=54934
        require Internals;
        Internals::SetRefCount($_[-1], Internals::GetRefCount($_[-1])+1);
    }
    no strict 'refs';
    # make sure the blessed glob is destroyed
    # earlier than the object representing the namespace.
    ${*$p} = ${"$_[0]::EGO"};

    return $p;
}

sub translate {
}

sub untranslate {
}

sub _FILL {
    my $line = readline( $_[1] );
    $_[0]->untranslate ($line) if defined $line;
    $line;
}

sub READ {
    my $ret = read $_[3], $_[1], $_[2];
    return $ret unless $ret > 0;
    $_[0]->untranslate ($_[1]);
    return length ($_[1]);
}

sub WRITE {
    my $buf = $_[1];
    $_[0]->translate($buf);
    $_[2]->autoflush (1);
    (print {$_[2]} $buf) ? length ($buf) : -1;
}

sub SEEK {
    seek ($_[3], $_[1], $_[2]);
}

sub new {
    my ($class, %arg) = @_;
    my $self = {};
    my $package = 'PerlIO::via::dynamic'.substr("$self", 7, -1);
    eval qq|
package $package;
our \@ISA = qw($class);

1;
| or die $@;

    no strict 'refs';
    for (qw/translate untranslate/) {
	*{"$package\::$_"} = delete $arg{$_}
	    if exists $arg{$_}
    }
    %$self = %arg;
    unless ($self->{use_read}) {
	*{"$package\::FILL"} = *PerlIO::via::dynamic::_FILL;
    }
    bless $self, $package;
    ${"$package\::EGO"} = $self;
    weaken ${"$package\::EGO"};
    return $self;
}

sub via {
    my ($self, $fh) = @_;
    my $via = ':via('.ref ($_[0]).')';
    unless ($fh) {
	# 0.01 compatibility
	$self->{nogc} = 1;
	return $via;
    }
    binmode ($fh, $via) or die $!;
    if (defined *$fh{SCALAR}) {
	if (defined *$fh{ARRAY}) {
	    warn "handle $fh cannot hold references, namespace won't be cleaned";
	    $self->{nogc} = 1;
	}
	else {
	    ${*$fh}[0] = $self;
	}
    }
    else {
	${*$fh} = $self;
    }
}

sub DESTROY {
    my ($self) = @_;
    return unless UNIVERSAL::isa ($self, 'HASH');
    return if $self->{nogc};

    no strict 'refs';
    my $ref = ref($self);
    my ($leaf) = ($ref =~ /([^:]+)$/);
    $leaf .= '::';

    for my $sym (keys %{$ref.'::'}) {
	undef ${$ref.'::'}{$sym}
	    if $sym;
    }

    delete $PerlIO::via::{$leaf};
}

=head1 AUTHORS

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 by Chia-liang Kao E<lt>clkao@clkao.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

1;
