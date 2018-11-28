package Perinci::Script::Any;

our $DATE = '2018-11-22'; # DATE
our $VERSION = '0.001'; # VERSION

# IFUNBUILT
# use strict;
# use warnings;
# END IFUNBUILT

my %Opts = (
    -prefer_lite => 1,
);

sub import {
    my ($class, %args) = @_;
    $Opts{$_} = $args{$_} for keys %args;
}

sub new {
    my $class = shift;

    my @mods;
    if ($ENV{GATEWAY_INTERFACE} || $ENV{FCGI_ROLE}) {
        @mods = ('Perinci::WebScript::JSON');
    } else {
        @mods = qw(Perinci::CmdLine::Any);
    }

    for my $i (1..@mods) {
        my $mod = $mods[$i-1];
        my $modpm = $mod; $modpm =~ s!::!/!g; $modpm .= ".pm";
        if ($i == @mods) {
            require $modpm;
            return $mod->new(@_);
        } else {
            my $res;
            eval {
                require $modpm;
                $res = $mod->new(@_);
            };
            if ($@) {
                next;
            } else {
                return $res;
            }
        }
    }
}

1;
# ABSTRACT: Allow a script to be a command-line script or PSGI (CGI, FCGI)

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Script::Any - Allow a script to be a command-line script or PSGI (CGI, FCGI)

=head1 VERSION

This document describes version 0.001 of Perinci::Script::Any (from Perl distribution Perinci-Script-Any), released on 2018-11-22.

=head1 SYNOPSIS

In your script:

 #!/usr/bin/env perl
 use Perinci::Script::Any;
 Perinci::Script::Any->new(url => '/Package/func')->run;

=head1 DESCRIPTION

This module lets you have a script that can be a command-line script as well as
a PSGI (CGI, FCGI) script.

=for Pod::Coverage ^(new)$

=head1 ENVIRONMENT

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Script-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Script-Any>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Script-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci::CmdLine::Any>, L<Perinci::WebScript::JSON>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
