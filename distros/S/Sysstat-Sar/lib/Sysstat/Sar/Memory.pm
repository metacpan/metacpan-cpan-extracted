#
#===============================================================================
#
#         FILE: Memory.pm
#
#  DESCRIPTION: get sar information for Memory
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
package Sysstat::Sar::Memory;

# ABSTRACT: Sysstat sar module to handle memory information
use utf8;
use Carp;
use 5.010;
use Moo;
use Smart::Comments -ENV;

#-------------------------------------------------------------------------------
#  detect if line is memory information
#  - if second element is not decimal
#  - 3rd and 7th element is decimal
#  - total element is 8
#-------------------------------------------------------------------------------
sub is_memory
{
    my $self   = shift;
    my $line   = shift;
    my $result = shift;

    my @array = split '\s+' => $line;
    if (     $#array == 7
         and $array[ 2 ] !~ /^\d+\.\d+$/x
         and $array[ 3 ] =~ /^\d+\.\d+$/x
         and $array[ 7 ] =~ /^\d+\.\d+$/x )
    {
        ### [<now>] [<file>][<line>] line is detected as memory information...

        my $time = shift @array;    # this can be time or 'Average'

        my $used = $array[ 2 ];
        $self->set_min_used( $used, $result );
        $self->set_max_used( $used, $result );

        if ( $time =~ /^Average/x )
        {
            ### [<now>] [<file>][<line>] array = (kbmemfree, kbmemused, %memused, kbbuffers, kbcached, kbcommit, %commit)
            ### [<now>] [<file>][<line>] Processing Memory Average...
            ### $line

            push @{ $$result{ $self->hostname }{ $self->date }{ memory }
                  { 'average' } }, @array;
        }
        else
        {
            ### [<now>] [<file>][<line>] array = (time, kbmemfree, kbmemused, %memused, kbbuffers, kbcached, kbcommit, %commit)
            ### [<now>] [<file>][<line>] Processing Memory detail...
            unshift @array, $time;
            ### @array
            push
              @{ $$result{ $self->hostname }{ $self->date }{ memory }{ detail }
              }, [ @array ];
        }

        return $result;
    }
    else
    {
        return 0;
    }
}

sub set_min_used
{
    my $self   = shift;
    my $used   = shift;
    my $result = shift;

    if (
         defined $$result{ $self->hostname }{ $self->date }{ memory }{ 'used' }
         { 'min' } )
    {
        if ( $used <
             $$result{ $self->hostname }{ $self->date }{ memory }{ 'used' }
             { 'min' } )
        {
            $$result{ $self->hostname }{ $self->date }{ memory }{ 'used' }
              { 'min' } = $used;
        }
    }
    else
    {
        $$result{ $self->hostname }{ $self->date }{ memory }{ 'used' }{ 'min' }
          = $used;
    }

    return;
}

sub set_max_used
{
    my $self   = shift;
    my $used   = shift;
    my $result = shift;

    if (
         defined $$result{ $self->hostname }{ $self->date }{ memory }{ 'used' }
         { 'max' } )
    {
        if ( $used >
             $$result{ $self->hostname }{ $self->date }{ memory }{ 'used' }
             { 'max' } )
        {
            $$result{ $self->hostname }{ $self->date }{ memory }{ 'used' }
              { 'max' } = $used;
        }
    }
    else
    {
        $$result{ $self->hostname }{ $self->date }{ memory }{ 'used' }{ 'max' }
          = $used;
    }

    return;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sysstat::Sar::Memory - Sysstat sar module to handle memory information

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    This module handle method for any memory parsing from Sysstat::Sar
    To turn on diagnostics, set environment variable SMART_COMMENTS=1.

=head1 METHODS

=head2 is_memory

    return hash reference passed by Sysstat::Sar parse method.
    This method will filter line that contain memory information.

=head2 set_max_idle

    set maximum value memory idle.
    hostname->date->memory->used->max 

=head2 set_min_idle

    set minimum value memory idle.
    hostname->date->memory->used->min

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
