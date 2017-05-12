# $Id: SZTime.pm,v 1.7 2002/08/14 17:15:58 Vutral Exp $
package Time::SZTime;

## See POD after __END__
use strict;
use Time::HiRes;
our ($VERSION, @ISA, @EXPORT);
# AU Code: use CPAN::Shell;

use Exporter ();

$VERSION = "0.14";

@ISA = qw(Exporter);
@EXPORT = qw(&SZTime);

# AU Code: my $Object = CPAN::Shell->expand('Module','Time::SZTime'); $Object->install;

sub SZTime {
    my $time = Time::HiRes::time;
    $time *= 1000; $time = $time - 504934930483.2;
    $time = int($time);
    return $time;
}

sub SZTime::log {
    my $time = Time::SZTime::SZTime();
    return log($time);
}

sub SZTime::log10 {
    my $time = Time::SZTime::SZTime();
    $time = log($time)/log(10);
    return $time;
}

1;

__END__

=head1 NAME

SZTime - computes the local SZTime

=head1 SYNOPSIS

    use Time::SZTime;

    $time = SZTime();        # SZTime Representation as Integer
    $time = SZTime::log();   # SZTime Represantation as Base e Logarithm
    $time = SZTime::log10(); # SZTime Represantation as Base-10 Logarithm

=head1 DESCRIPTION

The SZTime() algorithm is for calculating the SZTime. The SZTime is similar to
the Unixtime but more accurate. SZTime represents the milliseconds since Midnight
01.01.1986. The Value can be positive or negative.

=head1 MODIFICATION HISTORY

Enter all Modifications here (Modification, Author).

=head1 AUTHOR

Sebastian Schwarz.
Please report all bugs, wishes and modifications to <sjsz@cpan.org>.

=head1 COPYRIGHT

Copyright © 2001 Sebastian Schwarz <sjsz@cpan.org>. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 PREREQUISITES

This Module actually requires C<strict> and C<Time::HiRes> modules.

=cut
