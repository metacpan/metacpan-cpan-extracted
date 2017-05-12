package ShellQuote::Any;
use strict;
use warnings;

our $VERSION = '0.03';

sub import {
    my $caller = caller;

    no strict 'refs'; ## no critic
    *{"${caller}::shell_quote"} = \&shell_quote;
}

sub shell_quote {
    my ($cmd, $os) = @_;

    if ($os) {
        _require($os);
        return _is_win32($os) ? _win32_quote($cmd) : _bourne_quote($cmd);
    }
    else {
        _q()->($cmd);
    }
}

my $Q;
sub _q {
    return $Q if $Q;

    _require($^O);

    if ( _is_win32($^O) ) {
        $Q = \&_win32_quote;
    }
    else {
        $Q = \&_bourne_quote;
    }

    return $Q;
}

my %K;
sub _require {
    my ($os) = @_;

    return $K{$os} if $K{$os};

    my $klass = _is_win32($os) ? 'Win32/ShellQuote.pm' : 'String/ShellQuote.pm';
    $K{$os} = $klass;

    require "$klass"; ## no critic
}

sub _win32_quote {
    my ($cmd) = @_;
    Win32::ShellQuote::cmd_escape(join ' ', @$cmd);
}

sub _bourne_quote {
    my ($cmd) = @_;
    String::ShellQuote::shell_quote(@$cmd);
}

sub _is_win32 {
    my ($os) = @_;

    return $os =~ m!^(?:MS)?Win(?:32)?$!i ? 1 : 0;
}

1;

__END__

=encoding UTF-8

=head1 NAME

ShellQuote::Any - escape strings for the shell on Linux, UNIX or MSWin32


=head1 SYNOPSIS

    use ShellQuote::Any;

    shell_quote('curl', 'http://example.com/?foo=123&bar=baz');
    # curl 'http://example.com/?foo=123&bar=baz'


=head1 DESCRIPTION

ShellQuote::Any escapes strings for the shell on Linux, UNIX or MSWin32.


=head1 METHOD

=head2 shell_quote(\@cmd [, $os])

If this method was called without C<$os>, then C<@cmd> escapes for current OS. C<$os> supports C<MSWin32> or C<Bourne>.


=head1 REPOSITORY

=begin html

<a href="http://travis-ci.org/bayashi/ShellQuote-Any"><img src="https://secure.travis-ci.org/bayashi/ShellQuote-Any.png?_t=1472506498"/></a> <a href="https://coveralls.io/r/bayashi/ShellQuote-Any"><img src="https://coveralls.io/repos/bayashi/ShellQuote-Any/badge.png?_t=1472506498&branch=master"/></a>

=end html

ShellQuote::Any is hosted on github: L<http://github.com/bayashi/ShellQuote-Any>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<String::ShellQuote>

L<Win32::ShellQuote>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
