# ABSTRACT: Constants used by PONAPI::DAO and PONAPI repositories
package PONAPI::Constants;

use strict;
use warnings;

my $constants;
BEGIN {
    $constants = {
        PONAPI_UPDATED_EXTENDED => 100,
        PONAPI_UPDATED_NORMAL   => 101,
        PONAPI_UPDATED_NOTHING  => 102,
    };

    require constant; constant->import($constants);
    require Exporter; our @ISA = qw(Exporter);
    our @EXPORT = ( keys %$constants,
        qw/
            %PONAPI_UPDATE_RETURN_VALUES
        /,
    );
}

our (%PONAPI_UPDATE_RETURN_VALUES);

$PONAPI_UPDATE_RETURN_VALUES{+PONAPI_UPDATED_EXTENDED}  = 1;
$PONAPI_UPDATE_RETURN_VALUES{+PONAPI_UPDATED_NORMAL}    = 1;
$PONAPI_UPDATE_RETURN_VALUES{+PONAPI_UPDATED_NOTHING}   = 1;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::Constants - Constants used by PONAPI::DAO and PONAPI repositories

=head1 VERSION

version 0.003003

=head1 SYNOPSIS

    use PONAPI::Constants;
    sub update {
        ...

        return $updated_more_rows_than_requested
               ? PONAPI_UPDATED_EXTENDED
               : PONAPI_UPDATED_NORMAL;
    }

=head1 EXPORTS

=head2 PONAPI_UPDATED_NORMAL

The update-like operation did as requested, as no more.

=head2 PONAPI_UPDATED_EXTENDED

The update-like operation did B<more> than requested; maybe it added rows,
or updated another related table.

=head2 PONAPI_UPDATED_NOTHING

The update-like operation was a no-op.  This can happen in a SQL implementation
when modifying a resource that doesn't exist, for example.

=head1 AUTHORS

=over 4

=item *

Mickey Nasriachi <mickey@cpan.org>

=item *

Stevan Little <stevan@cpan.org>

=item *

Brian Fraser <hugmeir@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Mickey Nasriachi, Stevan Little, Brian Fraser.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
