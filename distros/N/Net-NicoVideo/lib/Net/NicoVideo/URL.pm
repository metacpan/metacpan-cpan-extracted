package Net::NicoVideo::URL;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.27';

use base qw(Exporter);
use vars qw(@EXPORT);
@EXPORT = qw(shorten unshorten);

use Carp qw(croak);

sub shorten {
    my $url = shift or croak 'No URL passed to shorten';
    if( 0 ){
        return;
    }

    # douga
    elsif( $url =~ m{^(https?)://www\.nicovideo\.jp/watch/([-_0-9A-Za-z]+)} ){
        return "$1://nico.ms/$2";
    }

    # seiga
    elsif( $url =~ m{^(https?)://seiga\.nicovideo\.jp/seiga/([-_0-9A-Za-z]+)} ){
        return "$1://nico.ms/$2";
    }
    elsif( $url =~ m{^(https?)://seiga\.nicovideo\.jp/watch/([-_0-9A-Za-z]+)} ){
        return "$1://nico.ms/$2";
    }

    # live
    elsif( $url =~ m{^(https?)://live\.nicovideo\.jp/watch/([-_0-9A-Za-z]+)} ){
        my $sc = $1;
        my $id = $2;
        if( $id =~ /^lv/ ){
            return "$sc://nico.ms/$id";
        }elsif( $id =~ /^co/ ){
            return "$sc://nico.ms/l/$id";
        }
    }

    # community
    elsif( $url =~ m{^(https?)://com\.nicovideo\.jp/community/([-_0-9A-Za-z]+)} ){
        return "$1://nico.ms/$2";
    }

    # channel
    elsif( $url =~ m{^(https?)://ch\.nicovideo\.jp/channel/([-_0-9A-Za-z]+)} ){
        return "$1://nico.ms/$2";
    }
    elsif( $url =~ m{^(https?)://ch\.nicovideo\.jp/article/([-_0-9A-Za-z]+)} ){
        return "$1://nico.ms/$2";
    }

    # chokuhan
    elsif( $url =~ m{^(https?)://chokuhan\.nicovideo\.jp/products/detail/(\d+)} ){
        return "$1://nico.ms/nd$2";
    }

    # ichiba
    elsif( $url =~ m{^(https?)://ichiba\.nicovideo\.jp/item/([-_0-9A-Za-z]+)} ){
        return "$1://nico.ms/$2";
    }

    # app
    elsif( $url =~ m{^(https?)://app\.nicovideo\.jp/app/([-_0-9A-Za-z]+)} ){
        return "$1://nico.ms/$2";
    }

    # jikkyou
    elsif( $url =~ m{^(https?)://jk\.nicovideo\.jp/watch/([-_0-9A-Za-z]+)} ){
        return "$1://nico.ms/$2";
    }

    # commons
    elsif( $url =~ m{^(https?)://www\.niconicommons\.jp/material/([-_0-9A-Za-z]+)} ){
        return "$1://nico.ms/$2";
    }

    # news
    elsif( $url =~ m{^(https?)://news\.nicovideo\.jp/watch/([-_0-9A-Za-z]+)} ){
        return "$1://nico.ms/$2";
    }

    # dictionary
    elsif( $url =~ m{^(https?)://dic\.nicovideo\.jp/id/([-_0-9A-Za-z]+)} ){
        return "$1://nico.ms/dic/$2";
    }

    # user
    elsif( $url =~ m{^(https?)://www\.nicovideo\.jp/user/([-_0-9A-Za-z]+)} ){
        return "$1://nico.ms/user/$2";
    }

    # mylist
    elsif( $url =~ m{^(https?)://www\.nicovideo\.jp/mylist/([-_0-9A-Za-z]+)} ){
        return "$1://nico.ms/mylist/$2";
    }

    return;
}

sub unshorten {
    my $url = shift or croak 'No URL passed to unshorten';

    my $schem   = undef;
    my $dir     = undef;
    my $id      = undef;
    my $class   = undef;
    if( $url =~ m{^(https?)://nico\.(?:ms|sc)/(\w+)/([-_0-9A-Za-z]+)} ){
        $schem  = $1;
        $dir    = $2;
        $id     = $3;
    }elsif( $url =~ m{^(https?)://nico\.(?:ms|sc)/((\w{2})[-_0-9A-Za-z]+)} ){
        $schem  = $1;
        $id     = $2;
        $class  = $3;
    }

    if( defined $dir and defined $schem and defined $id ){

        if( 0 ){
            return;
        }

        # live
        elsif( $dir eq 'l' ){
            return "$schem://live.nicovideo.jp/watch/$id";
        }

        # dictionary
        elsif( $dir eq 'dic' ){
            return "$schem://dic.nicovideo.jp/id/$id";
        }
        
        # user
        elsif( $dir eq 'user' ){
            return "$schem://www.nicovideo.jp/user/$id";
        }
        
        # mylist
        elsif( $dir eq 'mylist' ){
            return "$schem://www.nicovideo.jp/mylist/$id";
        }

        else{
            return;
        }

    }elsif( defined $class and defined $schem and defined $id ){

        if( 0 ){
            return;
        }

        # douga
        elsif( $class eq 'sm' or $class eq 'nm' or $class eq 'so' ){
            return "$schem://www.nicovideo.jp/watch/$id";
        }
        
        # seiga
        elsif( $class eq 'im' ){
            return "$schem://seiga.nicovideo.jp/seiga/$id?ref=nicoms";
        }
        elsif( $class eq 'sg' or $class eq 'mg' ){
            return "$schem://seiga.nicovideo.jp/watch/$id?ref=nicoms";
        }
        elsif( $class eq 'bk' ){
            return "$schem://seiga.nicovideo.jp/watch/$id";
        }

        # live
        elsif( $class eq 'lv' ){
            return "$schem://live.nicovideo.jp/watch/$id";
        }

        # community
        elsif( $class eq 'co' ){
            return "$schem://com.nicovideo.jp/community/$id";
        }

        # channel
        elsif( $class eq 'ch' ){
            return "$schem://ch.nicovideo.jp/channel/$id";
        }
        elsif( $class eq 'ar' ){
            return "$schem://ch.nicovideo.jp/article/$id";
        }

        # chokuhan
        elsif( $class eq 'nd' and $id =~ /^nd\d+$/ ){
            $id =~ s/^$class//;
            return "$schem://chokuhan.nicovideo.jp/products/detail/$id";
        }

        # ichiba
        elsif( $class eq 'az' or $class eq 'ys' or $class eq 'gg' or $class eq 'ga'
            or $class eq 'nd' or $class eq 'dw' or $class eq 'it' or $class eq 'ip' ){
            return "$schem://ichiba.nicovideo.jp/item/$id";
        }

        # app
        elsif( $class eq 'ap' ){
            return "$schem://app.nicovideo.jp/app/$id";
        }

        # jikkyou
        elsif( $class eq 'jk' ){
            return "$schem://jk.nicovideo.jp/watch/$id";
        }

        # commons
        elsif( $class eq 'nc' ){
            return "$schem://www.niconicommons.jp/material/$id";
        }

        # news
        elsif( $class eq 'nw' ){
            return "$schem://news.nicovideo.jp/watch/$id";
        }

        else{
            return;
        }
    }

    return;
}


1;
__END__


=pod

=head1 NAME

Net::NicoVideo::URL - nicovideo URL

=head1 SYNOPSIS

    use Net::NicoVideo::URL;
    
    shorten("http://www.nicovideo.jp/watch/sm1097445");
    unshorten("http://nico.ms/sm1097445");

=head1 DESCRIPTION

This module provides functions to convert long URL and short URL mutually.

=head1 SEE ALSO

L<http://dic.nicovideo.jp/a/nico.ms>
L<http://dic.nicovideo.jp/a/id>

=head1 AUTHOR

WATANABE Hiroaki E<lt>hwat@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
