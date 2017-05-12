package Number::Phone::JP::AreaCode;
use 5.008005;
use strict;
use warnings;
use utf8;
use parent qw/Exporter/;
use Encode;
use Lingua::JA::Numbers;
use Lingua::JA::Regular::Unicode qw/alnum_h2z/;
use Number::Phone::JP::AreaCode::Data::Address2AreaCode;
use Number::Phone::JP::AreaCode::Data::AreaCode2Address;

our $VERSION   = "20131201.2";
our @EXPORT_OK = qw/
    area_code_by_address
    area_code_by_address_prefix_match
    area_code_by_address_fuzzy
    address_by_area_code
/;

sub area_code_by_address {
    my ($address) = @_;

    my ($prefecture, $town) = _separate_address($address);
    return get_address2areacode_map()->{$prefecture}->{$town};
}

sub area_code_by_address_prefix_match {
    my ($address) = @_;

    my ($prefecture, $town) = _separate_address($address);
    my $pref_map = get_address2areacode_map()->{$prefecture};
    return _search_area_code_by_address_recursive($pref_map, $town);
}

sub area_code_by_address_fuzzy {
    my ($address) = @_;

    my ($prefecture, $town) = _separate_address($address);
    my $pref_map = get_address2areacode_map()->{$prefecture};

    if (exists $pref_map->{$town}) {
        return {"$prefecture$town" => $pref_map->{$town}};
    }

    my $hits = {};
    for my $key (keys %$pref_map) {
        if ($town =~ $key || $key =~ $town) {
            $hits->{"$prefecture$key"} = $pref_map->{$key};
        }
    }
    return $hits;
}

sub address_by_area_code {
    my ($area_code) = @_;

    $area_code =~ s/\A0//;
    return get_areacode2address_map()->{$area_code};
}

sub _search_area_code_by_address_recursive {
    my ($pref_map, $town) = @_;

    if (exists $pref_map->{$town}) {
        return $pref_map->{$town};
    }

    $town = _minimum_substitute_by_municipality($town);

    # One character or less (e.g. "町")
    if (!$town || length $town <= 1) {
        return;
    }

    return _search_area_code_by_address_recursive($pref_map, $town);
}

sub _separate_address {
    my ($address) = @_;

    eval { $address = Encode::decode_utf8($address) }; # decode (but not twice)

    my ($prefecture, $town) = $address =~ /\A(京都府|東京都|大阪府|北海道|.+?県)(.*)/;
    $town =~ s/大字//g; # XXX ignore "大字"

    # Support numerical number (hankaku / zenkaku)
    for my $num (0..9) {
        my $kanji_num   = num2ja($num);
        my $zenkaku_num = alnum_h2z($num);
        $town =~ s/(:?$num|$zenkaku_num)/$kanji_num/g;
    }

    return ($prefecture, $town);
}

sub _minimum_substitute_by_municipality {
    my ($town) = @_;

    my @substitutes;
    (my $block   = $town) =~ s/区.*?\Z/区/; push @substitutes, $block;
    (my $city    = $town) =~ s/市.*?\Z/市/; push @substitutes, $city;
    (my $group   = $town) =~ s/郡.*?\Z/郡/; push @substitutes, $group;
    (my $cho     = $town) =~ s/町.*?\Z/町/; push @substitutes, $cho;
    (my $village = $town) =~ s/村.*?\Z/村/; push @substitutes, $village;

    my $minimum_substituted = '';
    for my $substituted (@substitutes) {
        next if $substituted eq $town;
        if (length $substituted > length $minimum_substituted) {
            $minimum_substituted = $substituted;
        }
    }

    return $minimum_substituted;
}

1;
__END__

=encoding utf-8

=head1 NAME

Number::Phone::JP::AreaCode - Utilities for Japanese area code of phone

=head1 SYNOPSIS

    use Number::Phone::JP::AreaCode qw/
        area_code_by_address
        area_code_by_address_prefix_match
        area_code_by_address_fuzzy
        address_by_area_code
    /;

    address_by_area_code('1456'); # => { addresses => [ '北海道新冠郡新冠町里平', '北海道沙流郡日高町', ], local_code_digits => '1' }
    address_by_area_code('01456'); # => same as above
    area_code_by_address('大阪府東大阪市岩田町'); # => { area_code => '72', local_code_digits => '3' }
    area_code_by_address_prefix_match('大阪府東大阪市岩田町一丁目'); # => { area_code => '72', local_code_digits => '3' }
    area_code_by_address_fuzzy('大阪府東大阪市岩田'); # => {
                                                      #        '大阪府東大阪市岩田町' => {
                                                      #            area_code         => '72',
                                                      #            local_code_digits => '3',
                                                      #        },
                                                      #        '大阪府東大阪市岩田町三丁目' => {
                                                      #            area_code         => '6',
                                                      #            local_code_digits => '4',
                                                      #        },
                                                      #        '大阪府大阪市' => {
                                                      #            area_code         => '6',
                                                      #            local_code_digits => '4',
                                                      #        },
                                                      #        '大阪府東大阪市' => {
                                                      #            area_code         => '6',
                                                      #            local_code_digits => '4',
                                                      #        }
                                                      #    }

=head1 DESCRIPTION

Number::Phone::JP::AreaCode provides utilities for Japanese area code of phone.
You can retrieve area code by address and opposite.

If you want to know about Japanese area code of phone, please refer L<http://www.soumu.go.jp/main_sosiki/joho_tsusin/top/tel_number/shigai_list.html> (Japanese web page).

=head1 FUNCTIONS

All of functions return C<undef> if result of retrieving is nothing.

=over 4

=item * address_by_area_code($area_code)

Retrieve addresses list by area code.
This function returns hash reference like;

    {
        addresses         => [ '北海道◯◯市××町', '北海道◯◯市△△町' ],
        local_code_digits => '3'
    }

C<addresses> is the list of addresses that belong with area code.
C<local_code_digits> is the number of digits of local code.

You can append country code (0) or not. As you like it!

=item * area_code_by_address($address)

Retrieve area code by address (perfect matching). C<$address> B<MUST> have prefecture name.
This function returns hash reference like;

    {
        area_code => '72',
        local_code_digits => '3'
    }

C<area_code> is the area code which excepted country code (0).
C<local_code_digits> is the number of digits of local code.

=item * area_code_by_address_prefix_match($address)

Retrieve area code by address (prefix matching and longest matching). C<$address> B<MUST> have prefecture name.
This function returns hash reference that is the same as C<area_code_by_address>.

=item * area_code_by_address_fuzzy($address)

Retrieve area code by address (partial match). C<$address> B<MUST> have prefecture name.
This function returns hash reference like;

    {
        '大阪府◯◯市' => {
            area_code         => '6',
            local_code_digits => '4',
        },
        '大阪府△△市' => {
            area_code         => '72',
            local_code_digits => '3',
        }
    }

=back

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 CONTRIBUTOR

ytnobody

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut

