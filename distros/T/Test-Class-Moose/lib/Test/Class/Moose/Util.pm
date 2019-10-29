package Test::Class::Moose::Util;

use strict;
use warnings;

our $VERSION = '0.98';

use Test2::API qw( context );

use Exporter qw( import );

our @EXPORT_OK = qw( context_do );

# This is identical to the version in Test2::API except we set level to 0
# rather than 1.
sub context_do (&;@) {
    my $code = shift;
    my @args = @_;

    my $ctx = context( level => 0 );

    my $want = wantarray;

    my @out;
    my $ok = eval {
        $want ? @out
          = $code->( $ctx, @args )
          : defined($want) ? $out[0]
          = $code->( $ctx, @args )
          : $code->( $ctx, @args );
        1;
    };
    my $err = $@;

    $ctx->release;

    die $err unless $ok;

    return @out if $want;
    return $out[0] if defined $want;
    return;
}

1;

# ABSTRACT: Internal utilities

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Class::Moose::Util - Internal utilities

=head1 VERSION

version 0.98

=for Pod::Coverage context_do

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/test-class-moose/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Test-Class-Moose can be found at L<https://github.com/houseabsolute/test-class-moose>.

=head1 AUTHORS

=over 4

=item *

Curtis "Ovid" Poe <ovid@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 - 2019 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
