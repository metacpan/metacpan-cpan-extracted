package Reply::Plugin::DataDumpColor;

our $DATE = '2014-12-01'; # DATE
our $VERSION = '0.01'; # VERSION

use strict;
use warnings;

use base 'Reply::Plugin';

use Data::Dump::Color 'dump';
use overload ();

sub new {
    my $class = shift;
    my %opts = @_;
    $opts{respect_stringification} = 1
        unless defined $opts{respect_stringification};

    my $self = $class->SUPER::new(@_);
    $self->{filter} = sub {
        my ($ctx, $ref) = @_;
        return unless $ctx->is_blessed;
        my $stringify = overload::Method($ref, '""');
        return unless $stringify;
        return {
            dump => $stringify->($ref),
        };
    } if $opts{respect_stringification};

    return $self;
}

sub mangle_result {
    local $Data::Dump::Color::COLOR = 1;

    my $self = shift;
    my (@result) = @_;
    # Data::Dump::Color currently does not support filtering
    #return @result ? dumpf(@result, $self->{filter}) : ();
    return @result ? dump(@result) : ();
}

1;
# ABSTRACT: Format results using Data::Dump::Color

__END__

=pod

=encoding UTF-8

=head1 NAME

Reply::Plugin::DataDumpColor - Format results using Data::Dump::Color

=head1 VERSION

This document describes version 0.01 of Reply::Plugin::DataDumpColor (from Perl distribution Reply-Plugin-DataDumpColor), released on 2014-12-01.

=head1 SYNOPSIS

 ; .replyrc
 [DataDumpColor]

=head1 DESCRIPTION

This is like L<Reply::Plugin::DataDump> except using L<Data::Dump::Color>
instead of L<Data::Dump>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Reply-Plugin-DataDumpColor>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Reply-Plugin-DataDumpColor>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Reply-Plugin-DataDumpColor>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
