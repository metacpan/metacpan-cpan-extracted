package Perl::Unsafe::Signals;

use strict;
use XSLoader ();

our $VERSION = '0.03';

XSLoader::load 'Perl::Unsafe::Signals', $VERSION;

sub import {
    no strict 'refs';
    *{caller() . '::UNSAFE_SIGNALS'} = *UNSAFE_SIGNALS;
}

sub UNSAFE_SIGNALS (&) {
    my $code = shift;
    my $restore = Perl::Unsafe::Signals::Restore->new;
    $code->();
}

{
    package # helper class, hide from PAUSE indexer
	Perl::Unsafe::Signals::Restore;
    sub new {
	my($class) = @_;
	my $oldflags = Perl::Unsafe::Signals::push_unsafe_flag();
	bless \$oldflags, $class;
    }
    sub DESTROY {
	my $self = shift;
	my $oldflags = $$self;
	Perl::Unsafe::Signals::pop_unsafe_flag($oldflags);
    }
}

1;

__END__

=head1 NAME

Perl::Unsafe::Signals - Allow unsafe handling of signals in selected blocks

=head1 SYNOPSIS

    use Perl::Unsafe::Signals;

    # ... some code ...
    local $SIG{ALRM} = sub { ... };
    alarm(60);
    UNSAFE_SIGNALS {
	# we want to interrupt this after one minute
	call_some_long_XS_function();
    };
    alarm(0);
    # ... continue ...

=head1 DESCRIPTION

Quoting L<perl581delta>:

I<In Perl 5.8.0 the so-called "safe signals" were introduced.  This
means that Perl no longer handles signals immediately but instead
"between opcodes", when it is safe to do so.  The earlier immediate
handling easily could corrupt the internal state of Perl, resulting
in mysterious crashes.>

It's possible since perl 5.8.1 to globally disable this feature by using
the C<PERL_SIGNALS> environment variables (as specified in
L<perlrun/PERL_SIGNALS>); but there's no way to disable it locally, for a
short period of time. That's however something you might want to do,
if, for example, your Perl program calls a C routine that will potentially
run for a long time and for which you want to set a timeout.

This module therefore allows you to define C<UNSAFE_SIGNALS> blocks
in which signals will be handled "unsafely".

Note that, no matter how short you make the unsafe block, it will still
be unsafe. Use with caution.

=head1 NOTES

This module used to be a source filter, but is no longer, thanks to Scott
McWhirter.

=head1 AUTHOR

Copyright (c) 2005, 2015 Rafael Garcia-Suarez. This program is free software; you
may redistribute it and/or modify it under the same terms as Perl itself.

A git repository for the sources is at L<https://github.com/rgs/Perl-Unsafe-Signals>.

=head1 SEE ALSO

L<perlrun>, L<perl581delta>

=cut
