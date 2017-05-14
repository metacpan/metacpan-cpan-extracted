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
use 5.010;
use Moo;
use Smart::Comments -ENV;

#-------------------------------------------------------------------------------
#  detect if line is cpu
#  - if second element is 'all' and >= 0
#  - total element is 11
#-------------------------------------------------------------------------------
sub is_cpu
{
    my $self   = shift;
    my $line   = shift;
    my $result = shift;

    my @array = split '\s+' => $line;
    if (     $#array == 10
         and $array[ 1 ] =~ /^(all|\d+)/x
         and $array[ 0 ] =~ /^(\d+|Average)/x )
    {
        ### [<now>] [<file>][<line>] line is detected as cpu information...

        my $time = shift @array;    # this can be time or 'Average'
        my $cpu  = shift @array;

        my $idle = $array[ 8 ];
        $self->set_min_idle( $idle, $result, $cpu );
        $self->set_max_idle( $idle, $result, $cpu );

        if ( $time =~ /^Average/x )
        {
            ### [<now>] [<file>][<line>] array = (usr, nice, sys, iowait, steal, irq, soft, guest, idle)
            ### [<now>] [<file>][<line>] Processing CPU ($cpu) Average...
            ### [<now>] [<file>][<line>] Got: $line

            push
              @{ $$result{ $self->hostname }{ $self->date }{ cpu }{ 'average' }
                  { $cpu } }, @array;
        }
        else
        {
            ### [<now>] [<file>][<line>] array = (time, usr, nice, sys, iowait, steal, irq, soft, guest, idle)
            ### [<now>] [<file>][<line>] Processing CPU ($cpu) detail...
            unshift @array, $time;
            ### @array
            push @{ $$result{ $self->hostname }{ $self->date }{ cpu }{ $cpu } },
              [ @array ];
        }

        return $result;
    }
    else
    {
        return 0;
    }
}

sub set_min_idle
{
    my $self   = shift;
    my $idle   = shift;
    my $result = shift;
    my $cpu    = shift;

    if (
         defined $$result{ $self->hostname }{ $self->date }{ cpu }{ 'idle' }
         { $cpu }{ 'min' } )
    {
        if ( $idle <
             $$result{ $self->hostname }{ $self->date }{ cpu }{ 'idle' }{ $cpu }
             { 'min' } )
        {
            $$result{ $self->hostname }{ $self->date }{ cpu }{ 'idle' }{ $cpu }
              { 'min' } = $idle;
        }
    }
    else
    {
        $$result{ $self->hostname }{ $self->date }{ cpu }{ 'idle' }{ $cpu }
          { 'min' } = $idle;
    }

    return;
}

sub set_max_idle
{
    my $self   = shift;
    my $idle   = shift;
    my $result = shift;
    my $cpu    = shift;

    if (
         defined $$result{ $self->hostname }{ $self->date }{ cpu }{ 'idle' }
         { $cpu }{ 'max' } )
    {
        if ( $idle >
             $$result{ $self->hostname }{ $self->date }{ cpu }{ 'idle' }{ $cpu }
             { 'max' } )
        {
            $$result{ $self->hostname }{ $self->date }{ cpu }{ 'idle' }{ $cpu }
              { 'max' } = $idle;
        }
    }
    else
    {
        $$result{ $self->hostname }{ $self->date }{ cpu }{ 'idle' }{ $cpu }
          { 'max' } = $idle;
    }

    return;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sysstat::Sar::CPU - Sysstat sar module to handle cpu information

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    This module handle method for any cpu parsing from Sysstat::Sar
    To turn on diagnostics, set environment variable SMART_COMMENTS=1.

=head1 METHODS

=head2 is_cpu

    return hash reference passed by Sysstat::Sar parse method.
    This method will filter line that contain cpu information.

=head2 set_max_idle

    set maximum value cpu idle.
    hostname->date->cpu->idle->'cpu number'->max 

=head2 set_min_idle

    set minimum value cpu idle.
    hostname->date->cpu->idle->'cpu number'->min

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
