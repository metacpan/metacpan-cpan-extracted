#
#===============================================================================
#
#         FILE: Sar.pm
#
#  DESCRIPTION: generic info from sar
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Heince Kurniawan (), heince.kurniawan@itgroupinc.asia
# ORGANIZATION: IT Group Indonesia
#      VERSION: 1.0
#      CREATED: 10/14/16 18:51:12
#     REVISION: ---
#===============================================================================
package Sysstat::Sar;
# ABSTRACT: Sysstat sar file parser
use utf8;
use Carp;
use v5.10.1;
use Mo;
use Smart::Comments -ENV;
extends 'Sysstat::Sar::CPU';

has 'sarfilepath' => ( is => 'ro' );
has 'hostname'  => (is => 'rw');
has 'date'      => (is => 'rw');

sub BUILD
{
    my $self = shift;

    #-------------------------------------------------------------------------------
    #  die if sar file is not found
    #-------------------------------------------------------------------------------
    ### [<now>] [<file>][<line>] check if sar file exists...
    carp "sar file not valid" unless -f $self->sarfilepath;
}

sub parse
{
    my $self = shift;
    my %result;

    ### [<now>] [<file>][<line>] opening sar file...
    open ( my $fh, "<", $self->sarfilepath ) or carp "$!";

    ### [<now>] [<file>][<line>] loop lines...
    while ( <$fh> )
    {
        $self->check_header( $_, \%result );
        $self->is_cpu( $_, \%result );
    }

    close $fh;

    return \%result;
}

#-------------------------------------------------------------------------------
#  return $result hash ref hostname->date->{os,kernel,arch,totalcpu}
#-------------------------------------------------------------------------------
sub check_header
{
    my $self    = shift;
    my $line    = shift;
    my $result  = shift;

    if ( $line =~ /.*CPU\)/ )
    {
        #  return array of (OS, kernel, hostname, date, arch, no_of_cpu)
        my @header      = split '\s+' => $line;
        my $hostname    = $header[ 2 ];
        my $date        = $header[ 3 ];

        #-------------------------------------------------------------------------------
        #  remove '(' and ')' character on hostname
        #-------------------------------------------------------------------------------
        $hostname =~ s/(\(|\))//g;

        $$result{ $hostname }{ $date }{ os }       = $header[ 0 ];
        $$result{ $hostname }{ $date }{ kernel }   = $header[ 1 ];
        $$result{ $hostname }{ $date }{ arch }     = $header[ 4 ];
        $$result{ $hostname }{ $date }{ totalcpu } = $header[ 5 ] . $header[ 6 ];

        $self->hostname($hostname);
        $self->date($date);

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

Sysstat::Sar - Sysstat sar file parser

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    This module will parse sar file output to perl data structure for easy manipulation.
    Some additional value is added like min and max value for each day / all records in a day.

    'hostname' => {
                      '08/28/16' => {
                                      'totalcpu' => '(4CPU)',
                                      'kernel' => '2.6.32-431.29.2.el6.x86_64',
                                      'cpu' => {
                                                 '1' => [
                                                          [
                                                            '00:10:01',
                                                            '0.14',
                                                            '0.00',
                                                            '0.13',
                                                            '0.00',
                                                            '0.00',
                                                            '0.00',
                                                            '0.00',
                                                            '0.00',
                                                            '99.73'
                                                          ],
                                                          [
                                                            '00:20:01',
                                                            '0.15',
                                                            '0.00',
                                                            '0.12',
                                                            '0.00',
                                                            '0.00',
                                                            '0.00',
                                                            '0.00',
                                                            '0.00',
                                                            '99.73'
                                                          ],
                                        ........ output shorten ................

=head1 METHODS

=head2 check_header
    parameter (current line from file handle, hash reference )
    This method return a hash reference passed from parse method.

    it will set current position hostname, date, os, kernel version, cpu arch and totalcpu.
    hash structure that being setup are : 
    {hostname}{date}{os}
    {hostname}{date}{kernel}
    {hostname}{date}{arch}
    {hostname}{date}{totalcpu}

=head2 parse
    return parse output in hash

=head1 SEE ALSO

=over 4

=item *

L<Sysstat::Sar::CPU>

=back

=head1 AUTHOR

Heince Kurniawan <heince@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Heince Kurniawan <heince@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
