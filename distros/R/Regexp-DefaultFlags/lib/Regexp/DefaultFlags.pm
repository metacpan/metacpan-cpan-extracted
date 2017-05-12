package Regexp::DefaultFlags;
$Regexp::DefaultFlags::VERSION = '0.01';

use strict;
use overload;

sub import {
    my $class = shift;                          # Ignore package name
    my $flags = @_ ? join(' ', @_) : 'xms';     # Get flags (or defaults)
    $flags =~ s{[\s/]+}{}g;                     # Remove decorations
    if ($flags =~ m/([^imsx]+)/) {              # Detect invalid flags
        require Carp;
        Carp::croak("Unknown regular expression flag: $1");
    }
    overload::constant(                         # Prefilter constants...
        qr => sub {                             # For every regex constant:
            return "(?$flags:$_[1])";           # Flag via (?mix:...) syntax
        },
    );
}

1;
__END__

=head1 NAME

Regexp::DefaultFlags - Set default flags on regular expressions

=head1 VERSION

This document describes version 0.01 of Regexp::DefaultFlags
released September 28, 2004.

=head1 SYNOPSIS

    use Regexp::DefaultFlags;

    # Match /ab[c-z]d/, but lay the pattern out more readably...
    $str =~ / a b [c-z]   # Not fussy on the third letter
                d         # But fussy again on the fourth
            /;

=head1 DESCRIPTION

When this module is C<use>'d, it causes regexes in the current
namespace to act as if the C</xms> flags had been applied to them.

See L<perlre> for more details and caveats on these flags.

If an argument is passed to the C<use> statement, the module uses the flags
specified in that argument instead of C</xms>. The replacement flags can
be specified in any of the following ways:

    use Regexp::DefaultFlags qw( /x /i /m );
    use Regexp::DefaultFlags qw( /xim );
    use Regexp::DefaultFlags qw( xim );

=head1 TEST COVERAGE

 ------------------------------------------------------------------
 File                        stmt branch cond   sub pod  time total
 ------------------------------------------------------------------
 lib/Regexp/DefaultFlags.pm 100.0  100.0  n/a 100.0 n/a 100.0 100.0
 Total                      100.0  100.0  n/a 100.0 n/a 100.0 100.0
 ------------------------------------------------------------------

=head1 AUTHOR

Damian Conway (damian@conway.org)

=head1 MAINTAINERS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>,
Brian Ingerson E<lt>INGY@cpan.orgE<gt>.

=head1 COPYRIGHT

   Copyright (c) 2004, Damian Conway. All Rights Reserved.
 This module is free software. It may be used, redistributed
     and/or modified under the same terms as Perl itself.
