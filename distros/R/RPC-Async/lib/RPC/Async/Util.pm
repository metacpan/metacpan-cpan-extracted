package RPC::Async::Util;
use strict;
use warnings;

our $VERSION = '1.05';

=head1 NAME

RPC::Async::Util - util module of the asynchronous RPC framework

=cut

use base "Exporter";
use Class::ISA;
use Storable qw(nfreeze thaw);

our @EXPORT_OK = qw(append_data read_packet make_packet expand);

=head1 METHODS

=over

=cut

=item expand($ref, $in)

Expands and normalizes the def_* input and output definitions to a unified
order and naming convention.

=cut

sub expand {
    my ($ref, $in) = @_;
    
    treewalk($ref,
        sub { 
            if($in and ${$_[0]} =~ s/^(.+?)_(\d+)$/$2$1/) {
                return ${$_[0]};
            } elsif($in) {
                my $count = 0;
                return map { sprintf "%02d$_", $count++ } split /\|/, ${$_[0]};
            } else {
                return split /\|/, ${$_[0]};
            }
        }, 
        sub{ 
            no warnings 'uninitialized'; # So we can use $1 even when we got no match
            ${$_[0]} =~ s/^(?:latin1)/latin1string/;
            ${$_[0]} =~ s/^(?:str(?:ing)?)|(:?utf8)/utf8string/;
            ${$_[0]} =~ s/^(?:(u)?int(?:eger)?(?:8))|(?:byte)|(?:char)/$1integer8/;
            ${$_[0]} =~ s/^(?:(u)?int(?:eger)?(?:16))|(?:short)/$1integer16/;
            ${$_[0]} =~ s/^(?:(u)?int(?:eger)?(?:(:)|(?:32)|$))|(?:long)/$1integer32$2/; # Default to 32bit
            ${$_[0]} =~ s/^(?:(u)?int(?:eger)?(?:64))|(?:longlong)/$1integer64/;
            ${$_[0]} =~ s/^(?:float)?(?:(:)|(?:32)|$)/float32$1/; # Default to 32bit
            ${$_[0]} =~ s/^(?:float64)|(?:double)/float64$1/;
            ${$_[0]} =~ s/^(?:bin)|(?:data)/binary/;
            ${$_[0]} =~ s/^(?:bool)/boolean/;
        } 
    );

    return $ref;
}

=item append_data($buf, $data)

Function for buffering data.

=cut

sub append_data {
    my ($buf, $data) = @_;

    if (not defined $$buf) {
        $$buf = $data;
    } else {
        $$buf .= $data;
    }
}

=item read_packet($buf)

Reads the next packet and thaws it if enough data has been received.

=cut

sub read_packet {
    my ($buf) = @_;

    return if not defined $$buf or length $$buf < 4;

    my $length = unpack("N", $$buf);
    die if $length < 4; # TODO: catch this
    return if length $$buf < $length;

    my $frozen = substr $$buf, 4, $length - 4;
    if (length $$buf == $length) {
        $$buf = undef;
    } else {
        $$buf = substr $$buf, $length;
    }

    return thaw $frozen;
}

=item make_packet($ref)

Generate a packet for sending.

=cut

sub make_packet {
    my ($ref) = @_;

    my $frozen = nfreeze($ref);
    return pack("N", 4 + length $frozen) . $frozen;
}

#use Misc::Common qw(treewalk); # FIXME: Put in own module instead

=item treewalk($tree, $replace_key, $replace_value)

Sub used to walk a tree structure.

=cut

sub treewalk {
    my ($tree, $replace_key, $replace_value) = @_;
    $replace_key = $replace_key?$replace_key:sub{};
    $replace_value = $replace_value?$replace_value:sub{};

    my @walk = ($tree);
    while(my $branch = shift @walk) {
        if(ref($branch) eq 'HASH') {
            foreach my $key (keys %{$branch}) {
                my $newkey = $key;
                if(my @results = grep { $_ } $replace_key->(\$newkey)) {
                    if(@results > 1) {
                        if (ref($branch->{$newkey}) eq '') {
                            $replace_value->(\$branch->{$key});
                            foreach my $result (@results) {
                                $branch->{$result} = $branch->{$key};
                            }
                        } else {
                            foreach my $result (@results) {
                                $branch->{$result} = $branch->{$key};
                            }
                        }
                        $newkey = $results[0];
                        delete($branch->{$key});

                    } elsif($newkey ne $key) {
                        $branch->{$newkey} = $branch->{$key};
                        delete($branch->{$key});
                    }
                }

                if (ref($branch->{$newkey}) eq 'HASH') {
                    push(@walk, $branch->{$newkey});
                } elsif (ref($branch->{$newkey}) eq 'ARRAY') {
                    push(@walk, $branch->{$newkey});
                } else {
                    $replace_value->(\$branch->{$newkey});
                }

            }
        } elsif(ref($branch) eq 'ARRAY') {
            for(my $i=0;$i<int(@{$branch});$i++) { 
                if(ref($branch->[$i]) eq 'ARRAY') {
                    push(@walk, $branch->[$i]);
                } elsif(ref($branch->[$i]) eq 'HASH') {
                    push(@walk, $branch->[$i]);
                } else {
                    $replace_value->(\$branch->[$i]);
                }
            }
        }
    }
}

=back

=head1 AUTHOR

Jonas Jensen <jbj@knef.dk>, Troels Liebe Bentsen <tlb@rapanden.dk> 

=head1 COPYRIGHT

Copyright(C) 2005-2007 Troels Liebe Bentsen

Copyright(C) 2005-2007 Jonas Jensen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
# vim: et sw=4 sts=4 tw=80
