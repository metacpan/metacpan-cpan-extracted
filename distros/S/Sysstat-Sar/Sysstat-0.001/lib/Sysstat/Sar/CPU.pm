#
#===============================================================================
#
#         FILE: CPU.pm
#
#  DESCRIPTION: get sar information for CPU
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Heince Kurniawan (), heince.kurniawan@itgroupinc.asia
# ORGANIZATION: IT Group Indonesia
#      VERSION: 1.0
#      CREATED: 10/14/16 18:48:42
#     REVISION: ---
#===============================================================================
package Sysstat::Sar::CPU;
# ABSTRACT: Sysstat sar module to handle cpu information
use utf8;
use Carp;
use v5.10.1;
use Mo;
use Smart::Comments -ENV;

#-------------------------------------------------------------------------------
#  detect if line is cpu
#  - if second element is 'all' and >= 0
#  - total element is 11
#-------------------------------------------------------------------------------
sub is_cpu
{
    my $self    = shift;
    my $line    = shift;
    my $result  = shift;

    my @array   = split '\s+' => $line;
    if ( $#array == 10 and $array[1] =~ /^(all|\d+)/ and $array[0] =~ /^(\d+|Average)/ )
    {
        ### [<now>] [<file>][<line>] line is detected as cpu information...

        my $time = shift @array; # this can be time or 'Average'
        my $cpu  = shift @array;

        if ($time =~ /^Average/)
        {
            ### [<now>] [<file>][<line>] array = (usr, nice, sys, iowait, steal, irq, soft, guest, idle)
            ### [<now>] [<file>][<line>] Processing CPU ($cpu) Average...
            ### [<now>] [<file>][<line>] Got: $line

            push @{$$result{$self->hostname}{$self->date}{cpu}{'Average'}{$cpu}} , [@array];
        }
        else
        {
            ### [<now>] [<file>][<line>] array = (time, usr, nice, sys, iowait, steal, irq, soft, guest, idle)
            ### [<now>] [<file>][<line>] Processing CPU ($cpu) detail...
            unshift @array, $time;
            ### @array
            push @{$$result{$self->hostname}{$self->date}{cpu}{$cpu}} , [@array];
        }

        return $result;
    }
    else
    {
        return undef;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sysstat::Sar::CPU - Sysstat sar module to handle cpu information

=head1 VERSION

version 0.001

=head1 METHODS

=head2 is_cpu
    return hash reference passed by Sysstat::Sar parse method
    This method will filter line that contain cpu information

=head1 SYNOPSIS
    This module handle method for any cpu parsing from Sysstat::Sar
    To turn on diagnostics, set SMART_COMMENTS=1 to environment variable.

=head1 SEE ALSO

=over 4

=item *

L<Sysstat::Sar>

=back

=head1 AUTHOR

Heince Kurniawan <heince@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Heince Kurniawan <heince@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
