package String::BOM;

# use warnings;
# use strict;

$String::BOM::VERSION = '0.3';

# http://www.unicode.org/faq/utf_bom.html#BOM
# http://search.cpan.org/perldoc?PPI::Token::BOM
%String::BOM::bom_types = (
    "\x00\x00\xfe\xff" => 'UTF-32',
    "\xff\xfe\x00\x00" => 'UTF-32',
    "\xfe\xff"         => 'UTF-16',
    "\xff\xfe"         => 'UTF-16',
    "\xef\xbb\xbf"     => 'UTF-8',
);

sub string_has_bom {
    if ( $_[0] =~ m/^(\x00\x00\xfe\xff|\xff\xfe\x00\x00|\xfe\xff|\xff\xfe|\xef\xbb\xbf)/s ) {
        return $String::BOM::bom_types{$1};
    }
    return;
}

sub strip_bom_from_string {
    my $copy = $_[0];    # Modification of a read-only value attempted at ...
    $copy =~ s/^(\x00\x00\xfe\xff|\xff\xfe\x00\x00|\xfe\xff|\xff\xfe|\xef\xbb\xbf)//s;
    return $copy;
}

sub file_has_bom {

    # Would rather not bring in >0.5MB Fcntl just for this so we do a read() of characters instead of a sysread() of bytes()
    #   sysopen(my $fh, $_[0],&Fcntl::O_RDONLY) or return;
    #   sysread($fh, my $buf, $length_in_bytes_of_biggest_bom);
    open( my $fh, '<', $_[0] ) or return;
    $! = 0;              # yes this happens
    read( $fh, my $buf, 4 ) or return;    # 4 "characters" should be big enough to bring in enough anything in bom_types
    $! = 0;                               # yes this happens
    close($fh) or return;
    $! = 0;                               # yes this happens
    return string_has_bom($buf);
}

sub strip_bom_from_file {
    if ( file_has_bom( $_[0] ) ) {

        # there is [probabaly] a better way to do this (faster, w/ out .bak file, etc), suggestions/patches welcome

        # in-place edit
        my $inplace_error = 0;
        {
            local $^I              = '.bak';
            local @ARGV            = ( $_[0] );
            local $SIG{'__WARN__'} = sub {
                $inplace_error++;

                # my $err = shift();
                # $inplace_error = {
                #     'errno_int' => int($!),
                #     'errno_str' => "$!",
                #     'raw_warn'  => $err,
                # };
            };

            while (<ARGV>) {
                if ( $. == 1 ) {
                    print strip_bom_from_string($_);    # ... write stripped line back to the file
                    next;
                }
                print;                                  # ... write the line back to the file
            }
        }

        return if $inplace_error;

        unlink "$_[0].bak" unless $_[1];

        return 1;
    }
    else {
        return if $!;                                   # file_has_bom() must've returned false due to FS issue (hence the "yes this happens" bits above)
        return 1;
    }
}

sub import {
    shift;
    return if !@_;

    my $caller = caller();

    # no strict 'refs';
    for (@_) {
        next if !defined &{$_} || m/\:\'/;
        *{"$caller\::$_"} = \&{$_};
    }
}

1;

__END__

=head1 NAME

String::BOM - simple utilities to check for a BOM and strip a BOM

=head1 VERSION

This document describes String::BOM version 0.3

=head1 SYNOPSIS

    use String::BOM qw(string_has_bom);
    
    if (my $bom = string_has_bom($string)) {
        print "According to the string's BOM it is '$bom'\n";
    }

=head1 DESCRIPTION

See if a string or file has a BOM. Remove the BOM from a string or file.

=head2 You [c|sh]ould use PPI to do this is you are looking at a perl file

Something like this modified L<PPI> sysnopsis example should detect and remove a BOM:

    use PPI;
    
    my $Document = PPI::Document->new('Module.pm');

    # Does it contain a BOM?
    if ( $Document->find_any('PPI::Token::BOM') ) {
        print "Module contains BOM!!\n";
        $Document->prune('PPI::Token::BOM');
        $Document->save('Module.pm.bom_free');
    }

=head1 INTERFACE 

All of these functions can be imported.

=head2 string_has_bom()

Takes a string and returns true (the type of BOM it is) if there is a BOM.

=head2 strip_bom_from_string()

Takes a string and returns a version with the BOM, if any, removed.

=head2 file_has_bom()

Takes a path and returns true (the type of BOM it is) if there is a BOM.

Check $! for file operation failure when it returns false.

=head2 strip_bom_from_file()

Takes a path and removes the BOM, if any, from it.

Check $! for file operation failure when it returns false.

A second argument with a true value will make it leave the original document on the file system with a .bak extension added.

Note: If the file had no BOM and was thus not edited then there is no .bak file.

=head1 DOM TYPES

The DOM data is the same as L<PPI::Token::BOM> which are taken from L<http://www.unicode.org/faq/utf_bom.html#BOM>.

=head1 DIAGNOSTICS

String::BOM throws no warnings or errors 

=head1 CONFIGURATION AND ENVIRONMENT

String::BOM requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-string-bom@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

L<PPI>, L<File::Bom>

L<File::Bom> doesn't really do what this module does and has other utility functions that we don't need for the purposes of this module.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
