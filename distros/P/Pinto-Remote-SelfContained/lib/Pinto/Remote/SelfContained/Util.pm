package
    Pinto::Remote::SelfContained::Util; # hide from PAUSE

use v5.10;
use strict;
use warnings;

use Carp qw(croak);
use Time::Moment;

use Exporter qw(import);

our $VERSION = '1.000';

our @EXPORT_OK = qw(
    current_time_offset
    current_username
    mask_uri_passwords
);

sub current_time_offset { Time::Moment->now->offset }

sub current_username {
    return $ENV{PINTO_USERNAME} // $ENV{USER} // $ENV{LOGIN} // $ENV{USERNAME} // $ENV{LOGNAME}
        // croak("Can't determine username; try setting \$PINTO_USERNAME");
}

sub mask_uri_passwords {
    my ($uri) = @_;

    $uri =~ s{ (https?://[^:/@]+ :) [^@/]+@}{$1*password*@}gx;
    return $uri;
}

1;
__END__

=head1 NAME

Pinto::Remote::SelfContained::Util - various utility functions

=head1 AUTHOR

Aaron Crane, E<lt>arc@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2020 Aaron Crane.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.

=cut
